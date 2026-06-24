## Context

`firebase-auth-multiuser-sync` 已建立同步基礎，但實測有四個缺口：web 連 `firebase/firestore` 都沒 import、零 `onSnapshot` (純 REST + 30 秒 cache)；iOS `CloudSyncFeatureFlag.isEnabled` 預設關閉、`CloudSync` 只有 collection 參照零 listener、且**完全沒有後端 API client** (訂單只進本機 SwiftData，CloudKit 關閉)；後端各 model 無時鐘/版本欄、`update()` 為整筆覆蓋的 last-write-wins、鏡像失敗只 `Logger.warn`。

使用者定奪三項策略，決定本設計走向：(1) **iOS 離線優先**——SwiftData 維持本機 SoT、離線可編輯、跨裝置同步 opt-in；(2) **欄位級合併**——不同欄位自動合併、同欄才決勝，且必須平台中立 (任意兩平台同帳號皆一致收斂)；(3) **失敗 retry 3 次後顯示待同步/失敗狀態**、自動重送、不採持久化 outbox。

既有鐵則延續：後端 domain 層為財務公式唯一實作、per-order summary 由後端算好附 DTO、金額 decimal-as-string；後端為 Firestore/Storage 唯一寫入方、Postgres 為 SoT；同步 metadata 不進 shared/data-model schema (延續 `ownerUid` 先例)；所有「現在」時間經依賴注入。

本設計經對抗式驗證 8 個邊界案例 (時鐘偏移、in-flight 競態、lost-ack、刪除復活、照片表示、合併副作用冪等、lookup cascade、永久鏡像失敗收斂)，以下決策已納入修正。

## Goals / Non-Goals

**Goals:**

- 同一帳號任意兩平台 (iOS↔web 為示範，並涵蓋含 Android 的任意配對) 即時雙向同步 Order/Campaign。
- 並行修改：不同欄位皆保留、同欄位以 HLC 決定性決勝、不誤丟資料、不彈出非必要衝突提示。
- 同步失敗不丟資料：client retry 3 次後顯示待同步/失敗、持久化佇列、恢復自動重送且冪等；後端鏡像永久失敗仍最終收斂。
- iOS 離線可完整操作；sync 關閉時行為與導入前 byte-for-byte 一致。
- 維持後端唯一寫入方、Postgres SoT、財務計算後端化、shared schema 不變。

**Non-Goals:**

- 不對 `items` 等非 cascade 陣列/JSON 欄位做元素級合併 (v1 採整欄 LWW + 安全處的 union)；元素級 merge 延後。
- 不改既有登入方式、不處理 Android 實作 (但合約平台中立、不得假設只有 iOS+web)。
- 不把財務計算或衝突判定搬到 client 或 Cloud Function。
- 不採持久化 payload outbox；不做正式資料 migration (dev 重建)。
- 不強化 Firestore Security Rules 完整規則集。
- 同步 metadata 不進 shared/data-model 領域 schema。

## Decisions

### 以後端集中的欄位級合併取代樂觀並行 409

Order/Campaign 各帶每欄位 HLC 時鐘圖 `fieldClocks`。client 送 partial patch `{ id, changedFields, fieldClocks, optional delete }` 到 `PATCH /orders/:id`、`/campaigns/:id`。後端逐欄套用：incoming 勝出當且僅當 `incomingClock > storedClock` (嚴格大於，等於保留 stored)；不同欄位兩裝置各自存活 (自動合併)、同欄位以時鐘再 writerId 決勝。Order/Campaign 全部寫入路徑 (POST/PUT/status/receipt/merge/cascade) 收斂走同一 `applyFieldWrites` 核心。PATCH 回應帶完整 DTO (含後端重算 summary)、`appliedFieldClocks` 與每欄位權威合併值，讓寫入端能精確清除 dirty (不依賴可能遺失的快照)。
替代方案：整筆 version + expectedVersion + 409 (先前草稿)——否決，每次並行都丟掉一裝置的不相交欄位修改並無謂提示；client 端合併——否決，三平台漂移；整筆 PUT LWW——否決，覆蓋並行不相交修改。

### HLC 含「接收」步驟、後端為線性化點並 clamp 偏移

