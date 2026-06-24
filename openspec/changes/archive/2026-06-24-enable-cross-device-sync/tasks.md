本變更橫跨 shared/backend/web/iOS 四面，屬大型功能。任務依相依性排序、以 TDD 先測後實作，`[P]` 標記可與同群其他 `[P]` 並行 (檔案不重疊且不依賴未完成任務)。**可示範里程碑**：完成第 1–4 群的核心子集後，即可在 iOS 模擬器與 web localhost:3000 演示 A↔B 同步、衝突與失敗；第 5 群為文件與跨平台驗收。

## 1. 共用 HLC 合約與 conformance vectors (shared)

- [x] 1.1 撰寫單一 normative HLC 規格 (token 格式 `p(13):c(6):w`、generate/receive/compare、伺服器 clamp 容忍、writerId 來源) 與跨平台 conformance test vectors (偏移交錯、delete-vs-edit 復活、lost-ack 冪等、照片 union)，對應 design 決策「HLC 含「接收」步驟、後端為線性化點並 clamp 偏移」；行為：三平台可載入同一組向量；驗證：vectors 檔以 JSON 落在共用位置且後端/iOS/web 測試各自引用同一檔。
- [x] 1.2 [P] 在 vectors 中依 design「欄位分類 (apply 定案)」標註 Order/Campaign 每欄位類別 (A 唯讀 `id`/`mergedSourceIDs`；B 衍生 `isCashOnDelivery`/`customerInitials`/summary；C 一般可合併；D 特殊規則 `status`/`photos`/`items`/`categories`/`campaignNames`/`orderSource`/`verificationStatus`/Campaign `status`/`name`)，含 `merged` sticky 終態、`customer` decomposed 粒度、`items` v1 整欄 LWW；驗證：每欄位於向量中標註類別、後端 `applyFieldWrites` 套用測試引用之。

## 2. Backend：欄位級合併、HLC、tombstone、冪等、照片、鏡像修復、lookup cascade

