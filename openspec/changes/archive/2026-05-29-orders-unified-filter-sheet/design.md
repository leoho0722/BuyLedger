## Context

iPhone Compact 訂單頁目前的篩選列結構 (剛 archive 的 `2026-05-29-orders-category-filter-sheet-picker` change 收斂後狀態)：

```
[BLSearchField]              <- BLSpacing.large 左右 padding
[狀態 chip 列 (ScrollView)]   <- OrderStatusFilterBar
[日期 chip 列 (ScrollView)]   <- dateChipStrip
[類別 trigger button]         <- categoryFilterTrigger，單顆 Capsule 填滿寬度，點開 OptionPickerSheet 選類別
```

實際使用觀察 (使用者本人 dogfooding 後回饋)：
- **狀態**：高頻，幾乎每次進訂單頁都會切換
- **類別**：高頻，用於依分類快速 narrow down
- **日期**：幾乎沒按過——使用者直接說「甚至沒按過」；codebase 也只有 `RootFeature` 對 `selectedDatePeriod` 做 reset 引用，沒有任何 inbound deep-link 設定具體日期

設計目標：保護高頻動作的 1-tap 速度，把低頻動作埋進 sheet，省下視覺份量並為未來篩選擴充預留空間。

`OrdersFeature` state shape 與 actions 完全不動 (`statusFilterSelected` / `datePeriodSelected` / `categoryFilterSelected` 仍是進入點)；`RootFeature` 跨頁 reset 行為不動。

## Goals / Non-Goals

**Goals:**

- iPhone Compact 訂單頁篩選列從「狀態 chip + 日期 chip + 類別 trigger」(3 排) 縮減為「狀態 chip + 整合 trigger」(2 排)
- 新 `OrderFilterSheet` 元件提供「日期區間」與「商品類別」兩個 section 的選擇 UI；搜尋只過濾類別 section
- Trigger button 視覺與 archived change 的 `categoryFilterTrigger` 一致：單顆 Capsule、填滿可用水平寬度、多行 label、icon + summary + chevron
- Trigger label 摘要當前篩選 (「篩選：全部」/「篩選：本月」/「篩選：美妝」/「篩選：本月 · 美妝」)，使用者不點開即知當前篩選狀態
- 點選任一 row 後 sheet 自動 dismiss (直接體現選擇)
- iPad regular 與 macOS UI 完全不動 (尺寸大、版面壓力低，平台一致性收益不抵改動成本)
- 既有 TCA actions / state / reducer 行為 100% 維持，含 `RootFeature` 的跨頁 reset

**Non-Goals:**

- 不動 iPad regular 與 macOS 的篩選列佈局
- 不重用 `OptionPickerSheet`，OrderFilterSheet 是獨立新元件
- 不移除 `OptionPickerSheet` 或其既有 call site (訂單編輯流程選類別 / 付款方式 / 幣別 仍用)
- 不移除 `OrdersFeature.State.selectedDatePeriod` 或 `dateChipStrip` helper code (iPad / macOS 仍用)
- 不新增付款方式 / 訂單來源篩選
- 不改 SwiftData schema / migration / repository
- 不改 TCA reducer 邏輯
- 不改狀態篩選 chip 列呈現
- 不為 OrderFilterSheet 寫 macOS 卡片版本 (iPhone-only)

## Decisions

### 為什麼 iPhone-only

iPad regular 中間欄寬 280–360pt、macOS 視窗寬鬆，三排 chip 列在這兩個平台都不佔版面。把整合 sheet 推到 iPad / macOS 會：
- 需要為 OrderFilterSheet 寫 macOS 卡片版本 (對齊 `LookupManagementView` / `CustomersView`)
- 在 iPad split view 內處理 sheet 與 detail 欄的互動
- 三平台維護兩套並存的篩選 UI (整合 + 既有 chip + trigger) 成本翻倍

收益方面，iPad / macOS 並沒有省版面的剛性需求；平台 UX 不一致雖然破例，但這個破例的成本遠低於整合 sheet 跨平台的維護成本。

### Trigger label 用具體摘要而非 count

label 格式：「篩選：<summary>」，summary 規則：

| selectedDatePeriod | selectedCategory | summary |
| --- | --- | --- |
| .all | nil | 全部 |
| .all | X | X |
| non-.all | nil | 日期 title |
| non-.all | X | 日期 title · X |

使用者掃一眼就能直接讀出當前篩選狀態，不需點開 sheet 確認。`篩選 (2 項條件)` 這種抽象計數需要點開才知道具體是什麼，違背 trigger label 「at-a-glance」初衷。

