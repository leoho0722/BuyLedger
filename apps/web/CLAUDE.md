# Web 前端指引 (apps/web)

本檔記錄 Web 前端 (Next.js + React + Tailwind v4 + TanStack Query) 的硬規則與隱性 gotcha；跨平台通用規範見 repo 根目錄 [`CLAUDE.md`](../../CLAUDE.md)，技術棧與開發指令見本目錄 [`README.md`](README.md)。

## 主要技術棧

- **Next.js 15 (App Router) + React 19 + TypeScript strict**。
- **Tailwind CSS v4**：token 化設計系統。
- **TanStack Query v5**：對獨立後端 (REST) 的 client 端資料層。

## 設計系統 (對齊 iOS)

- **色票/間距/圓角 token 定義在 `src/app/globals.css`** (`@theme inline` + `:root`/`.dark` CSS 變數)，值逐一對齊 iOS `BLPalette`。元件**只用語意 class** (`text-bl-label`、`bg-bl-surface`、`border-bl-separator`、`rounded-bl-lg` 等)，不寫死色碼。
- **圓角 token 與 Tailwind 「左下角」工具撞名**：`bl` 前綴的 `rounded-bl-*` 會被 Tailwind 當成 bottom-left 角、用預設 radius 蓋掉左下角 (與其他三角不一致)。因此 `@theme` 用 **`--radius-*: initial`** 清掉預設 radius scale、只留 `--radius-bl-*` (含 `--radius-bl-pill: 9999px`)，`rounded-bl-*` 才會套到四個角。**勿移除該 `--radius-*: initial`**，也勿新增裸 `--radius-{sm,md,lg…}`，否則左下角 bug 會重現。
- **深淺色以 `html.dark` class 切換** (`src/lib/theme.tsx`，`system` 跟隨 `prefers-color-scheme`)；`layout.tsx` 有 anti-flash inline script。深色不用陰影、改靠 0.5px 邊框 (`.bl-card-shadow` 在 `.dark` 下清空)。
- **`BLTone` → `TONE_CLASSES`** (`src/lib/domain/constants.ts`)：非中性背景為前景色 14%。商業狀態→tone 對照 (`ORDER_STATUS_TONE` 等) 也在此。
- DS 元件在 `src/components/ds/`，一元件一檔。
- **token 對齊 iOS，但佈局走 Web 風格**：色票/間距/圓角沿用 iOS 值，版面與導覽則用 Web 慣例——桌機固定側欄、手機頂部 app bar + 漢堡抽屜 (`AppShell`，無 iOS 底部 tab bar)；內容區 `max-w-7xl`、總覽/分析多欄並排、訂單/開團為單欄寬列、更多頁為工具卡片網格 (圖示色塊+標題+說明，非 iOS inset 清單列)、列與卡片有 hover 態。勿改回 iOS 行動樣式 (底部 tab、窄單欄 `max-w-3xl`、以滿版 sheet 為主要互動)。

## 資料層與職責切分

- **後端是財務公式單一事實來源**：per-order `summary` 已附在 `OrderDTO`，前端**不重算單筆公式**。
- **前端只做呈現層彙總** (`src/lib/domain/aggregations.ts`：開團結算/儀表板/分析/客戶)，金額彙總用 **decimal.js** (`src/lib/decimal.ts`)，不可用 `number` 加總金額。
- **篩選 predicate 在 `src/lib/domain/orders.ts`** (`filterOrders`)，語意對齊 iOS (開團狀態「至少一團相符」、類別 containment、日期區間半開、合併葉端判定等)。
- 顯示格式一律走 `src/lib/format.ts` (locale `zh-TW`、金額 0 小數、tabular 數字加 `bl-tabular`)。
- API 與 hooks 在 `src/lib/api.ts` / `src/lib/queries.ts`；訂單異動的 mutation 同時 invalidate `orders` 與 `campaigns` (開團統計衍生自訂單)。

## 生成型別

- `src/lib/data-model/generated/` 由 `shared/data-model` 產出 (decimal/date 皆字串)，**不可手改**；改形狀改 schema 再 `bun run generate`。

## 跨裝置同步 (cross-device-sync)