- [x] 2.1 TDD `HlcService` (generate/receive/compare、確定性冪等伺服器蓋章、偏移 clamp) 以 `NowService` 注入，對應 design 決策「HLC 含「接收」步驟、後端為線性化點並 clamp 偏移」，滿足 **HLC operations are identical across platforms and clamped by the backend**；驗證：`hlc.service.spec.ts` 跑 1.1 conformance vectors 全綠。
- [x] 2.2 以 `prisma db push` 加 `fieldClocks Json`、`deletedAt`、`deleteClock`、`mirrorDirty`、`mirrorPendingSinceClock` (Order/Campaign) 與 `recordClock` (lookups) 及 `(ownerUid, deletedAt)` 索引，對應 design Migration Plan；行為：欄位 additive、空 clock 排序在任何真實 HLC 之前；驗證：`prisma db push` 於 docker 後 `prisma validate` 通過、種子 `version=空 clock` 重灌成功。
- [x] 2.3 TDD `applyFieldWrites` 核心 (逐欄 `incoming>stored` 才套用、receive+clamp、確定性重蓋章、合併列跑 normalize/clamp) 並把 POST/PUT/status/receipt/merge/cascade 全路徑收斂走它，對應 design 決策「以後端集中的欄位級合併取代樂觀並行 409」，滿足 **Field-level merge with strict-greater clock acceptance**；驗證：`orders.service.spec.ts` 涵蓋不相交皆保留、同欄較高時鐘勝、偏移離線 A 後到 vs 線上 B→B 存活。
- [x] 2.4 新增 `PATCH /orders/:id` 與 `/campaigns/:id`：body `{ id, changedFields, fieldClocks, delete? }`、缺欄位時鐘回 400、UUID upsert + 對缺 id 自動建立，回應帶 DTO(含後端重算 summary)+`appliedFieldClocks`+`deletedAt`，滿足 **Clients write through the backend and read the projection**；驗證：controller e2e 測試斷言 400/200 形狀與 summary 一致。
- [x] 2.5 實作帶時鐘 tombstone 與非破壞性復活 (保留完整欄位集、僅疊較晚時鐘欄位、等時鐘 delete 勝)、讀取 filter `deletedAt IS NULL`、tombstone 有界保留與清除，對應 design 決策「刪除為帶時鐘 tombstone、復活還原完整欄位集」，滿足 **Delete is a clocked tombstone with non-lossy resurrection**；驗證：測試 delete(1800) vs edit amount(2000)→復活保留 customerName/note。
- [x] 2.6 使訂單合併副作用時鐘守衛 (來源 status 僅當 `mergeClock>storedFieldClock` 才翻 merged) 並於合併後訂單 M 已存在時短路整個交易，對應 design 決策「以 client UUID upsert 達重送冪等、跨實體合併副作用時鐘守衛並短路」，滿足 **Resends are idempotent and side effects are clock-guarded**；驗證：測試 lost-ack 重送 merge-create→不重複且不回退來源較晚 active。
- [x] 2.7 照片：維持 base64 於 wire/DTO、後端為 Storage 唯一寫入方、內容雜湊鍵 `photo-{sha256}.jpg`+GC、鏡像把參照寫入 `photoRefs`(絕不 base64)、以內容雜湊 union 合併、PATCH 套 `MAX_PHOTO_COUNT`，對應 design 決策「照片：base64 單一線上表示、後端為 Storage 唯一寫入方、內容雜湊鍵、合併取聯集」；驗證：測試並行新增照片取聯集、無 blob 覆蓋/孤兒。
- [x] 2.8 鏡像失敗：有限次內聯重試 (3 次 100/300/900ms) 後 log 並回成功、蓋 `mirrorDirty`+`mirrorPendingSinceClock`，新增背景/惰性 dirty-key 掃描自 Postgres 重新鏡像、寫顯式 `_deleted` tombstone 文件，對應 design 決策「持久化鏡像修復：dirty-key 掃描 (非 payload outbox) 確保永久失敗不留陳舊」，滿足 **A permanently failed mirror still converges**；驗證：測試鏡像 3 次失敗且無後續寫入→掃描重新鏡像、離線裝置重連抵達 Postgres 值。
- [x] 2.9 投影文件帶每欄位 HLC、`_deleted`+`_deleteClock`、`photoRefs`，更新 `firestore-mirror.service.ts` 寫同步信封，滿足 **Projection carries clocks, tombstones, and photo references**；驗證：`firestore-mirror.service.spec.ts` 斷言文件含 `_fieldClocks`/`_deleted`/`photoRefs`/`summary` 且無 base64 (summary 後端每次鏡像重算、與投影欄位一致，供 web 直接呈現)。
- [x] 2.10 lookups 加 `recordClock` 整筆 LWW，cascade 到 `categories`/`campaignNames` 改為元素級時鐘感知、每筆 order PATCH 對當前 lookup 集做合併時正規化 (改名遷移/刪除剝除)、`removeCategory`/`removeOrderSource` 加 cascade-strip，對應 design 決策「Lookups 與陣列：referential 完整性走元素級時鐘 cascade、lookup 本身整筆 LWW + 合併時正規化」；驗證：測試 lookup 改名 cascade 與並行不相交陣列新增並存、刪除不孤立參照。
- [x] 2.11 補齊後端 conformance + 回歸測試：跑 1.1 全 vectors、summary 合併後重算、既有 uid 圈選不回歸；驗證：`bun run test` (backend) 全綠且 `shared/data-model` `bun run check` exit 0 (同步 metadata 不在生成型別)。

## 3. Web：即時 listener、HLC、partial PATCH、待送佇列

- [x] 3.1 [P] 實作 web `hlc.ts` (三操作、writerId 存 localStorage、lastIssued 持久化跨 reload)，滿足 **HLC operations are identical across platforms and clamped by the backend**；驗證：`hlc.test.ts` 跑 1.1 conformance vectors 全綠。
- [x] 3.2 啟用 `firebase/firestore`、新增 `useFirestoreCollection` 以 `onSnapshot` 訂閱 `users/{uid}/<collection>` 並 `setQueryData` 餵入 TanStack Query cache、於每次 (重新) 連線做全量重讀，滿足 **Projection carries clocks, tombstones, and photo references** 的 client 消費端；驗證：手動於兩分頁/裝置改一端，另一端無刷新即更新 (對應 firestore-realtime-projection)。
- [x] 3.3 `api.ts` 寫入改送 partial PATCH `{ id, changedFields, fieldClocks }`、移除任何 PUT/409 路徑、in-flight 編輯防 snapshot 覆蓋，滿足 **Clients write through the backend and read the projection** 與 **Field-level merge with strict-greater clock acceptance** 的 client 端；驗證：兩端並行改不同欄位→皆保留 (手動 + 單元測 patch body 形狀)。
- [x] 3.4 localStorage 持久化 `writeQueue`：retry 3 次 backoff、失敗顯示「待同步/失敗」狀態、恢復/reload 自動重送、UUID upsert 冪等，滿足 **Bounded client retry then observable pending or failed state**；驗證：DevTools 斷網→建單顯示待同步→恢復自動送達 (手動 + 佇列單元測)。

