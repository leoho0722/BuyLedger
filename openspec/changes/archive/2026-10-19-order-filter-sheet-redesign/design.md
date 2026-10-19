## Context

6d 是第 6 步 (Orders) discuss 裁決排定的最後一個 change，需求與裁決累積在 2026-10-04 discuss 與 2026-10-17 wireframe 討論；2026-10-17 經 claude-impl、codex-impl、gemini-impl 三方唯讀審查後修訂本文件。現況 (2026-10-17 讀程式碼確認)：

- iPhone 篩選 sheet (`OrderFilterSheet`) 是 `List` 內三個區段：日期 (`OrderFilterDateSection`)、付款方式 (`OrderFilterPaymentMethodSection`)、類別 (`OrderFilterCategorySection`)，`.searchable` 放導覽列，同時過濾類別與付款方式。
- 暫存選擇在 `OrderFilterFeature.State.pendingFilterSelection` (`OrderFilterSelection`：`datePeriod`、`category: String?`、`paymentMethod: String?`)，套用由 `OrdersFilterOperations.filterApplied` 寫回清單；dirty 為 `pendingFilterSelection != committedFilterSelection`。
- 清單的 sheet 呈現有三份平行狀態：`@Presents var filterSheet` 與兩個 Bool (`isCategoryPickerPresented`、`isPaymentMethodPickerPresented`)，`OrdersView` 掛三個 `.sheet`，`OrdersCompactView` 掛一個。這違反 `.claude/rules/ios-navigation.md`「同一畫面的多個 sheet 併進單一 `@Presents` destination 列舉」。
- iPad (`OrdersRegularListColumn`) 篩選列：狀態 chips、日期 chips、付款方式與類別兩個全寬 `BLFilterChip` 觸發鈕，兩者都開 `OptionPickerSheet`，選了就套用並關閉。
- 類別篩選是單一值：`OrderListFeature.State.selectedCategory: String?`；直接讀它或 `pendingFilterSelection.category` 的 production 檔有 `OrdersListQuery`、`OrdersQuery`、`OrdersFilterOperations`、`OrderListInteraction`、`OrderSummaryPrompt`、`OrdersContainerPlan+Requests`、`OrderFilterCategorySection`、`OrdersView`、`OrdersRegularListColumn`、`OrderFilterPreviewFixtures`。
- 開團投影是容器的一般屬性 `OrdersFeature.State.campaigns: [Campaign]`，由 `RootFeature` 的 `onChange(of: \.campaigns.campaigns)` 直接賦值；清單與篩選 sheet 拿不到開團。
- 日期脈絡：`OrderListFeature.State.dateContext: OrderDateContext?`，在 `view(.task)`／`view(.retryTapped)` 寫入，Root 經容器 `refreshDateContext(now:calendar:)` 更新；尚未寫入時 `OrdersListQuery.filteredOrders` 回傳空陣列。
- R6：iPhone `OrdersCompactView.navigationContent` 與 iPad `OrdersView.regularSplitContent` 每次重繪分別讀 `dateSections(locale:)`／`filteredOrders`、`isAllFilteredSelected`、`filteredIDs`，各自跑一次 `OrdersQuery.filteredOrders`。
- 行數 (以 archive 內 `style_checks.py` 的 LEN 計，不含檔頭與空行，2026-10-17 量測)：`OrderListFeature.swift` 298 (上限 300)、`OrdersFeature.swift` 356 (例外上限 359)、`OrderFilterFeature.swift` 154。以 `wc -l` 量的總行數不是驗收依據。
- 資料量：類別、訂單、開團與付款方式的數量都無法預估，可能只有一兩個，也可能上百上千 (使用者 2026-10-17 指示)。
- 目前沒有任何 UI 測試走過篩選 sheet (`OrdersScreen.openFilterSheet` 沒有呼叫端)；`OrdersFeaturePerformanceTests` 從 `BuyLedger.xctestplan` 排除，要以 `-only-testing` 單獨執行。

## Design Source

- 來源：Claude Design 畫布「訂單篩選 sheet 改版 wireframe」https://claude.ai/artifact/GGgmxjwXxWAVPTTfzduLRW ，2026-10-17 與使用者逐項確認。採用第四列「格子版」三張 (`IPhoneGrid.dc.html`、`IPhoneGridExpanded.dc.html`、`IPhoneGridSearch.dc.html`) 與第三列 iPad 兩張 (`IPadPaymentMenu.dc.html`、`IPadCategoryPicker.dc.html`)；清單版與 `Current.dc.html` 只作對照。
- 快取：`.spectra/design-cache/order-filter-sheet-redesign/` (不提交)。
- wireframe 以 LeoKit token 畫，只定結構與互動；顏色、字級、間距一律換成 App 既有的 Design System。

| 元素 | wireframe 值 | 實作對應 |
| --- | --- | --- |
| sheet 區段順序 | 篩選條件標題列 → 日期／付款方式 Menu 兩列 → 商品類別 (搜尋 → 全部 → 開團中 → 已收單) | 同左 |
| Menu 列 | 前置 `calendar`／`creditcard`，尾端值＋上下箭頭 | SF Symbols `calendar`、`creditcard`、`chevron.up.chevron.down`，圖示色 `.blAccent` |
| 搜尋框 | 放大鏡、提示「搜尋類別」、有字時顯示清除鈕 | `magnifyingglass`、`xmark.circle.fill`；獨立 section 內固定 `.id` 的一般列，底色為 44pt 膠囊 (`insetGrouped` 儲存格的圓角遮罩沒有公開 API 可關閉，wireframe 的 10px 圓角做不到，使用者 2026-10-18 裁定維持此 List 列樣式) |
| 清除篩選 | 文字鈕＋逆時針箭頭，預設時 40% 不透明 | `arrow.counterclockwise`；停用用 `.disabled(_:)` |
| 組標題 | `開團中 (3)`、`已收單 (5)`＋右側箭頭；有選取時加「已選 N」膠囊 | `chevron.down`／`chevron.right` |
| 格子 | 間距 8、格高至少 48、圓角 10、置中文字 | 間距 `BLSpacing.small`、圓角 `BLRadius.small`、命中區至少 `BLHitTarget.minimum`；欄數見「格子欄數依實際寬度與字級計算」 |
| 選中格 | 淡色底＋品牌色框＋右上角勾號 | `.blAccent` 系語意色；勾號 `checkmark` 放在文字左側同一列、垂直置中 (使用者 2026-10-18 視覺調整) |
| iPad 付款方式 | 全寬膠囊鈕開 Menu，選項前置勾號 | `Menu` 內放 inline `Picker`，勾號由系統單選語意提供；標籤用 `BLFilterChipLabel` |
| iPad 類別選擇器 | form sheet：取消 (xmark)、標題「選擇商品類別」、「完成」 | toolbar `.cancellationAction`／`.confirmationAction` |