時鐘為 Hybrid Logical Clock `{ p:physicalMillis, c:logicalCounter, w:writerId }`，序列化為可排序零填字串 (p 寬 13 : c 寬 6 : w)，使字典序等於因果序。三個操作每平台一致：(1) GENERATE `next.p=max(injectedNow,lastIssued.p)`、`next.c=(lastIssued.p==next.p ? lastIssued.c+1 : 0)`；(2) RECEIVE——觀察到任何遠端 HLC (拉回欄位、tombstone、API 回應) 後、下一次本地寫入前，`lastIssued.p=max(lastIssued.p, m.p, injectedNow)`、tie 時 counter+1，並**持久化**使其跨重啟存活；(3) COMPARE 依 p→c→w。後端對每個 PATCH 跑 RECEIVE、對超過容忍度 (5 分鐘，對應裝置時鐘偏差、非離線時長；apply 定案) 的未來時鐘 reject(400)/clamp，並以**確定性、冪等**的伺服器時鐘重新蓋章勝出欄位 (相同重送得相同 stored clock、為真正 no-op)。物理時間只經注入依賴讀取 (iOS `@Dependency(\.date)`、後端 `NowService`、web 注入 clock)。
替代方案：僅 generate+compare (原始片段)——否決，缺少承載偏移界限的 receive 步驟；純裝置時間戳——否決，偏移無界、勝者錯誤；純伺服器時間戳——否決，喪失離線因果序；vector clock——否決，每欄位儲存/修剪成本不成比例。

### iOS 離線優先：SwiftData 為本機 SoT、sync opt-in 且關閉時完全惰性

SwiftData (`PersistenceContainer.shared`、CloudKit 關閉) 維持唯一本機 SoT、離線新增/編輯/刪除與現況完全相同。sync 由 `CloudSyncFeatureFlag.isEnabled` (預設關閉) 控制；關閉時不實例化任何 `CloudSyncEngine`/`BackendAPIClient`/listener，且新增的本機專屬 model (`SyncMeta`、`SyncQueueItem`) 不改變既有 on-disk 行為 (新 schema 版本經證明等價/flag-gated，未啟用 sync 的 store 絕不靜默 migration)。開啟 (Firebase 登入後) 時 `CloudSyncEngine` 推送 dirty 欄位 patch、拉回投影並透過**同一個** `OrderPersistence @ModelActor` 逐欄合併進 SwiftData，使 TCA 功能永不與引擎競態。所有同步 metadata (每欄位時鐘、dirty 集、tombstone、pending/failed、lastIssued HLC、pendingRemote、photoRefs) 放本機專屬 sidecar、不入 `OrderRecord` 或生成型別。
替代方案：把欄位加進 `OrderRecord`/領域型別——否決，污染 mapping、觸發 SwiftData 屬性指紋 migration 陷阱、誘使違規改 shared schema；第二個 ModelContainer——否決，會破壞 SwiftData 狀態；寫入直穿 API + SwiftData 當讀取快取——否決，破壞離線。

### 拉取合併保護 DIRTY 欄位、但絕不靜默丟棄較高時鐘的遠端值

拉取時每個遠端欄位合併進 SwiftData 當且僅當 `remoteClock > localClock` 且該欄位非本機 DIRTY (未推送)。DIRTY 欄位受保護，但若被略過的遠端帶有較本機更高的時鐘，引擎將其記入 `SyncMeta.pendingRemote[field]` (有別於 `lastPulledVersion`)、不丟棄。DIRTY 只在 push ACK 時逐欄、於單一 `@ModelActor` 交易內、以 PATCH 回應清除：若 `appliedFieldClocks[X]==myPushedClock` 表示本機值勝出→寫入 clock 並清 DIRTY；若 `>` 表示本裝置敗→採用伺服器回傳權威值+clock 並清 DIRTY；清除後若 `pendingRemote[X].clock` 較高則套用 (補放 in-flight 窗口略過的值)。重新訂閱時亦以拉回投影對 DIRTY 做核對：若投影已反映本裝置值且 clock≥本機 dirty clock，即使原 ack 遺失也清 DIRTY。
替代方案：HTTP 送出/成功即清 DIRTY 而不比對 `appliedFieldClocks`——否決，把「已送達」誤當「我方勝出」→永久分歧；靜默丟棄受保護快照——否決，喪失較新值唯一一次的送達；僅依首次回應清 DIRTY——否決，ack 遺失即把欄位釘死 DIRTY、永遠重推。

### 刪除為帶時鐘 tombstone、復活還原完整欄位集

