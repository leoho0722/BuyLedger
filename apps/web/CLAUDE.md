# Web 前端指引 (apps/web)

本檔記錄 Web 前端 (Next.js + React + Tailwind v4 + TanStack Query) 的硬規則與隱性 gotcha；跨平台通用規範見 repo 根目錄 [`CLAUDE.md`](../../CLAUDE.md)，技術棧與開發指令見本目錄 [`README.md`](README.md)。

## 主要技術棧

- **Next.js 15 (App Router) + React 19 + TypeScript strict**。
- **Tailwind CSS v4**：token 化設計系統。
- **TanStack Query v5**：對獨立後端 (REST) 的 client 端資料層。

## 設計系統 (對齊 iOS)

- **色票/間距/圓角 token 定義在 `src/app/globals.css`** (`@theme inline` + `:root`/`.dark` CSS 變數)，值逐一對齊 iOS `BLPalette`。元件**只用語意 class** (`text-bl-label`、`bg-bl-surface`、`border-bl-separator`、`rounded-bl-lg` 等)，不寫死色碼。
- **深淺色以 `html.dark` class 切換** (`src/lib/theme.tsx`，`system` 跟隨 `prefers-color-scheme`)；`layout.tsx` 有 anti-flash inline script。深色不用陰影、改靠 0.5px 邊框 (`.bl-card-shadow` 在 `.dark` 下清空)。
- **`BLTone` → `TONE_CLASSES`** (`src/lib/domain/constants.ts`)：非中性背景為前景色 14%。商業狀態→tone 對照 (`ORDER_STATUS_TONE` 等) 也在此。
- DS 元件在 `src/components/ds/`，一元件一檔。

## 資料層與職責切分

- **後端是財務公式單一事實來源**：per-order `summary` 已附在 `OrderDTO`，前端**不重算單筆公式**。
- **前端只做呈現層彙總** (`src/lib/domain/aggregations.ts`：開團結算/儀表板/分析/客戶)，金額彙總用 **decimal.js** (`src/lib/decimal.ts`)，不可用 `number` 加總金額。
- **篩選 predicate 在 `src/lib/domain/orders.ts`** (`filterOrders`)，語意對齊 iOS (開團狀態「至少一團相符」、類別 containment、日期區間半開、合併葉端判定等)。
- 顯示格式一律走 `src/lib/format.ts` (locale `zh-TW`、金額 0 小數、tabular 數字加 `bl-tabular`)。
- API 與 hooks 在 `src/lib/api.ts` / `src/lib/queries.ts`；訂單異動的 mutation 同時 invalidate `orders` 與 `campaigns` (開團統計衍生自訂單)。

## 生成型別

- `src/lib/data-model/generated/` 由 `shared/data-model` 產出 (decimal/date 皆字串)，**不可手改**；改形狀改 schema 再 `bun run generate`。

## Next.js / 容器 gotcha

- **用 `useSearchParams()` 的頁面必須包 `<Suspense>`**，否則 `next build` 會因 CSR bailout 失敗 (見 `app/orders/page.tsx`、`app/orders/new/page.tsx` 的 inner 拆法)。
- **`NEXT_PUBLIC_API_BASE_URL` 於 build 期 inline 進 client bundle**——必須是「瀏覽器端可達」的位址 (容器以 build arg 注入，預設 `http://localhost:4000/api`)。
- `next.config.ts` 設 `output: 'standalone'` 供容器精簡部署。

## 表單與流程 gotcha

- **費率欄位 UI 以「百分比」輸入**，儲存前 `÷100` 轉 fraction (`OrderEditForm`)；載入時 `×100` 還原。
- **類別/開團在「合併模式」(非空 `mergedSourceIDs`) 才多選**，否則單選 (對齊 iOS)。
- **合併流程**：訂單詳情 → `mergeDraft` API → 合併照片若超過 5 張先挑選 → 草稿存 `sessionStorage` → 導 `/orders/new?merge=1` 預填。
- 照片於前端正規化 (最長邊 ≤1600、JPEG dataURL，`src/features/orders/photoUtils.ts`)，上限 5 張。

## 註解

- 一律正體中文、精簡重點式 (對齊 root `CLAUDE.md`)。
