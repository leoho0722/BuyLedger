## Why

macOS 上 `OptionPickerSheet` 的單選 pop-up 沿用系統原生 `List`，呈現過於樸素，與 iOS / iPadOS 的精緻列表落差過大，也與剛改為 Design System 卡片的 `LookupManagementView` / `CustomersView` 等 macOS 頁面不一致。

## What Changes

- macOS 上 `OptionPickerSheet` 改採與 `LookupManagementView` / `CustomersView` 一致的 Design System 卡片版面：`ScrollView` + `palette.background` + `BLCard` 列表。
- macOS 卡片內容涵蓋現有所有元素：`allowsAdd` 新增按鈕、選項列 (含 `selected` 勾選)、`ContentUnavailableView` 空狀態、`searchable` 搜尋欄。
- iOS / iPadOS 維持現有 `List` (含 Section、選項列、勾選、空狀態) 完全不動。
- 共用且不變：`navigationTitle`、toolbar 取消按鈕、一般新增 `.alert`、付款方式 `.sheet` (`PaymentMethodEditorSheet`)、`SearchableModifier`、`onSelect` / `onAdd` / `onAddPaymentMethod` callbacks、`displayName` / `searchKeywords` / `filteredOptions` 邏輯，由兩平台分支共用。

## Capabilities

### New Capabilities

- `option-picker`: 訂單編輯與 Settings / Quote / FX 工具頁使用的單選選項 pop-up，其平台自適應呈現方式，以及跨平台維持一致的選取、新增、搜尋與勾選行為。

### Modified Capabilities

(none)

## Impact

- Affected specs: `option-picker` (new)
- Affected code:
  - Modified: apps/apple/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - New: (none)
  - Removed: (none)