## Goals / Non-Goals

**Goals:**

- iPhone 篩選 sheet 依 wireframe 改成 Menu 列＋分組格子，搜尋只搜類別，新增清除篩選。
- 類別篩選全面改為多選集合 (任一類別)，iPhone、iPad、Root 深連結、AI 摘要一致。
- 類別依開團狀態分組、可收合、每次打開重算展開；格子欄數依寬度與字級、同列等高、各格獨立點選。
- iPad 付款方式改 Menu、類別改共用分組格子的選擇器 (暫存＋完成)、新增清除篩選。
- 清單的 sheet 呈現併成單一 destination。
- 開團投影改無鍵 `@Shared`；`OrdersFeature` ≤ 359、`OrderListFeature` 與其他改到的 Feature ≤ 300 (LEN)。
- R6：清單重繪只篩選一次。
- 從單一類別到大量類別都正常運作，並有大小兩種資料量的測試。
- 每個 task 結束時都能建置，完整單元測試全綠。

**Non-Goals:**

- 不動資料庫 schema、`shared/data-model/schema/` 與篩選狀態的持久化。
- 不改 `OptionPickerSheet` (其他呼叫端不受影響)。
- iPad 日期篩選維持 chips；訂單狀態篩選與清單搜尋欄不動。
- 清除篩選不清訂單狀態與搜尋文字。
- 不改首頁、分析頁、開團分頁的「篩選與分組」。
- 不新增「依最近訂單排序」等其他組內排序。

## Decisions

### 類別選取改為集合並以任一類別比對

`OrderFilterSelection.category: String?` 改為 `categories: Set<String>`，`OrderListFeature.State.selectedCategory` 改為 `selectedCategories: Set<String>`，空集合代表全部類別。`OrdersQuery.filteredOrders` 參數改為 `selectedCategories`，比對為「集合為空或與 `order.categories` 有交集」。`isActive` 以 `!categories.isEmpty` 判斷。顯示用的名稱一律以 `localizedStandardCompare` 排序後再取用。

為了讓本步結束時就能建置，所有讀單一類別的地方在同一個 task 內改成集合：iPhone 的 `OrderFilterCategorySection` 以 `contains` 判斷勾選、`filterPendingCategorySelected(String?)` 暫時改成「選一項＝只含它的集合、全部＝空集合」；iPad 的 `OptionPickerSheet` 暫時以 `selectedCategories.first ?? ""` 顯示、選一項設為只含它的集合、清除設為空集合。兩處暫時對接在後續 task 改版時移除。

替代方案：`[String]` 保留點選順序。否決：要另外去重，dirty 比對會因順序不同誤判。

### Root 深連結介面維持單一類別

`OrdersFeature.State.applyFilterNavigation(searchText:category:now:calendar:)` 與 `OrderListFeature.State.applyFilterNavigation(searchText:category:)` 參數維持 `String?`，清單內部轉成 `category.map { [$0] } ?? []`。Root 與既有深連結測試的呼叫方式不變。

### 開團投影改無鍵共享引用

`OrdersFeature.State.campaigns` 改為無鍵 `@Shared var campaigns: [Campaign]`，容器建立清單時傳入 `SharedReader($campaigns)`，清單以 `@SharedReader var campaigns` 讀取並在開啟 sheet 時把同一個 `SharedReader` 交給子層。`RootFeature` 的 `onChange(of: \.campaigns.campaigns)` 改為 `state.orders.$campaigns.withLock { $0 = state.campaigns.campaigns }`；`OrdersEditorOptions` 照舊讀 `state.campaigns`。宣告寫成 `@Shared(value: []) var campaigns: [Campaign]` (swift-sharing 的 `Shared.init(value:)`)，`init` 內以 `SharedReader(_campaigns)` 傳給清單 (讀已初始化的儲存屬性，不在初始化完成前呼叫 `$campaigns`)，估計 `OrdersFeature.swift` 增加 1 行到 357；若改照 `orders` 的寫法 (區域變數＋指派) 則增加 3 行到 359，仍在上限內。以實測 LEN 為準。

型別系統只保證清單與子層拿到的是唯讀的 `SharedReader`；容器自身與 Root 仍可寫入，「只有 Root 寫」由 `ProjectionWriteBoundaryTests` 守門。守門補上：Orders 範圍內 (容器主檔與其他檔) 的 `$campaigns.withLock` 與一般賦值、把可寫的 `$campaigns` 傳給其他型別或 helper、重綁 projected reference 都算違規；Root 的 `orders.$campaigns.withLock`、容器 `init` 建立引用與 `SharedReader($campaigns)` 轉換不算違規；`CampaignFeature` 自己的 `$campaigns` 寫入不受影響。另加整合測試：Root 更新開團後，已開啟的篩選 sheet 與 iPad 選擇器讀到新值 (防止誤用 `SharedReader(value:)` 形成快照)。

替代方案一：容器 `campaigns` 改成轉存到清單的 computed property。否決：`OrdersFeature` 會到 362 行，超過 359 行例外上限；清單持有可寫副本，誤寫只能靠額外守門發現。替代方案二：維持 359 行並另刪 3 行。否決：要動無關程式碼。使用者 2026-10-17 同意本方案。

### 清單的 sheet 呈現併成單一 destination

