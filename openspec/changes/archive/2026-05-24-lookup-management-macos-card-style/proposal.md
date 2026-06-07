## Why

訂單來源、商品類別、付款方式三個主檔管理頁 (`LookupManagementView`) 在 macOS 上沿用系統原生 `List`，與同處「更多」入口的客戶名單 (`CustomersView`) 以及 `MoreView` 採用的 Design System 卡片樣式不一致，造成 macOS 上視覺斷裂。

## What Changes

- macOS 上 `LookupManagementView` 改採與 `CustomersView` 一致的 Design System 卡片版面：`ScrollView` + `palette.background` + 單一 `BLCard(padding: 0)` 內含列表 (列間以帶 leading inset 的 `Divider` 分隔)。
- macOS 的計數改成 `CustomersView` 風格的區塊 header (大寫次級標籤 + 右側「N 項」)，取代原本的 List section header「目前已建立 N 項」。
- macOS 的付款方式「無卡」說明改以卡片下方 `.footnote` 次級色文字呈現，取代 List footer；列右側「無卡」Capsule 徽章保留。
- macOS 的重新命名／刪除維持以 `.contextMenu` (右鍵) 觸發，與現況完全相同。
- iOS / iPadOS 維持現有 `List` + `.swipeActions` + `.contextMenu` + section header + footer，行為與外觀完全不變。
- 新增入口 (toolbar `+` primaryAction)、新增與重新命名的 `.alert`、付款方式新增的 `.sheet`、`.task` 載入，以及 `LookupManagementFeature` 的所有 action 與業務邏輯一律不動，改由兩個平台分支共用同一組 modifier。

## Capabilities

### New Capabilities

- `lookup-management`: 訂單來源／商品類別／付款方式主檔管理頁的平台自適應呈現方式，以及跨平台維持一致的新增／重新命名／刪除操作與付款方式無卡標示。

### Modified Capabilities

(none)

## Impact

- Affected specs: `lookup-management` (new)
- Affected code:
  - Modified: apps/apple/BuyLedger/Features/Lookups/LookupManagementView.swift
  - New: (none)
  - Removed: (none)
