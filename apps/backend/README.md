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

## 專案結構

```text
src/
├── domain/            # 財務公式 (order-summary, order-merge)、常數、decimal 設定
├── data-model/        # 生成型別 (generated/) 與 barrel
├── common/            # NowService / IdService (環境相依注入)
├── prisma/            # PrismaService / Module
├── orders/            # 訂單 CRUD + 合併 + 狀態/收款 + cascade 改名
├── campaigns/         # 開團 CRUD + 結團 + 自動收單
├── lookups/           # 類別/來源/付款方式/對帳狀態主檔
├── currency/          # 幣別清單 (7 天快取) + 匯率 (ExchangeRate-API 代理)
├── ai-summary/        # Ollama 串流代理
├── settings/          # 設定單例
└── main.ts            # bootstrap (global prefix /api、CORS、ValidationPipe)
prisma/
├── schema.prisma      # 持久化 schema
└── seed.ts            # 示範資料 (有資料自動略過)
```

## 開發

```bash
npm install
npx prisma generate                 # 生成 Prisma client
# 需要本機或容器的 PostgreSQL；DATABASE_URL 見 .env.example
npx prisma db push                  # 套用 schema
npm run db:seed                     # 種子 (ts-node)
npm run start:dev                   # 開發 (watch)，預設 :4000
npm run build && npm run start:prod # 正式
npm run typecheck                   # tsc --noEmit
```

## 環境變數

見 [`.env.example`](.env.example)：`DATABASE_URL`、`PORT`、`WEB_ORIGIN` (CORS)、`EXCHANGE_RATE_API_KEY`、`OLLAMA_API_KEY` (後二者留空時對應功能以空狀態降級)。

## API 一覽 (前綴 `/api`)

| 資源 | 路由 |
|------|------|
| 健康檢查 | `GET /health` |
| 訂單 | `GET/POST /orders`、`GET/PUT/DELETE /orders/:id`、`POST /orders/:id/status`、`POST /orders/:id/receipt`、`POST /orders/merge/draft` |
| 開團 | `GET/POST /campaigns`、`GET/PUT/DELETE /campaigns/:id`、`POST /campaigns/:id/settle`、`POST /campaigns/:id/status` |
| 主檔 | `GET/POST /lookups/{categories,order-sources,verification-statuses,payment-methods}`、`PUT/DELETE …/:name` |
| 幣別/匯率 | `GET /currency/codes`、`POST /currency/codes/refresh`、`GET /fx/latest`、`POST /fx/refresh` |
| AI 總結 | `POST /ai-summary/stream` (串流) |
| 設定 | `GET/PUT /settings` |

## 容器化

`Dockerfile` 為多階段 (builder 編譯 → runner 執行)。entrypoint (`docker-entrypoint.sh`) 等 DB 就緒後 `prisma db push` → 種子 → 啟動。整體一鍵啟動見 `deploy/docker-compose.yml` (根目錄 `make up`)。