長類別名稱會撐長 summary 字串，但 trigger 已支援多行 (沿用 archived change 收斂的設計)，capsule 自然增長高度。

### 為什麼 OrderFilterSheet 不重用 OptionPickerSheet

`OptionPickerSheet` 是「完整 sheet」——`NavigationStack` 包 `List` 包 toolbar 包 searchable，本質是「**一個** sheet 對應 **一個** 單選 picker」。OrderFilterSheet 需要：
- 兩個並列 section (日期 + 類別)，不是單一選項列表
- 搜尋只作用在類別 section，不影響日期
- 點選任一 section 的列都立刻 dismiss

要重用 OptionPickerSheet，需要把它拆成：
- 「sheet chrome」(NavigationStack + toolbar + presentation modifiers)
- 「options content」(List + sections + searchable)

兩者既有 call site (訂單編輯選類別 / 付款方式 / 幣別) 都會受影響，回歸風險高。本次直接從零建構 OrderFilterSheet，內部直接寫 `List` + 兩個 `Section` + `.searchable`。共用的「row 多行支援」邏輯重新實作即可 (約 10 行 SwiftUI)。

未來如果發現多個新 sheet 都需要「searchable list + clear option」pattern，再以另一個 change 把 OptionPickerSheet 重構成可重用 building block。

### 搜尋只過濾類別 section，不影響日期

`.searchable` modifier 只負責加搜尋欄並提供 `searchText` binding；filtering 邏輯由資料源決定。OrderFilterSheet 把 `searchText` 套用在類別 `ForEach` 的資料源 (`filteredCategories`)，日期 section 完全不參考 `searchText`，所以搜尋時日期 4 列維持顯示。

搜尋過濾後若無類別匹配，類別 section 顯示空狀態列；「全部」clear row 仍維持顯示 (與 `2026-05-29-orders-category-filter-sheet-picker` 既有 `OptionPickerSheet` 內 clear row 的行為一致)。

### Pending selection + Apply / Cancel pattern (取代原本「點選後自動 dismiss」)

實機驗證後改採此 pattern。原本「點選即 dispatch + dismiss」的設計在「同一 session 想改多個篩選」(例如「本月的美妝」「上月的 3C」這類月底切片操作) 時要重複開關 sheet，UX 不佳。

OrderFilterSheet 內每列 (日期或類別) `Button` action 改為「更新本地 pending state」而非「立即 dispatch + dismiss」。使用者可在同一 sheet session 內依序調整多個 pending 篩選，點右上「套用」toolbar button (`.confirmationAction`) 才把所有變動 dispatch 到 store 並 dismiss；左上「取消」(`.cancellationAction`) 直接 dismiss、不 dispatch、pending 變動全部丟棄。

Pending state 結構：
- `@State private var pendingDatePeriod: OrderDatePeriod`，於 view init 時以 `store.state.selectedDatePeriod` 為初值
- `@State private var pendingCategory: String?`，於 view init 時以 `store.state.selectedCategory` 為初值
- Row checkmark 規則改成比對 `pendingX`，**不是** store state

Apply 行為：
- 比對 pending vs 目前 store state，**只 dispatch 真正變動的欄位** (避免冗餘 action，例如 `selectedOrderID` 重算邏輯只在類別/日期真有改變時觸發)
- Dispatch 後 `dismiss()` 關 sheet
- 即使無變動，Apply 仍 dismiss (不 disable button、不顯示警告)

選此 pattern 而非「點選自動 dismiss」的理由：
- 使用者實機驗證後明確要求改成 Apply 模式，理由是「同時改多個篩選」是常見場景
- 標準的 form-style sheet pattern (iOS Mail / Settings 多 section sheet 都是此模式)，使用者預期一致

代價：
- 單一篩選變更要多按一次「套用」(可接受，trigger 點開後 sheet 已在 .medium detent 上方、Apply 按鈕在標題列右側，拇指可及)
- 「取消」按鈕語義變得更重要 (要明確說「不套用」)；使用者誤觸需有反悔路徑

### iPad / macOS 的「類別 trigger」維持現狀

剛 archived 的 change 已在 iPad / macOS 上把類別篩選改為 `categoryFilterTrigger`；本次不動這兩個平台。spec delta 對 `order-category-filter` capability 的修改只是把「Category filter is presented as a trigger button with a searchable picker sheet」requirement 的範圍從「all platforms」收斂成「iPad 與 macOS」(因為 iPhone Compact 已改由新 capability `order-filter-sheet` 覆蓋)。

## Implementation Contract

**Observable behavior — iPhone Compact 篩選列**

