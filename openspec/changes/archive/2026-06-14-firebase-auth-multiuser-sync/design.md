## Context

BuyLedger 後端 (NestJS + Prisma + PostgreSQL) 目前無任何身分驗證，且為單租戶單使用者：`Settings` 是固定 singleton、`Order` / `Campaign` / lookups 等實體皆無擁有者欄位，CORS 對前端全開且不帶憑證。iOS 端以 SwiftData (搭配 CloudKit) 做本機持久化與 Apple 生態同步，web 端則透過後端讀寫 Postgres，兩者是互不相通的資料孤島。

既有財務鐵則必須延續：後端 domain 層是財務公式唯一實作、per-order summary 由後端算好附在 DTO、前端不重算；金額/比率以 decimal-as-string 進出 API。本設計在不違反上述前提下，導入 Firebase Authentication 與一條 Firestore 即時投影通道，讓多使用者各自的資料能跨裝置與跨平台同步。後端已安裝 firebase-admin 14。

## Goals / Non-Goals

**Goals:**

- 後端能驗證 Firebase ID token，將每個請求綁定到一個 uid，並按 uid 隔離所有領域資料的讀寫。
- 同一使用者在 web 與 (日後啟用的) iOS 之間看到同一份資料，透過後端寫出的 per-user Firestore 投影即時同步。
- 維持 Postgres 為唯一 source of truth、後端為唯一寫入方，完整保留既有財務計算與 DTO 契約。
- web 與 iOS 支援 Google 與 Apple 登入；iOS 的登入與同步以預設關閉的 feature flag 包裹。

**Non-Goals:**

- 不啟用 iOS 的雲端同步 (flag 預設關閉，僅完成串接)；iOS 預設維持 local-only。
- 不支援 email/password 等 Google、Apple 以外的登入方式。
- 不處理 Android (文件化保留位置)。
- 不做既有資料 migration (dev 階段清空重建)。
- 不讓 client 直接寫入 Firestore，也不把財務計算搬到 Firestore 端 (Cloud Function trigger)。

## Decisions

### 後端為唯一寫入方、Firestore 為非權威即時投影

Postgres 維持 source of truth；後端寫入 Postgres 成功後，再把該實體 (含後端算好的 summary) 鏡像到 Firestore。client 一律經後端 API 寫入，不直寫 Firestore；client 可即時讀取自己的 Firestore 投影，關鍵流程仍可回退讀後端 API。如此保留「domain 層唯一財務實作、後端算 summary」鐵則，並避免雙寫衝突。
替代方案：client 直連 Firestore 讀寫 + Security Rules — 否決，因 summary 必須後端算、財務邏輯無法用 Security Rules 表達，且會繞過後端正規化。

### 以 firebase-admin 驗證 Firebase ID token 並注入 uid 請求情境

以 NestJS Guard 解析 `Authorization: Bearer <Firebase ID token>`，呼叫 firebase-admin 的 verifyIdToken，將解出的 uid 注入請求情境供 Service 取用；驗證失敗回 401。登入方式限定 Google 與 Apple，web 與 iOS 皆同。
替代方案：自建 JWT/session 與使用者憑證表 — 否決，重造輪子且要自行管理密碼與第三方 OAuth。

### 領域實體以 uid 歸屬、Service 層查詢與寫入按 uid 圈

所有領域實體新增擁有者欄位 (對應 Firebase uid)；Service 層每個查詢一律帶該 uid 條件、寫入一律填入當前 uid；`Settings` 由固定 singleton 改為以 uid 為主鍵的 per-user 設定。歸屬與圈選集中在 Service 層 (對齊既有 cascade 集中於 OrdersService 的慣例)。
替代方案：PostgreSQL row-level security — 否決，應用層更可控，且要與 Firestore 投影的歸屬邏輯一致，集中在一處較不易漏。

### ownership 為後端持久化欄位、不進 shared schema

