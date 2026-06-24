# BuyLedger Web 前端

Next.js (App Router) + React + Tailwind v4 + TanStack Query 的前端，功能與設計語言對齊 iOS 版。版本 1.3.0。AI 協作硬規則見 [`CLAUDE.md`](CLAUDE.md)。

## 技術棧

| 項目       | 選型                                                  |
|------------|-------------------------------------------------------|
| 框架       | Next.js 15 (App Router) + React 19                    |
| 樣式       | Tailwind CSS v4 (token 化設計系統，對齊 iOS BLPalette) |
| 資料層     | TanStack Query v5 (對獨立後端 REST)                   |
| 即時同步   | Firebase Firestore `onSnapshot` (讀取 per-user 投影) + 本機待送佇列 + 每欄位 HLC |
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
    ├── firebase.ts auth.tsx        # Firebase client (延遲初始化、含 getFirestoreDb) 與 AuthProvider / AuthGate / 登入頁
    ├── sync/                       # 跨裝置即時同步層 (見「跨裝置同步」)
    │   ├── useFirestoreSync.tsx    # FirestoreSync：訂閱 per-user 投影 onSnapshot、餵入 Query cache
    │   ├── hlc.ts                  # 每欄位 Hybrid Logical Clock + 本機時鐘 (writerId / lastIssued 存 localStorage)
    │   ├── writeQueue.ts           # 失敗重送的本機持久化佇列 (localStorage)
    │   ├── orderPatch.ts           # 組裝 partial patch (changedFields + fieldClocks)
    │   └── SyncStatusBadge.tsx     # 待同步/失敗狀態與手動重試
    └── theme.tsx providers.tsx     # 外觀切換與 Provider (含 AuthProvider + AuthGate + FirestoreSync + SyncStatusBadge)
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

## 跨裝置同步

同一帳號的任意兩平台 (web↔iOS) 經後端 (Postgres 為 source of truth) + per-user Firestore 投影即時傳播 Order/Campaign 變更。Web 端職責：

- **即時讀取**：`FirestoreSync` (`lib/sync/useFirestoreSync.tsx`) 登入後訂閱 `users/{uid}/orders|campaigns` 的 `onSnapshot`，把投影覆寫進既有 TanStack Query cache，另一裝置經後端鏡像的變更即時出現、無需手動刷新；帶 `_deleted` 的 tombstone 文件不顯示。
- **唯一寫入方在後端**：web 只讀 Firestore、所有寫入仍走後端 REST。寫入送 partial patch (`changedFields` + 每欄位 `fieldClocks`)，後端逐欄以每欄位 Hybrid Logical Clock (HLC，p→c→writerId) 合併——不同欄位並行修改皆保留、同欄位以 HLC 決勝、後端 clamp 時鐘偏移 (5 分鐘)。刪除為帶時鐘的 tombstone、較晚修改可非破壞性復活。
- **HLC 本機時鐘** (`lib/sync/hlc.ts`)：演算法與後端 `apps/backend/src/sync/hlc.ts` 完全一致 (共用 conformance vectors)；`writerId` 採每安裝穩定 UUID、`lastIssued` 皆持久化於 localStorage 跨 reload 存活，觀察到的遠端時鐘 (RECEIVE) 推進本地時鐘，確保後續本地寫入時鐘必大於已見的遠端值。
- **同步失敗恢復** (`lib/sync/writeQueue.ts`)：寫入後端失敗 (離線/網路/5xx) retry 3 次後標記 failed，操作存 localStorage 佇列、`SyncStatusBadge` 顯示待同步/失敗並可手動重試；連線恢復或重新載入自動重送，重送以 client UUID upsert + 每欄位 HLC 對後端 PATCH 冪等 (相同時鐘為 no-op)。

## 端對端測試 (Playwright)

```bash
# 先以根目錄 make up 啟動全棧 (前端 :3000、後端 :4000)
npx playwright install chromium    # 首次
npm run test:e2e                   # 對 :3000 跑驗收
```

涵蓋導覽、訂單詳情/新增/狀態篩選、開團結算與客戶分貨、主檔徽章、深色外觀、匯率空狀態等。`E2E_BASE_URL` 可覆寫目標位址。

## 容器化

`Dockerfile` 以 Next.js standalone 輸出打包；一鍵啟動見 `deploy/docker-compose.yml` (根目錄 `make up`，會以 build arg 注入 `NEXT_PUBLIC_API_BASE_URL`)。