Order/Campaign 新增 `deletedAt`+`deleteClock`。軟刪除保留整列與所有每欄位時鐘 (`deletedAt` 設值)，並鏡像顯式 tombstone 文件 `{ _deleted:true, _deleteClock }`、絕不用文件缺席表示。並行欄位寫入時：若任一 incoming 欄位 clock 嚴格大於 `deleteClock`→**復活**：取消 `deletedAt`、保留全部欄位於其 stored clock、僅疊上 `incomingClock > storedFieldClock` 的 changedFields、再對整列跑 normalize/clamp；若 `deleteClock` ≥ 全部 incoming clock 則維持刪除；位元全等 (p→c→w 完全相同) 時 delete 勝 (Option A：統一 `p→c→w` 比較器、writerId 統一參與決勝，不為 delete 另開「只比 (p,c)」特例；同 (p,c) 不同 w 由 writerId 決，可能改欄位勝→復活；apply 定案)。讀取 filter `deletedAt IS NULL`。tombstone 保留有界窗口 (90 天，= 支援的最大「離線且持續編輯」窗；apply 定案) 後硬清除。
替代方案：復活只套那些較晚欄位 (原始措辭)——否決，靜默清掉低於 deleteClock 的未觸及欄位、產生缺必填欄的 Frankenstein 列；永遠刪除勝忽略時鐘——否決，丟掉嚴格較晚的修改；硬刪除/文件缺席——否決，殭屍重推、無法區分已刪與未同步。

### 以 client UUID upsert 達重送冪等、跨實體合併副作用時鐘守衛並短路

實體 id 為 client 生成 UUID，create=以 `(ownerUid,id)` upsert=在 create 時鐘下的 PATCH-all；對不存在 id 的 PATCH 自動建立 (對整列跑 normalize/clamp)。關鍵：訂單合併把來源訂單翻成 `status='merged'` 的副作用本身受時鐘守衛——僅當 `mergeClock > 來源 status 欄位時鐘` 才設定並蓋章；當合併後訂單 M 已存在 (重送)，整個合併交易短路 (跳過來源 updateMany)。每次寫入後重新鏡像自我修復暫時的 Firestore 缺漏。
替代方案：伺服器生成 id——否決，重試 create 會重複；獨立 idempotency-key 表——否決，UUID+時鐘已足、且違背「後端保持簡單」；重送時盲目非時鐘 updateMany——否決，重複套用、丟掉來源較晚的並行修改。

### 照片：base64 單一線上表示、後端為 Storage 唯一寫入方、內容雜湊鍵、合併取聯集

PATCH 與所有 API DTO 的 `photos` 一律 base64 (對齊現行 Postgres/DTO 現實)；client (含 iOS) 絕不上傳 Storage 或在 patch 送路徑參照——後端維持 Storage 唯一寫入方。Firestore 投影以**另一個** `photoRefs` 鍵承載參照 (絕不放 base64)；拉取端在任何欄位合併前先把 `photoRefs` 解析回 `[Data]`、絕不把參照字串寫入 `[Data]` 欄。Storage 鍵內容定址 (`photo-{sha256}.jpg`)，使重送/重排冪等且不覆蓋不同影像；blob GC 以每次寫入後的合併參照集為準。`photos` 以內容雜湊取聯集合併 (對齊 `makeMergeDraft` 既有 `orderedUnion`)，使兩裝置並行新增不會靜默丟照片。PATCH normalize 套用與 create 相同的 `MAX_PHOTO_COUNT` 切片。
替代方案：iOS 上傳 Storage 並送路徑參照——否決，把路徑字串 base64-decode 成亂碼覆蓋真 blob (永久影像遺失 + 跨裝置不同步)；index 鍵 `photo-{i}.jpg`——否決，重送/重排覆蓋不同 blob、孤兒永不 GC；整陣列 LWW——否決，靜默丟掉並行新增。

### 持久化鏡像修復：dirty-key 掃描 (非 payload outbox) 確保永久失敗不留陳舊