ownership 採後端持久化層：`ownerUid` 只加在後端 Prisma 各 model (Order、Campaign、lookups、`Settings`)，由 token 解出的 uid 填入；shared/data-model schema 與三平台生成型別**維持不變**。Firestore 以 `users/{uid}/…` per-user 路徑編碼 owner，client 只讀寫自己的子集合、DTO 不需帶 owner 欄位。
此選擇讓 shared DTO 維持乾淨、iOS 本機領域模型零變更；未來 iOS 上雲時 owner 仍由後端 Prisma 欄與 Firestore 路徑供應，DTO 無需新增或回填欄位。`CurrencyMetadata`／`FxSnapshot` 屬全域參考資料、不 per-user。
替代方案：把 `ownerUid` 放進 shared schema 並 regenerate 三平台 — 否決，會污染 iOS 本機模型 (flag 關閉時須帶空字串 sentinel、上雲時還要回填)、對 client 冗餘 (子集合路徑已編碼 owner)，並把後端多租戶概念塞進平台中立 schema。

### Firestore 以 per-user subcollection 分層並鏡像全部 collection

Firestore 採 `users/{uid}/<collection>/{id}` 的 per-user subcollection 結構，鏡像範圍涵蓋 orders、campaigns、lookups、settings 等全部 collection；後端寫入時 upsert 對應文件、刪除時同步刪除。文件內容對齊既有 DTO 形狀 (decimal 仍為字串)。
替代方案：單一頂層 collection + ownerUid 欄位 + Security Rules 過濾 — 可行，但 per-user subcollection 對 client 即時查詢與最小權限規則更直覺。

### iOS 登入與 Firestore 同步以預設關閉的 feature flag 包裹

iOS 編入 Firebase Auth 與 Firestore 能力，但「登入 + 跨平台同步」以 feature flag 預設關閉；預設維持 SwiftData 本機儲存與 CloudKit 同步，雲端跨平台同步留作日後 opt-in。
替代方案：iOS 本次完全不接 — 否決，使用者要求先把串接做好，只是預設不啟用。

### dev 階段以清空重建取代資料 migration

新增擁有者欄位、`Settings` 主鍵變更屬 BREAKING；因仍在 dev、尚未上線，採 schema 變更後重建資料庫並以帶 owner 的種子重灌，不撰寫資料 migration。
替代方案：寫 migration 將既有資料指派給某 uid — 否決，dev 無正式資料，徒增複雜。

### 訂單照片改存 Firebase Storage、Firestore 僅放參照

訂單照片以 base64 內嵌會超過 Firestore 單文件 1 MiB 上限。鏡像 order 時，後端將照片上傳至 Firebase Storage (per-user 路徑)，於 Firestore 文件僅放 Storage 參照 (路徑或下載 URL)、不放 raw base64；client 取圖透過該參照向 Storage 取得。Postgres 與後端 API 維持既有 base64 形狀不變 (不影響 order-photo-attachments 既有行為)。新增 Firebase Storage 為外部相依。
替代方案：鏡像時直接排除照片欄位 — 否決，web 等 client 會看不到照片、喪失同步意義。

## Implementation Contract

**Behavior (可觀察行為)：**

- 未帶有效 ID token 的 API 請求一律回 401；帶有效 token 的請求只讀得到、也只能寫入自己 uid 的資料。A 使用者讀不到 B 使用者的任何資料。
- 經後端建立/更新/刪除訂單等寫入成功後，對應的 `users/{uid}/<collection>/{id}` Firestore 文件即時反映同一份資料 (含後端算好的 summary)；刪除則同步移除該文件。
- 訂單照片不內嵌於 Firestore，而是上傳 Firebase Storage 後於文件放參照；client 透過該參照取圖。
- web 可用 Google 或 Apple 登入並呼叫 API；iOS 在 flag 關閉時不顯示登入、不啟用 Firestore，維持本機 SwiftData。

**Interface / data shape：**

