## Context

訂單分頁目前由一個 `OrdersFeature` (1,405 行) 承擔清單、詳情、篩選、多選、寫入、合併、AI 摘要與七種呈現；訂單編輯 `OrderEditFeature` (1,086 行) 自行抓選項。2026-10-06／07 唯讀調查的現況 (行數為 `wc` 實測，扣除檔頭與空行)：

- **`OrdersFeature`**：State 167 行、Action 55 個平放 case 230 行、11 個依賴 24 行；`OrdersFeature+StateQuery` 221 行。
    - 7 個 `@Presents`：`editOrder`、`deletionConfirmation`、`writeFailureAlert`、`aiSummary`、`aiDisabledAlert`、`orderMerge`，以及篩選 sheet 的 `filterDiscardConfirmation`。
    - 詳情：iPhone 以 `detailPath` (`StackState<OrderDetailPath.State>`，`OrderDetailPath` 是只有 `orderID` 的空殼 Feature) 推入；iPad 以 `selectedOrderID` 在右欄顯示，兩邊各寫一套可選狀態、勾選標籤與「更多」選單。合併資格判斷在 `OrdersCompactView` 兩處與 `OrdersRegularListColumn`、`OrdersRegularDetailColumn` 各一處重複。
    - `OrderDetailView` (770 行) 無 store，成本組成在 View 內計算並回傳 `Color`。
    - 依賴 `CampaignService` 只為了已死的開團篩選、表單首幀開團清單，以及與開團端重複的結單日自動轉狀態寫入；`SettingsService` 只為了讀 AI 摘要設定 (Root 的 `preferences` 已有)。
- **Root 與 Orders 的耦合**：
    - Root 送 `.orders(.task)` (首頁、分析、客戶的 refresh delegate)、`.orders(.receiptStatusChanged)` (開團收款切換)、`.orders(.paymentMethodFlagsApplied)` (付款方式更正)。
    - `RootNavigationOperations` 直接寫 `selectedStatus`、`searchText`、`selectedDatePeriod`、`selectedCategory` 並呼叫 `selectFirstFilteredOrder`；`RootCascadeOperations` 就地改 `state.orders.orders`；Root 在處理首頁新增訂單時直接建立 `OrderEditFeature.State`。
    - Root 投影 `orders.campaigns`；Root 自己的 `.view(.task)` 不送任何載入。
- **啟動載入**：訂單由畫面 `.task` 觸發 (首頁經 Root 轉送)；開團只在 `CampaignListView` 出現時由 `CampaignListFeature` 載入並評估自動結單。所以沒進過開團分頁時，首頁開團卡與分析頁每團毛利排行是空的 (第 5 步 task 0.3 實測)。訂單頁沒有重試鈕；首頁與分析頁的重試經 delegate 由 Root 送 `.orders(.task)`。
- **時間**：`OrdersView`、`OrdersCompactView`、`OrderMergeCandidateSheet` 在畫面宣告 `@Dependency` 取現在時間 (`apps/ios/CLAUDE.md` 已登記的過渡例外)；開團以 reducer 寫入 `dateContext`，Root 在 `.appLock(.delegate(.didBecomeActive))` 與 `.significantTimeChanged` 兩處呼叫 `refreshDateContext`。
- **日標題**：`OrderFormatters.daySectionTitle` 的分組判斷用注入 calendar，格式化卻未設時區；`CampaignFormatters.sectionTitle` 的 `.yearMonth`／`.year`／`.month` 與 `OrderFormatters.fullTimestamp` 也用裝置時區。
- **訂單編輯** (6a 部分)：
    - 建立表單的入口有訂單分頁新增與編輯、合併確認、首頁新增；首頁新增只帶 id 與日期。
    - `.task` 以 7 個 `async let` 抓四種主檔、開團、幣別與照片；選項讀取失敗時靜默，照片失敗送 `photosLoadFailed` 並記錄失敗狀態。
    - 幣別清單沒有任何一層持有；新訂單幣別寫死在 `OrderDraft.init`。
    - snapshot 測試未覆寫這些 Service，表單進入視窗就觸發 `.task`；2026-10-06 整批 log 記錄 18 個 Unimplemented issue。
- **守門現況**：
    - `ActionGroupingScanTests` 的畫面清單不含任何 Orders 畫面。
    - `ProjectionWriteBoundaryTests` 的投影擁有者不含 `OrdersFeature`；它禁止擁有者主檔以外出現 `inout <Owner>.State`，且 `RootFeature.swift` 以外禁止 `$orders.withLock`。
    - `LocalizationCatalogTests+SourceGuards` 寫死 `OrdersView`、`OrdersCompactView` 路徑。
- **先例**：第 5 步開團的方案 B (`openspec/changes/archive/2026-10-04-campaigns-style-compliance/`) 把 1,350 行拆成容器 (300 行)、列表、詳情與兩個無 View 子 Feature，並把純計算外移到獨立型別。

## Goals / Non-Goals

**Goals:**

- `OrdersFeature` 拆成容器、清單、詳情、寫入四個 Feature，每個 Feature 主檔 (含本體與同檔 extension) 不含檔頭與空行不超過 300 行，State、Action、依賴與 `body` 依 `/ios-dev-kit` 留在本體。
- Root 對 Orders 只送請求 action、讀投影、呼叫容器的 State 方法；啟動時載入訂單與開團；開團的自動結單只由開團端評估與寫入一次。
- 訂單編輯選項在建立時帶入、新訂單套用預設幣別、修正表單與訂單分頁的已知缺陷。
- 日標題與完整時間依注入 calendar 的時區，格式化收在共用層。
- 受影響的 production 與測試檔整檔對齊 `/ios-dev-kit`，每檔不超過 300 行；`SnapshotTests` 整批不再有訂單編輯的 Unimplemented issue。
- 首頁與分析頁的 `DashboardFeature`、`InsightsFeature`、`DashboardOngoingCampaignsSection` 整檔對齊；本 change 改到的畫面不留資料處理與組字。

**Non-Goals:**

- 6c (Service 搬遷、訂單只讀 `lookupCatalog`、新增選項經 Root 轉主檔端、改名在同一交易更新訂單，以及 `OrderEditPickersFeature` 攤平選項)、6d (篩選 sheet 重新設計，含 `OrderListFeature` 三個 sheet 旗標併成單一 destination)、第 7 步 (`DashboardView`、`InsightsView` 的 `@Dependency` 現在時間與 `Calendar.current`，以及本 change 沒改到的首頁與分析頁畫面計算)。
- 試算頁同型的 `fetchCodes` Unimplemented、設定與匯率頁各自抓幣別、幣別清單為空時的 `CurrencyCode.defaults` 退回行為。
- 畫面外觀改變：既有 snapshot 一律不重錄 (含 iPad 雙欄與 iPhone 推入的詳情)。
- `Features/Orders/` 的資料夾重整 (第 10 步)。

## Decisions

### Orders 拆成容器、清單、詳情與寫入四個 Feature

| Feature | 職責 | 主要 State | 送給容器的 delegate |
| --- | --- | --- | --- |
| `OrdersFeature` (容器) | 唯一呈現者、轉送請求、對 Root 的介面、iPad 右欄詳情同步 | 無鍵 `@Shared` 訂單 (資料來源，容器本身不寫)、`list`、`load`、`writes`、`path` (`StackState`)、`regularDetail`、`@Presents destination`、呈現佇列、Root 投影欄位 | (對 Root) AI 設定請求 |
| `OrdersLoadFeature` (無 View) | 載入訂單與四種主檔，在 reducer 處理回應時寫入共用訂單與 `lookupCatalog`；載入狀態 | 可寫的 `@Shared` 訂單、`@Shared(.lookupCatalog)`、`isLoading`、`hasLoaded`、`errorMessage` | 載入失敗 |
| `OrderListFeature` | 篩選、搜尋、多選、篩選 sheet 與捨棄確認、iPad picker、日期分組、`dateContext`、iPad 選取 | `SharedReader` 訂單、`@Shared(.lookupCatalog)`、篩選欄位、多選、`dateContext`、`selectedOrderID` | `requested(OrderRequest)`：新增、編輯、合併、刪除、顯示詳情、批次改狀態、AI 摘要；載入需求；選取變更 |
| `OrderDetailFeature` | 詳情內容、可選狀態、可否合併、成本組成；無 effect | `orderID`、`SharedReader` 訂單 | `requested(OrderRequest)`：改狀態、編輯、合併、刪除 |
| `OrderWritesFeature` (無 View) | 訂單寫入、表單新增主檔選項、Root 的 cascade 與付款方式旗標套用；在 reducer 處理回應時寫入共用資料 | 可寫的 `@Shared` 訂單、`@Shared(.lookupCatalog)` | `failed(Failure)`、`saved`、`deleted`、`merged`、`optionAdded` 等 |