後端鏡像有限次內聯重試 (3 次，退避 100/300/900ms) 後 `Logger.warn` 並回成功 (Postgres 已 commit、絕不 rollback、絕不 throw)。為補殘餘缺口，內聯重試耗盡時在 Postgres 列蓋 `mirrorDirty`+`mirrorPendingSinceClock`；輕量背景掃描 (NestJS `@Interval` 每 30 秒週期觸發、不做 on-read；SLA 永久失敗後 ~1 分鐘內收斂、每輪批次設上限；apply 定案) 從 Postgres 重算當前列重新鏡像 dirty 列——只存 dirty **鍵** (從 SoT 重算)，非被否決的持久化 payload outbox。client 仍於每次 (重新) 訂閱/重啟對投影全量重讀核對；因投影已被掃描自我修復，重讀能抵達權威值。
替代方案：純「client 重讀投影」無修復觸發 (原始合約)——否決，重讀同一陳舊文件、分歧無界；完整持久化 payload outbox+worker——使用者否決；鏡像失敗就 throw/讓 API 失敗——否決，Postgres 為 SoT 且已 commit。

### Lookups 與陣列：referential 完整性走元素級時鐘 cascade、lookup 本身整筆 LWW + 合併時正規化

Category/OrderSource/VerificationStatus/PaymentMethod 各加單一 `recordClock` (新增/改名/刪除整筆 LWW)。刪除於投影採帶 `recordClock` 的 tombstone 文件 `{ _deleted:true, recordClock }` (與 Order/Campaign 同一套、留 90 天)、改名 = 舊名 tombstone + 新名建檔，取代現行硬刪；delete-vs-rename 競態以 `recordClock` 經統一 `p→c→w` (Option A) 決勝 (apply 定案)。但改名/刪除 cascade 到 `Order.categories`/`campaignNames` 為**元素級且時鐘感知**：把這些陣列建模為每元素帶時鐘的集合，cascade 只改受影響元素 (Food→Snacks) 而並行不相交新增 (Gifts) 存活。此外每筆 order PATCH 合併時對該 uid 當前 lookup 集正規化陣列值——其 lookup 在 ≤ 欄位時鐘時被改名/刪除者於後端自動遷移或剝除 (比照 `isCashOnDelivery` 為衍生而非輕信)；`removeCategory`/`removeOrderSource` 加同樣 cascade-strip 使 lookup 刪除不致孤立 order 參照。其餘陣列/JSON 欄位 (如 `items`) v1 維持整欄單一時鐘 + 語意安全處 union。
替代方案：在改名時鐘整陣列重蓋 (原始)——否決，「較晚直接編輯勝」會重新帶回被刪 lookup 名並孤立；一次性 cascade 無常駐不變式——否決，孤兒永不修復。

## Implementation Contract

> 完整逐平台合約 (行為、資料形狀、失敗模式、驗收) 由 design workflow 對抗驗證後產出，摘要如下；apply 時以各平台 `applyFieldWrites`／`CloudSyncEngine`／`useFirestoreCollection` 為落地點。

**Behavior：** 同帳號 iOS(A)+web(B)：A 改某欄位成功後 B 經 listener 數秒內看到合併值 (含後端 summary)；反向亦然。A、B 並行改不同欄位→兩者皆存活；改同欄→HLC 決定性決勝。A 離線編輯→進佇列、UI 顯示待同步、恢復後自動推送並被 B 觀察到。A 刪除 vs B 改欄 (較晚時鐘)→復活並保留 B 未觸及欄位。iOS sync 關閉→純本機、零網路、零 migration。

**Interface / data shape：** `PATCH /orders/:id`、`/campaigns/:id` body `{ id, changedFields, fieldClocks:{field:HLC}, delete?:{clock} }`，缺欄位時鐘→400；回應 `{ DTO(含summary), appliedFieldClocks, deletedAt }`。Prisma 加 `fieldClocks Json`、`deletedAt`、`deleteClock`、`mirrorDirty`、`mirrorPendingSinceClock` (Order/Campaign)、`recordClock` (lookups)，additive via schema push。Firestore 同步信封 `{ _writerId, _fieldClocks, _deleted, _deleteClock, photoRefs }`、`_syncStatus` 為 client 端專屬。iOS `SyncMeta`/`SyncQueueItem` 為本機專屬 @Model (新 `BuyLedgerSchemaV12` lightweight)。HLC 字串 `p(13):c(6):w`、後端 writerId 字面 `server`。

**Failure modes：** 缺欄位時鐘→400；incoming p 超 5 分鐘容忍→400/clamp；等時鐘同欄→writerId 決定性決勝；永久鏡像失敗→`mirrorDirty` 掃描自我修復、client 重讀抵達權威值；ack 遺失→以投影核對清 DIRTY、不永久釘死；tombstone 保留須大於最大離線窗。