## 4. iOS：本機優先 sync 引擎、API client、SyncMeta sidecar、待送佇列

- [x] 4.1 新增 `BuyLedgerSchemaV12` (lightweight) 加本機專屬 `SyncMeta`/`SyncQueueItem` @Model、凍結 V11 shadow，走 `/swiftdata-schema-migration` 流程，對應 design 決策「iOS 離線優先：SwiftData 為本機 SoT、sync opt-in 且關閉時完全惰性」，滿足 **iOS Firestore sync is gated behind a default-off feature flag**；驗證：flag OFF 時既有 store 開啟無 migration、行為與導入前一致 (migration 單元測 + 手動)。
- [x] 4.2 [P] 實作注入式 `Hlc`/`HlcClient` (三操作、seed 自 `@Dependency(\.date)`、lastIssued 存 `SyncMeta`)，滿足 **HLC operations are identical across platforms and clamped by the backend**；驗證：Swift 測試跑 1.1 conformance vectors、固定 `\.date` 與穩定 writerId 下決定性決勝。
- [x] 4.3 新增 `BackendAPIClient` (`@Dependency`、Bearer Firebase ID token、`patchOrder`/`patchCampaign`/`deleteEntity`、photos 送 base64)，滿足 **Clients write through the backend and read the projection**；驗證：以 stub URLProtocol 測 patch body 形狀與 token 夾帶。
- [x] 4.4 建 `CloudSyncEngine` (flag ON only)：`onSnapshot` 拉取 + 逐欄合併、保護 DIRTY、較高時鐘遠端進 `pendingRemote` 不丟棄，全程經 `OrderPersistence @ModelActor`，對應 design 決策「拉取合併保護 DIRTY 欄位、但絕不靜默丟棄較高時鐘的遠端值」；驗證：TestStore 測 dirty 保護、in-flight 較高時鐘遠端到達→最終收斂遠端。
- [x] 4.5 實作 push-ack 對帳 (依 `appliedFieldClocks` 清/採用、replay `pendingRemote`、重新訂閱以投影核對清 DIRTY)，滿足 **A lost ack does not pin a field dirty forever**；驗證：TestStore 測 lost-ack→投影核對清 DIRTY、佇列不卡死。
- [x] 4.6 `SyncQueueItem` retry 3 次 + 注入式 `NWPathMonitor` 重連 drain + 逐 id 待同步/失敗狀態 (顯示於 LedgerOrder 旁、不入領域/生成型別)、引擎 merged 訊號→`OrdersFeature` re-fetch，滿足 **Bounded client retry then observable pending or failed state** 與 **Opt-in cross-device propagation between same-account platforms**；驗證：TestStore 測離線→重連 drain、UI 狀態轉換。
- [x] 4.7 在 Xcode 加 `FirebaseStorage` 產品、拉取時把 `photoRefs` 解析回 `[Data]` 後再合併 (絕不把參照字串寫入 `[Data]` 欄)，對應 design 決策「照片：base64 單一線上表示、後端為 Storage 唯一寫入方、內容雜湊鍵、合併取聯集」；驗證：手動同步含照片訂單兩端一致、無亂碼。
- [x] 4.8 處理 iOS 刪除 tombstone 與復活 (讀投影 `_deleted`/`_deleteClock`、復活採伺服器完整合併列)，對應 **Delete is a clocked tombstone with non-lossy resurrection**；驗證：TestStore 測本機刪除 vs 遠端較晚改欄→復活保留完整欄位。

## 5. 文件同步與跨平台驗收

