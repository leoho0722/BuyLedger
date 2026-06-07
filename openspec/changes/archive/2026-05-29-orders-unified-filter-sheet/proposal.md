## Summary

把 iPhone (compact) 訂單頁的「日期區間」與「商品類別」兩個篩選整合到單一 sheet，由一顆「篩選」trigger button 開啟，省下 1 排篩選 UI 的版面；狀態篩選 chip 列維持不動，iPad regular 與 macOS 也維持現狀。

## Motivation

訂單頁目前在 iPhone Compact 由上而下有「狀態 chip + 日期 chip + 類別 trigger」三排篩選，加上搜尋欄共佔約 4 排垂直空間，能看到的訂單數有限。實際使用頻率上：狀態與類別都高頻、日期幾乎沒按過 (RootFeature 也只有「reset to .all」單向引用，無 inbound deep-link 設定日期)。把日期與類別整合進一個 sheet 後，篩選列從 3 排縮到「狀態 chip + 1 顆 trigger」共 2 排，trigger label 摘要當前篩選讓使用者不點開也能掃一眼當前狀態。同時為未來加入付款方式 / 訂單來源等篩選預留擴充空間 (新增 sheet section 即可，無需再動篩選列佈局)。

iPad regular 與 macOS 沒有篩選列版面壓力 (iPad 中間欄寬 280–360pt、macOS 整個視窗寬鬆)，且維持平台一致性的價值低於 iPhone 的版面收益，因此本次只動 iPhone。

## Proposed Solution

### Trigger button (取代既有 categoryFilterTrigger)

iPhone Compact 在原 `categoryFilterTrigger` 位置改為 `unifiedFilterTrigger`，視覺與行為延續上次 archived change `2026-05-29-orders-category-filter-sheet-picker` 收斂的設計：
- 單顆 Capsule，填滿可用水平寬度 (左右對齊搜尋欄)
- 結構：`HStack(.firstTextBaseline) { filterIcon; Text("篩選：<summary>").multilineText.fixedSize.frame(maxWidth: .infinity, .leading); chevron.down }`
- Icon：`line.3.horizontal.decrease` (filter 通用圖示)
- Capsule fill：當任一非預設條件啟用時 (`selectedDatePeriod != .all` 或 `selectedCategory != nil`) 為 `palette.purple.opacity(0.18)`；否則 `palette.fillTertiary`
- Trigger label 摘要規則：

| selectedDatePeriod | selectedCategory | summary |
| --- | --- | --- |
| .all | nil | 全部 |
| .all | X | X |
| non-.all | nil | 日期 title |
| non-.all | X | 日期 title · X |

例如 (selectedDatePeriod = .thisMonth, selectedCategory = "美妝") → 「篩選：本月 · 美妝」。

點 trigger 改 dispatch 本地 `@State var showsFilterSheet = true`，透過 `.sheet(isPresented:)` 呈現新元件 `OrderFilterSheet`。

### OrderFilterSheet (新元件)

新元件位於訂單功能的 Components 資料夾，僅供 iPhone Compact 使用。

結構：
- `NavigationStack` + `.navigationTitle("篩選")` + `.navigationBarTitleDisplayMode(.inline)`
- Toolbar：左側「取消」button (`.cancellationAction`，呼叫 `dismiss()`)
- `.presentationDetents([.medium, .large])` + `.presentationDragIndicator(.visible)`
- 內容為 `List` + `.searchable(text:, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("搜尋類別"))`

兩個 Section：

1. **日期區間**：固定 4 列 (`OrderDatePeriod.orderBrowsingCases`)，每列以 `Button` 包 `HStack` 呈現 calendar icon + period title + 末端 checkmark (僅選中項顯示)。點選 dispatch `OrdersFeature.Action.datePeriodSelected(period)` 後 sheet 自動 dismiss。搜尋輸入不影響此 section (永遠顯示)。

2. **商品類別**：第一列「全部」clear row (點選 dispatch `categoryFilterSelected(nil)` 並 dismiss)；其後依 `store.availableCategories` 過濾後列出 (受 search 文字影響)，每列 tag icon + 類別名 + 末端 checkmark (選中項顯示)。點選 dispatch `categoryFilterSelected(name)` 後 sheet 自動 dismiss。搜尋無結果時類別 section 顯示空狀態列 (`ContentUnavailableView` 或同等)；「全部」row 維持顯示。所有列支援多行 (`.multilineTextAlignment(.leading) + .fixedSize(horizontal: false, vertical: true) + HStack(.firstTextBaseline)`)。