依 `.claude/rules/ios-navigation.md`，`OrderListFeature.State` 以 `@Presents var destination: Destination.State?` 取代 `filterSheet` 與兩個 Bool；`@Reducer enum Destination` 放 `OrderListFeature+Destination.swift`，case 為 `filterSheet(OrderFilterFeature)` 與 `categoryPicker(OrderCategoryPickerFeature)` (後者在 iPad 選擇器 task 加入)。付款方式改 Menu 後不再有 picker sheet，`isPaymentMethodPickerPresented` 隨付款方式 task 移除。`OrdersCompactView`／`OrdersView` 以 `$listStore.scope(state: \.$destination, action: \.destination)` 的各 case 掛 `.sheet(item:)`。子層的捨棄確認仍由各自的 Feature 持有。

`body` 以 `.ifLet(\.$destination, action: \.destination)` 組合 `Destination` reducer，取代現行 `.ifLet(\.$filterSheet, action: \.filterSheet)`。destination 委派的處理 (套用、取消) 與「已套用篩選同步給已開啟子層」收在無 case 的 `OrderListDestinationOperations` (只放 `static func`，不讀依賴)，`OrderListFeature.core` 的 `.destination` 分支只呼叫它並回傳結果，`core` 的 switch 仍依 Action 宣告順序留在主檔。已套用篩選有兩條變更路徑都要同步：經 action (`core` 的 `defer`，現行寫法) 與經 State 方法 (`OrdersFilterOperations.applyNavigation`，Root 深連結直接呼叫)；兩處都改呼叫同一個同步函式。測試修改 enum case 內欄位時依 `ios-unit-tests.md` 用 `destination?.modify(\.filterSheet) { … }`。

過渡期例外：1.4 到 4.1 之間，iPad 的類別與付款方式 picker 仍是 Bool 呈現，與 destination 並存；付款方式 Bool 在 2.2 移除、類別 Bool 在 4.1 移除，4.1 完成後清單只剩單一 destination。過渡期間不把「單一 destination」當作該步的驗收條件。

### 日期脈絡在開啟與刷新時同步給選擇器

- 開啟：清單 reducer 在處理開篩選 sheet 或 iPad 類別選擇器的 action 前，若 `dateContext` 為 `nil`，先以注入的 `date.now` 與 `calendar` 建立並寫回清單，再交給互動輔助型別建立子 State；子 State 的 `init` 接收非 Optional 的 `OrderDateContext`。純輔助型別不讀時間。
- 刷新：清單新增 `mutating func refreshDateContext(_ context: OrderDateContext)`，更新自己的 `dateContext`，並把同一個值寫進已開啟的 destination 子 State；容器 `OrdersFeature.State.refreshDateContext(now:calendar:)` 改呼叫它 (容器行數不變)。
- 分組的預設展開只在開啟時計算；開啟後日期或開團變更只影響分組歸屬與顯示，不重設使用者已操作的展開狀態。

### 類別分組與展開由純計算輔助型別產生

新增 `Features/Orders/OrderCategoryGroups.swift`：無 case 的 `enum OrderCategoryGroups`，只放 `static func`，不宣告 `@Dependency`、不讀現在時間；相關值型別寫成巢狀型別 (`OrderCategoryGroups.Kind { ongoing, closed }`、`Group`、`Expansion`、`Display`)，符合一檔一個頂層型別。

- `groups(categories:orders:campaigns:context:) -> [Group]`：先把開團經 `evaluatingAutoClose(asOf:calendar:)` 後 `status == .ongoing` 的名稱放進集合，再掃訂單一次，訂單的 `campaignNames` 與該集合有交集就把它的類別放進「進行中類別」集合，最後把已排序的類別分成兩組。原本就是 `.closed` 的開團不會因時間變成進行中；找不到名稱的開團視為非進行中。
- `isSearching(_ text:) -> Bool`：去掉空白與換行後非空才算搜尋；兩個宿主與 `displayGroups` 共用這個判斷。
- `initialExpansion(groups:selected:) -> Expansion`：開團中展開；已收單在「有選中類別屬於已收單」或「開團中為空」時展開。
- `displayGroups(groups:expansion:selected:searchText:) -> [Display]`：搜尋時只留名稱包含去空白後文字的類別 (沿用 `localizedStandardContains`)、不回傳沒有結果的組、搜尋中一律展開；收合的組可見類別為空陣列；顯示數為該組符合的類別數，已選數計算整組 (含搜尋隱藏的)。
- `toggled(_:in:) -> Set<String>`：切換單一類別的成員資格。
- 組標題在搜尋中被點時，兩個宿主的 reducer 都不改變儲存的 `Expansion`。

### 分組計算每次重繪只算一次並交給各區段

分組結果由宿主 State 的 computed property 提供 (iPhone `filterSheetCategoryGroups`、iPad 選擇器對應屬性)，畫面在 sheet 的 body 內讀一次，再把值傳給各區段 View，避免一次重繪重算多次。單次計算量：可用類別合併 O(訂單的類別引用總數＋主檔類別數)、排序 O(K log K)、開團評估 O(開團數)、分組 O(訂單的開團引用總數＋K)、搜尋與已選數 O(K)；排序不是線性，文件與規格不再把整條路徑稱為線性。

`OrdersFeaturePerformanceTests` 量兩種規模，記錄兩者耗時：小規模 1,000 筆訂單、50 個類別、20 個開團；大規模 10,000 筆訂單、500 個類別、200 個開團，訂單各含 1 到 3 個類別與 0 到 2 個開團 (皆為測試夾具規模，不是實際資料量估計)。門檻依 `ios-unit-tests.md` 取大規模實測正常耗時約 6 倍。大規模超出門檻時，改為「State 存分組快照，在訂單、主檔、開團或日期脈絡變更時重算」並先回報使用者，不放寬門檻、不使用永久快照。

替代方案：sheet 開啟時就把分組存進 State。否決：訂單或開團在 sheet 開著時載入完成，快照會缺類別；要自行處理失效規則才划算，目前以效能測試確認不需要。

### 兩平台共用的分組格子 View 以值與 closure 溝通

新增 `Features/Orders/Components/OrderCategoryGrid.swift`：不綁 store，以 closure 回報「點了某個類別」與「點了某組標題」；不自帶 `ScrollView` 或 `List`，產出的是放進宿主 `List` 的內容：