- 進入訂單頁時，篩選列從上到下：
  1. `BLSearchField` (不動)
  2. 狀態 chip 列 `OrderStatusFilterBar` (不動)
  3. 整合 trigger button (`unifiedFilterTrigger`，取代既有 `dateChipStrip` 與 `categoryFilterTrigger`)
- Trigger button：
  - 單顆 Capsule，水平填滿可用寬度 (左右對齊上方搜尋欄)
  - 左側 `Image(systemName: "line.3.horizontal.decrease")`
  - 中段 `Text("篩選：<summary>")` (套 `.multilineTextAlignment(.leading)` + `.fixedSize(horizontal: false, vertical: true)` + `.frame(maxWidth: .infinity, alignment: .leading)`)
  - 右側 `Image(systemName: "chevron.down")`
  - HStack `alignment: .firstTextBaseline`，icon 對齊第一行
  - Summary 規則同上 (4 種組合)
  - Capsule fill：`(selectedDatePeriod != .all || selectedCategory != nil)` 為 `palette.purple.opacity(0.18)`；否則 `palette.fillTertiary`
  - 前景色：同條件下分別 `palette.purple` 或 `palette.secondaryLabel`
- 點 trigger → 呈現 `OrderFilterSheet`

**Observable behavior — OrderFilterSheet**

- Sheet chrome：
  - `NavigationStack` + `.navigationTitle("篩選")` + `.navigationBarTitleDisplayMode(.inline)`
  - Toolbar 左側「取消」button (`.cancellationAction`，呼叫 `dismiss()`)
  - `.presentationDetents([.medium, .large])` + `.presentationDragIndicator(.visible)`
- 內容為 `List`，套 `.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("搜尋類別"))`
- **Section 「日期區間」**：
  - 固定 4 列，順序為 `OrderDatePeriod.orderBrowsingCases` (`.all` / `.thisWeek` / `.thisMonth` / `.lastMonth`)
  - 每列 `Button { dispatch + dismiss }`，label 為 `HStack(.firstTextBaseline) { calendar icon; Text(period.title); Spacer; if selected: checkmark }`
  - `period.title` 來自既有 `OrderDatePeriod.title`
  - 列支援多行 (期間 title 不太可能長到換行，但統一格式以保險)
  - 搜尋輸入完全不影響此 section
- **Section 「商品類別」**：
  - 第一列「全部」clear row：`Button { dispatch categoryFilterSelected(nil) + dismiss }`，label 為 `HStack(.firstTextBaseline) { tag icon; Text("全部"); Spacer; if selectedCategory == nil: checkmark }`
  - 接著依 `filteredCategories` 列出每個類別：`Button { dispatch categoryFilterSelected(name) + dismiss }`，label 為 `HStack(.firstTextBaseline) { tag icon; Text(name).multilineText.fixedSize; Spacer; if selectedCategory == name: checkmark }`
  - `filteredCategories` 過濾規則：當 `searchText` 為空時返回 `availableCategories`；否則返回 `availableCategories.filter { $0.lowercased().contains(searchText.lowercased()) }`
  - 搜尋無類別匹配時 (`filteredCategories.isEmpty`)，類別 section 顯示一列 `ContentUnavailableView("沒有符合的類別", systemImage: "tray", description: Text("試試其他搜尋關鍵字。"))` 或同等的空狀態 row；「全部」clear row 維持顯示
  - 當 `availableCategories` 本身為空時 (使用者沒任何類別 master 也沒任何訂單有類別)，類別 section 仍存在但只顯示「全部」row + 空狀態描述「尚無類別」(此情境下整個 trigger button 本身在 iPhone Compact 仍會顯示——因為 trigger 不再條件依賴 `availableCategories.isEmpty`)
- 列點選**只更新 pending state**，不 dispatch、不 dismiss；右上「套用」(`.confirmationAction`) 才 dispatch 變動的欄位並 dismiss；左上「取消」(`.cancellationAction`) 直接 dismiss、丟棄 pending 變動

**Trigger 顯示條件**

- 本次新 trigger button 不再條件依賴 `availableCategories.isEmpty`：即使類別清單為空，trigger 仍渲染 (使用者仍可改日期)。
- Sheet 內類別 section 在 `availableCategories` 為空時顯示空狀態提示。

**Interfaces (未變動，列出以利驗證)**

- `OrdersFeature.Action.statusFilterSelected(OrderStatusFilter)`
- `OrdersFeature.Action.datePeriodSelected(OrderDatePeriod)`
- `OrdersFeature.Action.categoryFilterSelected(String?)`
- `OrdersFeature.State.selectedStatus`、`selectedDatePeriod`、`selectedCategory`、`availableCategories`
- `RootFeature` 跨頁 reset 行為

