# Web 後端指引 (apps/backend)

本檔記錄 Web 後端 (NestJS + Prisma + PostgreSQL) 的硬規則與隱性 gotcha；跨平台通用規範 (產品政策、標點、註解、Commit 風格、Data Model codegen) 見 repo 根目錄 [`CLAUDE.md`](../../CLAUDE.md)，技術棧與開發指令見本目錄 [`README.md`](README.md)。

## 主要技術棧

- **NestJS 11 + Prisma 6 + PostgreSQL 18**；TypeScript strict。
- 金額/比率運算一律 **decimal.js**，**不可用 JS `number`**。

## 財務邏輯 (單一事實來源)

- **`src/domain/` 是財務公式的唯一實作**，逐項移植自 iOS。改公式只改這裡：
  - `order-summary.ts`：手續費以 `chargedAmount` 為基準；`platformFee` 無條件進位到整數 (`.ceil()`)；`revenue = chargedAmount + 無卡補款 − 無卡折抵`；僅 `isCashOnDelivery` 時三種運費計入成本；`margin = profit/revenue` (revenue 0 時為 0)。
  - `order-merge.ts`：費率以兩筆 `chargedAmount` 加權平均並 clamp [0,1]；付款方式來源「相同取主、恰副屬無卡取副、其餘取主」，對帳狀態與貨到付款旗標隨來源。
- **per-order `summary` 由後端算好附在 OrderDTO**；前端不重算單筆公式 (只做呈現層彙總)。

## decimal-as-string 契約

- API 進出的金額/比率欄位**一律字串**；Prisma 用 `Decimal` 欄位、運算用 decimal.js。日期為 ISO 字串、`date` 欄位 timestamptz。

## 生成型別

- `src/data-model/generated/` 由 `shared/data-model` 的 `datamodel-gen` 產出 (見 root `CLAUDE.md`「跨平台 Data Model」)，**不可手改**；改形狀請改 `shared/data-model/schema/` 後 `cd shared/data-model/generator && bun run generate` (會同時更新 Swift 與前後端兩份 TS)。

## 環境相依注入

- **不可直接 `new Date()` / `randomUUID()`** (除註冊處)；一律走 `src/common/now.service.ts` 的 `NowService` / `IdService`。`BUYLEDGER_FIXED_NOW` (ISO) 可固定時間供 seed/重現。
- 開團「結單日過期自動收單」、合併訂購日期等皆用注入的 now。

## 寫入驗證與正規化

- **全域 `ValidationPipe` 開 `whitelist: true` 會剝除未裝飾欄位**——大型訂單 body 故意用 TS interface 型別 (metatype 為 `Object`，pipe 跳過)，在 `OrdersService.normalize` 內手動正規化：clamp 金額 `>= 0`、費率 `[0,1]`；非無卡付款方式清空 cardless 欄位；非無卡/非銀行匯款清空 `verificationStatus`；`isCashOnDelivery` 一律依付款方式主檔旗標推導 (**不信任前端**)；類別至少一個 (空則補 `未分類`)。

## 合併與 cascade

- **合併儲存原子性**：`create` 帶非空 `mergedSourceIDs` 時，於單一 `$transaction` 插入新訂單並將來源訂單狀態設為 `merged`。
- **改名 cascade 集中在 `OrdersService`** (`cascadeRenameScalar` / `cascadeRenameCategory` / `cascadeRenameCampaign`)；`CampaignsModule`、`LookupsModule` 注入它。類別/開團為陣列欄位，逐筆替換並去重。

## 容器化 gotcha