- `OrderRequest` 是清單與詳情共用的請求值 (比照 `CampaignRequest`)；容器以單一 `fulfill(_:)` 決定開表單、開確認 alert 或轉給 `writes`。`fulfill` 只回傳要做的事 (值)，由容器 `core` 套用，避免在主檔以外接收 `inout OrdersFeature.State`。
- 純計算外移到獨立型別以壓容器行數 (比照開團)：可選狀態與合併資格的單一來源、詳情內容 (成本組成改為語意色調而非 `Color`)、日期分組、篩選、AI 摘要 prompt、選項值、呈現佇列。`OrdersFilterOperations`、`OrdersBatchOperations`、`OrdersMergeFlowOperations` 改為只接收所需的值或子 State。
- **行數預算** (含 `/ios-dev-kit` 要求的文件註解；皆為估計，以下列量測點 `wc` 實測確認，超過 300 行就停下回報，不自行登記例外)：

| Feature | State | Action (含巢狀 View／Delegate) | 依賴與 body | core 與方法 | 合計 (估計) | 第一次量測 |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| 容器 | 60 | 70 | 30 | 130 | 290 | 3.2 至 4.8 每個改到容器的 task 只記錄行數與拆分進度；4.9 起為硬性上限 |
| `OrdersLoadFeature` | 25 | 30 | 15 | 70 | 140 | 3.3 結束時 |
| 清單 | 70 | 80 | 20 | 100 | 270 | 4.6 結束時 |
| 詳情 | 25 | 40 | 10 | 50 | 125 | 4.7 結束時 |
| 寫入 | 20 | 90 | 20 | 150 | 280 | 4.1 結束時，4.2、4.3 各再量一次；若超過，合併寫入與 cascade 先抽成請求計畫型別 (比照 `CampaignSavePlan`) |

    - 容器在 4.9 (清單、詳情、寫入、載入都已移出) 之前仍承擔尚未搬走的職責，量到的行數只用來追蹤進度；新的子 Feature 從第一次完成的 task 起就適用 300 行上限。
    - 校準依據：開團容器實測 300 行 (State 72、Action 58、依賴與 body 18)，`CampaignWritesFeature` 275 行。Orders 容器把載入交給 `OrdersLoadFeature`、cascade 與旗標套用交給 `writes` 之後，才可能落在 300 行內。
- 替代方案：State／Action 分檔而不拆 Feature。`@CasePathable` 明確標註後可編譯，但違反 `/ios-dev-kit`「State 與 Action 必須在本體」，不採用 (2026-10-07 Codex 審查實測三塊合計 421 行)。

### 訂單以無鍵 @Shared 共用，寫入集中在寫入 Feature

容器持有無鍵 `@Shared` 訂單，`init` 先建立區域引用再指派給子層 (比照開團)。

- **寫入者**：只有 `OrdersLoadFeature` (套用讀取結果) 與 `OrderWritesFeature` (寫入成功、cascade、付款方式旗標套用) 以 `withLock` 寫入；清單與詳情只拿 `SharedReader`，容器本身不寫。
- **寫入位置**：一律在 reducer 處理回應或請求時寫入，不在 `.run` effect 內寫，讓 Root 的 `onChange(of: \.orders.orders)` 在改動來源的那一次 action 就把變更投影給開團、「更多」、首頁與分析。
    - 「同一次 action」指實際改動來源的那個 action (載入回應、寫入回應或 `writes` 處理 cascade 的 action)，不是 Root 最初收到的 delegate；請求的轉送另以 `receive` 驗證。
    - 以 Root 測試驗證「改動來源的 action 之後 `campaigns.orders` 與 `more.orders` 已更新」。
- **Root cascade**：開團刪除與改名、主檔改名後的訂單調整，改由 Root 送 `.orders(.cascadeRequested(…))`，容器轉給 `writes` 在 reducer 內套用 (不再由 Root 就地改 `state.orders.orders`)。`RootCascadeOperations` 隨之搬到 `Features/Orders/` 並改名 (例如 `OrdersCascadeOperations`)，避免 Orders 引用 `Features/App/`。現行三個呼叫點處理完 cascade 即回 `.none`，改成送請求不影響其他操作的先後。
- **守門**：`ProjectionWriteBoundaryTests` 的 `sharedOrderViolations` 現在只允許 `RootFeature.swift` 出現 `$orders.withLock`；改為依擁有者分別允許：Root (開團與「更多」的訂單投影)、`OrdersLoadFeature.swift` 與 `OrderWritesFeature.swift` (訂單資料來源)，每條允許與禁止都補正反 fixture；`Features/Campaigns/`、`Features/More/` 的 `SharedReader` 限制不變。
- **過渡 (3.2 到 4.3)**：轉成 `@Shared` 時，現行寫入點不只在容器主檔 (`OrderDraft`、`OrdersBatchOperations`、`OrdersMergeFlowOperations` 的 helper，Root 的三處 cascade，以及五個畫面的 Preview)。處理方式：
    - 容器主檔加一個暫時的 State 方法 (例如 `mutateOrders(_:)`) 包住 `$orders.withLock`；helper 與 Root cascade 一律改呼叫它，不在其他檔寫 `withLock`，也不擴大允許清單。
    - Preview 改以建立 State 時帶入訂單 (`init` 參數，內部 `Shared(value:)`)，不寫 `withLock`。
    - 3.2 暫時允許 `OrdersFeature.swift` (只有這個暫時方法與現行容器寫入)；4.2 把 Root cascade 改成請求，4.3 搬完最後一批寫入 (合併) 後刪除暫時方法與這條允許，並以變異 (容器寫回 `$orders.withLock`) 確認轉紅。
- **合併的例外**：訂單合併維持既有的樂觀更新加快照回滾 (`.claude/rules/ios-navigation.md` 與規格 `order-write-ordering` 明列的例外)，移入 `writes` 時保留；其餘寫入一律先落盤、成功才更新共用資料。

### 容器是唯一呈現者，表單開著時的結果等關好才顯示

- **`Destination` 內容**：6 個 `@Presents` 併成單一 `Destination`：`edit(OrderEditFeature)`、`merge(OrderMergeFeature)`、`aiSummary(AISummaryFeature)`、`alert(AlertState<Alert>)`，其中 `Alert` 含確認刪除、寫入失敗、AI 摘要未啟用三種。篩選 sheet 的捨棄確認留在清單 (比照「表單捨棄確認留在表單內」)。
- **受保護的呈現**：`edit`、`merge`、`aiSummary` 三種 sheet 開著或關閉中時，寫入失敗與新增選項失敗只暫存最新一則，不換掉 sheet；sheet 的 `onDismiss` 送 `view(.formSheetDismissed)` 後才呈現暫存的那一則 (比照開團 `CampaignPresentationQueue`，擴充為三種 sheet)。
- **合併轉場的先後**：候選 sheet 完成後保留 500ms 延遲 (`continuousClock`) 再開合併確認表單。延遲期間到達的通知仍暫存；合併確認表單優先開啟，暫存的通知等確認表單關閉後才顯示。
- **測試**：以 `TestClock` 涵蓋通知在 `onDismiss` 前後、500ms 前後到達，以及 merge／AI 摘要 sheet 開啟中到達的情境；「連續兩則只顯示最新一則」。
- **alert 掛載**：只掛在最上層畫面 (iPad 雙欄時另一層給 `.constant(nil)`)。

### 詳情以 OrderDetailFeature 供 iPhone 推入與 iPad 右欄共用

- **iPhone 推入**：`Path` 只有 `detail(OrderDetailFeature)`；顯示詳情走容器的 `showDetail(orderID:)`，先清空再推入。訂單刪除或合併後以 `popDetail` (內部 `pop(from:)`) 移除，取代 `pruneDetailPath` 的 `removeAll` (`.claude/rules/ios-navigation.md`)。
- **iPad 右欄**：容器持有 `regularDetail: OrderDetailFeature.State?`，隨清單的選取變更 delegate 同步；右欄畫面以 `store.scope` 使用同一個 Feature 與同一個「更多」選單元件。
- **深連結**：Root 的篩選深連結改呼叫容器的方法 (例如 `applyFilterNavigation(…)`)，由容器呼叫清單的 State 方法套用篩選並重選第一筆，同時同步 `regularDetail`；Root 不直接呼叫清單 State。以 Root 入口測試斷言 iPad 右欄實際的訂單 id。
- **詳情狀態**：可選狀態排除 `.merged` (除非訂單已是 merged)；合併資格、成本組成為 State 的 computed，取自純計算型別；四處 View 的合併資格判斷刪除；`selectedOrder(referenceDate:)` 刪除。
- **`OrderDetailPath` 刪除**。