**Acceptance criteria：** 後端測試涵蓋不相交皆保留、同欄較高時鐘勝、偏移離線 A 後到 vs 線上 B→B 存活、刪(1800) vs 改 amount(2000)→復活保留 customerName/note、lost-ack create→不重複不回退來源狀態、鏡像 3 次失敗後無後續寫入仍由掃描重新鏡像、summary 合併後重算、照片並行新增取聯集無 blob 損壞。iOS：模擬器 build and run，登入後可演示 A↔B/衝突/失敗、flag 關閉行為不變。Web：docker compose build and run 於 localhost:3000、即時反映另一端、可演示衝突與失敗。跨平台型別：`shared/data-model` check 通過 (exit 0)、同步 metadata 不在生成型別。

**Scope boundaries：** In scope：共用 HLC 規格 + conformance vectors；後端 `applyFieldWrites`+PATCH+tombstone+冪等合併+照片內容雜湊+鏡像 dirty-key 掃描+lookup 元素級 cascade；web onSnapshot+writeQueue+HLC；iOS 本機優先 sync 引擎+API client+SyncMeta sidecar+待送佇列；三平台版本與文件同步。Out of scope：`items` 元素級合併、Security Rules 完整強化、Android 實作、email/password 登入、正式資料 migration、把同步 metadata 放 shared schema。

## Risks / Trade-offs

- [HLC 正確性依賴每平台一致實作 receive/max-merge；單一不合規 client 即破壞全域排序] → 以共用 normative 規格 + 跨平台 conformance vectors，後端為權威線性化點。
- [`items` 等非 cascade 陣列以整欄時鐘 v1 仍可能丟並行元素編輯] → v1 接受、元素級延後並記 Open Questions。
- [dirty-key 鏡像掃描為新基礎設施；掃描自身停擺則投影自我修復延遲] → 需監控與掃描 SLA、client 重讀為界。
- [新增 SyncMeta/SyncQueueItem 需新 SwiftData schema 版本並重評 version-removal 政策；誤 gate 會靜默 migration 未啟用 sync 的 store] → flag-gate + 證明等價 + 凍結 V11 shadow。
- [伺服器偏移 clamp 容忍 (5 分鐘) 為可調；太緊拒絕合法離線編輯、太鬆重開偏移勝出漏洞] → 對齊真實最大離線窗調參。
- [元素級 cascade + 合併時正規化較整陣列重蓋更具侵入性；漏一路徑即重開孤立/遺失窗] → 集中於 `applyFieldWrites` 與 `removeCategory/removeOrderSource`。
- [內容雜湊照片鍵 + GC 改 Storage 佈局；GC 錯誤可能刪掉慢裝置仍引用的 blob] → GC 以合併參照集為準並尊重 tombstone 保留。
- [web 無持久本機 DB、其 dirty-guard 弱於 iOS] → iOS↔web parity 須測不可假設，共用 conformance vectors。

## Migration Plan

- dev 部署：改 Prisma schema (加上述欄位) → schema push (additive，`--accept-data-loss` 於 dev) 重建 → 帶 owner 且空 clock 的種子重灌 (空 clock 排序在任何真實 HLC 之前→首個 client 寫入勝，刻意) → 啟用鏡像掃描 → web/iOS 接 listener 與 API client。iOS 新增 `BuyLedgerSchemaV12` 走 `/swiftdata-schema-migration` 流程。無 production 資料 migration。
- rollback：功能仍在 dev，回退即移除 PATCH/合併核心/掃描並還原 schema 後重建；client sync 關閉即回純本機行為。

## Open Questions（本輪 apply 全數定案）

以下原為待決項，經與使用者逐項討論後定案；參數與規則已併入上方 Decisions、欄位列舉見下方「欄位分類 (apply 定案)」。

