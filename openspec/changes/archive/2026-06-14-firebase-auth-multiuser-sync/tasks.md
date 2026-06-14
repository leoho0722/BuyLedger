## 1. 跨平台資料模型：ownership 放置確認

- [x] 1.1 ownership 定案為後端持久化層 (對應 design「ownership 為後端持久化欄位、不進 shared schema」)：確認 shared/data-model schema 與三平台生成型別不含 owner，spec「Domain entities are owned by a single user」改由後端 Prisma 欄位 (3.1) 承擔。驗證：LedgerOrder.yaml 與 Campaign.yaml 不含 ownerUid。
- [x] 1.2 執行 bun run generate 並以 check 守門，確認 shared schema 與三平台生成檔同步且皆不含 owner。驗證：在 shared/data-model/generator 跑 bun run check 回 exit 0、三平台 generated 檔皆無 ownerUid。

## 2. 後端 Firebase 初始化與身分驗證

- [x] 2.1 在 apps/backend/src/firebase/ 建立 firebase-admin 初始化，缺 service account 憑證時 fail closed，落實 spec「Missing Firebase credentials fail closed」。驗證：缺憑證啟動即報錯、不靜默放行的單元測試。
- [x] 2.2 在 apps/backend/src/auth/ 實作 NestJS Guard 解析 Authorization: Bearer ID token 並 verifyIdToken (對應 design「以 firebase-admin 驗證 Firebase ID token 並注入 uid 請求情境」)，落實 spec「Backend verifies Firebase ID tokens on protected endpoints」。驗證：無 token→401、invalid token→401、valid token→放行 的 e2e 測試。
- [x] 2.3 將驗證後的 uid 注入請求情境供 Service 取用，落實 spec「Authenticated request context exposes the caller uid」。驗證：Service 能讀到 caller uid 的單元測試。
- [x] 2.4 於 apps/backend/src/app.module.ts 與 apps/backend/src/main.ts 全域套用 auth Guard 並讓 CORS 帶憑證。驗證：受保護端點預設需有效 token 才回 200 的 e2e 測試。

## 3. 後端多使用者資料歸屬

- [x] 3.1 於 apps/backend/prisma/schema.prisma 為 Order、Campaign 及 lookups (Category、OrderSource、PaymentMethod、VerificationStatus) 新增 ownerUid 欄位、Settings 主鍵由 singleton 改為以 uid 為鍵 (對應 design「領域實體以 uid 歸屬、Service 層查詢與寫入按 uid 圈」)；CurrencyMetadata／FxSnapshot 維持全域不加 owner。驗證：prisma db push 成功、上述各 model 含 ownerUid 且 Settings 以 uid 為主鍵。
- [x] 3.2 在 apps/backend/src/orders/、campaigns/、lookups/ 的 Service 查詢一律加 caller uid 條件，落實 spec「Reads are scoped to the caller's uid」。驗證：A 使用者查詢得不到 B 資料的測試。
- [x] 3.3 Service 寫入填入 caller uid、且 update/delete 只命中自己擁有的紀錄，落實 spec「Domain entities are owned by a single user」與「Writes target only records owned by the caller」。驗證：建立後 owner 為 caller、改他人紀錄回 not-found 的測試。
- [x] 3.4 在 apps/backend/src/settings/ 將 Settings 改為 per-user 讀寫，落實 spec「Settings are per-user」。驗證：兩使用者各自獨立 settings、A 改不影響 B 的測試。

## 4. dev 資料重建

- [x] 4.1 改 apps/backend/prisma/seed.ts 讓每筆種子帶 owner，並以清空重建取代資料 migration (對應 design「dev 階段以清空重建取代資料 migration」)，落實 spec「Seeded development data carries explicit ownership」。驗證：db push 重建後 seed 出的每筆 order/campaign/lookup 皆含 owner uid。

## 5. 後端 Firestore 即時投影

- [x] 5.1 在 apps/backend/src/firebase/ 建立 Firestore 鏡像 service，確立後端為唯一寫入方 (對應 design「後端為唯一寫入方、Firestore 為非權威即時投影」)，落實 spec「Backend is the sole writer of Firestore」。驗證：service 寫入 users/{uid}/<collection>/{id} 路徑的單元測試。
- [x] 5.2 在 Postgres 寫入成功後 upsert 對應 Firestore 文件 (含後端算好的 summary)、刪除時同步刪除文件 (對應 design「Firestore 以 per-user subcollection 分層並鏡像全部 collection」)，落實 spec「Authoritative writes are mirrored to per-user Firestore collections」。驗證：建立後對應文件出現且 summary 與 DTO 一致、刪除後文件消失的測試。
- [x] 5.3 讓 Firestore 鏡像失敗不回退已成功的 Postgres 寫入、改記錄供重試，落實 spec「Firestore is non-authoritative」。驗證：模擬鏡像失敗時 API 仍回成功且失敗被記錄的測試。
- [x] 5.4 讓鏡像涵蓋 orders、campaigns、lookups 與 settings 全部 collection，落實 spec「Mirror covers all mirrored collections」。驗證：四類資料變更各自觸發鏡像的測試。
- [x] 5.5 鏡像 order 時將照片上傳 Firebase Storage、Firestore 文件僅放參照 (路徑或 URL) 以守住單文件大小上限 (對應 design「訂單照片改存 Firebase Storage、Firestore 僅放參照」)，落實 spec「Mirrored documents stay within the Firestore document size limit」。驗證：含照片 order 鏡像後，照片進 Storage、Firestore 文件含參照且不含 raw base64、大小在限制內的測試。

## 6. Web 登入與 token 夾帶

- [x] 6.1 [P] 在 apps/web 完成 Firebase client 初始化與 Google、Apple 登入流程，落實 spec「Supported sign-in providers are Google and Apple only」。驗證：登入頁僅顯示 Google 與 Apple、登入後取得 Firebase ID token 的整合驗證。
- [x] 6.2 讓 apps/web 的 API client 一律以 Authorization: Bearer 夾帶 ID token，未登入時導回登入。驗證：受保護請求帶 token、401 時導回登入頁的整合驗證。

## 7. iOS 串接 (預設關閉)

- [x] 7.1 [P] 在 apps/apple 接上 Firebase Auth (Google、Apple) 並以預設關閉的 feature flag 包裹登入 (對應 design「iOS 登入與 Firestore 同步以預設關閉的 feature flag 包裹」)，落實 spec「iOS sign-in is gated behind a default-off feature flag」。驗證：flag 關閉時不顯示登入、行為與導入前一致的測試。
- [x] 7.2 讓 iOS 的 Firestore 同步受同一預設關閉 flag 控制，落實 spec「iOS Firestore sync is gated behind a default-off feature flag」。驗證：flag 關閉時不存取 Firestore、改走本機 SwiftData 的測試。

## 8. 文件同步

- [x] 8.1 [P] 依文件同步鐵則更新 apps/backend/README.md、apps/backend/CLAUDE.md、apps/web/README.md 與 apps/apple/CLAUDE.md，補上 Firebase Auth、Firestore 鏡像、多使用者歸屬與環境設定 (service account 憑證) 等技術棧、外部服務與硬規則。驗證：對照本次 diff 逐列檢查文件同步鐵則表、命中列皆已同步。
