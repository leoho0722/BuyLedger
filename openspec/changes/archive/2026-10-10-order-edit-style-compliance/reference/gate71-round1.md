# 7.1 style 閘門第一輪紀錄 (2026-10-09)

12 組唯讀審查 262 檔 (本 change 改到、新增與拆出的 Swift 檔，排除不進任何 target 的 `reference/order-edit-task-probe.swift`)。`style_checks.py` 明確清單：只有 `DashboardFeature`、`InsightsFeature` 有失敗代碼 (`D9` 6、`MK1` 2)，其餘只有不計失敗的 `WSIG`／`WSTR`／`WCL`。行號為第一輪當下的位置，修正時以符號名稱為準。

## 使用者裁決

1. 改到的檔一律整檔對齊，不因只改一行而延後：`DashboardFeature`、`InsightsFeature`、`DashboardOngoingCampaignsSection` 在本 change 完成。
2. 畫面內的資料處理與組字全部移出，分兩層：資料處理進 State computed 或純計算型別；格式化進格式化型別或由 State 給本地化值；畫面只留版面與綁定接線。輸出逐字相同、snapshot 不重錄。
3. 測試預期值不可由受測程式產生 (2026-10-09 細化)：禁止用 production 函式算預期、把 Given 或 When 執行後從 store 讀出的值當預期、`sampleOrders` 經 production 處理後當預期；變動部分寫字面值 (`TestStore` 的 `$0.欄位 = 字面值`、以 Given 自建輸入為底只改字面值欄位)，不把整筆資料展開成全欄位字面值；狀態不變時比對 Given 輸入或 `send` 不帶 closure；比對用資料的 `id` 在 Given 固定。能直接設進初始 State 的 Given 不用 `send`；一個測試多組 When／Then 拆開或參數化；`store.finish()`、`clock.advance`、`continuation.finish()`／`yield` 屬等待 effect，留在 Then。
4. Bool 命名 (is／has／can／should) 套用到屬性、區域變數、函式與測試參數 (`expected: Bool` 改描述事實的名稱)；回傳 Bool 的方法允許動詞式 (`contains`、`matches`、`requires`、`wait…`)。
5. 只含 `@Test` 的 test extension 不設 MARK；helper、fixture、nested type 所在的 extension 照區名設。
6. 註解的反引號只標程式碼識別字 (型別、成員、關鍵字如 `inout`／`mutating`／`nil`、檔名)；sheet、alert、reducer、store、iPad、AI、UTC 等一般概念詞不加。

## 主對話判定

- **直接修** (規則明確)：
    - 巢狀呼叫由外而內斷行：外層超過 100 或內層超過三個引數時外層先斷，內層放得進一行就維持一行；不寫 `))` 收尾 (`formatting.md`「參數與引數對齊」)。
    - `#expect(x == [ … ])` 的唯一引數是運算式不是字面值，不適用 `])` 貼合例外。
    - doc：單一參數用 `- Parameter`、enum case 的關聯值補 `- Parameter`、`- Note` 放最後且一則一事、白話、識別字加反引號。
    - MARK 段名 `Reducer Body` 改 `Body`；modifier 四組順序；store 文件措辭統一為「畫面的狀態與事件來源，由父層建立後傳入」。
    - 單一表達式單一參數的 closure 用 `$0`；只本檔使用的成員改 `private`；三層 optional chaining 拆開；`.none` 寫 `nil`。
    - 空本體宣告 `enum X {}` 依 kit 樣板 (`RuntimeEnvironment.swift`) 改為 `{`、空行、`}`。
    - `.foregroundStyle(.tint)` 改 `BLPalette.accent` (App 不設全域 tint，兩者都是 `systemBlue`)。
    - TCA：內部回應命名 `<名詞>Response(Result<…, any Error>)`、`core` 的 case 超過十行抽 Private Method、switch 次序與 Action 宣告一致 (`tca-architecture.md`)；Action 用事件式命名。
    - 測試的 static stored property 放在型別本體的 Properties，不放 extension。
- **不算違規**：git mv 改名檔保留原檔頭日期；`ForEach($…) { $item in` 的 binding 投影；enum case 的 `- Parameter` 用語意名 (同 kit 樣板)；`{ _ in … }`；會改變 memberwise init 呼叫端的 Properties 跨組順序維持原狀 (不影響 init 的 `@ScaledMetric` 等照改)；`.frame(maxWidth:)` 不改 `@ScaledMetric` (不改畫面)；AI 提示字串不適用中英空格規則；測試 `let` 鏈的 `.environment` 與 `.frame` 不套 body modifier 分組；`.searchable` 歸導航與呈現組。
- **延後**：`OrderListFeature` 三個 sheet 旗標併單一 destination 屬 6d；`OrderEditPickersFeature` 攤平 options 與 `@Shared(.lookupCatalog)` 可寫屬 6c。
- **疑似未用 import**：主對話以 build 判定，實作者不移除。

## 逐檔違規 (依 task 分組)

### 7.4 首頁、分析頁與其他非訂單 production 檔