- writerId 來源**已定案**：iOS = Firebase Installation ID (FID)、web = localStorage UUID、後端 = 字面 `server`；原議的 FCM device token 因需 APNs/aps-environment (未 provision) 否決。
- tombstone 保留窗 / 偏移 clamp 容忍**已定案**：clamp 容忍 **5 分鐘** (對應裝置時鐘偏差、非離線時長)、tombstone 保留 **90 天** (= 支援的最大「離線且持續編輯」窗)。
- `items` 等非 cascade 陣列/JSON**已定案**：v1 採整欄 LWW、元素級合併延後 v2。
- dirty-key 鏡像掃描觸發**已定案**：採 NestJS `@Interval` 週期 cron **每 30 秒**、不做 on-read；SLA 永久失敗後 ~1 分鐘內收斂、每輪批次設上限。
- lookup 刪除於投影表示**已定案**：採帶 `recordClock` 的 tombstone 文件 `{ _deleted:true, recordClock }` (與 Order/Campaign 同一套、留 90 天)、改名 = 舊名 tombstone + 新名建檔，取代現行硬刪。
- 長期離線 delta-pull/backfill**已定案**：v1 僅靠 Firestore listener 全量重讀 (per-user 投影即完整現況)、不做 since-hlc REST 端點；90 天墓碑窗界定正確性邊界、超窗離線屬不支援範圍。延後 v2。
- 等 HLC 的 delete-vs-update**已定案**：採 **Option A** —— 統一 `p→c→w` 比較器，復活 iff incoming 欄位 clock 嚴格大於 `deleteClock`、delete 僅在位元全等時勝；同 (p,c) 不同 w 由 writerId 決 (與欄位間決勝一致)，不為 delete 另開「只比 (p,c)」特例。
- Order/Campaign 欄位分類**已定案**：見下方「欄位分類 (apply 定案)」。

## 欄位分類 (apply 定案)

Order/Campaign 各欄位依「是否參與欄位級合併、是否帶 client clock」分四類；對應 task 1.2 的 vectors 標註與 `applyFieldWrites` 套用。

**A. 唯讀／不可變** (create 後鎖定、不收 clock、排除於欄位圖)

| 範圍 | 欄位 |
|---|---|
| Order | `id`、`mergedSourceIDs` |
| Campaign | `id` |

> domain `LedgerOrder` 無 `createdAt`；持久層 Postgres `createdAt` client 從不送，不屬同步欄位。

**B. 後端衍生／重算** (不收 client clock、不參與合併、由 normalize 從來源欄位重算)

| 欄位 | 來源 |
|---|---|
| `isCashOnDelivery` | 依勝出的 `paymentMethod` 主檔旗標重算 |
| `customerInitials` | 依勝出的 `customerName` 以 `deriveInitials` 重算 |
| per-order `summary` | 後端財務公式重算、掛 DTO 並隨投影鏡像 (每次重算、與投影欄位一致)、不入欄位合併圖、Postgres 不存 |

**C. 一般可合併** (各帶 clock、`incoming > stored` 嚴格大於才套用、writerId 決 tie)

| 範圍 | 欄位 |
|---|---|
| Order | `customerName`、`customerTier`、`currency`、`date`、`itemCost`、`domesticShipping`、`internationalShipping`、`foreignDomesticShipping`、`cardFeeRate`、`platformFeeRate`、`paymentFeeRate`、`chargedAmount`、`cardlessDeductionAmount`、`cardlessSupplementAmount`、`paymentMethod`、`notes`、`paymentReceiptStatus` |
| Campaign | `name`、`openDate`、`closeDate`、`settledDate`、`notes` |

> `customer` 採 decomposed 粒度：`customerName`、`customerTier` 各自帶 clock (並行改名 vs 改分級皆存活)；`customerInitials` 歸 B 類衍生。

**D. 可合併但帶特殊規則**

| 欄位 | 規則 |
|---|---|
| Order `status` | 一般值 higher-clock-wins；`merged` 為 sticky 終態 (一般 PATCH 忽略 `status` 欄、不可直接設 `merged`，只由合併流程 clock-guarded 副作用寫入，task 2.6)；`cancelled` 不 sticky |
| `photos` | 內容雜湊 union 合併 (task 2.7)，非整欄 LWW |
| `items` | v1 整欄 LWW，元素級合併延後 v2 |
| `categories`、`campaignNames` | 元素級、lookup 改名/刪除 cascade-aware (task 2.10) |
| `orderSource`、`verificationStatus` | 字串引用 lookup，cascade-aware (task 2.10) |
| Campaign `status` | C 類可合併 + auto-close (closeDate 早於 now → `closed`) 當後端 normalize 投影、以確定性伺服器時鐘重蓋章 |
| Campaign `name` | C 類可合併 + 改名 cascade `campaignNames` (task 2.10) |