### Root 只送請求、讀投影、呼叫容器方法

- **啟動與載入**：
    - Root 的 `.view(.task)` 送 `.orders(.loadRequested)` 與 `.campaigns(.loadRequested)`。
    - 首頁、分析、客戶的 refresh delegate 改送 `.orders(.loadRequested)`。
    - 訂單分頁畫面出現時，清單經 delegate 要求載入，容器轉給 `load`，首次讀取失敗後切回訂單分頁仍會重試。
    - 去重：一般載入在「載入中或已載入」時略過 (同時檢查兩個旗標)；失敗後兩者皆為假，下一次請求即重新讀取，所以不需要另設強制重載。
- **請求 action**：
    - `.receiptStatusChanged` 改為 `.orders(.receiptStatusChangeRequested)`，`.paymentMethodFlagsApplied` 改為 `.orders(.paymentMethodFlagsApplyRequested)`，cascade 改為 `.orders(.cascadeRequested)`；容器轉給 `writes`。
    - 規格 `app-layer-boundaries` 的「Feature actions are grouped by who is allowed to send them」以 MODIFIED 補上「父層請求」這一組 (只有父層送、子層 reducer 處理、不得代替子層的使用者互動)，掃描範例補對應列。
    - 回覆範圍：父層需要處理的結果 (載入失敗、寫入失敗、需要呈現的通知) 經子層 delegate 回報；成功載入、cascade 與旗標套用的成功結果只經共用資料觀察，不另送 delegate。
    - `apps/ios/CLAUDE.md` 刪除第 153 行的例外並寫入這條規則。
- **投影**：
    - `orders.campaigns` (既有)、`orders.defaultCurrency` (6a)、`orders.aiSummarySettings` (Root `preferences` 的 AI 摘要開關與模型；容器移除 `SettingsService` 注入)。
    - `OrdersFeature` 加入 `ProjectionWriteBoundaryTests` 的投影擁有者清單，投影屬性為上述三個。拆分後主檔以外不再有 `inout OrdersFeature.State`，所以這個掃描可以守住 Orders 內部與 helper 都不寫投影；正反 fixture 涵蓋 Root 路徑、Orders reducer 與 extension、接收子 State 的 helper。
- **首頁新訂單**：改呼叫容器的 `presentNewOrder(...)`，與訂單分頁共用同一個建構選項的方法；Root 不再建立 `OrderEditFeature.State`。
- **型別引用**：`DashboardFeature`、`InsightsFeature` 引用的 `OrdersFeature.State.LoadState` 改為獨立的載入狀態型別。
- **舊 action 刪除**：`.task`、`.receiptStatusChanged`、`.paymentMethodFlagsApplied` 在各自被取代的 task 內刪除，並以 `grep` 確認為 0 筆。

### 開團載入與自動結單移到開團端的無 View 子 Feature

新增 `CampaignLoadFeature` (無 View)，接收 `loadRequested`，負責 `fetchCampaigns`、以注入的 `date.now`／`calendar` 評估自動結單、在 reducer 處理回應時寫入容器共用的 `@Shared` 開團並逐筆存檔 (現行 `CampaignListFeature.applyLoadedCampaigns` 的邏輯)。

- **去重**：在「載入中或已載入」時略過 (同時檢查 `isLoading` 與 `hasLoaded`)；失敗後列表重試經容器再送 `loadRequested`。測試在第一次讀取暫停時再送一次請求，斷言讀取與結單存檔各只發生一次。
- **訂單端同時停用**：同一個 task 內刪除 `OrdersFeature` 的 `fetchCampaigns`、重複的自動結單寫入與 `CampaignService` 注入，訂單端的開團只來自 Root 的投影；以 Root 同時觸發兩端載入、控制讀取順序的測試，斷言過期開團的存檔次數為一。
- **失敗呈現與畫面**：失敗以 delegate 交容器呈現 (現有 `.autoCloseFailure`)；載入狀態以 `@Shared` 提供給列表顯示。
- **列表出現時也請求載入**：現行 `CampaignListFeature` 的 `.view(.task)` 在未載入時會讀取，首次讀取失敗後切回開團分頁會重讀。改動後列表的 `.view(.task)` 寫入 `dateContext` 並經 delegate 請容器送 `loadRequested` (已載入或載入中時由去重略過)，保留這個恢復路徑，與訂單分頁一致。
- **載入不綁畫面生命週期** (使用者 2026-10-08 裁決)：開團與訂單的列表畫面以不等待 `finish()` 的 `store.send(.view(.task))` 送出載入請求，載入 effect 屬於容器的載入子 Feature，切走分頁不會取消讀取；`.task { await store.send(…).finish() }` 只用於畫面在才該跑的長效 effect。不以 CancelID 在畫面消失時取消：讀取結果由多個分頁共用，取消會讓 Root 啟動時那次讀取一併停止。這個生命週期由畫面的寫法決定，無法以 TestStore 驗證，以程式審查確認。
- **300 行限制**：`CampaignFeature` 目前剛好 300 行，且是投影擁有者 (主檔以外不得接收 `inout CampaignFeature.State`)。加入 `Scope(load)` 與轉送後，把 `fulfill` 改為回傳要做的事 (值) 的純函式放到獨立檔，由 `core` 套用，維持 300 行內 (task 結束時實測)。

### 現在時間由 reducer 寫入 dateContext

- **清單**：在 `view(.task)` 與重試時寫入 `dateContext` (寫在「已載入就略過」之前)，日期分組與篩選以它為準；`OrdersView`、`OrdersCompactView` 的 `@Dependency` 刪除。
- **合併**：`OrderMergeFeature` 在建立時帶入 `dateContext`，`OrderMergeCandidateSheet` 的 `@Dependency` 刪除。
- **刷新**：Root 的兩個刷新點各加一行 `state.orders.refreshDateContext(...)`。

### 日期區段標題與完整時間收到共用層並依注入時區

- **新的共用格式化**：放在 `apps/ios/BuyLedger/Shared/` 下的格式化檔，只接收 `Date`、`now`、`Calendar`、`Locale` 這類基本型別，不引用 Feature 型別 (`LayerBoundaryTests`：`Shared/` 不得引用 Features)。格式化以 `calendar.timeZone` 與 `calendar` 設定，涵蓋日標題 (今天、昨天、同年、跨年)、年月、年、月與完整時間 (`yyyy/MM/dd HH:mm:ss`)；完整時間只取注入 calendar 的時區、曆法固定西曆 (見「verify／review 後的補修」)。
- **呼叫端改用它**：`OrderFormatters.daySectionTitle`、`CampaignFormatters.sectionTitle`、`OrderFormatters.fullTimestamp` 改委派給它；函式改名時同步 `String+SourceLiteralScan` 的 `displayProperties`。
- **表單的完整時間**：`OrderEditOptions` 帶入建構時的注入 calendar，表單 State 據此提供完整時間，畫面不自行取時區；`SnapshotTests+OrderEdit` 改為帶入時區明確設為 Asia/Taipei 的固定 calendar (既有基準圖在 Asia/Taipei 錄製，系統 `DatePicker` 膠囊仍跟裝置時區；使用者 2026-10-07 裁決不用 UTC 的 `TestDependencies.fixedCalendar`，避免同一張圖兩個時間不一致)，若畫面與既有基準圖不同就停下回報，不重錄。
- **驗證**：測試讓注入時區與裝置時區不同，涵蓋清單分組標題、開團月標題與表單畫面的完整時間；以變異 (移除格式化的時區設定) 確認轉紅。

### 刪除訂單依開團篩選

刪除 `selectedCampaign`、`selectedCampaignStatus`、`campaignFilterSelected`、`campaignStatusFilterSelected`、`campaignStatusByName`、相關篩選操作與測試 (`OrdersFeatureTests`、`CampaignIntegrationTests+Filters` 整檔、`OrdersFilterOperationsTests` 與 `OrdersFeaturePerformanceTests` 中的相關段落)，規格 `order-campaign-filter` 以 REMOVED 移除。開團分頁的「篩選與分組」是另一個功能，不動。

