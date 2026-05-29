## Why

訂單頁的類別篩選目前在三個平台都用「水平滑動膠囊列」。類別由使用者自行新增，數量上限會隨使用時間成長；當類別變多 (例如 10 個以上) 時，使用者需要長距離橫向滑動才能找到想要的類別，且部分膠囊一直被裁切在可視範圍外。原本評估改成 `Menu` 可解，但 SwiftUI `Menu` 展開後仍有滾動高度上限，且無內建搜尋，到了 20–30 個類別時可發現性仍不足。改為「trigger button + sheet picker」並開啟搜尋後，數量天花板被移除：使用者點 trigger 直接看當前選擇，sheet 內可滾可搜尋，與 Apple 在 Mail 資料夾選擇、Photos 相簿選擇所用的 pattern 一致。

## What Changes

- 三平台訂單頁類別篩選的主控件從「`ScrollView(.horizontal)` + Capsule 膠囊列」改為一顆 **trigger button**：tag icon + `類別：<current>` + chevron.down 的單顆 Capsule，`<current>` 在未選時為「全部」、已選時為類別名；capsule fill 在已選時為 purple、未選時為 fillTertiary。按鈕 label 對 `.lineLimit(1) + .truncationMode(.tail)` 處理長類別名。
- 點 trigger 後 present **既有 `OptionPickerSheet` 元件**，傳入下列參數：
  - `title: "選擇商品類別"`
  - `allowsAdd: false`（類別 CRUD 仍由 `LookupManagementFeature` 負責，不在篩選 sheet 內新增）
  - `searchable: true`
  - `options: store.availableCategories`
  - `selected: store.selectedCategory ?? ""`（`""` 為「沒選任何類別」的 sentinel，與 `availableCategories` 不會撞名）
  - `onSelect`: dispatch `OrdersFeature.Action.categoryFilterSelected(option)` 並 dismiss sheet
  - `clearOption: ClearOption(title: "全部", onClear: { ... })`（見下一條）
- **擴充 `OptionPickerSheet`**：新增一個 optional 參數 `clearOption: ClearOption?`，並在元件內定義 nested type `ClearOption { let title: String; let onClear: () -> Void }`。當 `clearOption` 非 `nil` 時：
  - iOS / iPadOS `listContent`：在選項 Section 之上額外渲染一列 `title` row（點擊呼叫 `onClear` 並 dismiss）。
  - macOS `optionsCard`：在 `BLCard` 內第一列為 `title` row，下接 Divider 再列既有選項。
  - Checkmark 規則：當 `selected` 為空字串時，clear row 顯示 checkmark；既有選項列維持 `option == selected` 比對（空字串不會撞到任何實際選項）。
  - 既有所有 call site（`OptionPickerSheet` 在訂單編輯流程選類別 / 付款方式 / 幣別）不傳 `clearOption`，行為與外觀完全不變。
- 三平台的 sheet 呈現沿用 `OptionPickerSheet` 既有設定（iOS / iPadOS 預設 sheet detents、macOS `.frame(minWidth: 400, minHeight: 480)`）。此尺寸比 `PaymentMethodEditorSheet` 的 `420×320` 大，因為內容是可搜尋列表（含搜尋欄、可變高度列表、空狀態）而非固定欄位的 form。
- 既有 TCA 行為完全不變：`OrdersFeature.Action.categoryFilterSelected(String?)` action、`selectedCategory` / `categoryMaster` / `availableCategories` state、合取篩選與 `selectedOrderID` 重算邏輯皆原樣。
- 從 analytics 類別排行 deep-link 進來時的「指定類別變成 active filter」行為不變；spec 中描述「對應膠囊以選中樣態呈現」的措辭改為「trigger button label 顯示為該類別、開啟 picker 時該項目顯示 checkmark」。

## Non-Goals (optional)

- **不**改動狀態篩選 (`OrderStatusFilterBar`)、日期篩選與搜尋欄的呈現方式。
- **不**改動類別 master 的 CRUD (`LookupManagementFeature`) 與 cascade rename 行為。
- **不**加入「最近使用 / 常用類別」排序、群組或多選——sheet 內順序仍照 `availableCategories` 既有合併規則。
- **不**為付款方式 / 訂單來源新增篩選 UI——本次只動類別篩選。
- **不**改動 SwiftData schema 與 migration。
- **不**改 `OrdersFeature` 的 state shape、action set 或 reducer 行為。
- **不**新建獨立的 `CategoryFilterPickerSheet`——選擇重用 `OptionPickerSheet` 並擴充 `clearOption`，避免兩套可搜尋 picker 邏輯各自演化。
- **不**改動 `OptionPickerSheet` 既有 call site 的行為或外觀——既有呼叫者不傳 `clearOption`，畫面零 diff。
- **不**走「依數量自適應 (少量膠囊、多量 sheet)」混合 pattern——已明確選擇全平台一律使用 trigger button + sheet picker。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `order-category-filter`: 類別篩選的呈現方式由「橫向膠囊列 + 選中變色」改為「trigger button (帶當前選擇 label) + 點開 `OptionPickerSheet` 可搜尋列表」；deep-link 後的視覺反饋描述同步更新。底層篩選行為、合取規則與 cross-feature reset 不變。
- `option-picker`: `OptionPickerSheet` 新增 optional `clearOption` 行為——允許呼叫者在選項列表上方額外渲染一列「清除目前選擇」row，並在 `selected` 為空字串時於該 row 顯示 checkmark。未傳 `clearOption` 時行為完全不變。

## Impact

- Affected specs:
  - Modified: `order-category-filter`（新增「trigger button + sheet picker」呈現方式 requirement、deep-link scenario 視覺反饋描述同步更新）
  - Modified: `option-picker`（新增「optional clear option」requirement）
- Affected code:
  - Modified:
    - `BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift`：新增 `ClearOption` nested type 與 `clearOption: ClearOption?` 參數；iOS `listContent` 與 macOS `optionsCard` 渲染 clear row；filteredOptions 不受 clearOption 影響（clear row 不參與搜尋）
    - `BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift`：移除 `categoryChipStrip` / `categoryChipButton`，新增 `categoryFilterTrigger(palette:)` helper 與 `.sheet` 控制 state
    - `BuyLedger/BuyLedger/Features/Orders/OrdersView.swift`：移除 `categoryChipScrollStrip` / `categoryChip`，新增 `categoryFilterTrigger(palette:)` helper 與 `.sheet` 控制 state
    - `BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift`：移除 `categoryChipRow` / `categoryChip`，新增 `categoryFilterTrigger(palette:)` helper 與 `.sheet` 控制 state
    - `BuyLedger/BuyLedgerTests/__Snapshots__/`：iOS 393×852 baseline 因為篩選列從膠囊列改為單顆 trigger button 而需要 re-record
  - New: (none — `ClearOption` 為 `OptionPickerSheet` 的 nested type，不獨立成檔案)
  - Removed: (none — 舊的 chip 相關 helper 被新 trigger helper 取代，不獨立成檔案故無檔案刪除)