- `DashboardFeature`：MARK `Reducer Body`；`delegate(Delegate)`、`campaignTapped(String)` 缺 `- Parameter`；body 內 `Reduce { }` 改 `Reduce(core)`；`task`、`retryTapped` 收進 `view(View)`。
- `InsightsFeature`：同上 (另 `binding`、`categoryTapped` 缺 `- Parameter`)。
- `DashboardOngoingCampaignsSection`：`rows` 在畫面內過濾、彙總與退回值；`.lineLimit(1)` 排在外觀組之後。
- `CampaignListFeature`：State 的 computed (`loadState`、`dateSections`、`rowSummaries`) 位於 `init` 與巢狀型別之後。

### 7.5 訂單詳情

- `OrderDetailSourceView`：`orderSource`、`categories`、`campaigns` 在畫面內 trim、filter、join 與退回值。
- `OrderDetailCostView`：`costFraction(_:)` 在畫面內算占比與夾限；`.fill` 排在 `.frame` 之前 (兩處)。
- `OrderDetailContentView`：`hasNotes` 在畫面內 trim 判空。
- `OrderDetailCardlessView`、`OrderDetailSummaryView`：畫面內拼 `"+"`／`"-"` 正負號；`OrderDetailSummaryView` 另有 `.fill` 在 `.frame` 前、註解識別字未加反引號。
- `OrderDetailView`：store 文件措辭；`let store` 排在 `let layout` 之後；註解識別字。
- 空本體 `enum X {}`：`OrderFormatters`、`OrderCostBreakdown`、`OrderStatusRules`。
- `OrderDetailFeatureTests`：`#expect(statuses == [ … ])` 等四處收尾、`$0 = [LedgerOrder.fixture( … )]` 陣列寫法、參數 `expected: Bool`。

### 7.6 訂單清單、容器與側邊欄

- `OrdersCompactView`、`OrdersView`：畫面內算 `filteredIDs` 與已全選；store 文件措辭；Bool 區域變數 `allFilteredSelected`；`OrdersView` 的 Properties (`@ScaledMetric` 應在 store 前)、`filterSummaryText` 在畫面組篩選摘要 (`OrdersCompactListContent` 也呼叫)。
- `OrdersToolbarContent`：參數 `allFilteredSelected: Bool`；store 文件措辭；註解識別字。
- `OrdersCompactListContent`、`OrderSelectableRow`、`OrderFilterSheet`、`OrderFilterCategorySection`、`OrderFilterDateSection`、`OrderFilterPaymentMethodSection`：store 文件措辭；三個篩選區段的 `.tint`；`OrderFilterSheet` 的 `.accessibilityIdentifier` 排在 `.searchable` 之後。
- `OrdersRegularListColumn`：store 文件措辭；兩個 `ForEach(…) { filter in` 與 `{ period in` 單一表達式具名。`OrdersRegularDetailColumn`：store 文件措辭。
- `OrdersFeature`：`presentNewOrder` 內 `.edit(OrderEditFeature.State(` 巢狀斷行。
- `OrdersContainerPlan`、`+Requests`：四處 `.edit(`／`.merge(`／`.aiSummary(`／`.send(.writes(` 巢狀斷行。`+Writes`：三層 optional chaining。
- `OrdersBatchOperations`、`OrdersFilterOperations`：單一參數用 `- Parameters:`；`OrdersFilterOperations` 的 `didChangeFilter`。
- `OrdersQuery`：`matchesStatus`、`matchesCategory`、`matchesPaymentMethod`。
- `OrdersCascadeOperations`：`campaignDeleted`、`campaignRenamed`、`lookupItemRenamed` 只本檔使用卻是 internal；`nil` 未加反引號。
- `OrdersLoadFeature`：`Outcome` 欄位 doc 的 `nil` 未加反引號。
- `OrderDateSection`：`.map { day in` 單一表達式具名。`OrderFilterPreviewState`：檔尾多一空行。
- `RootSidebarLayout`：`badgeAccessibilityValue(_:)` 在畫面由數量組朗讀值；`.fill` 排在 `.frame` 之前。
- 空本體 `enum X {}`：`OrdersBatchOperations`、`OrdersCascadeOperations`、`OrdersContainerPlan`、`OrdersDetailSelection`、`OrdersEditorOptions`、`OrdersFilterOperations`、`OrdersListQuery`、`OrdersMergeFlowOperations`、`OrderSummaryPrompt`、`OrdersQuery`、`OrderFilterPreviewState`、`OrderListInteraction`。

### 7.7 訂單編輯