### 選項整理成一個值，四個入口以同一個建構方式帶入

新增 `OrderEditOptions` (訂單來源、類別、付款方式、對帳狀態、開團、幣別代碼與 calendar)，由容器的單一建構方法產生。

- **建構來源**：
    - 四種主檔取清單共用的衍生計算 (主檔加訂單已用值)。
    - 開團以注入的 `now`／`calendar` 評估自動結單。
    - 幣別取共用的幣別清單 (為空時 `CurrencyCode.defaults`)。
    - 建構時的注入 `calendar` 一併放進選項，表單的完整時間據此格式化 (見「日期區段標題與完整時間收到共用層並依注入時區」)。
- **入口**：訂單分頁新增與編輯、合併確認、首頁新增 (Root 經 `presentNewOrder`) 都只用這個方法；首頁的選項接線與訂單分頁在同一個 task 完成。
- **`OrderEditFeature.State.init`**：
    - 接收 `options`、`defaultCurrency` 與合併用的 `prefill` (預填草稿、`mergeSourceIDs`、保留的照片)，在 init 內完成現行 `available*Loaded` 的整理規則。
    - 新參數皆有預設值 (`options` 空、`defaultCurrency` 為 `.twd`、`prefill` 為 `nil`)，既有約 100 處測試呼叫、三條 snapshot 與兩個 `#Preview` 不必全改；入口一律明確帶入。
- **刪除**：六個 `available*Loaded`、`.task` 的選項抓取，以及 `OrderEditFeature` 六個不再使用的 Service 依賴；`.task` 只保留新訂單初始焦點與既有訂單照片載入。

### 幣別清單由 Root 載入到記憶體內的共用狀態

新增 `apps/ios/BuyLedger/Core/Dependencies/SharedKey+CurrencyCodes.swift`，寫法比照 `Features/Lookups/SharedKey+LookupCatalog.swift`，定義 `InMemoryKey<[CurrencyCode]>` (預設空陣列)；放在 `CurrencyMetadataService` 旁邊 (`Core/Dependencies/` 既有檔已 import TCA；6c 搬 Service 時一起移)。

- **載入**：Root 在 `.view(.task)` 既有的 `refreshIfStale` 之後 (刷新失敗也照做) 呼叫一次 `fetchCodes`，非空才寫入。
- **失敗時**：讀取失敗或空結果保留原有的共用清單並記錄；只有共用清單本身為空時，建構方法才退回 `CurrencyCode.defaults` (既有行為，不寫進規格)。
- **測試隔離**：既有送 `.view(.task)` 的 Root 測試必須覆寫 `fetchCodes`；新測試在建立 State 前以 `$0.defaultInMemoryStorage = InMemoryStorage()` 注入獨立儲存。
- **檔案位置**：`RootFeature` 超過 300 行時依 7.23 把啟動幣別載入與重大時間變更抽成 `RootLaunchFeature`，投影寫入留在 `RootFeature.swift`。

### 預設幣別由 Root 投影，在建立表單時成為初始草稿

容器的 `defaultCurrency` 由 Root 在初始化與 `onChange(of: \.preferences)` 投影 (守門見「Root 只送請求、讀投影、呼叫容器方法」)；`OrderDraft.init` 的幣別改由參數決定。新訂單以它建立表單，`initialDraft` 與草稿一致，開新訂單不會變成已修改；編輯既有取原幣別、合併取主訂單幣別。

### 合併預填在建立時成為初始草稿

合併流程先組出合併後的草稿，再以 `prefill` 建立表單：`initialDraft` 即預填草稿，`isMergeContext` 在 init 時成立，保留照片放進 `draftPhotos` 但不設 `hasEditedPhotos`，`cardlessDeductionWasCapped` 依預填金額計算。

- **期望值要改的測試**：`OrdersFeatureTests` 中 `mergeConfirmationReady` 一帶以逐欄覆寫的 `expectedEdit` 比對整個 State 的測試，期望值改為以預填建立。
- **保留的測試**：`editOrder_合併草稿按下取消_詢問是否捨棄` (先建立再手動改值) 保留。
- **新增的測試**：「合併確認未修改時取消直接關閉」必須經實際的合併建立入口，不可直接建立帶預填的 State。

### 綁定、日期、費率與存檔守門

- **金額綁定**：
    - 照 `CampaignEditFeature.State.draftName`，在 State 加 `chargedAmount`、`cardlessDeductionAmount` 可寫 computed property，畫面綁定它們，reducer 比對 `.binding(\.chargedAmount)`、`.binding(\.cardlessDeductionAmount)` 夾限。
    - 三條直送 `.set(\.draft.…)` 的假綠測試改走 `Store` 加 `@Bindable`，並以變異 (比對改回 `\.draft.chargedAmount`) 確認轉紅。
- **日期**：年月日時分與目前草稿相同時不改草稿；compact `DatePicker` 是否真的觸發以 UI Automation 實測，不觸發也保留守門並記錄。
- **費率**：
    - 所有 `percentField` 改用畫面與測試共用的 `Decimal` 換算函式 (顯示 `rate × 100`、寫回 `value ÷ 100`，顯示兩位小數)。
    - 測試驗證函式與 binding 的 get／set：範例表、只讀不寫不改草稿、超過兩位小數依顯示捨入。
    - 以變異 (改回經 `Double`) 確認 4.56 那列轉紅；單測 `Decimal("4.56") / 100` 不算數。
- **存檔守門與存檔 delegate 同時落地**：
    - `canSave`、`isNumericFieldFocused` 移進 State。
    - 子層存檔在 `canSave` 為假時什麼都不做；為真時先送 `delegate(.saveRequested)`、再 `dismiss()`。
    - 父層改攔這個 delegate 並在處理時讀編輯 State 交給 `writes`。
    - 因為 `PresentationReducer` 先跑子層再跑父層，子層回 `.none` 擋不住父層現有的 `.saveTapped` 攔截，所以守門與接線在同一個 task 完成，並以父層整合測試驗證「必填未齊沒有寫入、沒有 dismiss；合法資料只寫一次後關閉」。

### 訂單編輯的 Action 分組與照片子 Feature

- **Action 分組**：`OrderEditFeature.Action` 分 `binding`、`view` (含 `.task`)、`delegate` 與子層。
    - 畫面只明確送 `view` action，焦點與欄位經 store binding (完成鍵改 `store.focusedField = nil`)。
    - `ActionGroupingScanTests` 不加 allowlist，負例保留。
- **新增選項**：子層送 `delegate(.addOptionRequested(kind, name, flags))`，付款方式帶 `PaymentMethodFlags`。
    - 容器轉給 `writes` 先落盤，請求與回應都帶表單實例 id：沿用 `OrderEditFeature.State.id` (容器建立表單時以注入的 `uuid()` 產生，與訂單 id 無關，同一筆訂單重開也不同)。「A 關閉後開 B」的測試要讓兩個表單的 id 不同 (例如 `.incrementing`)。
    - 成功後 `writes` 在 reducer 內更新 `lookupCatalog`；容器只在目前開著的表單實例 id 相符時，以表單的 State 方法把新值加入清單並選取。表單已關閉或已換成另一個表單時，只更新 `lookupCatalog`。
    - 失敗時清單與草稿不變，失敗經呈現佇列在表單關閉後顯示。
    - 這改變現行「先改畫面再寫入」的行為，`RootFeatureTests+LookupSync` 中斷言先改行為的測試要改寫。
- **照片子 Feature**：照片的選取、匯入、載入、刪除與檢視抽成子 Feature `OrderEditPhotosFeature`，以 `Scope` 組合。
    - 照片載入的成功與失敗合成單一 outcome response。
    - 搬到 extension 的巢狀型別依需要明確標 `@CasePathable`。
- **選項選擇子 Feature** (使用者 2026-10-08 裁決)：抽出照片後主檔仍 709 行，光巢狀型別就超過 300 行；依 `/ios-dev-kit` 拆分順序第 2 步，把六個選項清單、選擇器路由 (`PickerRoute`)、選取／切換／新增選項的 action 與 init 時的整理規則抽成子 Feature (例如 `OrderEditPickersFeature`)，以 `Scope` 組合；草稿欄位的寫入經子層 delegate 交父層，或由父層以 State 方法套用 (實作時擇一並記錄)。新增選項的 delegate 仍由父層轉給 `OrdersFeature`。
- **`body`**：改為 `BindingReducer()`、`Scope(photos)`、`Scope(pickers)`、`Reduce(core)`、`.ifLet`；State 依使用者裁決 stored → computed → init → nested types → 方法。