- 每組一個 `Section`，組標題是 section header 內的 `Button` (以 `accessibilityValue` 表達已展開／已收合，顯示「組名 (數量)」與「已選 N」)。
- section 內是 `ForEach(rows)`，`rows` 由可見類別依欄數切段而成，每段一個 `List` 列；列的識別值為「組種類＋段序號」，欄數改變時列身分不變、只換內容，不在 body 內產生 UUID。直接產生 `List` 列的 `ForEach` 每個元素固定是一個列 (單一 `GridRow` 的 `Grid`)，該層不寫 `if` 或 `AnyView`；收合、搜尋隱藏、空組都由 `displayGroups` 的資料決定。列容器內部的條件 (選中勾號、實格與佔位格) 不影響列數，允許使用。
- 每格是 `Button`，`.buttonStyle(.plain)`，讓同一列的多個按鈕各自獨立點選 (`List` 列內放多個預設樣式按鈕時整列會一起反應)；格子 `.frame(maxWidth: .infinity, maxHeight: .infinity)`、文字不截斷、命中區至少 `BLHitTarget.minimum`；選中格在文字左側同一列加 `checkmark` (垂直置中，`.accessibilityHidden(true)`) 與 `.accessibilityAddTraits(.isSelected)` (`AccessibilityConventionScanTests` 以正規表達式比對 `accessibilityAddTraits(… isSelected`，不可改用其他封裝)。
- 未滿一列補透明佔位格 (`.gridCellUnsizedAxes(.vertical)`、`.accessibilityHidden(true)`)。
- 列與列之間 `.listRowSeparator(.hidden)`，列距以列內距控制。
- 「全部」列、搜尋框、空狀態列不在此 View 內，由 `OrderCategoryFilterRows` 提供，兩個宿主擺在 `ForEach` 之外 (見「verify／review 後的整併」)。

依據：Apple 文件 `Grid`「the tallest cell in a row sets the height of the entire row」；`gridCellUnsizedAxes(_:)` 避免可伸縮 view 決定列或欄尺寸；WWDC23「Demystify SwiftUI performance」：`List` 「Rows are created on-demand」，但 `ForEach` 內容含條件或 `AnyView` 時「All rows must be created」，並建議用 `Section` 組織巢狀 `ForEach`。

實測 (2026-10-17，iPhone 17 模擬器，寬 393pt，暫時性實驗測試，量完已刪)：

| 項目 | 結果 |
| --- | --- |
| `List` 放 300 列 | 只建立 12 列 |
| `ScrollView`＋`VStack` 放 300 列 | 建立 300 列 |
| `ScrollView`＋`LazyVStack` 放 300 列 | 建立 18 列 |
| `List` 兩個 section、每列一個單列 `Grid`，共 103 列、309 格 | 建立 33 格 (約 11 列) |
| 同列「書籍／aespa Lemonade QQ 音樂限定禮包／保健」 | 三格高度皆 106.3pt，短名稱列 40.3pt |
| 1 格＋2 個佔位格、2 格＋1 個佔位格 | 格寬 104.3pt，與滿列相同 |
| 1 格不補佔位格 | 格寬 329.0pt，撐滿整列 |

實驗量的是列被繪製的次數，量不到 `List` 為了收集識別值而建立列的那一步，所以「`ForEach` 內容含條件會先建立全部列」以官方說明為準；佔位格加不加 `.gridCellUnsizedAxes(.vertical)` 在此實驗結果相同，保留作為保險。實驗沒有驗證點擊，同列各格獨立點選由 UI 測試守。

### 格子欄數依實際寬度與字級計算

本決策取代本 change 先前的「格子欄數由宿主決定」(三方審查指出規格寫「依可用寬度」而 design 固定欄數，且 iPad 分割畫面寬度會變)。`OrderCategoryGrid` 以 `@ScaledMetric` 的最小格寬 (基準 96pt) 與 `BLSpacing.small` 間距，依實際可用寬度計算欄數：`static func columnCount(width:minimumCellWidth:spacing:isAccessibilitySize:) -> Int`，結果為 `max(1, floor((width + spacing) / (minimumCellWidth + spacing)))`，無障礙字級固定 1。寬度以 `onGeometryChange` 量測格子列容器的寬度 (列容器填滿列寬，寬度不受欄數影響)，存在 `OrderCategoryGrid` 自己的 `@State` (版面量測值；它是不綁 store、以 closure 溝通的元件，依規則可持有元件內部狀態)。量到之前的欄數：無障礙字級直接 1 欄；其餘用宿主傳入的初始欄數 (iPhone sheet 3、iPad 選擇器 4)，量到後若結果不同才重新切段。以 iPhone 17 實測的內容寬 329pt 計算為 3 欄；iPad form sheet 內容寬約 476pt 為估計值，預設字級下算得 4 欄，實際以 iPad 模擬器量到的寬度依公式判斷 (例如同為 476pt、縮放後最小格寬 128pt 時應為 3 欄)。

替代方案：宿主固定欄數 (iPhone 3、iPad 4)。否決：iPad 分割畫面或台前調度的窄視窗會擠壓格子，且與規格不符。

### iPhone 篩選 sheet 先擴充再遷移

分兩個 task，每個結束都能建置：

1. 擴充：`OrderFilterFeature.State` 新增開團 `SharedReader`、`dateContext`、`categoryGroupExpansion`、`isSearchFieldFocused` 與 `filterSheetCategoryGroups`；新增 action `filterPendingCategoryToggled(String)`、`filterPendingCategoriesCleared`、`filterCategoryGroupToggled(OrderCategoryGroups.Kind)`、`filterClearTapped`、`filterSearchSubmitted`、`filterSearchClearTapped`。舊的 `filterPendingCategorySelected`、`filterSheetFilteredCategories`、`filterSheetFilteredPaymentMethods` 暫時保留，畫面不變。
2. 遷移並收尾：畫面改版後刪除上述舊介面、`OrdersListQuery.filteredPaymentMethods(state:)`，以及只測舊介面的測試段落 (`OrderListFeatureTests+FilterPending`、`OrdersFilterOperationsTests+FilterSheet`、`OrderFilterFeatureTests+Queries` 中對應者)。

