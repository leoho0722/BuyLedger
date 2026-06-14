# BuyLedger Web 後端

NestJS + Prisma + PostgreSQL 的 REST 後端，功能與財務邏輯對齊 iOS 版。AI 協作硬規則見 [`CLAUDE.md`](CLAUDE.md)。

## 技術棧

| 項目 | 選型 |
|------|------|
| 框架 | NestJS 11 |
| ORM | Prisma 6 |
| 資料庫 | PostgreSQL 18 |
| 金額運算 | decimal.js (decimal-as-string 契約) |
| 型別來源 | `shared/data-model` 生成的 TypeScript |
| 身分驗證 | Firebase Authentication (firebase-admin)；全域 guard 驗 ID token |
| 雲端投影 | Firestore (後端唯一寫入方鏡像) + Firebase Storage (訂單照片) |
| 測試 | Jest + ts-jest + supertest |

## 專案結構

```text
src/
├── domain/            # 財務公式 (order-summary, order-merge)、常數、decimal 設定
├── data-model/        # 生成型別 (generated/) 與 barrel
├── common/            # NowService / IdService (環境相依注入)
├── auth/              # Firebase ID token 驗證 guard、@CurrentUid / @Public、全域 APP_GUARD
├── firebase/          # firebase-admin 初始化 (fail-closed) + Firestore 鏡像 service (含照片上 Storage)
├── prisma/            # PrismaService / Module
├── orders/            # 訂單 CRUD + 合併 + 狀態/收款 + cascade 改名 (皆按 uid 圈)
├── campaigns/         # 開團 CRUD + 結團 + 自動收單
├── lookups/           # 類別/來源/付款方式/對帳狀態主檔
├── currency/          # 幣別清單 (7 天快取) + 匯率 (ExchangeRate-API 代理)
├── ai-summary/        # Ollama 串流代理
├── settings/          # 設定 (per-user，以 ownerUid 為鍵)
└── main.ts            # bootstrap (global prefix /api、CORS、ValidationPipe)
prisma/
├── schema.prisma      # 持久化 schema
└── seed.ts            # 示範資料 (有資料自動略過)
```

## 開發

```bash
npm install
npx prisma generate                 # 生成 Prisma client
# 需要本機或容器的 PostgreSQL；環境變數見 deploy/backend.env.example
npx prisma db push                  # 套用 schema
npm run db:seed                     # 種子 (ts-node)
npm run start:dev                   # 開發 (watch)，預設 :4000
npm run build && npm run start:prod # 正式
npm run typecheck                   # tsc --noEmit
```

## 環境變數

環境變數收斂在 [`deploy/`](../../deploy/)，見 [`deploy/backend.env.example`](../../deploy/backend.env.example)：`DATABASE_URL`、`PORT`、`WEB_ORIGIN` (CORS)、`EXCHANGE_RATE_API_KEY`、`OLLAMA_API_KEY` (後二者留空時對應功能以空狀態降級)。

Firebase service account (身分驗證與雲端投影，**缺則 fail-closed、後端拒絕啟動**，與上述可降級服務不同)：以 `FIREBASE_SERVICE_ACCOUNT_FILE` 指向 service account JSON 檔 (放 `apps/backend/`、已 gitignore，由 compose volume 唯讀掛入容器)，或改用 `FIREBASE_PROJECT_ID` / `FIREBASE_CLIENT_EMAIL` / `FIREBASE_PRIVATE_KEY` 三變數；另需 `FIREBASE_STORAGE_BUCKET` (訂單照片)。種子可用 `SEED_OWNER_UID` 指定 dev 資料擁有者 (預設 `dev-user`)。

## API 一覽 (前綴 `/api`)

除健康檢查外，所有端點預設需 `Authorization: Bearer <Firebase ID token>`，資料一律按 uid 隔離。

| 資源 | 路由 |
|------|------|
| 健康檢查 | `GET /health` (公開，免驗證) |
| 訂單 | `GET/POST /orders`、`GET/PUT/DELETE /orders/:id`、`POST /orders/:id/status`、`POST /orders/:id/receipt`、`POST /orders/merge/draft` |
| 開團 | `GET/POST /campaigns`、`GET/PUT/DELETE /campaigns/:id`、`POST /campaigns/:id/settle`、`POST /campaigns/:id/status` |
| 主檔 | `GET/POST /lookups/{categories,order-sources,verification-statuses,payment-methods}`、`PUT/DELETE …/:name` |
| 幣別/匯率 | `GET /currency/codes`、`POST /currency/codes/refresh`、`GET /fx/latest`、`POST /fx/refresh` |
| AI 總結 | `POST /ai-summary/stream` (串流) |
| 設定 | `GET/PUT /settings` |

## 容器化

`Dockerfile` 為多階段 (builder 編譯 → runner 執行)。entrypoint (`docker-entrypoint.sh`) 等 DB 就緒後 `prisma db push` → 種子 → 啟動。整體一鍵啟動見 `deploy/docker-compose.yml` (根目錄 `make up`)。
