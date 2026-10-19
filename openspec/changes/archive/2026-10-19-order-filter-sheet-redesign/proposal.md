## Why

訂單篩選的類別清單只會越來越長：所有用過的類別平鋪一列一個，已收單開團的舊類別和進行中開團的類別混在一起，使用者要捲很久才找到目前在跑的團；類別一次也只能選一個。日期與付款方式各佔一整個清單區段，搜尋框同時搜類別與付款方式，畫面長、操作路徑也長。6a＋6b 的 review 另留下一項效率問題 (R6)：iPhone 與 iPad 清單每次重繪都對全部訂單篩選三次。這是第 6 步 discuss 裁決排定的 6d，wireframe 已於 2026-10-17 與使用者逐項確認 (https://claude.ai/artifact/GGgmxjwXxWAVPTTfzduLRW 第四列與第三列)。

## What Changes

- iPhone 篩選 sheet 改版：
  - 頂部「篩選條件」標題列右側新增「清除篩選」，把日期區間、付款方式、類別三項的待套用選擇還原成不篩選；三項都已是預設時停用。仍需按「套用」才生效。
  - 日期區間與付款方式各改成一列 Menu，放在 sheet 上方；不再是清單區段。
  - 搜尋框移到「商品類別」區段內，只搜類別，提示文字改為「搜尋類別」。
  - 類別改成固定欄數的格子，同一列有長名稱換行時整列格子等高、同列各格各自點選；欄數依實際可用寬度與 Dynamic Type 計算，無障礙字級時降為單欄。
  - 搜尋框有清除鈕、按 return 與捲動都能收鍵盤，焦點由 Feature 管理。
  - 類別依訂單推導分「開團中」與「已收單」兩組，兩組都可展開收合，組標題顯示類別數與「已選 N」。
- 類別篩選支援多選 (iPhone sheet 與 iPad 選擇器)：選取改成集合，訂單只要含任一選中類別就列出；「全部」清空選取。**BREAKING** (程式內部介面)：`OrderFilterSelection.category`、`OrderListFeature.State.selectedCategory`、`OrdersQuery.filteredOrders(selectedCategory:)`、`OrderSummaryPrompt.summaryPrompt(selectedCategory:)` 由單一值改為集合；Root 的深連結入口 `applyFilterNavigation(searchText:category:)` 介面不變，帶入的單一類別轉成一個元素的集合。
- 分組規則：任一筆含該類別的訂單屬於進行中開團 (以 `Campaign.evaluatingAutoClose(asOf:calendar:)` 判斷) 就歸「開團中」，其餘 (含主檔有、但沒有開團訂單的類別) 歸「已收單」；組內依名稱排序。每次打開重算展開狀態：開團中展開、已收單收合；已收單有選中類別或開團中為空時已收單展開；開團中為空時整組隱藏；搜尋時兩組都展開，沒有結果的組隱藏。
- iPad 篩選改版：
  - 付款方式篩選鈕改成 Menu，不再開選擇器 sheet。
  - 類別篩選鈕開啟新的分組格子選擇器 (與 iPhone 共用同一個格子 View，不動 `OptionPickerSheet`)：點格子只改暫存，按「完成」才套用，取消可反悔，有未套用變更時阻擋下滑關閉並確認捨棄。
  - 篩選鈕選一項顯示名稱，兩項以上顯示「類別：N 項」。
  - 篩選鈕下方新增「清除篩選」，立即還原日期、付款方式、類別；不清訂單狀態與搜尋文字。
- iPhone 訂單頁「篩選：…」摘要：選兩項以上類別時寫「N 項類別」。
- 訂單容器的開團投影改為無鍵 `@Shared`，清單以 `SharedReader` 讀取供分組；Root 改以 `withLock` 寫入，納入投影寫入守門測試。`OrdersFeature` 維持 359 行例外上限內。
- 清單的 sheet 呈現 (iPhone 篩選 sheet、iPad 類別選擇器) 併成單一 `@Presents` destination，符合「同一畫面只一個 destination」規則；日期脈絡在開啟與 Root 刷新時同步給已開啟的選擇器。
- R6：清單每次重繪改成只篩選一次，同一次結果提供日期區段、識別值與全選狀態。
- 資料量無法預估 (可能只有一兩個類別，也可能上百上千)：格子以清單列為單位按需建立，未滿一列時格寬不撐滿；分組只掃訂單與其類別、開團引用固定次數 (不會每個類別各掃一次)，類別排序為 K log K，搜尋與已選數與類別數成正比，並以兩種規模的效能測試與 300 個類別的 UI 測試守住，少量邊界另有單元測試與 snapshot。
- AI 摘要提示文字的類別範圍改為列出所有選中類別。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `order-filter-sheet`: iPhone 篩選 sheet 改為 Menu 列加分組格子、搜尋只搜類別、類別多選、新增清除篩選；iPad 付款方式改 Menu 並新增清除篩選；觸發鈕摘要的多選寫法。
- `order-category-filter`: 類別篩選改為多選集合 (任一類別)、依開團狀態分組的固定欄數等高格子、iPad 類別選擇器改暫存加完成鈕、篩選鈕多選文字、深連結與跨功能導覽的集合語意。
- `ai-order-summary`: 摘要輸入範圍由單一類別改為所有選中類別。
- `condition-readability`: 「篩選是否啟用」的情境改用空的類別集合描述預設值。
- `standard-navigation-affordance`: 篩選 sheet 搜尋提示與實際範圍 (只搜類別) 一致的情境。
- `sheet-dismissal-safeguard`: 防誤關的 sheet 清單加入 iPad 類別選擇器，並明訂搜尋文字與分組展開屬於呈現狀態、不算未套用變更。

## Impact

- Affected specs: `order-filter-sheet`, `order-category-filter`, `ai-order-summary`, `condition-readability`, `standard-navigation-affordance`, `sheet-dismissal-safeguard` (皆為 delta 修改，不新增 capability)。
- Affected code (iOS)：
  - 篩選資料與查詢：apps/ios/BuyLedger/Features/Orders/OrderFilterSelection.swift、OrderFilterFeature.swift、OrderListFeature.swift、OrderListInteraction.swift、OrdersFilterOperations.swift、OrdersListQuery.swift、OrdersQuery.swift、OrderSummaryPrompt.swift、OrdersContainerPlan+Requests.swift、Components/OrderFormatters.swift (皆在 apps/ios/BuyLedger/Features/Orders/)；新增 OrderListFeature+Destination.swift、OrderListDestinationOperations、OrderListSnapshot、OrderCategoryGroups、OrderCategoryPickerFeature。
  - 容器與 Root：apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift、OrdersEditorOptions.swift、apps/ios/BuyLedger/Features/App/RootFeature.swift。
  - 畫面：apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift、OrderFilterDateSection.swift、OrderFilterPaymentMethodSection.swift、OrderFilterCategorySection.swift、OrderFilterPreviewFixtures.swift、apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift、OrdersView.swift、OrdersRegularListColumn.swift；新增分組格子 View、iPad 類別選擇器 Feature 與分組計算輔助型別 (位置見 design)。
  - 字串與 identifier：apps/ios/BuyLedger/Resources/Localizable.xcstrings (新增文案與 en)、apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift。
  - Design System：apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift，新增 BLFilterChipLabel.swift。
  - 測試：apps/ios/BuyLedgerTests/ 下篩選、清單、Root 深連結、開團投影、AI 摘要、投影寫入守門與 snapshot 相關檔；apps/ios/BuyLedgerUITests/ 新增篩選 sheet 與 iPad 選擇器的 UI 測試 (目前沒有 UI 測試走過篩選 sheet)。
  - 文件：apps/ios/CLAUDE.md、.claude/rules/ios-data-layer.md、.claude/rules/ios-navigation.md 中開團投影與清單 sheet 呈現的描述。
  - verify／review 後的整併 (2026-10-19 使用者裁定)：新增 apps/ios/BuyLedger/Features/Orders/OrderFilterConfirmations.swift 與 Components/OrderCategoryFilterRows.swift；改動 OrderCategoryGroups.swift、OrderCategoryPickerFeature.swift、Components/OrderCategoryPickerSheet.swift、OrderEditFeature.swift (formatter 呼叫端的 doc 對齊)，以及 `.claude/rules/ios-navigation.md` 的參考實作描述；新增訂單篩選相關 snapshot 基準圖。
  - 第二輪 verify／review 修正 (2026-10-19 使用者裁定)：改動 apps/ios/BuyLedger/Resources/Localizable.xcstrings (移除兩個無呼叫端的 key)、OrdersRegularListColumn.swift、OrdersListQuery.swift、OrderCategoryGroups.swift 與對應單元測試、apps/ios/BuyLedgerUITests/Tests/Orders/OrderPaymentMethodMenuTests.swift 與 Screens/OrdersScreen+RegularFilters.swift；apps/ios/BuyLedger.xcodeproj/project.pbxproj 的 build number (實機建置產生，使用者裁定保留)。
- 不動資料庫 schema 與 `shared/data-model/schema/`。