`filterClearTapped` 把暫存設回 `OrderFilterSelection()`、不送 delegate；停用條件為 `!pendingFilterSelection.isActive`。日期與付款方式兩列 `Menu` 內放 inline `Picker` (選項為帶 tag 的 `Text`，identifier 掛在各選項)。搜尋框是「商品類別」標題下獨立 section 的一般列 (固定 `.id`、列內距歸零、44pt 膠囊底色、隱藏分隔線)，「全部」列與空狀態列放在下一個 section；不放 section header，因為輸入使結果改變時 header 會重建、輸入框失焦 (5.1 實測，規則見 `.claude/rules/ios-navigation.md`)。`TextField` 綁 `filterSheetSearchText`，焦點以 State 的 `isSearchFieldFocused` 搭配 View 的 `@FocusState` 鏡像 (`.bind`)；`onSubmit` 送 `filterSearchSubmitted` 清焦點；有字時顯示清除鈕送 `filterSearchClearTapped`；宿主 `List` 加 `.scrollDismissesKeyboard(.interactively)`。焦點、搜尋與展開都是呈現狀態，不進 dirty 比較 (dirty 仍是 `pendingFilterSelection != committedFilterSelection`)。

### iPad 類別選擇器是 destination 的一個 case

新增 `OrderCategoryPickerFeature` 與畫面 `OrderCategoryPickerSheet`，作為 `OrderListFeature.Destination.categoryPicker`。State：`@SharedReader` 的訂單、主檔、開團，`dateContext`、`committedCategories`、`pendingCategories`、`searchText`、`isSearchFieldFocused`、`groupExpansion`、`@Presents discardConfirmation`；`hasUnappliedChanges` 為 `pendingCategories != committedCategories`。View action：`categoryToggled(String)`、`allTapped`、`groupToggled(OrderCategoryGroups.Kind)`、`searchSubmitted`、`searchClearTapped`、`doneTapped`、`cancelTapped`；Delegate：`applied(Set<String>)`、`cancelled`。捨棄確認與篩選 sheet 由同一個工廠函式產生 (見「verify／review 後的整併」)。畫面以 `OrderCategoryGrid` (初始欄數 4，量到寬度後依公式)、`.interactiveDismissDisabled(hasUnappliedChanges)`、取消 `xmark`、完成 `common.action.button.done`，搜尋框的焦點、清除與收鍵盤同 iPhone。

`categoryPickerTapped` 建立 `.categoryPicker` 狀態；`applied` 寫入 `selectedCategories`，有變更時重選第一筆並送 `delegate(.selectionChanged)`；`cancelled` 關閉；`OrderListDestinationOperations` 的同步函式擴充為也把 `committedCategories` 同步給已開啟的 `.categoryPicker`。類別觸發鈕 (`OrdersRegularListColumn.categoryFilterTrigger`) 新增 identifier，`OrdersScreen` 改以它開啟選擇器。刪除 `isCategoryPickerPresented`、`View.categoryFilterSelected`、`OrdersFilterOperations.categoryFilterSelected`、`OrdersView.categoryPickerSheet`，以及 `OrdersFeatureTests.FilterPicker` 參數化測試中屬於類別 picker 的部分。

替代方案：選擇器狀態放進 `OrderListFeature` 本體。否決：清單會超過 300 行，且與 iPhone 的 `OrderFilterFeature` 結構不對稱。

### iPad 付款方式改 Menu 並抽出 chip 標籤

`BLFilterChip` 是 `Button`，不能直接當 `Menu` 的標籤。把它的標籤抽成 `Shared/DesignSystem/Components/Chips/BLFilterChipLabel.swift` (外觀、字級、最小命中高度不變)，`BLFilterChip` 改用它；`OrdersRegularListColumn` 的付款方式改為 `Menu`，內放 inline `Picker` (「全部」＋各付款方式，選中者的勾號由系統單選語意提供)，選取經 binding 送既有 `.view(.paymentMethodFilterSelected(_:))`。同一個 task 內移除 `isPaymentMethodPickerPresented`、`View.paymentMethodPickerTapped` 與其 `OrderListInteraction` 分支、`OrdersFilterOperations.paymentMethodPickerTapped`、`OrdersView.paymentMethodPickerSheet`，並改寫 `OrdersFeatureTests.FilterPicker` 參數化測試 (移除 `.paymentMethod` case)、`OrderListFeatureTests+FilterDelegates`、`OrderListFeatureTests+FilterSheet`、`OrdersFilterOperationsTests+FilterSheet` 中相關段落。identifier 掛在 `Menu` 本身、各選項掛在 `Picker` 內各自的 `Text`。

### 清除篩選在 iPhone 改暫存、在 iPad 立即生效

iPhone 見「iPhone 篩選 sheet 先擴充再遷移」。iPad 在 `OrderListFeature.View` 新增 `clearFiltersTapped`，由 `OrderListInteraction` 呼叫新的 `OrdersFilterOperations.clearFilters(state:)`：日期 `.all`、付款方式 `nil`、類別空集合，有變更時 `selectFirstFilteredOrder()` 一次並沿用 `selectionChanged` 回報。停用條件為 `!committedFilterSelection.isActive`。按鈕放在付款方式與類別觸發鈕下方。

### 清單重繪只篩選一次

新增 `OrderListSnapshot` (`orders`、`ids`、`isAllSelected`，獨立檔 `OrderListSnapshot.swift`) 與 `OrderListFeature.State.listSnapshot()` (一行轉呼叫 `OrdersListQuery.listSnapshot(state:)`，計算放在 `OrdersListQuery`)，內部只呼叫一次 `OrdersListQuery.filteredOrders(state:)`；日期分組改為接收已篩選訂單的 `OrdersListQuery.dateSections(orders:context:locale:)`；`OrdersListQuery.isAllFilteredSelected(state:)` 改為接收已篩選識別值。`OrdersCompactView.navigationContent` 與 `OrdersView.regularSplitContent` 各取一次 snapshot 再交給清單與 `OrdersToolbarContent`；移除 `filteredIDs`、`isAllFilteredSelected`、`dateSections(locale:)`，並遷移使用它們的 `OrderListFeatureTests+Presentation`、`OrderListFeatureTests+Dates`。`filteredOrders` 保留給 reducer、`OrdersBatchOperations` 與 AI 摘要。