- **`nest build` 只編 `src/` → `dist/main.js`**。若把 `prisma/` 納入 `tsconfig.build` 的編譯範圍，tsc 的 `rootDir` 會上移，`main.js` 變成 `dist/src/main.js` 害 entrypoint 找不到 → **保持 `tsconfig.build.json` 排除 `prisma/seed.ts`**，種子改由 entrypoint 以 `ts-node` 執行。
- **Prisma on Alpine**：`schema.prisma` 的 `binaryTargets` 須含 `linux-musl-openssl-3.0.x`，Dockerfile `apk add openssl`。
- **PostgreSQL 18**：資料 volume 掛載點為 `/var/lib/postgresql` (**不是** `.../data`；18+ 改用版本子目錄)。
- entrypoint 先 `prisma db push` (retry 等 DB 就緒) → 種子 (有資料自動略過) → 啟動。

## 外部服務降級

- 缺 `EXCHANGE_RATE_API_KEY` → 匯率快照回 `null` (前端空狀態)、幣別清單退回預載 fallback；缺 `OLLAMA_API_KEY` → AI 串流回 400 讓前端顯示失敗狀態。**不偽造資料** (對齊產品政策)。
- 幣別清單 7 天 TTL 快取於 `CurrencyMetadata` 單例。

## 身分驗證與多使用者

- **身分驗證走 Firebase、fail-closed (不同於上述可降級服務)**：`FirebaseAuthGuard` 以 `APP_GUARD` 全域註冊，所有端點預設需 `Authorization: Bearer <Firebase ID token>`；公開端點 (如 `/health`) 以 `@Public()` 豁免。缺 Firebase service account 憑證 (`FIREBASE_PROJECT_ID` / `CLIENT_EMAIL` / `PRIVATE_KEY`) 時 **`FirebaseService` 啟動即拋錯、後端拒絕啟動**，絕不靜默放行未驗證請求。controller 以 `@CurrentUid()` 取呼叫者 uid 傳入 service。
- **所有領域資料一律按 `ownerUid` 圈**：service 層每個查詢帶 caller uid、寫入填入 caller uid、update/delete 只命中自己擁有的紀錄 (否則回 not-found)；**漏一個 uid 過濾＝跨使用者資料外洩**。`ownerUid` 只存於後端 Prisma (Option B)，**不進 shared/data-model schema** (避免污染 iOS 本機模型、對 client 冗餘)。
- **lookups (Category / OrderSource / VerificationStatus / PaymentMethod) 主鍵為複合鍵 `@@id([ownerUid, name])`**：findUnique/upsert/delete 一律用 `ownerUid_name: { ownerUid, name }`。`Settings` 主鍵為 `ownerUid` (per-user)；`CurrencyMetadata` / `FxSnapshot` 維持全域單例、不 per-user。

## Firestore 即時投影

- **後端為唯一寫入方**：`FirestoreMirrorService` 在 Postgres 寫入成功後鏡像到 `users/{uid}/{collection}/{id}`；client 不直寫 Firestore。**Firestore 非權威 (Postgres 為 SoT)**：鏡像失敗只記錄告警、不拋出、不回退已成功的寫入。cascade 改名 / 合併 / 自動收單等衍生變動須一併重新鏡像受影響紀錄 (見 `OrdersService.remirrorOrders`、`CampaignsService.autoClose`)。
- **訂單照片改存 Firebase Storage**：`mirrorOrder` 把 base64 照片上傳 `users/{uid}/orders/{id}/photo-{i}.jpg`、Firestore 文件只放路徑參照 (避免超過 Firestore 單文件 1 MiB 上限)；Postgres 與 API 維持 base64 不變。

## 測試 gotcha

- **`firebase-admin` v14 依賴 ESM-only 的 `jose`，jest (CJS) 直接 import 會解析失敗**。凡測試檔會 (直接或經由 `FirebaseService` / `FirestoreMirrorService` 間接) import firebase-admin，檔頭一律加 `jest.mock('firebase-admin/app'|'/auth'|'/firestore'|'/storage', …)`。production 走 `nest build` (tsc) 與 Node 不受影響。
- 單元測試以 mock Prisma 驗 uid 圈選；全域 guard 行為用 `@nestjs/testing` + `supertest` 整合測試。