### OrdersFeature TCA 與 RootFeature 不動

沿用既有的：
- `OrdersFeature.Action.statusFilterSelected(OrderStatusFilter)`
- `OrdersFeature.Action.datePeriodSelected(OrderDatePeriod)`
- `OrdersFeature.Action.categoryFilterSelected(String?)`
- `OrdersFeature.State.selectedStatus`、`selectedDatePeriod`、`selectedCategory`、`availableCategories`
- `RootFeature` 跨頁進入訂單列表時 reset `selectedDatePeriod = .all` 與 `selectedCategory = nil` 的行為 (`RootFeature.swift` 既有的三處 reset 點不動)

### iPhone Compact 不再渲染 dateChipStrip

iPhone Compact 從篩選列移除 `dateChipStrip(palette:)` 的呼叫；helper 函式本體保留 (iPad regular 與 macOS 仍透過自己的 `dateChipScrollStrip` / `dateChipRow` 渲染日期 chip 列)。

## Non-Goals

- **不**動 iPad regular size class 或 macOS 的篩選列佈局——這兩個分支維持「狀態 chip + 日期 chip + 類別 trigger」現狀，不引入 OrderFilterSheet。
- **不**重用 `OptionPickerSheet` 作為 OrderFilterSheet 的內部實作：OrderFilterSheet 是 iPhone-only 且結構為「Form-like 兩 section」，重用需把 OptionPickerSheet 拆分 (NavigationStack 內外、List 內容區、searchable modifier) 才能嵌入新 sheet，成本高於價值；新 sheet 直接以 `List` + `Section` 構建。
- **不**動 OptionPickerSheet 元件或其既有 call site (訂單編輯流程選類別 / 付款方式 / 幣別 仍用)。
- **不**移除 `OrdersFeature.State.selectedDatePeriod` (仍需供 iPad / macOS 的 chip 列與 `RootFeature` reset 使用)。
- **不**移除 `dateChipStrip` helper code (iPhone Compact 只是不再呼叫；iPad / macOS 的對應 helper 仍各自存在於 `OrdersView.swift` / `OrdersMacView.swift`)。
- **不**新增付款方式 / 訂單來源篩選 (留給未來 change)。
- **不**改動 SwiftData schema / migration / repository。
- **不**改動 TCA reducer 邏輯 (action handlers、selectedOrderID 重算)。
- **不**改動狀態篩選 (`OrderStatusFilterBar`) 的 chip 列呈現。

## Alternatives Considered

- **全整合 (狀態 + 日期 + 類別都進 sheet)**：所有篩選都 2-tap，把高頻的狀態切換變慢，被否決。
- **三個各自 trigger (狀態、日期、類別各一顆 capsule trigger)**：視覺平行但沒省版面 (仍 3 排)、所有操作都變 2-tap，被否決。
- **iPhone-only 之外延伸到 iPad / macOS**：iPad / macOS 沒有版面壓力，三平台一致的維護成本高於收益，限制 iPhone 範圍。
- **OrderFilterSheet 重用 OptionPickerSheet**：需要拆分元件 (chrome 與 content)，破壞向後相容、回歸風險高；放棄重用，直接用 `List + Section` 從零建構新 sheet。

## Impact

- Affected specs:
  - New: `order-filter-sheet` (整合 sheet 的行為、trigger 摘要規則、搜尋與選擇互動)
  - Modified: `order-category-filter` (把現有 requirement「Category filter is presented as a trigger button with a searchable picker sheet」改為僅在 iPad regular 與 macOS 適用；iPhone Compact 上的類別篩選改由新 capability 描述)
- Affected code:
  - New:
    - `apps/apple/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift`
  - Modified:
    - `apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift` (移除 dateChipStrip 呼叫、移除 categoryFilterTrigger helper、移除 showsCategoryPicker @State 與其 .sheet 連接；新增 unifiedFilterTrigger helper、showsFilterSheet @State、`.sheet(isPresented: $showsFilterSheet) { OrderFilterSheet(...) }` 連接)
    - `apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png` (篩選列改變)
    - `apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png` (篩選列改變)
  - Removed: (none — `categoryChipStrip` / `categoryFilterTrigger` 已在上次 change 移除完畢；本次只是再次替換 trigger 邏輯)