**Failure / edge cases**

- 使用者刪除全部類別 master 後重新進入：trigger 仍渲染，sheet 內類別 section 為空狀態，使用者仍可改日期；reducer 既有「校正無效 selectedCategory」邏輯不變
- 同時設多個篩選：每次點選 dismiss sheet，回到列表看結果；要改下一個再點 trigger
- 類別名極長：trigger summary 多行 (沿用 archived 設計)；sheet 內類別 row 也多行
- 搜尋字串 trim 後為空：等同搜尋空字串，回到完整列表

**Acceptance criteria**

1. iPhone Compact 訂單頁篩選列：搜尋 + 狀態 chip + 整合 trigger 共 3 列 (原本搜尋 + 狀態 chip + 日期 chip + 類別 trigger 共 4 列)；省 1 列
2. Trigger label 在 4 種 (date, category) 組合下顯示正確摘要 (見上方表格)
3. Trigger capsule fill 在任一非預設條件啟用時為 purple，否則 fillTertiary
4. 點 trigger 後 OrderFilterSheet 出現，預設 detent 為 `.medium`，可下拉到 `.large`
5. Sheet 內「日期區間」section 4 列，目前選中項顯示 checkmark；點任一列 dispatch `datePeriodSelected` 後 sheet dismiss、trigger label 立即同步
6. Sheet 內「商品類別」section 第一列為「全部」clear row；點選 dispatch `categoryFilterSelected(nil)` 後 sheet dismiss、trigger label 立即同步
7. Sheet 內輸入搜尋字串：類別列即時過濾、日期 section 不受影響、「全部」row 永遠在最上方；無匹配時類別 section 顯示空狀態
8. iPad regular size class 與 macOS 訂單頁篩選列維持原狀 (狀態 chip + 日期 chip + 類別 trigger)，OrdersView 與 OrdersMacView 視覺零變動
9. 既有 `OptionPickerSheet` call site (訂單編輯流程選類別 / 付款方式 / 幣別) 行為零變動
10. iOS / iPadOS / macOS build 皆綠；既有 TCA 測試 (含 `OrdersFeatureTests`、`RootFeatureTests`) 全綠
11. iOS 393×852 snapshot baseline 重錄，反映新 trigger 與新 sheet
12. 從分析頁類別 row deep-link 後仍正確：trigger label 顯示「篩選：<被點的類別>」 (對應 selectedCategory 設定、selectedDatePeriod 仍 reset 到 .all)

**In scope**

- 新增：`BuyLedger/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift`
- 修改：`BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift` (移除既有 dateChipStrip 呼叫、移除 categoryFilterTrigger helper / showsCategoryPicker @State / 既有 .sheet 連接；新增 unifiedFilterTrigger helper、showsFilterSheet @State、新 .sheet 連接)
- 重錄：`BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactView*.1.png`

**Out of scope**

- `OrdersView.swift` (iPad)、`OrdersMacView.swift`、`OptionPickerSheet.swift`、`OrdersFeature.swift`、`RootFeature.swift` 全部不動
- 不動 `OrderDatePeriod` 與 `OrderStatusFilter` enum
- 不動 SwiftData schema / migration
- 不新增付款方式 / 訂單來源篩選

## Risks / Trade-offs

- [iPhone Compact 改了篩選 UI，iPad / macOS 沒改，平台不一致] → 接受。iPhone 是版面壓力主場景；iPad / macOS 改動成本高於收益。spec 也明確分流 (iPhone Compact 走新 `order-filter-sheet` capability、iPad / macOS 走 `order-category-filter` 既有 trigger requirement)
- [點選後自動 dismiss → 改多個篩選要重複開 sheet] → 接受。同時改多個篩選不是常見流程；改用「完成」按鈕收尾會讓常見的「點一次就走」變慢
- [trigger label 在「日期 + 類別」兩個都長時可能多行很高] → 沿用 archived 設計的多行 + capsule grows vertically，視覺上佔較多版面但不破壞 layout
- [從零實作 OrderFilterSheet 與 OptionPickerSheet 重複「row 多行支援」邏輯] → 可接受的重複；未來若有第三個類似 sheet 再重構成共用 building block
- [snapshot baseline 一定要重錄] → 已在 acceptance criteria 列出
- [iPhone Compact trigger 在 `availableCategories` 為空時仍渲染，與 archived change 行為改變] → 故意改變。整合 trigger 不再僅代表類別篩選，即使沒類別也仍提供日期篩選入口
