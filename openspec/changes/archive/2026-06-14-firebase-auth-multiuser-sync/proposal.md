## Why

BuyLedger 後端目前沒有任何身分驗證、且是單租戶單使用者 (Settings 為寫死的 singleton、所有領域資料皆無歸屬)，iOS (本機 SwiftData) 與 web (Postgres) 是互不相通的兩座資料孤島。要支援多位使用者各自的帳號與資料、並讓同一使用者跨裝置與跨平台看到同一份資料，必須導入身分驗證與一條跨平台同步通道。

## What Changes

- 導入 **Firebase Authentication** 作為身分提供者 (IdP)，web 與 iOS 皆支援 Google 與 Apple 兩種登入。
- 後端以 firebase-admin 驗證每個請求的 Firebase ID token，將請求綁定到一個 uid；未通過驗證的請求一律拒絕。
- **多使用者資料歸屬**：訂單、開團、lookups 等實體加上以 uid 為鍵的擁有者欄位，所有讀寫一律按 uid 圈；Settings 由全域 singleton 改為 per-user。
- **BREAKING**：既有 Postgres 單使用者資料清空重建 (目前仍為 dev 階段、尚未上線，不做資料 migration)。
- **Firestore 即時投影**：後端維持唯一寫入方，每次寫入 Postgres (source of truth) 後，將該實體鏡像到使用者各自的 Firestore collection；client 可即時讀取自己的資料，但不直接寫 Firestore。鏡像範圍涵蓋全部 collection。
- **訂單照片改存 Firebase Storage**：因 Firestore 單文件 1 MiB 上限，鏡像 order 時將照片上傳 Firebase Storage、Firestore 文件僅放參照 (Postgres 與後端 API 維持既有 base64 不變)。新增 Firebase Storage 為外部服務。
- 保留既有財務鐵則不變：後端 domain 層仍是財務公式唯一實作、per-order summary 仍由後端算好附在 DTO、前端不重算。
- **iOS 範圍**：iOS 本次接上 Firebase Auth 與 Firestore，但「登入 + Firestore 跨平台同步」以 feature flag 預設關閉 (iOS 已有本機 SwiftData)；預設 iOS 維持 local-only，雲端同步留作日後 opt-in。
- ownership 採後端持久化層：`ownerUid` 只加在後端 Prisma 各 model，shared/data-model schema 與三平台生成型別不變；Firestore 以 per-user 路徑編碼 owner、client DTO 不帶 owner。

## Capabilities

### New Capabilities

- `firebase-authentication`: Firebase Auth 作為 IdP (Google + Apple)；client 登入並取得 ID token、後端驗證 token 並建立帶 uid 的請求情境；iOS 的登入以預設關閉的 flag 包裹。
- `multi-user-data-ownership`: 所有領域實體以 uid 歸屬、讀寫按 uid 隔離；Settings 改為 per-user；dev 既有資料清空重建。
- `firestore-realtime-projection`: 後端為唯一寫入方，將 Postgres 權威寫入鏡像到 per-user Firestore collection 供 client 即時讀取；Firestore 非權威來源、鏡像涵蓋全部 collection；iOS 同步以預設關閉的 flag 包裹。

### Modified Capabilities

(none)

## Impact

- Affected specs: 新增 firebase-authentication、multi-user-data-ownership、firestore-realtime-projection 三個 capability；ownership 採後端 Prisma 欄位、shared schema 不變，data-model-codegen 不受影響。
- Affected code:
  - New:
    - apps/backend/src/auth/ (Firebase ID token 驗證 guard 與帶 uid 的請求情境)
    - apps/backend/src/firebase/ (firebase-admin 初始化、Firestore 鏡像 service、訂單照片上傳 Firebase Storage 並回寫參照)
    - apps/web 的 sign-in 介面、Firebase client 初始化、API client 夾帶 ID token 的封裝
    - apps/apple 的 Firebase Auth 串接與預設關閉的同步 feature flag
  - Modified:
    - apps/backend/prisma/schema.prisma (領域實體加 owner 欄位、Settings 改 per-user)
    - apps/backend/src/orders/ (查詢與寫入按 uid 圈、寫後觸發 Firestore 鏡像)
    - apps/backend/src/campaigns/ (同上的 uid 圈與鏡像)
    - apps/backend/src/lookups/ (同上的 uid 圈與鏡像)
    - apps/backend/src/settings/ (Settings 改 per-user)
    - apps/backend/src/app.module.ts (註冊 auth 與 firebase module)
    - apps/backend/src/main.ts (CORS 帶憑證、全域 auth 套用)
    - apps/backend/prisma/seed.ts (改為帶 owner 的 dev 種子)
    - apps/backend/README.md (技術棧與環境設定同步)
    - apps/backend/CLAUDE.md (auth 與 Firestore 鏡像硬規則)
    - apps/web/README.md (Firebase client 環境設定同步)
    - apps/apple/CLAUDE.md (Firebase Auth 與同步 flag 硬規則)
  - Removed:
    - 全域 Settings singleton 概念 (改為 per-user，無實體檔案刪除)