### 畫面拆區段與共用選擇列

- **`OrderEditView`**：`body` 只留骨架與 modifier，十個區段抽成獨立 View，六個選擇列合成不加 `.buttonStyle(.plain)` 的共用元件 (參考 `MoreView` 的 `entryButton`)，accessibility identifier 不變，過時註解依現況改寫。
- **訂單分頁畫面**：`OrdersCompactView`、`OrderDetailView`、`OrderFilterSheet` 等超過 300 行者依區段抽元件。
    - 「更多」選單與可選狀態選單合成 iPhone 詳情與 iPad 右欄共用的一個元件。
    - 列的 contextMenu 也共用。
    - `OrdersToolbarContent` 只綁清單 store，新增訂單與 AI 摘要經清單 delegate。
- **守門清單**：`ActionGroupingScanTests` 的畫面清單與元件目錄加入 Orders 的畫面與 `Features/Orders/Components`；`LocalizationCatalogTests+SourceGuards` 的寫死路徑隨拆檔更新，並以變異確認新檔仍被掃到。

### 改動前先錄基準

比照開團第 0 組：

- **snapshot**：在未改的程式上補錄改動前 snapshot，包括 iPhone 推入的訂單詳情 (含工具列)、iPad 右欄詳情與篩選 sheet，人工確認後才當基準，之後不得重錄。
- **UI 測試**：補錄並通過三條：
    - iPad 詳情「更多」選單的編輯、合併、刪除入口。
    - 冷啟動首頁開團卡：改動前預期失敗，以 `XCTExpectFailure(strict: true)` 標記讓主回歸維持綠燈，作為 RED 依據；修正它的 task (3.1) 移除標記 (strict 讓修好後未移除也會失敗)。
    - 「首次讀取失敗後點重試、資料出現」：用既有的 first-read failure 掛鉤。

### 拆檔方式

行數為 2026-10-06／07 實測 (不含檔頭與空行)；拆法為估計，每個拆檔 task 動手前在 task 下方記下切分方案與各檔預估行數：

| 檔案 | 行數 | 拆法 |
| --- | ---: | --- |
| `OrdersFeature` (+`StateQuery` 221) | 1182 | 依上述四個 Feature 與純計算型別 |
| `OrderEditFeature` | 893 | 主檔 (State／Action／依賴／body／Nested Types／core)、照片子 Feature、選項選擇子 Feature，必要時另有 operations 型別 |
| `OrderEditView` | 927 | 骨架、區段 View、共用選擇列、數值欄位輔助 |
| `OrderDetailView` | 770 | 依區段抽元件，成本組成移進 State |
| `OrdersCompactView` | 351 | 清單與詳情推入分開，選單抽共用元件 |
| `OrderFilterSheet` | 349 | 依區段抽元件 |
| `OrderDraft` | 325 | 草稿本體與寫入結果解析分檔 |
| `OrderMergeFeature` | 289 | 加入 `dateContext` 後若超過 300 行，候選分組移到純計算型別 |
| `OrderMergeFeatureTests` | 460 | 依受測行為分檔 (原列於 `EXISTING_OVER_LIMIT`，本 change 會改到所以移除) |
| `RootFeature` | 298 | 啟動幣別載入與重大時間變更抽成 `RootLaunchFeature` (7.23)；cascade 改送請求 action 後刪除 `RootCascadeOperations` 的就地寫入；投影寫入留主檔 |
| `CampaignFeature` | 300 | `fulfill` 改為回傳要做的事 (值) 的純函式移到獨立檔 |
| `OrderEditFeatureTests` | 1604 | 依受測行為分檔 |
| `OrdersFeatureTests` (+`AIDisabledAlert`) | 2910 | 依 Feature 建 `OrderListFeatureTests`、`OrderDetailFeatureTests`、`OrderWritesFeatureTests`、容器 `OrdersFeatureTests`，再依主題分 `+<主題>.swift` |

- 拆檔與風格整理分兩步，拆檔只搬移，測試數與結果不變。
- 抽出的 View 不宣告 `@Dependency`，不把 `private` 的 `@State`／`@Environment` 降為 internal。
- 每個 Feature 依「Orders 拆成容器、清單、詳情與寫入四個 Feature」的預算表量測點實測，超過 300 行就停下回報，不自行登記例外。

### 整批 snapshot 外溢的驗收

整批執行能否重現，取決於表單 `.task` 的非同步讀取剛好在哪個測試還在執行時跑完，0.1 在修正前的程式上整批 9 輪、重開模擬器 2 次都沒有重現。改以探針對照驗收 (使用者 2026-10-07 裁決)：

- **探針**：`reference/order-edit-task-probe.swift` (不提交進 App 或測試 target，量測時暫時複製進 `apps/ios/BuyLedgerTests/`，量完移除，探針產生的 `__Snapshots__/SnapshotTests+ZZProbe/` 一併移除)。探針二以與既有 snapshot 相同的方式渲染表單，再讓出主執行緒 1 秒，讓 `.task` 在測試範圍內跑完。7.2 驗收完成後已刪除，修正前後的量測結果記在 tasks 0.1 與 7.2。
- **修正前證據 (0.1 實測)**：探針二在修正前的程式上報 6 個 Unimplemented (`CampaignService.fetchCampaigns`、`CategoryService.fetchCategories`、`CurrencyMetadataService.fetchCodes`、`OrderSourceService.fetchOrderSources`、`PaymentMethodService.fetchPaymentMethodInfos`、`ReconciliationStatusService.fetchReconciliationStatuses`)。
- **修正後驗收 (7.2)**：修正前程式跑探針對照一輪 (仍報 6 個) → 最終程式碼跑探針 (0 個) → 最終程式碼 SnapshotTests 整批五輪，每輪都沒有來自訂單編輯的 Unimplemented issue。探針與 `OrderEditFeature` 的 API 不相容時，只調整探針的建構方式，渲染與等待方式不變。

- **基準 commit**：0.1 以 `git rev-parse HEAD` 記錄，並確認 `openspec/changes/order-edit-style-compliance/` 以外的工作樹乾淨 (change 自己的文件會在實作中更新，不算)。
- **修正前程式**：一律用基準 commit 的獨立 checkout，避免混用新舊程式：
    - `git worktree add` 到 scratchpad。
    - 建置前把被 git 忽略的 `apps/ios/BuyLedger/Resources/Config.xcconfig` 與 `apps/ios/BuyLedger/Resources/GoogleService-Info.plist` 從主工作目錄複製過去，兩邊用相同設定。
    - 只在 iPhone 17 模擬器執行；先以 `git diff --stat <基準> -- apps/ios/BuyLedger/Core/Persistence` 確認 SwiftData schema 沒變。
    - 量完 `git worktree remove`。
- **範圍外 issue**：試算頁 `quoteView` 的 `fetchCodes` Unimplemented 獨立列報，不計入失敗，但不得新增其他 issue。
- **雜訊判定**：單元或 UI 失敗只有在列為已知雜訊、且以 `-only-testing` 指定到方法層單獨重跑轉綠 (該次 `totalTestCount` 至少 1) 時才算雜訊；其餘一律是失敗。
    - 例外 (使用者 2026-10-08 裁決)：`orderEditView_合併訂單情境_符合基準圖` 的系統 compact `DatePicker` 日期膠囊會隨真實時間在「2026/4/12」與「2026年4月12日」之間切換 (基準 commit 的獨立 checkout 也一樣)。這張失敗時以 `reference/check_snapshot_alternates.py <UDID>` 比對實際畫面，與 `reference/snapshot-alternates/` 內任一格式逐像素相同即算通過，不重錄；不同就是真失敗。
    - 延伸 (使用者 2026-10-10 裁決)：同一系統行為在年月日格式下會讓日期欄折到第二行，影響所有含日期欄位的編輯表單 (`orderEditView_合併訂單情境_符合基準圖`、`orderEditView_一般既有訂單_符合基準圖`、`orderEditView_長訂單識別碼_顯示短識別碼`、`campaignEditView_編輯既有開團_符合基準圖`)。這四張的折行版面登記為 `longformwrap` 替代圖，判定方式同上；基準圖不重錄。長期改為另開 change：編輯表單 snapshot 改逐區段、含系統 `DatePicker` 的區段不做像素比對 (改由單元與 UI 測試守)，並廢除替代圖機制。