### verify／review 後的整併

`/spectra-verify` 與 `/spectra-review` (2026-10-19) 指出：iPhone 篩選 sheet 與 iPad 類別選擇器有三處重複 (分組組裝、捨棄確認、類別區固定列)，iPad 清單欄每次重繪多掃一次訂單，`OrderFormatters.campaignsDisplayText(_:)` 留下回傳本地化 key 字串的分支。使用者 2026-10-19 裁定在本 change 內處理：

- 分組入口：`OrderCategoryGroups` 新增 `groups(orders:campaigns:catalog:context:)`，以 `OrdersListQuery.availableCategories(orders:catalog:)` 合併可用類別後呼叫既有 `groups(categories:orders:campaigns:context:)`。`OrderFilterFeature.State` 與 `OrderCategoryPickerFeature.State` 刪除各自的 `makeCategoryGroups`，`init` 的初始展開與顯示分組的 computed property 都改用這個入口，computed property 名稱 (`filterSheetCategoryGroups`、`categoryGroups`) 不變。仍是純計算、不讀依賴。
- 捨棄確認：新增 `Features/Orders/OrderFilterConfirmations.swift` (無 case 的 `enum`)，`static func discardChanges<Action>(discard: Action) -> AlertState<Action>` 產生共用的捨棄確認 (標題與破壞性按鈕 `orders.list.label.discardChanges`、取消 `orders.list.label.keepEditing`、訊息 `orders.list.message.filtersHaveApplied`)；`OrdersFilterOperations.filterCancelTapped(state:)` 與 `OrderCategoryPickerFeature` 處理 `cancelTapped` 的分支都改呼叫它。
- iPad 清單欄：`OrdersRegularListColumn.listHeader` 每次重繪只取一次付款方式名稱，存成區域常數，供「是否顯示 Menu」與 Menu 內容共用 (Menu 內容改由參數傳入)；類別觸發鈕的顯示判斷改用不排序的條件，結果與 `availableCategories(...)` 是否為空一致 (主檔類別非空，或任一訂單含去空白後非空的類別)。
- `OrderFormatters.campaignsDisplayText(_:)`：刪除空陣列時回傳 `"orders.detail.label.unassigned"` 字串的分支，只負責以「、」串接名稱，doc 寫明呼叫端要先處理空陣列。「未歸團」文案只由 `OrderEditFeature.State.campaignsDisplayText` 以 `LocalizedStringResource` 提供 (Codex 在 5.3 選擇的方案 1，不變)。
- 類別區固定列：新增 `Features/Orders/Components/OrderCategoryFilterRows.swift`，不綁 store，提供搜尋列 (含清除搜尋鈕與固定 `.id`、列內距、膠囊底色、隱藏分隔線等列設定，列設定放最外層)、「全部」列與空狀態列；以搜尋文字 `Binding<String>`、焦點 `Binding<Bool>`、是否全選、各按鈕 closure 與各列 identifier 溝通。元件持有 `@FocusState` 並在搜尋框上與焦點 binding 同步，兩個宿主不再各自 `.bind` (目前 iPhone 掛在 Section、iPad 掛在 List)。section 與 header 仍由宿主決定 (iPhone 有「商品類別」標題，iPad 沒有)。畫面輸出不變，既有 snapshot 基準圖不重錄。
- 測試補強：寬版 snapshot 覆蓋 iPad 無付款方式且無類別時兩個觸發鈕都不顯示；snapshot 覆蓋 iPhone 篩選 sheet 與 iPad 類別選擇器在搜尋無結果時只剩「全部」列與空狀態列。這些基準圖先於上兩項重構錄製，讓重構有畫面基準可守。

範圍外：分組規則、文案、identifier 與畫面外觀不變；不新增 UI 測試類別。

### 第二輪 verify／review 修正

第二輪 `/spectra-verify` 與 `/spectra-review` (2026-10-19) 沒有 Critical 或 Warning，使用者 2026-10-19 裁定在本 change 內處理其中三項建議：

- 移除沒有呼叫端的文案：`orders.list.label.matchingPaymentMethods` 與 `orders.filter.message.tryAnother` 的最後呼叫端 (iPad 付款方式選擇 sheet 與舊版付款方式區段的空狀態) 已由本 change 刪除，依「文案、identifier 與摘要格式」對 `orders.filter.placeholder.searchCategoriesPayment` 的同一規則從 `Localizable.xcstrings` 移除。以文字方式刪除展開格式的 entry，不整檔重寫。
- iPad 付款方式 `Menu` 補回「已選取」無障礙特徵：`OrdersRegularListColumn.paymentMethodFilterTrigger(names:)` 依 `store.hasPaymentMethodFilter` 加 `.accessibilityAddTraits(.isSelected)`，與同檔類別觸發鈕一致；改 `Menu` 前的 `BLFilterChip` 觸發鈕原本就有這個特徵，VoiceOver 套用付款方式後會唸「已選取」。
- 類別分組只排序一次：`OrdersListQuery` 新增 `mergedCategories(orders:catalog:) -> Set<String>` (主檔類別原樣、訂單類別去前後空白並略過空字串)；`availableCategories(orders:catalog:)` 改為對它排序，`OrderCategoryGroups.groups(orders:campaigns:catalog:context:)` 改傳未排序的集合，語系排序只在 `groups(categories:orders:campaigns:context:)` 內做一次。`OrderListFeature.swift` 已在 300 行上限，這項不改它。

範圍外：iPad 類別選擇器下滑測試補強與 `OrderListFeature.swift` 拆分 (使用者未選)；分組結果、文案顯示、identifier 與畫面外觀不變。

### 文案、identifier 與摘要格式