同帳號任意兩平台 (iOS↔web) 經後端 (Postgres 為 SoT) + per-user Firestore 投影即時傳播 Order/Campaign；衝突解決為每欄位 HLC 的欄位級合併、集中在後端 (web 不做合併判定)。web 端硬規則：

- **後端是唯一寫入方、web 只讀 Firestore**：即時讀取走 `onSnapshot` 訂閱 `users/{uid}/orders|campaigns` 投影 (`src/lib/sync/useFirestoreSync.tsx` 的 `FirestoreSync`、Firestore 進入點 `getFirestoreDb()` 在 `src/lib/firebase.ts`)，每次快照覆寫既有 TanStack Query cache (`qk.orders`/`qk.campaigns`)，使另一裝置的變更即時出現、無需手動刷新。**勿在 web 端寫 Firestore，也勿用 REST 輪詢取代 listener** (前一代的 30 秒 cache 已淘汰)。
- **帶 `_deleted` 的 tombstone 文件略過不顯示** (非以文件缺席表示刪除)；快照文件帶的 `_fieldClocks` 須逐一餵 `observeClock()` (HLC RECEIVE) 推進本地時鐘，確保後續本地寫入時鐘必大於已見的遠端時鐘。
- **HLC client 狀態持久化於 localStorage** (`src/lib/sync/hlc.ts`)：`writerId` 為每安裝穩定 UUID (`buyledger.sync.writerId`)、`lastIssued` 跨 reload 持久化 (`buyledger.sync.lastIssuedHlc`) 以維持時鐘單調遞增。實體時間集中在本檔 `now()` 單一呼叫點 (對齊環境相依注入精神)；演算法須與後端 `apps/backend/src/sync/hlc.ts` 完全一致 (規格與 conformance vectors 見 `shared/sync-conformance/`)，**勿單平台改動編碼寬度或比較順序** (`p→c→w`)。
- **同步寫入走 partial PATCH、不走 PUT、不靠 409**：訂單異動以 `api.orders.patch` → `PATCH /orders/:id` 送 `{ changedFields, fieldClocks }` (僅變更欄位 + 每欄位 HLC，diff 與時鐘附掛見 `src/lib/sync/orderPatch.ts`)，讓兩裝置改不同欄位皆存活；後端逐欄合併。**勿改回整筆 PUT + expectedVersion + 409 樂觀並行模型** (會丟掉並行不相交欄位修改)。送出欄位對齊後端 flat 欄位名 (`customerName`/`customerTier` 攤平)，不送衍生的 `isCashOnDelivery` 與建立後唯讀的 `mergedSourceIDs`/`customerInitials`。
- **照片一律以 base64 字串送** (`OrderInputBody.photos: string[]`，現行 Postgres/DTO 現實)；web 絕不上傳 Storage 或在 patch 送路徑參照。
- **寫入失敗走 localStorage 持久化待送佇列** (`src/lib/sync/writeQueue.ts`)：PATCH 失敗 (離線/網路/5xx) 時把操作存 `buyledger.sync.writeQueue` 並樂觀更新 cache，UI 顯示「待同步/失敗」(`SyncStatusBadge`)；retry 上限 3 次 (`MAX_ATTEMPTS`)、達上限標 `failed` 仍留佇列供手動重試；連線恢復或重新載入自動 `drainQueue` 重送。每筆帶 `opId` (UUID)，重送以 client UUID upsert + 每欄位 HLC 對後端為冪等 no-op (不重複套用)。
- **同步寫入 mutation 必須設 `networkMode: 'always'`** (`src/lib/queries.ts` 的 `patch`)：TanStack Query v5 預設 `networkMode: 'online'`，在 `navigator.onLine === false` 時會**暫停整個 mutation、`mutationFn` 根本不執行**，離線存檔永久卡在「儲存中」、連待送佇列都進不去。改 `'always'` 讓 `mutationFn` 離線也照跑，再由其內離線分支 (`!navigator.onLine`) 直接走樂觀更新 + `enqueueWrite`、**不 `await api.orders.patch`** (`getCurrentIdToken` 對過期 token 的網路 refresh 在離線時會 hang，會卡在送出之前、進不到 catch)。

## Next.js / 容器 gotcha