## Implementation Notes (apply 階段精修)

apply 期間就「可示範核心」落地，並做了以下具體實作選擇，與上方 Decisions 一致、僅補充落地細節：

- **writerId 採 Firebase Installation ID (FID)**：iOS `CloudSyncEngine` 以 `Installations.installations().installationID()` 取每安裝穩定 id 當 HLC writerId；web 沿用 localStorage UUID、後端為字面 `server`。原議的 **FCM device token 否決**——FCM token 衍生自 APNs token，需 `registerForRemoteNotifications` + `aps-environment` entitlement，而本專案刻意未 provision，模擬器上 `Messaging.token()` 取不到 (回空字串)；FID 免 APNs、模擬器與實機皆可用，且非自產 UUID。
- **環境設定收斂到 `AppConfiguration`** (取代 `APIKeyProvider`)：統一提供 ExchangeRate / Ollama API key 與後端 base URL。機密 key 經 `Config.xcconfig` → `Info.plist` `$(VAR)` 注入；非機密的後端 base URL 直接定義於 `Info.plist` (`http://localhost:4000/api`)，皆由 `Bundle.main` 讀回，`BackendAPIClient.baseURL` 不再寫死。
- **網路層收斂到 `HTTPClient`**：新增 `send(url:method:headers:body:timeout:)` (組 request + 執行 + 2xx 驗證) 與 `stream` (逐位元組串流，供 NDJSON)，request 組裝抽成 `URLRequestBuilder`、method 用 `HTTPMethod` enum；`BackendAPIClient` 與 `OllamaClient` 皆改走 `HTTPClient`、不再各自手刻 `URLSession`，並改用 `URLSession(configuration: .default)` 而非 `URLSession.shared`。
- **iOS 推送觸發下沉到 `OrderRepository`**：所有訂單異動 (`saveOrder` / `saveOrders` / `mergeOrders` / `removeOrder` / cascade 改名) 在 repository 層統一發通知 (`buyLedgerOrderSaved` / `buyLedgerOrdersResyncNeeded` / `buyLedgerOrderDeleted`)，避免「靠各 feature 呼叫點手動發通知」漏發；`CloudSyncEngine` 以 `handleLocalSave` (單筆 diff 推送) / `syncAllLocalChanges` (批次/合併/改名全量重比) / `handleLocalDelete` (→ 後端 `DELETE /orders/:id`，硬刪 Postgres + Firestore tombstone) 接收。
- **iOS 拉取後刷新 UI**：`CloudSyncEngine.onOrdersMerged` 改觸發 `OrdersFeature.reloadFromStore` (繞過 `.task` 的 `hasLoaded` 防重載)，使遠端變更 upsert 進 SwiftData 後 TCA 畫面即時重讀 (原本接 `.task` 因 guard 而 no-op，導致跨裝置變更不刷新)。
- **Google 登入 URL scheme**：`Info.plist` 補 `CFBundleURLTypes` 註冊 `GoogleService-Info.plist` 的 `REVERSED_CLIENT_ID`，否則點 Google 登入會因缺 scheme 拋 ObjC `NSException` 閃退 (非 Swift `Error`、`do-catch` 攔不到)。
- **observer 收尾**：`CloudSyncEngine` 補 `deinit` 移除 listener 與 3 個 NotificationCenter observer (需 `@preconcurrency import FirebaseFirestore`，比照 `CloudAuth`)。
- **SwiftData**：`BuyLedgerSchemaV12` (lightweight，加 `SyncMeta` / `SyncQueueItem` sidecar) 已落地；migration floor 另經使用者要求由 V7 抬到 V10 (屬獨立維護，非本 change scope)。

**目前實作狀態**：A↔B 即時同步、欄位級合併核心、推送觸發 (含刪除)、拉取刷新 UI 已可運作並於模擬器/後端驗證。尚未完成 (對應下方 tasks 仍為 `[ ]`)：iOS 完整 DIRTY / `pendingRemote` ack 對帳 (4.5)、照片同步 (4.7)、tombstone 復活拉取端 (4.8)、後端 tombstone / 冪等 / 照片 / 鏡像掃描 / lookup 元素級 cascade 等 v2 強化 (2.5–2.11)、以及 iOS 待送佇列 `drainQueue` 的 production 觸發 (app 啟動 + `NWPathMonitor` 重連) 尚未接上。