- iPhone 觸發鈕摘要：類別一項顯示名稱，兩項以上用 `orders.filter.label.categoryCount` (`%lld 項類別`，en 走 plural)。
- iPad 類別觸發鈕：一項沿用 `orders.filter.label.categoryFormat`，兩項以上用 `orders.filter.label.categoryCountFormat` (`類別：%lld 項`)。
- 新增 key (都補 en)：`orders.filter.label.conditions`、`orders.filter.button.clearFilters`、`orders.filter.placeholder.searchCategories`、`orders.filter.button.clearSearch`、`orders.filter.label.groupHeader` (`%1$@ (%2$lld)`)、`orders.filter.label.selectedCount` (`已選 %lld`)、`orders.filter.label.groupExpanded` (已展開)、`orders.filter.label.groupCollapsed` (已收合)。組名沿用 `common.general.label.active`、`common.general.label.closed`；`orders.filter.placeholder.searchCategoriesPayment`、`orders.list.label.matchingPaymentMethods`、`orders.filter.message.tryAnother` 沒有呼叫端後移除。
- identifier 加在 `apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift`：清除篩選 (sheet 與 iPad 各一)、日期 Menu、付款方式 Menu (sheet 與 iPad) 與各選項、搜尋框與清除搜尋 (sheet 與 iPad)、組標題 (依組種類)、類別格 (依名稱，以現有 `option(_:key:)` 編碼)、iPad 選擇器的 sheet、完成與取消；這個檔依 task 依賴串成單線修改。
- AI 摘要：`summaryPrompt(orders:selectedCategories:)`，有選取時 `(已篩選類別：A、B)`，名稱排序後以「、」串接。

### 行數控制

- `OrderListFeature.swift` (現 298)：先做 R6 (移除三個 computed 與一個方法) 再做開團投影；`Destination` 型別放 `OrderListFeature+Destination.swift`；destination 委派處理放 `OrderListDestinationOperations`；付款方式 task 移除兩個 Bool 與一個 action。每個改到它的 task 結束時量 LEN，超過 300 即停下回報。
- `OrdersFeature.swift` (現 356)：開團投影 task 以外不新增行；`refreshDateContext` 改呼叫清單方法不增行。超過 359 即停下回報，不調上限。
- 其他新增或改到的 Feature 與 View 以 300 為上限，超過時依 `apps/ios/CLAUDE.md` 的拆分順序處理。

## Implementation Contract

**行為**：

- iPhone 篩選 sheet 依 spec `order-filter-sheet` 的 MODIFIED 與 ADDED 需求；iPad 依 `order-category-filter` 的 trigger／picker 需求與 `order-filter-sheet` 的 payment menu、clear filters 需求。
- 分組與格子依 `order-category-filter` 兩個 ADDED 需求；dirty 依 `sheet-dismissal-safeguard`；清單結果、深連結、跨功能導覽依 `order-category-filter` 的 MODIFIED 需求；AI 摘要依 `ai-order-summary`；`isActive` 真值表依 `condition-readability`。

**介面與資料形狀**：

- `OrderFilterSelection { datePeriod; categories: Set<String>; paymentMethod: String? }`。
- `OrderListFeature.State`：`selectedCategories: Set<String>`、`@SharedReader var campaigns`、`@Presents var destination: Destination.State?`、`listSnapshot() -> OrderListSnapshot`、`refreshDateContext(_:)`；移除 `selectedCategory`、`filterSheet`、`isCategoryPickerPresented`、`isPaymentMethodPickerPresented`、`filteredIDs`、`isAllFilteredSelected`、`dateSections(locale:)`。
- `OrderListFeature.Action`：`destination(PresentationAction<Destination.Action>)` 取代 `filterSheet(...)`；`View` 新增 `clearFiltersTapped`，移除 `paymentMethodPickerTapped`、`categoryFilterSelected(String?)`。
- `OrdersQuery.filteredOrders(...selectedCategories:...)`、`OrderSummaryPrompt.summaryPrompt(orders:selectedCategories:)`。
- `OrdersFeature.State.campaigns` 為無鍵 `@Shared`；Root 以 `$campaigns.withLock` 寫入。
- 新型別：`OrderCategoryGroups` (含巢狀 `Kind`、`Group`、`Expansion`、`Display`)、`OrderCategoryGrid`、`OrderCategoryPickerFeature`、`OrderCategoryPickerSheet`、`OrderListFeature.Destination`、`OrderListDestinationOperations`、`OrderListSnapshot`、`BLFilterChipLabel`、`OrderFilterConfirmations`、`OrderCategoryFilterRows`；`OrderCategoryGroups.groups(orders:campaigns:catalog:context:)` 為兩個 State 共用的分組入口。`OrdersListQuery.mergedCategories(orders:catalog:)` 回傳未排序的可用類別集合，供 `availableCategories(orders:catalog:)` 與分組入口共用。

**失敗模式**：本 change 沒有 I/O。無類別時 iPad 類別觸發鈕隱藏；已選類別在資料中消失時選取保留 (清單維持依它篩選)，由「清除篩選」還原，不自動清除 (與現行單選行為相同)；iPhone sheet 類別區段只剩「全部」列與空狀態；無付款方式時 iPad 付款方式 Menu 隱藏；名稱比對不到任何開團時視為非進行中；`dateContext` 為 `nil` 時開啟前由 reducer 補上。

**驗收**：