- **環境**：
    - 0.1 記錄執行環境時區 (模擬器沿用 Mac 的時區，以 `date +%Z` 記錄)；時區相關測試的注入時區必須與它不同，相同時改選另一個注入時區。
    - 所有模擬器工作 (build、單元、UI、worktree 對照) 一律序列執行，不並行；worktree 與主工作目錄的 build 也不重疊。
- **註解修正**：`SnapshotTests+OrderEdit` 的「快照不經過 .task」錯誤註解改正。

### 平行開發與整合

使用者 2026-10-08 裁決以兩位實作者平行開發：Codex CLI 做主線、`haiku-max-implementer` sub agent 做側線，主對話負責整合與驗證。

- **任務分組** (依 `grep` 實測的檔案重疊決定 `[after:]`)：
    - 主線 4.2 到 4.9 維持一條鏈：每項都改容器主檔 `OrdersFeature.swift` 與 `OrdersFeatureTests.swift`；4.8 另需 4.6 建立的 `dateContext`，4.7 與 4.8 都改 `OrdersMergeFlowOperations`。
    - 4.9 之後 4.10、4.11、4.12、5.3、5.6 彼此不相依。4.10 與 4.11 只共用 `ActionGroupingScanTests` 的清單幾行，由主對話整合時合併；4.12 只整理風格、不改型別、方法與 action 的名稱與簽章，所以不影響同時進行的測試檔任務。
    - 測試檔任務依「最後一個改到該檔的 task」排定：5.7 (開團列表、容器、載入與開團 snapshot 測試) 與 5.8 (4.x 不再改動的 Orders 測試) 不依賴 4.x；5.1 等 4.3 (新增選項會改 `OrderEditFeatureTests`、`OrderEditPickersFeatureTests`)；5.10 等 4.5 (4.2 改 `CampaignIntegrationTests+Delete`、`+Rename`，4.5 刪 `+Filters`)；5.11 等 4.6；5.12 等 4.8；5.9 與 5.13 等 4.11。4.13 (移除智慧分組) 不依賴 4.x，與主線同時進行，4.6 等它完成。
- **獨立副本**：每次派工從主 worktree 複製一份到 scratchpad 並建本地 baseline commit，實作者只在副本內修改。主 worktree 只在主對話整合時變動，驗證一項時不會 build 到另一項改到一半的程式。
- **整合**：主對話一次整合一項 (把副本相對 baseline 的差異套到主 worktree，不動 git index)，跑該 task 的驗證並勾選後再整合下一項；檔案重疊由主對話合併。模擬器驗證照「整批 snapshot 外溢的驗收」的環境規則序列執行。
- **雙派**：4.2 同時派給兩位實作者，比對後採用一份；其餘 task 只派一位。
- **自我檢查工具**：`reference/style_checks.py` 從腳本位置往上找含 `apps/ios` 的目錄當 repo 根目錄 (原本寫死主 repo 路徑，在副本執行會讀到主 repo)。
- 不在範圍：不改任何 task 的驗證內容；已完成的 task (0.1 至 4.1) 不動。

### 移除側邊欄智慧分組

使用者 2026-10-09 裁決在本 change 移除 iPad 側邊欄 (regular 版面) 的「智慧分組」：八個訂單狀態列 (報價中至已取貨)，各列顯示該狀態的訂單筆數，點選後切到訂單分頁並只換狀態篩選。

- **刪除**：`Features/App/SidebarSmartGroup.swift`；`RootSidebarLayout` 的「智慧分組」區段與側邊欄選取型別的 `.smartGroup`；`RootFeature` 的 `view(.smartGroupSelected)`；`RootNavigationOperations.showOrders(status:)`；`SidebarBadgeCounts.orderCount(for:orders:)`；只供智慧分組使用的 `OrderStatus.sidebarHue(in:)` 與 `BLAccessibilityID.Root.smartGroup`；對應的單元測試 (`RootFeatureTests+Sidebar` 的智慧分組測試、`ContrastComplianceTests` 的分組色相測試、`LocalizationCatalogTests+SourceGuards` 的智慧分組朗讀守門)。
- **保留**：側邊欄「訂單」列的進行中徽章 (`SidebarBadgeCounts.activeOrderCount`)；訂單清單的狀態篩選；客戶名稱與類別的深連結。
- **規格**：`navigation-path-integrity` 的單一選取情境改以分頁列為例並新增「側邊欄只列目的地」；`order-category-filter` 的跨功能導覽只剩客戶名稱來源 (原本兩份規格對智慧分組是否清除類別篩選互相矛盾，移除後一併消失)；`interface-consistency` 的狀態色只剩語意色調一軌。
- **順序**：4.13 不依賴未完成的 task，改的 Root 側邊欄、`OrderStatus+Presentation` 與三個測試檔和 4.3 至 4.5 不重疊，作為側線與主線同時進行；4.6 依賴 4.13，讓搬移 Root 篩選深連結時少一條狀態深連結。
- **字串**：`Localizable.xcstrings` 不手改，「智慧分組」等不再使用的字串由 Xcode 標為過時 (stale)。
- **文件**：6.1 一併同步 `.claude/rules/ios-design-system.md` 的訂單狀態色兩軌規則與 `apps/ios/README.md` 的 `SidebarSmartGroup` 目錄說明。
- 不在範圍：側邊欄其他列的排版與徽章樣式不變。

### 文件同步

- **`apps/ios/CLAUDE.md`**：
    - 「父層送請求 action」規則擴到有 View 的容器。
    - 刪除已解除的過渡例外：Root 送 Orders 內部 action、`OrdersFeature`／`OrderEditFeature` 的 `CampaignService`、`SettingsService`、`OrdersView` 等的 `@Dependency` 現在時間、`OrderEditFeature` 的 `.binding(\.draft.chargedAmount)`、日標題移共用層、`OrdersFeature+StateQuery`。
    - 新增 6c 前訂單仍注入主檔 Service 的例外說明。
- **`apps/ios/README.md`**：專案結構反映新 Feature 與拆出的檔。
- **`@Shared` 使用清單**：`.claude/rules/ios-data-layer.md` 的訂單投影與 `@Shared` 寫入者段落，以及 `apps/ios/CLAUDE.md`「本專案既有架構與 `/ios-dev-kit` 的差異」的 `@Shared` 條目，補上 Orders 容器的無鍵 `@Shared` 訂單、寫入者 (`OrdersLoadFeature`、`OrderWritesFeature`) 與 `@Shared(.currencyCodes)`。
- **`.claude/rules/`**：`ios-navigation.md` (Orders 詳情推入與 `popDetail`、`OrdersFeature.errorMessage`、`editOrder` sheet、首頁開新訂單、`OrderEditView.isNumericFieldFocused`) 等引用舊符號的段落更新。

### 7.1 第一輪審查後的修正

7.1 第一輪以 12 組唯讀審查 262 檔，逐檔結果、使用者 2026-10-09 的六項裁決與主對話判定記在 `reference/gate71-round1.md`。修正分成以下 task，全部完成後 7.1 對改到的檔重審。

- **首頁與分析頁 (7.4)**：
    - `DashboardFeature`、`InsightsFeature` 的 Action 分 `view`／`delegate`：`task`、`retryTapped` 與畫面直接送出的點擊 delegate (開團、新訂單、查看全部、類別) 改為 view 事件，由 reducer 轉成既有 delegate，Root 攔截的 delegate 不變；`Reduce(core)`、MARK 與 doc 依 kit。
    - `DashboardOngoingCampaignsSection.rows` 的過濾與彙總移到 State 或 `DashboardStats`。
    - 連帶只改 `DashboardView`、`InsightsView`、`DashboardRecentOrdersSection` 的送出點 (三檔第一輪前已通過 `style_checks.py`)；畫面的 `@Dependency` 現在時間與 `Calendar.current` 照舊屬第 7 步。
    - `CampaignListFeature` 的 State 順序一併在此整理 (與首頁同屬開團分頁以外的非訂單檔，和其他組不重疊)。
- **畫面內計算 (7.5、7.6、7.7)**：
    - 資料處理 (詳情來源卡的 trim／filter／join、成本占比、備註判空、清單已全選) 進 `OrderDetailFeature.State`、`OrderListFeature.State` 的 computed 或純計算型別 (`OrderCostBreakdown` 等)。
    - 格式化 (金額正負號、篩選摘要、編輯頁標題、側邊欄徽章朗讀值) 進 `OrderFormatters` 或由 State 給本地化值；畫面只留版面與綁定接線，`percentageBinding` 移到使用它的 `OrderEditPercentField`。
    - 輸出逐字相同，以既有 snapshot 不重錄通過確認；新 computed 與格式化方法各有單元測試。