- 請求帶 `Authorization: Bearer <Firebase ID token>`；後端 Guard 注入 uid 至請求情境。
- 領域記錄的 `ownerUid` 一律存於後端 Prisma (Order、Campaign、lookups、`Settings`)，由 token 解出的 uid 填入；shared schema 與三平台 DTO 不含 owner。`CurrencyMetadata`／`FxSnapshot` 不 per-user。
- `Settings` 主鍵由固定 singleton 改為以 uid 為鍵。
- Firestore 文件形狀對齊既有 DTO (OrderDTO 等)，金額/比率維持字串。
- 訂單照片於 Firestore 文件以 Firebase Storage 參照 (路徑或 URL) 表示、不含 raw base64；Postgres 與後端 API 維持 base64 不變。

**Failure modes：**

- token 驗證失敗 → 401，不洩漏內部細節。
- 缺 Firebase service account 憑證 → 屬硬失敗 (auth 無法運作)，後端啟動時明確報錯，不靜默放行未驗證請求。
- Firestore 鏡像的瞬時失敗 → 不影響已成功的 Postgres 寫入回應 (Postgres 為權威)，但須記錄並可重試/補償；不得為了鏡像而回退假資料 (對齊產品政策)。

**Acceptance criteria：**

- 測試：未帶 token 的請求得 401；A 使用者查詢得不到 B 的資料；經後端寫入後對應 Firestore 文件出現且 summary 與 DTO 一致；刪除後文件消失。
- 跨平台型別：於 shared/data-model 的 check 通過 (exit 0)，三平台重新生成後皆編譯通過。
- 照片：鏡像後 Firestore order 文件含 Storage 參照、不含 raw base64，且文件大小在 Firestore 上限內。
- iOS：flag 關閉時行為與導入前一致 (本機 SwiftData)。

**Scope boundaries：**

- In scope：後端 auth Guard + uid 圈選 + Firestore 鏡像；訂單照片上傳 Firebase Storage 並於 Firestore 放參照；web 登入與 API 夾帶 token；iOS 串接 Firebase Auth/Firestore 但 flag 關閉；shared schema 擁有者欄位與三平台重新生成；dev 清空重建。
- Out of scope：iOS 雲端同步的實際啟用、email/password 登入、Android、既有資料 migration、Firestore Security Rules 的完整強化 (本次僅做最小自我 uid 限制)。

## Risks / Trade-offs

- [訂單照片 base64 超過 Firestore 1 MiB 單文件上限] → 已決定 (見 Decisions)：鏡像 order 時將照片上傳 Firebase Storage、Firestore 文件僅放參照；新增 Firebase Storage 為外部相依，bucket 與憑證設定走環境變數。
- [Postgres 與 Firestore 短暫不一致] 鏡像非與 Postgres 同交易 → 以 Postgres 為唯一權威，鏡像失敗記錄並重試/補償，client 關鍵讀取可回退 API。
- [全量鏡像放大寫入與成本] 鏡像全部 collection → 先全量滿足需求，日後可按存取模式收斂 (列 Open Questions)。
- [Firebase service account 私鑰外洩] → 私鑰走環境變數注入、不入庫，對齊「不提交私鑰/憑證」原則。
- [日後開啟 iOS 同步的雙真值] SwiftData 與 Firestore 兩份資料的 SoT 取捨 → 本次 flag 關閉規避，留待 iOS 同步上線的獨立 change 處理。

## Migration Plan

- dev 部署：改 shared/data-model schema → 重新生成 → 後端 prisma db push 重建資料庫 → 以帶 owner 的種子重灌 → 啟用 auth Guard 與鏡像。無 production 資料 migration。
- rollback：功能仍在 dev 分支，回退即移除 auth Guard 與鏡像、還原 schema 後重新生成；資料以重建為前提，無需資料回滾。

## Open Questions

- Firestore 鏡像失敗的補償細節 (重試佇列 vs 記錄告警) 與 Security Rules 最小規則集 (client 直讀僅限自身 uid) 的具體形式。
- 全量鏡像是否需排除其他體積大或敏感欄位以控成本。