- 每個 task 結束：能建置、完整單元測試全綠、改到的 Feature 量 LEN 未超過上限。
- UI 測試 (使用者 2026-10-18 裁決)：中途只在改到畫面程式或 accessibility identifier 的 task 跑，只跑受影響平台的受影響類別：訂單區 9 個類別、`CustomersTests/testTapCustomerDeepLinksToOrders`、冒煙的 `LaunchSmokeTests` 與 `OrientationLayoutTests`，以及本 change 已新增的 UI 測試類別；完整 UI 主回歸 (iPhone 與 iPad) 只在 5.3 跑一次。`BLFilterChip` 只用在訂單畫面，抽出 `BLFilterChipLabel` 不另跑完整回歸。各 task 的平台分配見 tasks.md 開頭註解。
- 單元測試 (固定 `TestDependencies.fixedNow` 與 UTC gregorian calendar)：`OrderCategoryGroups` 依 spec 範例表逐列並含空白搜尋、搜尋中標題不改展開、已選數含隱藏、原本 closed 的開團、少量邊界 (0、1 個類別、只有開團中、只有已收單)；`columnCount` 範例 (寬 256／329／476pt 與無障礙字級)；切段與佔位 (1、2、3、4 個類別)；`OrdersQuery` 範例表；`OrderFilterFeature` 與 `OrderCategoryPickerFeature` 的 toggle、全部、清除、套用 (含付款方式)、取消、dirty、搜尋焦點與清除；destination 互斥與日期脈絡同步；`ProjectionWriteBoundaryTests` 正反片段；Root 深連結；`OrderSummaryPrompt`；`isActive` 真值表。
- 新邏輯的測試都留下 RED 與一次變異紀錄；R6 以「把 ids 改回從 `filteredOrders` 重算」的變異確認驗證方式抓得到。
- 效能：`OrdersFeaturePerformanceTests` 兩種規模，以 `-only-testing:BuyLedgerTests/OrdersFeaturePerformanceTests` 單獨執行並確認執行數大於 0。
- Snapshot：重錄 `orderFilterSheet_已選日期類別付款方式_符合基準圖`，新增分組格子 (長名稱同列等高、1 個類別、欄數減一、無障礙單欄) 基準圖。
- UI 測試 (兩個種子情境：一般與大量 300 個類別、30 種付款方式)：iPhone 與 iPad 主流程、同列兩格獨立點選、有變更時下滑不關閉且值保留、無變更與回到原狀時下滑可關閉、捨棄確認的「繼續編輯」、搜尋與清除搜尋、清除篩選；筆數斷言以篩選結果的確定值為準，不以畫面可見列數代表全部結果。
- `mobilebuildmcp ui-automation` 在 iPhone 與 iPad 各以兩個種子實測主流程；大量種子下確認 iPad 付款方式 Menu 能捲到第 30 項；記錄 iPhone 與 iPad 量到的格子寬度、縮放後最小格寬、間距與實際欄數，依公式判斷，不要求固定欄數。
- 完成前跑獨立 coding-style 閘門逐檔審查 (含「直接產生 `List` 列的 `ForEach` 每元素固定一列」；列容器內的條件不算違規)。
- verify／review 後的整併：新基準圖 (iPad 觸發鈕隱藏、兩個畫面的搜尋無結果) 先錄製並做變異；重構後既有與新增的 snapshot 都不需重錄；完成時再跑完整單元、兩平台完整 UI 主回歸與 style 閘門，並以 `mobilebuildmcp ui-automation` 確認長名稱類別選取後加上勾號是否換行、使該列高度跳動。
- 第二輪 verify／review 修正：文案移除以 Swift 零引用與 `LocalizationCatalogTests` 確認；付款方式 `Menu` 的已選取特徵以 `OrderPaymentMethodMenuTests` 斷言並以變異確認；排序一次以餵未排序輸入的分組測試與拿掉內層排序的變異確認，`OrdersFeaturePerformanceTests` 重跑；完成時再跑完整單元、兩平台完整 UI 主回歸與 style 閘門。

**範圍內**：上述 iOS 程式、測試、字串、identifier、`apps/ios/CLAUDE.md` 與 `.claude/rules/` 中開團投影與清單呈現的描述、六份 delta spec。

**範圍外**：Non-Goals 所列；`OptionPickerSheet`；其他分頁的篩選；`f03a82c` 同型誤換的單元測試資料。

## Risks / Trade-offs

- [`OrderListFeature` 只剩 2 行餘裕] → 任務順序先 R6 再加投影、Destination 與委派處理移出主檔；每個 task 量 LEN，超過即停下回報。
- [`OrdersFeature` 只剩 3 行餘裕] → 只有開團投影 task 動它，估計增加 1 到 3 行 (見「開團投影改無鍵共享引用」)，完成時立即量；359 是已裁決的上限，不為預留緩衝而拆改容器 (`apps/ios/CLAUDE.md` 限制容器主 switch 與 Root 介面外移)。
- [開團投影改 `@Shared` 牽動多個測試檔] → 以 grep `orders.campaigns` 與 `\.campaigns = ` 的全部命中檔為遷移清單 (2026-10-17 命中含 `OrderEditFeatureTests+Campaigns`、`CampaignIntegrationTests`、`CampaignIntegrationTests+Fixtures`、`CampaignIntegrationTests+Rename`、`CampaignIntegrationTests+Delete`、`RootFeatureTests+Campaigns`、`RootFeatureTests+CampaignLoading`、`RootFeatureTests+NewOrderOptions`、`ProjectionWriteBoundaryTests+Orders`)，不以本列為準。
- [`ForEach` 內容出現 `if`／`AnyView` 會讓 `List` 先建立全部列] → 收合與隱藏都在 `displayGroups` 處理；style 閘門逐檔確認。
- [`List` 列內多個按鈕同時觸發] → 格子 `.buttonStyle(.plain)`，UI 測試點同列兩格。
- [每次重繪重算分組] → body 只讀一次；兩種規模效能測試；超出門檻依「分組計算每次重繪只算一次並交給各區段」的備案處理並回報。
- [iPad form sheet 實際寬度未量] → 欄數依實測寬度以公式計算，不依賴估計值；ui-automation 記錄量到的寬度與欄數並依公式判斷。
- [UI 測試以 identifier 定位新控制項] → identifier 在各畫面 task 內加入；`BLAccessibilityID+Orders.swift` 串成單線。
- [抽出類別區固定列時改變畫面或焦點行為] → 先錄搜尋無結果的基準圖；既有 snapshot 不重錄，兩平台跑搜尋相關 UI 測試 (逐字輸入會抓到失焦)。
- [選中格勾號在文字左側，長名稱選取後會換行使列高跳動] → 6.5 實測：長名稱格選取後多換一行、列高增加 20pt (iPhone 篩選 sheet 與 iPad 類別選擇器皆然)；使用者 2026-10-19 裁定維持現狀，不預留勾號位置。

## Migration Plan

篩選狀態不持久化，沒有資料遷移；舊版 App 升級後篩選回到預設。回滾為還原本 change 的 commit。

## Open Questions

(none)