- **`core` 的分派留在 Feature (使用者 2026-10-09 裁決)**：`core` 內的 switch 依 Action 宣告順序寫在 Feature 主檔，不移到輔助型別；主檔因此超過 300 行時依 kit「拆分」的順序處理。
    - `OrderListFeature` (7.6)：篩選 sheet 流程 (暫存篩選、sheet 內搜尋、捨棄確認，以及它用到的選項清單) 抽成子 Feature，由清單以 `@Presents` 或 `Scope` 組合；6d 在這個子 Feature 上重新設計畫面。
    - `OrderEditFeature` (7.7)：先依「畫面內計算」把 State 內的格式化 (`campaignsDisplayText`、`fullTimestamp(locale:)`) 移到格式化型別或改由 State 給本地化值，仍超過 300 行才抽子 Feature；「未歸團」改為本地化值，修正英文介面以 `Text(verbatim:)` 顯示中文的既有缺陷。
- **測試寫法 (7.9 至 7.13)**：預期值改字面值、可直設的 Given 不送 action、多組 When／Then 拆開或參數化；`store.finish()`、`clock.advance`、`continuation` 等等待 effect 的呼叫留在 Then。每條改寫保留原本斷言的語意，並以變異驗證抽查改寫後仍會轉紅。
- **改名**：Bool 參數與變數 (含測試參數)、`deleteItems` 改事件式、`normalize` 改 `normalized`、`writesPhotos`、`cardlessDeductionWasCapped`；改名由擁有該型別的 task 一次改完所有呼叫點 (含測試檔的呼叫點)。
- **分組與順序** (依 `grep` 實測的呼叫點決定，可同時派 Codex 與 Haiku)：
    - production 依網域分五組，檔案互不重疊：7.4 首頁與分析頁、7.5 訂單詳情 (擁有 `OrderFormatters`、`OrderCostBreakdown`、`OrderStatusRules`)、7.6 清單容器與側邊欄 (含篩選元件與容器輔助型別)、7.7 訂單編輯 (含 `OrderDraft`、`OrderWriteOperations` 的改名呼叫點)、7.8 合併。改名在測試檔的呼叫點各自只落在一組。
    - 測試檔依「最後一個改到該檔的 task」排在 production 之後，分五組：7.9 容器與清單輔助、7.10 編輯、7.11 清單／詳情／合併／寫入、7.12 Root、守門、首頁分析與 UI 測試、7.13 開團與 snapshot。
    - 7.14 由主對話以 build 判定疑似未用的 import；7.15 同步規則文件 (等 production 組完成，README 才有最終檔名)。
- 不在範圍：第 7 步與 6c、6d 的延後項 (見 Non-Goals)；第一輪判定不算違規的項目 (見 `reference/gate71-round1.md`)。

### 7.1 第二輪審查後的修正

第二輪重審第一輪後有改動的 222 檔，結果與使用者 2026-10-09 的裁決記在 `reference/gate71-round2.md`。

- **訂單容器重做 (7.16)**：`OrdersFeature.core` 依 Action 宣告順序 switch，每個 case 呼叫 `OrdersContainerPlan` 收 `OrderRequest` 或寫入結果、回傳值型別的純計算方法 (刪除吃整個 Action 的 `make`、`followUp` 與 `OrdersTransition` 這種在 TCA 外重做 Effect 的寫法)。依 kit 拆分第 2 步抽兩個無 View 子 Feature 以 `Scope` 組合：`OrdersPresentationFeature` 持有 `destination`、呈現佇列、合併轉場延遲與表單關閉時序，把存檔、新增選項、刪除確認與 AI 設定轉成 delegate 交給容器；`OrdersDetailNavigationFeature` 持有 iPhone 詳情堆疊與 iPad 右欄並負責兩者同步。容器主檔實作後實測 359 行，依使用者裁決登記有邊界的例外 (上限 359 行，6c 後重量，見 `findings.md`「行數例外」)。同一次更新內必須完成的呈現與導覽用子 State 的 `mutating` 方法 (與既有 `showDetail` 一致)，一次性通知維持 action。計畫型別仍只讀值快照、回傳要套用的值，守住共享資料的寫入邊界。完整設計與裁決見 `reference/716-design.md`。
- **開團呈現子 Feature (7.22)**：`CampaignFeature` 已做完 kit 拆分第 1 步 (`+Path`、`+Destination`)，7.17 依 Action 次序修正後超過 300 行；比照訂單抽無 View 的呈現子 Feature (持有 `destination`、`presentationQueue`、存檔與呈現時序)，主檔回到 300 行內。
- **Root 子 Feature (7.23)**：`RootFeature` 7.17 修正後超過 300 行且沒有 `Path`／`Destination`；依唯讀設計 (`reference/723-design.md`) 把啟動幣別載入與重大時間變更抽成無 View 的 `RootLaunchFeature` (持有 `@Shared(.currencyCodes)`，時間變更以 delegate 交 Root 刷新日期脈絡)，投影同步與跨分頁導覽留在 Root (`onChange` 須在 `RootFeature.body` 尾端、投影寫入只在主檔)，主檔回到 300 行內。
- **錯誤型別**：內部回應保留具體錯誤型別 (與 Service 的 typed throws 一致)，登記為 kit 差異。
- **命名**：`shows…` Bool 與縮寫 `Twd` 依規則改名，波及的本 change 外檔案 (`SettingsService`、`OrderRowView`、開團詳情畫面等) 一併整檔對齊。
- **分組與順序**：7.17 Root、開團、首頁與分析 (含 `monthlyProfitGoalTWD`、`showsUnpaidOnly`)；7.18 訂單詳情與編輯 (含 `OrderFormatters` 縮寫)；7.20 測試雜項；以上三組檔案不重疊、可同時進行。7.16 容器 (含 `OrdersView`、`OrdersCompactView`、`OrdersFeatureTests+*`) 與 7.17 共用 `RootFeatureTests` 的 `+DefaultCurrency`、`+AISummaryProjection`、`+LookupSync`，排在 7.17 之後；7.22 開團呈現子 Feature 改 7.17 剛動過的 `CampaignFeature` 與 `RootFeatureTests+Campaigns`，也排在 7.17 之後，和 7.16 檔案不重疊可同時進行。7.19 訂單清單、寫入與列元件 (含 `showsDate`、篩選 picker 旗標) 與 7.16 共用 `OrdersView` 等檔，排在 7.16 之後；7.23 Root 子 Feature 改 `RootFeature` 與整個 `RootFeatureTests` 系列，排在 7.16、7.22 之後。7.21 主對話以 build 移除與 `SwiftUI` 重複的 `import Foundation` 並同步文件，排在全部修正之後。
- **主對話判定**：持久化 key `settings.monthlyProfitGoalTwd` 是已存資料不是識別字，不改 (改了會清掉既有使用者的月目標)；開團詳情畫面的條件文字 (空狀態、收款朗讀、結團按鈕) 依第二輪判定原則移到資料所在處的 computed；`CampaignFeature.Action` 依 kit 原文 `path` 排在 `destination` 前。

### verify／review 後的補修

2026-10-10 `/spectra-verify` 與 `/spectra-review` 沒有 Critical；以下五項經主對話核對程式碼屬實，使用者採納在本 change 修正 (第 8 組)。