- [x] 5.1 依文件同步鐵則更新 `apps/backend/CLAUDE.md`、`apps/web/README.md`、`apps/apple/CLAUDE.md`、`apps/backend/README.md`、root `README.md`：記 HLC/欄位級合併/離線優先/待送佇列硬規則與版本 (iOS 1.4.0 / Web 1.3.0 / Backend 1.2.0)；驗證：`git status` 比對 diff 逐列命中文件同步表、無遺漏。
- [x] 5.2 跨平台驗收：iOS 模擬器 build and run + web `docker compose` build and run 於 localhost:3000，同帳號登入演示 A→B、B→A、衝突 (不同欄位合併/同欄決勝)、失敗 (斷網待同步→恢復) 四情境，滿足 **Opt-in cross-device propagation between same-account platforms**；驗證：四情境逐一以截圖/錄影佐證、flag OFF 時 iOS 行為不變。

## 6. Apply 階段精修 (本次 session 落地與修正)

> 第 1–5 群為原 v2 計畫 (部分仍 `[ ]`)；本群記錄 apply 期間就「可示範核心」實際落地與修正的項目，細節見 design 的「Implementation Notes」。

- [x] 6.1 writerId 採 Firebase Installation ID (FID)：`CloudSyncEngine` 以 `Installations.installationID()` 取得當 HLC writerId (FCM token 因需 APNs/aps-environment 未 provision 而否決)，對應 design「Implementation Notes」writerId 定案；驗證：模擬器推送的 HLC clock `:w` 段為非空 FID (自後端 Postgres `fieldClocks` 解出 `…:elijmlqKgkPRv9xrOCqcnD`)。
- [x] 6.2 環境設定收斂 `AppConfiguration` (取代 `APIKeyProvider`)：統一 ExchangeRate/Ollama key 與後端 base URL，base URL 改由 `Info.plist` 定義、`BackendAPIClient` 不寫死；驗證：`AppConfigurationTests` 全綠、push demo 經注入 base URL 落地後端 Postgres。
- [x] 6.3 網路層收斂 `HTTPClient`：新增 `send`/`stream` + `URLRequestBuilder` + `HTTPMethod` enum，`BackendAPIClient`/`OllamaClient` 改走之並用 `URLSession(configuration: .default)`；驗證：build 通過、push demo 與 AI 串流路徑編譯無誤、push demo 落地。
- [x] 6.4 iOS 推送觸發下沉 `OrderRepository`：所有訂單異動 (save/saveOrders/merge/removeOrder/cascade 改名) 統一發通知，`CloudSyncEngine` 以 `handleLocalSave`/`syncAllLocalChanges`/`handleLocalDelete` 接收；補 `BackendAPIClient.deleteOrder`(DELETE) + 引擎刪除推送 (後端 DELETE 端點已存在)，滿足 **Clients write through the backend and read the projection** 之 iOS 寫入端全路徑覆蓋；驗證：審計確認原本 6 個漏發的異動路徑 (單筆/批次改狀態、收款狀態、合併、刪除、cascade 改名) 皆已涵蓋、build 通過。
- [x] 6.5 iOS 拉取後刷新 UI：`onOrdersMerged` 改觸發 `OrdersFeature.reloadFromStore` (繞過 `.task` 的 `hasLoaded` 防重載)，對應 firestore-realtime-projection 之 client 消費刷新；驗證：模擬器上以後端 PATCH 改一筆訂單→iOS 畫面無重啟即時更新 (前後截圖佐證狀態徽章變化)。
- [x] 6.6 Google 登入 URL scheme：`Info.plist` 補 `CFBundleURLTypes`(`REVERSED_CLIENT_ID`) 修點擊 Google 登入閃退；驗證：build 後 app bundle 內 `Info.plist` 含該 scheme、App 啟動正常。
- [x] 6.7 `CloudSyncEngine` 補 `deinit` 收尾 listener + 3 個 observer (`@preconcurrency import FirebaseFirestore` 比照 `CloudAuth`)；驗證：build 通過。
- [x] 6.8 iOS 待送佇列 `drainQueue` 的 production 觸發：目前僅 DEBUG `--auto-drain` 會呼叫，正式版未接「app 啟動 + `NWPathMonitor` 重連」觸發 (對應 4.6 的重連 drain 尚未生效)；驗證：TestStore/手動測離線推送失敗→重連自動重送、UI 待同步/失敗狀態轉換。
