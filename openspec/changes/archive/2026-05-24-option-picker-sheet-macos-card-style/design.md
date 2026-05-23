## Context

`OptionPickerSheet` 是訂單編輯表單與 Settings / Quote / FX 工具頁共用的「單選一個字串」pop-up。目前 body 是一段不分平台的系統 `List`：`allowsAdd` 時有一個新增按鈕 Section，接著一個選項 Section (選項列為 Button，含 `selected` 勾選；無選項時顯示 `ContentUnavailableView`)，外加 `navigationTitle`、toolbar 取消、`SearchableModifier`、一般新增 `.alert`、付款方式 `.sheet` (`PaymentMethodEditorSheet`)。在 macOS 上這個 `List` 呈現過於樸素，與已改為 Design System 卡片的 `LookupManagementView` / `CustomersView` 不一致。

此變更延續 `lookup-management-macos-card-style` 的作法與既有 `MoreView` 的 `#if os(macOS)` 平台分流慣例。

約束：

- Swift 6 strict concurrency、TCA、SwiftData (見 CLAUDE.md)。
- Design System：`BLCard(padding:radius:)`、`BLSpacing`、`BLTheme.palette(for:)`、`palette.background/surface/separator/label/secondaryLabel/tertiaryLabel/accent`。
- `.searchable` 為平台無關 modifier，套在內容容器上即可 (macOS 顯示於 sheet 工具列、iOS 顯示於 navigation bar drawer)，由現有 `SearchableModifier` 控制。
- pop-up 為 sheet，macOS 既有 `.frame(minWidth: 400, minHeight: 480)` 維持。

## Goals / Non-Goals

**Goals:**

- macOS 的 `OptionPickerSheet` 視覺與 `LookupManagementView` / `CustomersView` 一致 (ScrollView + palette 背景 + BLCard 列表)。
- iOS / iPadOS 的外觀與互動完全不變。
- 選取、新增 (一般 + 付款方式)、搜尋、勾選、空狀態、取消等行為與現況完全相同。

**Non-Goals:**

- 不改 iOS / iPadOS 的版面或互動。
- 不改 `OptionPickerSheet` 的對外 API (init 參數、callbacks)、`PaymentMethodEditorSheet`、`BLCard`、各呼叫端 (OrderEditView / Settings / Quote / FX)。
- 不改 `filteredOptions` / `displayText` / `searchKeywords` 的過濾與顯示邏輯。
- 不調整 macOS sheet 既有的 `minWidth` / `minHeight`。

## Decisions

### macOS 卡片版面與 iOS/iPadOS List 以 `#if os(macOS)` 分流

把選項內容區拆成 `@ViewBuilder` 的 `content`：`#if os(macOS)` 走新的 `macContent` (ScrollView + BLCard)，`#else` 沿用現有 List (`listContent`)。`NavigationStack` 外層與共用 modifier 不變。沿用 `MoreView` / `LookupManagementView` 的平台分流慣例。

- 替代方案：在 macOS 沿用 List 只調 `listStyle`／背景——否決，與 Design System 卡片風仍有落差，無法達成「對齊」。

### 共用 navigation / toolbar / alert / sheet / searchable modifier 提取到平台分支之外

`navigationTitle`、toolbar 取消、一般新增 `.alert`、付款方式 `.sheet` (`PaymentMethodEditorSheet`)、`SearchableModifier`、`#if os(macOS)` 的 `.frame(minWidth:minHeight:)` 一律掛在 `content` 之外的 root，由兩個分支共用，`@State` (`showsAddAlert` / `showsAddPaymentMethodSheet` / `draft` / `searchText`) 不變。確保新增與搜尋的觸發與業務邏輯兩平台一致。

- 替代方案：兩分支各掛一份——否決，重複且易漂移。

### macOS 選項列以 BLCard 呈現並沿用 selected 勾選與 onSelect 行為

macOS 選項包在單一 `BLCard(padding: 0)`，每列為 Button (點選呼叫 `onSelect(option)` 後 `dismiss()`)，顯示 `displayText(for:)`，`option == selected` 時於右側顯示 checkmark；列間以帶 leading inset 的 `Divider` 分隔。

### macOS 新增入口與空狀態對齊 `LookupManagementView` 樣式

`allowsAdd` 時於卡片上方顯示新增按鈕 (沿用現有點擊邏輯：`onAddPaymentMethod != nil` 開 `PaymentMethodEditorSheet`，否則開一般新增 alert)；無選項時以置中 `ContentUnavailableView` (`emptyTitle` / `emptyDescription`) 呈現，沿用 sheet 預設材質背景。