- **iPad 右欄冷啟動 (R1)**：`OrdersFeature.applyLoadedOrders` 只設 `list.selectedOrderID`，`detail.regularDetail` 在容器建立時因訂單為空而為 `nil`，之後只在選取變更、深連結與寫入結果時同步，冷啟動切到訂單分頁右欄是「選擇訂單」；改動前 `OrdersRegularDetailColumn.selectedOrder` 在沒有選取時取篩選結果第一筆。載入完成時同步右欄。`OrdersFeature.swift` 在 359 行上限，同步併入 `OrdersDetailNavigationFeature.State` 的方法 (與移除已不存在的詳情同一個呼叫)，主檔行數不增加。
- **照片載入隨區段取消 (R2)**：`OrderEditPhotosSection` 以 `.task { await store.send(.view(.task)).finish() }` 讀照片，區段在惰性 `Form` 內，捲離或推入選擇器時 `.task` 被取消，被取消的 effect 送不出回應，`photoLoadPhase` 停在 `.loading`，guard 只在 `.notLoaded` 才讀，同一次編輯再也不會讀。改為不等待 `finish()` (`ios-navigation.md`：一次性讀取不隨畫面等待)；sheet 關閉時 TCA 會取消已呈現子 Feature 的 effect。本機讀取很快，取消時機無法以測試穩定重現，以程式碼形狀、照片相關 UI 測試與 ui-automation 實測正常載入驗收。
- **完整時間的曆法 (R3)**：`BLFormatters.fullTimestamp` 除了時區也套用注入 calendar 的曆法；production 的 `\.calendar` 隨系統設定，系統選民國曆時固定格式 `yyyy` 印出 0115。改動前只設 locale，App 的 locale 沒有指定曆法所以是西曆。改為固定西曆、只套注入 calendar 的時區，規格 `app-localization` 補民國曆情境。同檔以 `Date.FormatStyle` 產生的日標題與年月標題本來就跟系統曆法，行為不變，不在範圍。
- **狀態規則單一來源 (R4)**：`OrderEditFeature.State.availableStatuses` 與 `OrderMergeCandidates.isEligible` 各自寫了狀態條件，改呼叫 `OrderStatusRules.selectableStatuses(for:)` 與 `canMerge(status:)`，行為不變。
- **狀態色測試 (R5)**：spec `interface-consistency` 的「部分到貨保留警告色」沒有測試；新增逐狀態參數化測試，預期 `OrderStatus.tone` 的每個值為字面值。「狀態色只有一個來源」維持人工確認，不新增掃描。
- **延後 (R6)**：review 的效率建議 (iPhone 與 iPad 清單每次重繪對全部訂單篩選三次，改動前一次) 延後到 6d：篩選 sheet 重設計會重寫清單的篩選與查詢，屆時以單次篩選的查詢回傳區段、識別值與全選狀態。
- **不在範圍**：verify 的「Spectra 追蹤清單漏了 5 個已暫存檔」在提交時明確帶上，不改程式；其他 verify 建議 (載入失敗後重讀的端到端測試、合併確認全部取消勾選) 不做。
- **驗收**：改到的檔整檔對齊並經 style 閘門 (`style_checks.py` 明確清單)；R1、R3、R4、R5 各以變異確認測試會轉紅；最後重跑完整回歸 (iPhone 17 單元、iPhone 17 與 iPad UI 主回歸、Pro Max 轉向)，全部晚於最後一次改程式。

## Implementation Contract

**行為**：

- 訂單分頁、詳情 (iPhone 推入與 iPad 右欄)、篩選、多選、合併、刪除、AI 摘要的使用者可見行為與現在相同；既有 snapshot 不重錄即通過。
- 冷啟動不進開團分頁時，首頁開團卡與分析頁每團毛利排行有內容；首次讀取失敗後重試可載入。
- 開團的自動結單每次載入只由開團端寫入一次，訂單端不寫開團。
- 共用訂單只由 `OrdersLoadFeature` 與 `OrderWritesFeature` 在 reducer 內寫入，Root 的投影在同一次 action 更新。
- 訂單編輯：
    - 四個入口開出的表單選項相同，表單出現時不呼叫選項 Service。
    - 新訂單用預設幣別；合併確認與重選同一時間不會讓表單變成已修改。
    - 編輯中折抵即時夾限；費率不丟精度；必填未齊不寫入。
    - 新增選項先落盤再出現，失敗不改畫面。
- 日標題、開團年月標題與完整時間依注入 calendar 的時區；完整時間固定以西曆印年月日。
- iPad 冷啟動載入訂單後，右欄顯示第一筆訂單的詳情 (與改動前相同)。
- 首頁與分析頁的載入、重試與點擊導覽行為不變。

**介面**：

- **Feature 與型別**：
    - `OrdersFeature` (容器)、`OrdersLoadFeature`、`OrderListFeature`、`OrderDetailFeature`、`OrderWritesFeature`、`OrderEditPhotosFeature`、`CampaignLoadFeature`。
    - `OrderRequest`、`OrderEditOptions` 與純計算型別 (名稱以實作為準，語意如上)。
- **Root 對 Orders**：
    - 請求 action：`.loadRequested`、`.receiptStatusChangeRequested`、`.paymentMethodFlagsApplyRequested`、`.cascadeRequested`。
    - 投影：`campaigns`、`defaultCurrency`、`aiSummarySettings`。
    - 容器方法：`presentNewOrder`、`refreshDateContext`、篩選深連結 (由容器套用到清單並同步 iPad 右欄)。
- **共用狀態與入口**：
    - `@Shared(.currencyCodes)`。
    - 共用層的日期區段與時間格式化入口。
- **`OrderEditFeature.State.init(id:currentDate:original:prefill:options:defaultCurrency:)`** (參數名以實作為準，新參數皆有預設值)。

**失敗模式**：

- **寫入失敗**：資料不變 (合併例外：樂觀更新後以快照回滾)，失敗經呈現佇列在表單關閉後顯示一次。
- **幣別快取為空或讀取失敗**：共用清單維持原值；清單為空時表單用 `CurrencyCode.defaults`。
- **拆檔或抽 View 讓既有 snapshot 改變**：修正寫法，不重錄。
- **Feature 主檔超過 300 行**：子 Feature 從第一次完成起、容器從 4.9 起超過就停下回報。

**驗收**：

- spec 各情境有對應測試 (單元或 UI)；假綠的金額綁定與費率測試以變異驗證確認轉紅。
- 守門 (`ActionGroupingScanTests`、`ProjectionWriteBoundaryTests`、`LocalizationCatalogTests+SourceGuards`、`LayerBoundaryTests`) 通過，新增規則有正反 fixture。
- 整批 snapshot 外溢依上述對照與五輪驗收。
- `reference/style_checks.py` 以明確清單重跑，所有範圍檔 `TOTAL` 只含不計失敗的代碼、每檔不超過 300 行；style agent 逐檔逐條 0 違規。
- 完整單元回歸、iPhone 17 與 iPad UI 主回歸全綠 (範圍外 `quoteView` issue 獨立列報)；iPhone 17 Pro Max `OrientationLayoutTests` 通過。

**範圍**：

- **範圍內**：
    - 上述 Feature、畫面、純計算型別、Root 與開團端的載入與投影。
    - 共用幣別狀態與日期格式化、受影響的測試檔與守門、文件同步。
    - 首頁與分析頁的 `DashboardFeature`、`InsightsFeature`、`DashboardOngoingCampaignsSection` 與三個畫面的送出點；7.1 第一輪指出的違規 (見 `reference/gate71-round1.md`)。
    - 規格變更 (修改 `order-campaign-assignment` 與 `app-layer-boundaries`、移除 `order-campaign-filter`、新增 `order-editor-options`，以及五份規格各加一條需求)。
- **範圍外**：Non-Goals 所列。

## Risks / Trade-offs

- [範圍是第 6 步最大的一次重構，task 數多] → 依 expand → migrate → contract 排序，每個 task 結束時 App 與測試都能編譯、相關測試全綠；先錄基準再動手。
- [容器行數預算是估計，開團容器實測剛好 300 行，且 Orders 容器職責較多 (iPad 右欄同步、深連結、合併轉場、`presentNewOrder`、四個請求 action)] → 純計算一開始就外移；子 Feature 第一次完成就量，容器在 4.9 硬性驗收，超過就停下回報，退路是把 `core` 的轉送整理成獨立型別。
- [`@Shared` 訂單在測試中的斷言時機] → 比照開團：測試先以 `withLock` 設初值，在第一個觀察點斷言。
- [啟動時 Root 同時送訂單與開團載入，與畫面 `.task` 重複] → `OrdersLoadFeature` 與 `CampaignLoadFeature` 都在「載入中或已載入」時略過，以暫停讀取的測試確認只讀一次。
- [新增選項改為先落盤，選項出現時間延後一次寫入] → 寫入是本機 SwiftData，延遲可忽略；行為符合 `.claude/rules/ios-navigation.md`「寫入先落盤、成功才改畫面狀態」。
- [iPad 右欄改用 `OrderDetailFeature` 後，選取同步與刪除後的清空] → 以「選取 A 後刪除 A」「詳情 A 換成深連結 B」測試掛載同步。
- [首頁在主檔尚未載入完成前開新訂單] → 冷啟動 Root 已送載入，與訂單分頁同一份資料；以 UI 測試從首頁開新訂單確認選項存在。
- [整批外溢只在特定時序下出現，整批不一定能重現] → 以探針讓 `.task` 在測試範圍內跑完，修正前與最終程式碼各跑一次對照。
