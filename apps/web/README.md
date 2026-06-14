# BuyLedger Web 前端

Next.js (App Router) + React + Tailwind v4 + TanStack Query 的前端，功能與設計語言對齊 iOS 版。AI 協作硬規則見 [`CLAUDE.md`](CLAUDE.md)。

## 技術棧

| 項目       | 選型                                                  |
|------------|-------------------------------------------------------|
| 框架       | Next.js 15 (App Router) + React 19                    |
| 樣式       | Tailwind CSS v4 (token 化設計系統，對齊 iOS BLPalette) |
| 資料層     | TanStack Query v5 (對獨立後端 REST)                   |
| 金額       | decimal.js (彙總)、Intl 格式化 (zh-TW)                 |
| 型別來源   | `shared/data-model` 生成的 TypeScript                 |
| 身分驗證   | Firebase Authentication (Google / Apple)；AuthGate 把關 |
| 端對端測試 | Playwright                                            |

## 專案結構

```text
src/
├── app/                            # App Router 路由
│   ├── page.tsx                    # 總覽 (儀表板)
│   ├── orders/                     # 訂單列表/詳情/新增/編輯
│   ├── campaigns/                  # 開團列表/詳情/新增/編輯
│   ├── insights/                   # 分析
│   ├── more/                       # 客戶/匯率/報價/設定/主檔管理
│   └── icon.png                    # 分頁 favicon (由 iOS AppIcon-Any-1024 縮放 512px；iOS icon 換了要重新同步)
├── components/
│   ├── ds/                         # 設計系統元件 (BLCard, BLStatusPill, OptionPicker …)
│   ├── AppShell.tsx                # 導覽殼 (桌機固定側欄、手機頂部列 + 漢堡抽屜)
│   └── OrderRow.tsx                # 訂單列 (含 charged 變體)
├── features/                       # orders/ (表單、合併、AI 總結、篩選)、campaigns/ (表單)
└── lib/
    ├── api.ts queries.ts           # API client 與 hooks
    ├── domain/                     # constants/orders(篩選)/aggregations(彙總)/fx
    ├── format.ts decimal.ts        # 格式化與精確運算
    ├── data-model/generated/       # 生成型別
    ├── firebase.ts auth.tsx        # Firebase client (延遲初始化) 與 AuthProvider / AuthGate / 登入頁
    └── theme.tsx providers.tsx     # 外觀切換與 Provider (含 AuthProvider + AuthGate)
e2e/                                # Playwright 測試
```

## 開發

```bash
npm install
# 需要後端在 http://localhost:4000 (見 apps/backend 或 docker compose)
npm run dev          # 開發伺服器 :3000
npm run build        # 正式 build (standalone)
npm run typecheck    # tsc --noEmit
```

API 位址以 `NEXT_PUBLIC_API_BASE_URL` 控制 (預設 `http://localhost:4000/api`，build 期 inline)。

## 身分驗證

未登入時 `AuthGate` 顯示登入頁 (僅 Google / Apple)；登入後 `api.ts` 自動為每個請求夾帶 `Authorization: Bearer <Firebase ID token>`，收到 401 即登出並導回登入。Firebase web 設定走 `NEXT_PUBLIC_FIREBASE_*` 環境變數 (見 [`.env.example`](.env.example)；`apiKey` / `appId` 需在 Firebase Console 註冊 Web app 後取得)。`firebase.ts` 採延遲初始化，避免 build 期 prerender 觸發 `getAuth` 的 apiKey 驗證。

## 端對端測試 (Playwright)

```bash
# 先以根目錄 make up 啟動全棧 (前端 :3000、後端 :4000)
npx playwright install chromium    # 首次
npm run test:e2e                   # 對 :3000 跑驗收
```

涵蓋導覽、訂單詳情/新增/狀態篩選、開團結算與客戶分貨、主檔徽章、深色外觀、匯率空狀態等。`E2E_BASE_URL` 可覆寫目標位址。

## 容器化

`Dockerfile` 以 Next.js standalone 輸出打包；一鍵啟動見 `deploy/docker-compose.yml` (根目錄 `make up`，會以 build arg 注入 `NEXT_PUBLIC_API_BASE_URL`)。