- **用 `useSearchParams()` 的頁面必須包 `<Suspense>`**，否則 `next build` 會因 CSR bailout 失敗 (見 `app/orders/page.tsx`、`app/orders/new/page.tsx` 的 inner 拆法)。
- **`NEXT_PUBLIC_API_BASE_URL` 於 build 期 inline 進 client bundle**——必須是「瀏覽器端可達」的位址 (容器以 build arg 注入，預設 `http://localhost:4000/api`)。
- `next.config.ts` 設 `output: 'standalone'` 供容器精簡部署。

## 表單與流程 gotcha

- **訂單表單 section 順序/分組對齊 iOS `OrderEditView`** (`OrderEditForm`)：基本資料 → 狀態與幣別 → 收款金額 → 開團與收款 → 成本 → 手續費 → 商品明細 → 備註 → 訂單照片；成本欄位順序亦同 iOS (商品成本 → 來源國當地運費 → 國際運費 → 國內運費)。改版面時勿讓兩端 section 順序漂移。
- **訂單表單欄位集合也對齊 iOS**：**客戶分級不在訂單表單編輯** (新訂單存 `new`、編輯沿用原值、合併沿用主訂單)，勿加回 tier 選擇器；**訂購日期**以 `datetime-local` 編輯 (ISO ↔ 本地值互轉見 `isoToLocalInput`/`localInputToIso`，分鐘精度)。
- **檔案上傳 input 不可用 `hidden`/`display:none`**：Safari/Firefox 會拒絕對 `display:none` 的 `<input type=file>` 觸發檔案選擇器 (Chrome 可，故易漏測)。新增照片改用 `<label>` 包一個 `sr-only` (clip 隱藏、非 `display:none`) 的 input、點 label 原生開啟，跨瀏覽器一致 (`OrderEditForm`)。
- **商品明細列走 RWD** (`OrderEditForm`)：手機 (`<md`) 直式 (商品名稱一列、數量/單價/刪除一列，避免橫向溢位)；桌機 (`md`+) 維持單列 (名稱 `flex-1` + 數量/單價/刪除並排)。橫排的彈性子項記得加 `min-w-0` 才不會撐破卡片寬度。
- **費率欄位 UI 以「百分比」輸入**，儲存前 `÷100` 轉 fraction (`OrderEditForm`)；載入時 `×100` 還原。
- **類別/開團在「合併模式」(非空 `mergedSourceIDs`) 才多選**，否則單選 (對齊 iOS)。
- **合併流程**：訂單詳情 → `mergeDraft` API → 合併照片若超過 5 張先挑選 → 草稿存 `sessionStorage` → 導 `/orders/new?merge=1` 預填。
- 照片於前端正規化 (最長邊 ≤1600、JPEG dataURL，`src/features/orders/photoUtils.ts`)，上限 5 張。

## 用詞 (對齊 iOS)

- **訂單詳情財務區拆成兩張卡 (對齊 iOS `OrderDetailView`)**：「獲利摘要」(獲利 + 毛利率 + 總收款/總成本/手續費) 與「成本拆解」(**僅成本面**)。成本拆解 = donut(中央總成本) + 元件清單：商品金額(itemCost)、刷卡/平台/金流手續費 (`summary.cardFee/platformFee/paymentFee`)、**僅貨到付款** (`isCashOnDelivery`) 才計國內/國際/外國國內運費；元件濾除 0 後加總須等於 `summary.totalCost`。勿把營收/獲利/毛利率放進「成本拆解」。

- **使用者可見字串一律對齊 iOS App 用詞** (iOS 為基準)，新增/修改文案前先比對 iOS 對應畫面。已知關鍵慣例：手續費 (非「費率」)、外國國內運費 (非「來源國當地運費」)、訂單金額區段標題帶 `(NT$)`／成本帶 `(NT$)`／手續費帶 `(%)`、picker sheet 標題用「選擇X」、訂單表單狀態列用「狀態」(非「訂單狀態」)、開團 (非「歸屬開團」)、新訂單 (非「新增訂單」)、總收款 (訂單詳情，非「收益」)、月度淨獲利目標 (非「每月獲利目標」)、分析的下單熱力／類別排行／每團毛利排行、走勢標題隨區間顯示「{區間}淨獲利」。domain 標題 (狀態/分級/收款狀態) 已與 iOS 一致，定義在 `src/lib/domain/constants.ts`。

## 註解

- 一律正體中文、精簡重點式 (對齊 root `CLAUDE.md`)。