- `OrderEditOperations`：`deleteItems` 的呼叫點隨 Action 改名。`OrderWriteOperations`：`writesPhotos` 的呼叫點隨改名。
- `OrderEditView`：`navigationTitle` 以三元運算子在畫面選標題；`percentageBinding` 放在畫面型別、由 `OrderEditPercentField` 呼叫；store 文件措辭。
- `OrderEditFeature`：`cardlessDeductionWasCapped` (Bool 命名)；`deleteItems(IndexSet)` 命令式命名。
- `OrderEditDraftOperations`：tuple 標籤 `wasCapped`；`.none` 寫成 `nil`；`reconcileCardlessDeductionCap`、`apply(_:state:)` 只本檔使用。
- `OrderDraft+WriteResult`：`writesPhotos` (Bool 命名)；doc 用 trim、clamp 等術語。
- `OrderEditOptionNormalizer`：`normalize` 無副作用，改 `normalized`。`OrderEditOptions`：六個建立後不再寫入的 `var` 改 `let`。
- `OrderEditPhotosSection`：store 文件措辭；HStack 子 View 之間缺空行；多種狀態只有一個未具名 `#Preview`。
- `OrderEditBasicSection`、`OrderEditCampaignSection`、`OrderEditCostSection`、`OrderEditFeesSection`、`OrderEditItemsSection`、`OrderEditPaymentSection`、`OrderEditPickerDestination`、`OrderEditStatusSection`：store 文件措辭；`OrderEditItemsSection` 的商品名稱與單價 TextField modifier 順序；註解識別字。
- `OrderPercentConversion`：一個 `- Note` 講兩件事。
- 空本體：`OrderEditPickerOperations`、`OrderPercentConversion`。

### 7.8 訂單合併

- `OrderMergeFeature`：`.candidatePhotosLoaded(` 巢狀斷行；Action 次序 (binding、view、delegate、alert、內部回應)；`candidatePhotosLoaded`／`candidatePhotosLoadFailed` 合為 `candidatePhotosResponse(Result<…, any Error>)`；`view(.candidateTapped)`、`candidatePhotosLoaded`、`view(.photoStepConfirmTapped)` 的 case 本體超過十行；`eligibleCandidates`、`filteredCandidates` 若畫面不用則改 `private` (測試改驗證公開行為)。
- `OrderMergeCandidateSheet`：store 文件措辭。

### 7.9 至 7.13 測試檔

- **測試寫法 (裁決 3)**：各組報告「已登記」節列出的起始快照或 fixture 預期值、Given 以 send 建前置、多組 When／Then，涵蓋 `OrdersFeatureTests+*`、`OrderListFeatureTests+*`、`OrderEditFeatureTests+*`、`OrderEditPhotosFeatureTests`、`OrderDraftTests`、`CampaignLoadFeatureTests+*`、`OrdersFilterOperationsTests+*`、`RootFeatureTests+*` 等；實作時逐檔重掃，不限於此清單。
- **Bool 參數 (裁決 4)**：`wasCapped`、`expected: Bool` (`OrderEditFeatureTests+Merge`、`+PaymentMethod` 三處、`OrderDetailFeatureTests`、`OrderStatusRulesTests`)、`includesJune`、`arrivesAfterDismiss`、`originalExists`、`editsPhotos`、`expectedIsLocked`、`wasReceived`、`startsDisplayScope`。
- **test extension MARK (裁決 5)**：刪除只含 `@Test` 的 extension 上的 `// MARK: - Internal Method` (`OrderDraftTests+Customer`、`+DefaultCurrency`、`+Photos`、`OrderWritesFeatureTests+BatchDelete`、`+Create`、`+Merge`、`+Receipt`、`+Requests`、`+Save`、`+Status`、`ProjectionWriteBoundaryTests+Orders` 等 13 處)。
- **巢狀斷行與收尾**：`OrdersFeatureTests+FailureTiming`、`+ListEntry`、`+ListRequests`、`+LoadAndSummary`、`+MergeTiming`、`+MergeWrites`、`+OptionWrites`、`+DeleteEditFailures`、`+Detail`、`+AISummaryProjection`、`OrderEditCampaignOptionsTests`、`OrderWritesFeatureTests+Merge`、`RootFeatureTests+LookupSync`、`+NewOrderOptions`、`BuyLedgerUITests` 的 `OrderCreateTests`；`OrderDateSectionTests` 兩處 `#expect(x == [`；`OrderWritesFeatureTests+Options` 陣列縮排。
- **其他**：`OrdersFeatureTests+MergeCandidates` 的 `// Then` 後接註解；`OrdersFeatureTests+FailureTiming` 的 `makeTimingDestination`、`MergePrefillFixture`、`MergeTimingFixture` 只本檔使用；`ProjectionWriteBoundaryTests+OrderWriters`、`+SharedOrders` 的 static stored property 在 extension；`OrderListFeatureTests.makeState` 的 doc 標籤順序；`OrderPercentConversionTests`、`ActionGroupingScanTests`、`ContrastComplianceTests` 型別層 `@MainActor` (以 build 判定可否移除)；`OrdersFeaturePerformanceTests` 四個單段命名與類別摘要不符；`RootFeatureTests+Cascade`、`+LoadRequests`、`ActionGroupingScanTests` 的參數化測試第一段不對應 When；`OrderWritesFeatureTests+Status` 註解與斷言不符；`BuyLedgerUITests` 的 `DashboardScreen`、`Waiting` 區內排序 (呼叫者在前)；註解識別字反引號 (`ProjectionWriteBoundaryTests*`、`OrdersLoadStateTests`、`OrderWritesFeatureTests+Cascade`)。