### sheet 內不套全頁深色 `palette.background`

`OptionPickerSheet` 是 sheet，自帶較淺的視窗材質，背景採分模式處理：

- 深色模式：`palette.background` 為純黑，套在 sheet 內會與標題列、底部工具列形成突兀的深色色塊，因此維持透明、沿用 sheet 預設材質。
- 淺色模式：sheet 預設材質近白，白色 `BLCard` 列會與之融合，因此套上 `palette.background` (淺色為 `0xF2F2F7`)——即表單 List 的淺灰群組底色，讓白色卡片有對比。

實作以 `palette.isDark ? Color.clear : palette.background` 表達。Design System 一致性由 `BLCard` (surface + 描邊 + 陰影) 與此淺灰群組底共同達成。

- 替代方案 1：兩模式都套 `palette.background`——否決，深色純黑過於突兀 (實機驗證)。
- 替代方案 2：兩模式都透明——否決，淺色白卡片與白底融合 (實機驗證)。

## Implementation Contract

**範圍**：僅修改 BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift 的呈現層。

**可觀察行為：**

- 在 macOS，所有使用 `OptionPickerSheet` 的單選 pop-up (OrderEditView 的訂單來源／商品類別／付款方式／幣別，以及 Settings / Quote / FX) 以 `ScrollView` + `BLCard` 卡片列表呈現 (沿用 sheet 預設材質背景，不套全頁深色 `palette.background`)，卡片風與 `CustomersView` / `LookupManagementView` 一致；`allowsAdd` 時卡片上方有新增按鈕；選項列顯示名稱與勾選；無選項時顯示置中空狀態；`searchable` 時可搜尋；toolbar 可取消。
- 在 iOS / iPadOS，pop-up 維持現有 `List` 呈現與互動，與本次變更前逐一相同。
- 三平台的選取 (`onSelect` 後關閉)、一般新增 (`.alert` → `onAdd`)、付款方式新增 (`PaymentMethodEditorSheet` → `onAddPaymentMethod`)、搜尋 (`filteredOptions` 含 `searchKeywords`)、`displayName` 顯示轉換、勾選標示，行為與現況完全相同。

**介面 / 資料形狀：** 不改 `OptionPickerSheet` 的 `init` 參數與所有 callbacks、不改 `SearchableModifier`、`PaymentMethodEditorSheet`、`BLCard`。body 重構為 root + 平台分支 `content`；共用 modifier 掛在 root。

**失敗模式：** 不新增；一般新增的空字串驗證 (`disabled` + trimming) 沿用現況。

**驗收標準：**

- macOS build 與 iOS Simulator build 皆成功 (依 CLAUDE.md 序列化執行，加 `--log-level error`)。
- macOS：OrderEditView 開啟訂單來源／商品類別／付款方式 pop-up 為卡片版面，可選取套用、可新增 (付款方式含無卡 toggle)、可搜尋 (幣別)、空狀態置中、可取消。
- iPhone：pop-up 與變更前一致 (List)。
- 既有 iOS snapshot 測試 (若涵蓋) 維持通過、不需重建 baseline。

**範圍邊界：** 不動呼叫端、`PaymentMethodEditorSheet`、`BLCard`、`filteredOptions`／`displayText` 邏輯、iOS/iPadOS 版面、snapshot baseline、macOS sheet 尺寸。

## Risks / Trade-offs

- [macOS 與 iOS 版面分歧造成維護兩套呈現] → 共用 modifier 集中於 root，分支只負責內容；以 `#if os(macOS)` 標示，沿用既有慣例。
- [macOS `.searchable` 套在 ScrollView 上的搜尋欄位置與 List 版不同] → `.searchable` 為平台慣例呈現 (macOS 工具列)，`filteredOptions` 綁定 `searchText` 不變，功能等價；以 macOS 幣別 pop-up 手動驗證搜尋可用。
- [選項過多時卡片內 ScrollView 效能] → 與 `CustomersView` 同樣以 `ForEach` 呈現，選項規模 (來源／類別／付款方式／幣別) 有限，風險低。

## Migration Plan

無資料或結構遷移。純呈現層重構；rollback 即還原單一檔案。

## Open Questions

無。平台範圍 (僅 macOS 改卡片、iOS/iPadOS 維持 List) 與方向已於對話確認。
