## Why

從「分析」頁點擊類別排行 row 應該深連結到「訂單」頁並套用該類別的篩選，這是昨天 `ai-product-summary` 上線新類別篩選膠囊後的明確期待行為。目前 `RootFeature.categorySelected` 仍沿用類別篩選膠囊存在以前的舊路徑，把類別名塞進 `searchText`，導致跳轉後類別膠囊維持「全部」、且訂單列表用文字模糊比對而非精準類別欄位比對，會把品名／客戶名含相同字串的訂單誤包進來。

## What Changes

- 修正 `RootFeature.Action.categorySelected`：改為設定 `state.orders.selectedCategory = category` 並清空 `state.orders.searchText`；維持原本的 `selectedStatus = .all`、`selectedDatePeriod = .all` 與重算 `selectedOrderID` 行為。
- 同步調整 `RootFeature.Action.smartGroupSelected` 與 `RootFeature.Action.customerSelected`：跨頁跳轉時一律重設 `state.orders.selectedCategory = nil`，避免使用者帶著前一頁的類別篩選狀態跳到新分頁時被「狀態 + 類別」兩條條件夾擊出空列表。
- 在 `RootFeatureTests` 新增 `categorySelected` 的 reducer 測試，並補上 `smartGroupSelected` / `customerSelected` 既有測試對 `selectedCategory` 重設行為的斷言。
- 在 `order-category-filter` spec 新增 requirement／scenario，明確規範「從分析頁類別排行深連結進訂單頁時，必須以類別欄位精準篩選並讓篩選膠囊高亮對應類別」與「跨頁跳轉時清掉殘留類別篩選」。

## Non-Goals (optional)

- 不改動 `OrdersFeature` 的 reducer body 或任何 view 程式碼；訂單頁的類別篩選膠囊已直接綁定 `selectedCategory`，行為正確。
- 不改 `customerSelected` 仍以 `searchText` 帶入客戶名的設計（客戶沒有獨立篩選欄位，文字搜尋是預期的後備機制）。
- 不調整 `Insights` 頁的 row 觸發點或 row 本身的 accessibility hint；只動跨頁狀態同步的這一層。
- 不改 `smartGroupSelected` 對狀態以外其他篩選器（除了新加上的 `selectedCategory`）的既有重設語意。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `order-category-filter`：新增跨頁深連結的 requirement 與 scenario，並將「跨頁跳轉時類別篩選重設」明文化。

## Impact

- Affected specs: `order-category-filter`
- Affected code:
  - Modified:
    - BuyLedger/BuyLedger/Features/App/RootFeature.swift
    - BuyLedger/BuyLedgerTests/RootFeatureTests.swift
  - New: （無）
  - Removed: （無）
