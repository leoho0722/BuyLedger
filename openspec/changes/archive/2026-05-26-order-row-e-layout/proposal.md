## Why

訂單列表的單列摘要原本第一行顯示「客戶名稱 · 訂單後三碼」。後三碼是該列掃視價值最低的資訊 (完整單號在訂單詳情頁與全文搜尋都取得到)，而使用者高頻關注的「訂購日期」被排到第三行、「商品類別」則完全沒在列表露出。重新編排可讓使用者一眼掌握「誰、何時、什麼狀態、什麼類別」，提升列表掃視效率。

## What Changes

- 移除單列第一行的訂單後三碼。第一行改為「客戶名稱 · 訂購日期」，並將狀態膠囊上移到日期右側。
- 第二行維持商品明細 (各商品名稱，可多行)。
- 新增第三行顯示商品類別：前導 tag 圖示置於膠囊外，右側以 neutral 灰底膠囊呈現類別文字 (沿用狀態膠囊外觀但不顯示狀態指示點、單行不提早換行)。類別為空字串時整行不顯示。
- 左欄垂直節奏與單列垂直邊距統一為 8pt，使類別膠囊的上下間距、以及分隔線的上下間距對稱。
- 將原型期 inline 在單列 view 內的類別膠囊抽成可重用的 Design System 元件。
- 單列摘要 view 為 iOS、iPadOS、macOS 與 Dashboard 共用；版面與間距調整一併套用，需確認各平台呈現一致。

## Capabilities

### New Capabilities

- `order-row-summary`: 訂單列表單列摘要的呈現契約 — 顯示哪些欄位、三行的排列方式、類別膠囊樣式與空值處理、以及間距節奏。

### Modified Capabilities

(none)

## Impact

- Affected specs: 新增 order-row-summary
- Affected code:
  - Modified:
    - BuyLedger/BuyLedger/Features/Orders/Components/OrderRowView.swift
    - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
    - BuyLedger/BuyLedgerTests/SnapshotTests.swift (重錄 baseline)
  - New:
    - BuyLedger/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - Removed: (none)
