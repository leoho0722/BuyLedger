## Context

`load-failure-reload-loop` (2026-11-09 archive) 的「後續待辦」列了匯率與報價頁、客戶頁載入狀態、訂單清單 `isLoading` 投影三項。使用者 2026-11-10 重排剩餘次序時選定「先修缺陷」，把三項合成第 2 項 (合併為一個 change 是主對話提出、使用者選定的次序)。

現況 (2026-11-11 讀碼，t17 逐項對照原始碼確認)：

- **匯率與報價**：`FxView`、`QuoteView` 的 `.task` 是 `await store.send(.view(.task)).finish()`，上一行標 `task-finish-exempt: 已知風險，待後續 change`。兩頁是 `MoreFeature.State.path` (`StackState<Path.State>`) 的元素，每次從入口開啟時重建狀態；切到其他根分頁時「更多」堆疊原樣保留 (`ios-navigation.md`「切分頁不清空更多堆疊」)。
    - `FxFeature` 的 `view(.task)`／`view(.retryTapped)` 以 `guard !state.isLoading` 去重，設 `isLoading = true` 後在一個 `.run` 內先讀幣別主檔再讀匯率；`isLoading` 只由 `ratesResponse` 清除。匯率頁每次出現都重讀。
    - `QuoteRateFeature` 的 `task` (`loadOnAppear`) 與 `refreshRequested` 同樣以 `isLoading` 去重，尚無快照時才讀匯率；`isLoading` 只由 `ratesResponse` 清除。
    - 兩頁的狀態橫幅在載入中只顯示「更新匯率中」，沒有重試鍵；失敗時才顯示重試鍵。匯率橫幅 (`FxStatusBanner`) 的載入中、失敗訊息與重試鍵都沒有 identifier，報價橫幅只有重試鍵有 (`BLAccessibilityID.Quote.retryButton`)。
- **工具頁缺陷的推論鏈** (t17 讀 TCA 1.26.2 原始碼確認)：
    - `finish()` 被取消時讀取 effect 跟著取消 (`StoreTask.finish()` 等待 `cancellableValue`，取消時呼叫 `cancel()`)；報價頁 `view(.task)` 回傳的 `.send(.rateSource(.task))` 衍生的讀取同樣被取消。
    - 取消後的回應被丟棄 (`Send.callAsFunction` 開頭是 `guard !Task.isCancelled`)，`isLoading` 停在 `true`。
    - 切回時被去重擋下，載入中不顯示重試鍵。
    - 只有「切根分頁會取消 `.task`」一環要靠實測：Apple 文件只寫 `.task` 在畫面消失後某個時間點取消，`onDisappear` 的時機依 view 類型而定，沒有保證 `TabView` 切分頁一定算消失。
- **堆疊元素移除時的取消** (t17 讀碼確認)：TCA 1.26.2 `StackReducer` 的 `forEach(_:action:)` 文件寫明「It automatically cancels all child effects when it detects the child's state is removed from the stack」，實作以上一次經過時記下的 `_mounted` 與目前的 id 求差，只在有 action 經過 `MoreFeature` 的 reducer 時計算。production 移除工具元素的路徑有三條：`view(.entrySelected(nil))` 經 `clearDestination()` (返回入口清單，由 `MoreView` 的 `List(selection:)` setter 送出)、`view(.entrySelected(其他))` 經 `open(_:)`，以及 Root 處理 `.orders(.delegate(.aiSettingsRequested))` 時直接呼叫 `state.more.showSettings()`。第三條不經過 `MoreFeature`，取消要等下一個 `.more` action (t1p、t17 指出)。production 沒有送 `.path(.popFrom(id:))` 的地方。
- **其他 `task-finish-exempt` 的畫面不在缺陷範圍**：`LookupManagementFeature` 以 `hasLoaded` 去重 (讀取被取消時 `hasLoaded` 維持 `false`，下次出現會重讀)；`SettingsFeature` 的 `view(.task)` 不去重；AI 摘要與開團提醒連結的豁免理由仍成立。
- **客戶頁**：`CustomersFeature.State` 只有 `@SharedReader var orders` (由 `MoreFeature.State.orders` 投影而來)，`CustomersView` 以 `store.customers.isEmpty` 決定顯示空狀態 (`customers.list.message.createOrderSee`，建議建立訂單) 或清單。`CustomersView` 的 `.task` 已經只送出 (`delegate(.ordersLoadRequested)`，經 `MoreFeature` 交 Root 先讀主檔目錄再讀訂單)。Root 只在 `.onChange(of: \.orders.loadState)` 把訂單載入狀態寫給總覽與分析。
- **`OrderListFeature.State.isLoading`**：`@SharedReader var isLoading`，由 `OrdersFeature.State.init` 以 `SharedReader(load.$isLoading)` 傳入。production 沒有讀取者；測試只有 `OrderListFeatureTests.task_各種載入旗標_記錄日期並委派載入` (以 `hasLoaded` × `isLoading` 參數化) 與 `OrdersFeatureListRequestsTests.list_已載入分頁再次出現_先記錄日期再經容器請求載入` 的一行 `#expect`。

## Goals / Non-Goals

**Goals:**

- 匯率頁與報價頁讀取中切分頁再切回，讀取結果仍送達，不再停在載入中；先以 UI 測試重現推論的缺陷。
- 客戶頁分辨載入中、失敗 (原因與重試鍵)、已載入三種狀態，失敗與載入中不再顯示「尚無客戶」。
- 移除沒有讀取者的 `OrderListFeature.State.isLoading`。
- 規格與規則同步現行做法。

**Non-Goals** (以下範圍取捨都是主對話決定)：

- 不改 `FxFeature`、`QuoteRateFeature` 的去重規則與讀取流程，也不加載入器自我恢復 (`cancelInFlight` 重啟讀取)：觸發條件見 roadmap 的「不排序、等觸發條件」項目。
- 不合併兩份匯率載入器 (`FxFeature` 與 `QuoteRateFeature` 各持一份)：t1p 建議等出現第三個讀匯率的工具、或要讓匯率快照跨工具保留時，再抽成掛在「更多」底下的載入子 Feature。
- 不改匯率頁「每次出現都重讀匯率」與報價頁「尚無快照才讀」的既有時機，也不調整橫幅樣式 (含匯率頁重試鍵的觸控區)。
- 不改 `LookupManagementView`、`SettingsView`、`AISummaryView`、`CampaignView` 的 `.task` 與豁免標記。
- 開團詳情的客戶分貨區同樣由共用訂單推導，訂單讀取失敗時顯示「沒有指派到此開團的訂單」(t17 指出)。它是畫面內的一個區塊，不在本 change 範圍；規格新增句限定為「整個畫面內容由共用讀取推導」的畫面，這個缺口記進 roadmap 另行處理。
- 客戶頁不做骨架畫面，不新增自動重試。
- 不由 `RootFeature` 統一負責「分頁出現就載入」(觸發條件同上)。
- 不在實機驗證；不實測 iPad 多視窗。

## Decisions

### 工具頁的 .task 只送出、讀取壽命跟堆疊元素

`FxView`、`QuoteView` 的 `.task` 改成 `store.send(.view(.task))`，刪除兩處 `task-finish-exempt` 標記 (主對話決定，t1p、t17 審查同意)。兩頁的 body 根都是單一 `ScrollView`，掛點不變。

理由：工具狀態的壽命是「更多」堆疊元素 (切分頁保留，返回或換工具才移除)，讀取結果只寫回這份狀態，而兩個載入器以只由回應清除的載入中旗標去重；effect 的壽命不可短於去重旗標所在的 State。只送出後：

- 切分頁時讀取繼續，回應寫回仍在堆疊內的元素；切回時若仍在讀取，`view(.task)` 照舊被去重，等讀取結束後顯示結果。
- 返回入口清單或換工具時，元素從 `StackState` 移除，由 `forEach(\.path, action: \.path)` 取消該元素的 effect (TCA 文件與實作已確認，見 Context)。訂單頁的 AI 設定深連結改經 `settingsRequested` 後同樣經過 `forEach`，見「設定深連結改經「更多」的請求 action」。
- 只送出另有獨立理由：回到 `.task` 規則的預設寫法，刪掉兩個「已知風險」標記。2.1 沒有重現時，使用者可依此判斷是否仍以預防性修正保留這一步。

替代方案 (都由主對話排除)：

- 保留 `finish()`，在 reducer 收到「被取消」時重設 `isLoading`：TCA 1.26.2 沒有這種掛鉤 (`load-failure-reload-loop` design「觸發共用讀取的 .task 只送出不等待 finish」已查證)，做不到。
- 讀取改 `.cancellable(id:cancelInFlight: true)`、只以快照去重：切回時重啟讀取可以自我恢復，但要改去重規則，每次出現都中斷進行中的讀取並重送網路請求，且這是 roadmap 另列、尚未觸發的「載入器自我恢復」方向，不採用。

### 先以 UI 測試重現工具頁停在載入中

新增 UI 測試替身 `BLUITestLoadFailure.exchangeRatesDelayed` (`rawValue` `exchangeRatesDelayed`，UI 測試端 `LaunchOptions.LoadFailure` 對齊)：匯率每次讀取先以 `Task.sleep` 等待 8 秒 (估計值，比照 `ordersDelayed`；實作後以 result bundle 時間軸記錄實際間隔) 再拋出傳輸層錯誤 (`APIError.transport`，由 `BLUITestErrorFactory` 新增的工廠建立)，被取消時仍回傳同樣的失敗；只在 `DEBUG`，幣別主檔讀取不受影響。選延遲後失敗而不是延遲後成功 (主對話代選)：失敗畫面有重試鍵，同一條測試能接著驗證重試；載入中停住與否在兩種結果下都一樣可觀察。

identifier (掛在元素本身，固定值寫完整字串字面值)：

- `BLAccessibilityID.Fx.loading` (`fx.loading`，掛在載入中的 `ProgressView`)、`Fx.loadFailure` (`fx.loadFailure`，掛在失敗訊息 `Text`)、`Fx.retryButton` (`fx.retryButton`，掛在重試鍵)。
- `BLAccessibilityID.Quote.loading` (`quote.loading`)、`Quote.loadFailure` (`quote.loadFailure`)；重試鍵沿用 `Quote.retryButton`。

新測試檔 `apps/ios/BuyLedgerUITests/Tests/Tools/ToolLoadTabSwitchTests.swift`，匯率頁與報價頁各一條，步驟相同 (t17 建議 5 採納後的版本)：

1. Given：`LaunchOptions(loadFailure: .exchangeRatesDelayed)` 啟動，以 `FxScreen.open`／`QuoteScreen.open` 開啟工具，以 `waitForExistence` 等 `loading` 出現 (逾時 5 秒，估計值) 並記下時刻；不成立以「時間窗不存在」的診斷訊息失敗。
2. When：`AppNavigator.selectTab` 切到總覽，再切回「更多」(比照 `LoadFailureReloadLoopTests` 只點擊；`RootNavigationScreen.goToMore` 也會把保留中的工具算成就緒，用 `selectTab` 是為了不多一層就緒等待)。切回後以 `waitForExistence` 等 `loading` (逾時 2 秒，估計值)，並計算從第 1 步記下的時刻到此的經過時間；超過延遲常數 (8 秒) 時以「時間窗不存在，切回前原讀取可能已結束」失敗。這一步證明切回時原讀取還沒結束：修改後若原讀取已結束，匯率頁與報價頁切回時會發起新讀取，單看 `loading` 存在分不出來。
3. Then：先以 `waitForExistence` 等 `loadFailure` (10 秒，估計值：切回時距讀取結束最多約 8 秒，加導覽餘裕)；逾時時以失敗訊息附上 `loading` 是否仍存在 (修改前的預期失敗型態是「失敗訊息逾時、載入中仍存在」)。出現後以 `assertLoadStateStaysStable` 穩定取樣，`retryButton` 存在、`loading` 不存在。
4. When／Then (第二組)：點重試鍵，`loading` 出現，之後在 12 秒內 (估計值：8 秒延遲加 4 秒餘裕) 再轉為 `loadFailure` 與重試鍵 (spec「Repeated failure does not loop」)。

修改前的判定 (主對話判定)：在 iPhone 17 以 `-test-iterations 3` 跑兩條，都要在第 3 步以「失敗訊息逾時、載入中仍存在」失敗；iPad Air 11-inch (M4) 另跑 1 次，確認寬版「更多」分欄的詳情欄同樣重現 (t17 觀察 3：只跑 iPhone 時寬版只驗到修改後通過)。

沒有重現時的處理 (t1p 建議 5 採納)：通過、時好時壞或失敗在其他步驟時，停下回報使用者，不改 `FxView`／`QuoteView`，也不放寬斷言。組 B (客戶頁)、組 C (訂單清單) 與 A 沒有程式依賴，照常進行到審查前。A 的處置由使用者決定：比照 `root-task-lock-cancellation` 改為預防性修正 (重現測試改成修改前後都通過的情境測試，2.3 照做)，或移除 A 的規格句與 scenario 另案處理；決定後以 `/spectra-ingest` 調整 2.3、5.1、6.1。

### 以 TestStore 固定堆疊元素移除時取消讀取

新測試檔 `apps/ios/BuyLedgerTests/Features/More/MoreFeatureToolLoadCancellationTests.swift`，以 `MoreFeature` 的 exhaustive `TestStore` 驗證 production 的移除路徑 (t1p 建議 2、t17 建議 2 採納：不以 production 不會送出的 `.path(.popFrom(id:))` 當作返回的證明)：

- (a) 匯率頁讀取中 (替身以 `TestClock` 或可控 continuation 停在讀取中) 送 `view(.entrySelected(nil))` 返回入口清單，再讓讀取結束：store 不收到任何 `ratesResponse`，`store.finish()` 不逾時。
- (b) 報價頁同上。
- (c) 匯率頁讀取中改送 `view(.entrySelected(.quote))` (`open(_:)` 在同一次更新內清空再推入)：舊元素的讀取被取消。

另新增 `apps/ios/BuyLedgerTests/Features/App/RootFeatureToolLoadCancellationTests.swift`，以 `RootFeature` 的 `TestStore` 記錄 Root 直接改堆疊的路徑：

- (d) 匯率頁讀取中送 `.orders(.delegate(.aiSettingsRequested))` (Root 直接呼叫 `state.more.showSettings()`)，再讓讀取結束，記錄實際行為 (預期：取消延後到下一個 `.more` action，期間的回應會對已移除的元素觸發 `reportIssue`)。

判讀 (主對話判定)：(a) 至 (c) 固定的是 TCA 行為與本 change 的前提，修改前後都應通過 (回歸測試，不是修改前會失敗的重現測試)；若不通過，停下回報使用者。(d) 觀察到對已移除元素的回應或 issue 時，停下由使用者決定路由。

實測與決定 (2026-11-11)：(a) 至 (c) 通過；(d) 失敗，回應送給已移除的元素 (細節見「實作與實測紀錄」)。使用者選定改由 Root 送「更多」的專用請求 action，見「設定深連結改經「更多」的請求 action」；(d) 維持「已取消」的斷言，7.1 改完後轉為通過。

### 設定深連結改經「更多」的請求 action

使用者 2026-11-11 依 2.2 (d) 的實測選定 (主對話推薦)：

- `MoreFeature.Action` 新增父層請求 `settingsRequested`，與既有的 `catalogLoadRequested`、`optionAdditionRequested` 同層；`core` 收到時呼叫 `state.showSettings()`。
- `RootFeature` 處理 `.orders(.delegate(.aiSettingsRequested))` 時只設 `state.selectedTab = .more`，回 `.send(.more(.settingsRequested))`；不再直接呼叫 `state.more.showSettings()`。
- 之後「更多」堆疊只由 `MoreFeature` 自己的 reducer 改動，每次移除元素都經過 `forEach`，讀取當下就被取消；規則同步寫成通則 (見「規則同步」)。
- `selectedTab` 與堆疊分在兩個 action 更新：`.send` 產生的 action 在同一次處理內接著送進 store (推論，t1p 指出畫面看不到中間態；7.1 以既有 `RootFeatureDeepLinksTests` 與 UI 回歸確認深連結仍正常)。

替代方案：

- 維持現行路由，(d) 以 `withExpectedIssue` 固定已知行為：使用者未選。
- Root 送「更多」的畫面事件 `.more(.view(.entrySelected(.settings)))`：父層不送子功能的 `view` action (主對話排除，比照專案「父層送專用請求 action」的寫法)。

範圍：只改上述兩個 reducer 與 `RootFeatureDeepLinksTests` 的兩處預期；`OrdersFeatureAIDisabledAlertTests`、`OrdersPresentationFeatureDelegateTests` 只驗到 Orders 送出 delegate，不受影響 (2026-11-11 讀碼)。沒有使用者可見的行為改變，不改規格。

### 客戶頁以「更多」的載入狀態投影分辨三種狀態

Root 把訂單載入狀態也投影給「更多」，客戶頁唯讀：

- `MoreFeature.State` 新增 `@Shared var ordersLoadState: OrdersLoadState` (無鍵，`init` 以 `.loading` 建立，與 `OrdersFeature.State.loadState` 的初值一致)。
- `RootFeature` 既有的 `.onChange(of: \.orders.loadState)` 在同一處以 `state.more.$ordersLoadState.withLock` 寫入。
- `CustomersFeature.State` 新增 `@SharedReader var loadState: OrdersLoadState`，`init(orders:loadState:)` 兩個參數都必填 (主對話代選：不給預設值，讓所有建立處明確傳入，測試與 snapshot 不會默默拿到載入中)；`MoreFeature.makeElement(for: .customers)` 傳 `SharedReader($ordersLoadState)`。
- `CustomersFeature.Action.View` 新增 `retryTapped`，與 `task` 一樣送 `delegate(.ordersLoadRequested)`；`OrdersLoadFeature` 在首次失敗後的下一次請求會重讀。
- `CustomersFeature.State` 推導 `screenState` (`loading`／`failed(LocalizedStringResource)`／`empty`／`customers`)，先看 `loadState`，`.loaded` 時再看 `customers.isEmpty` (t1p 建議 3 採納，主對話判定)：比照總覽與分析在 State 推導畫面狀態，customer-summary 的「screen state by order load state」四列以一條參數化單元測試守住，失敗優先於空狀態的順序不必只靠 UI 測試。

替代方案 (主對話判定，t1p 審查同意)：

- 「更多」持有普通副本，變更時逐一更新堆疊中的客戶頁元素：Root 要伸手進 `more.path`，客戶頁同時有引用 (`orders`) 與副本 (`loadState`) 兩種同步方式。
- 把 `OrdersLoadFeature` 的 `hasLoaded`／`errorMessage` 唯讀引用一路傳進「更多」再於客戶頁推導：推導邏輯多一份，或要跨 Feature 引用 Orders 的查詢型別。
- Root 建立 `MoreFeature.State` 時直接接來源的 `SharedReader`：「更多」在編譯期就無法寫，但來源目前是兩個旗標而不是單一 `OrdersLoadState`，要先改 `OrdersLoadFeature`，並與既有「Root `onChange` 寫投影」並存成兩套機制 (t1p 建議等 `OrdersLoadFeature` 因其他原因重整時再評估)。
- 選定共用引用的理由 (對照 `ios-data-layer.md`「擴用前先確認需要共用引用」)：客戶頁元素在推入時建立，顯示期間要隨訂單載入狀態更新，Root 的 `onChange` 寫不到堆疊元素，與既有的 `MoreFeature.State.orders` 投影同型。

寫入邊界與連帶影響：

- 只有 Root 在 reducer 內 `withLock`，`Features/More/` 內的 `$ordersLoadState` 只能作為 `SharedReader(` 的引數。`ProjectionWriteBoundaryScanner` 的 `sharedOrderViolations` 以 `\$orders\b` 比對，涵蓋不到 `$ordersLoadState` (主對話、t1p 指出)，要擴充：把寫死的名稱抽成一張表 (投影名、合法寫入檔、唯讀目錄)，兩個投影共用同一段比對，不複製第二個函式 (t1p 建議 4 採納)。
- Root 層 exhaustive `TestStore` 逐條斷言載入狀態投影，多寫一份共用投影後，每個斷言 `dashboard.loadState`／`insights.loadState` 的地方都要補 `$0.more.$ordersLoadState.withLock { … }`，以 `initial.dashboard.loadState = …` 建初始狀態的測試也要同步設定 `more` 的初值 (t1p 必修 2、t17 必修 2)。漏寫只會在執行期失敗，找齊方式是搜尋 `(dashboard|insights)\.loadState` 的所有斷言與初值設定處：2026-11-11 計數 8 個檔 (`RootFeatureCampaignLoadingTests`、`RootFeatureLoadCancellationTests`、`RootFeatureLoadRequestsTests`、`RootFeatureLookupCatalogFailuresTests`、`RootFeatureLookupCatalogTests`、`RootFeatureSharedOrdersTests`、`CampaignIntegrationTests`、`Support/RootFeatureTestSupport.swift`)，apply 前重算一次。

### 客戶頁的三種畫面

`CustomersView.content` 依 `store.screenState` 單層切換，`.task` 掛點不變 (body 根為單一 `ScrollView`、只送出)：

- `.loading`：`ProgressView()`，以 `.containerRelativeFrame(.vertical)` 撐滿可視高度並置中，identifier `BLAccessibilityID.Customers.listLoading` (`customers.list.loading`)。不加文字 (比照開團清單的載入中，主對話代選；不新增 catalog key)。不做骨架畫面：content-truthfulness 的骨架規格目前只定義總覽的範例，開團與訂單清單也以進度指示器呈現。
- `.failed(let message)`：`BLLoadFailureView(message:onRetry:retryIdentifier:)`，重試送 `view(.retryTapped)`；容器 identifier `Customers.listLoadFailure` (`customers.list.loadFailure`)，重試鍵 `Customers.listLoadFailureRetryButton` (`customers.list.loadFailureRetryButton`)。在 `ScrollView` 內同樣以 `.containerRelativeFrame(.vertical)` 撐高 (比照既有空狀態)。
- `.empty`：現有空狀態；`.customers`：現有前三名與清單。

`#Preview` 補載入中與失敗兩種 (使用 App 程式碼已有的 key `orders.general.message.ordersLoadedTry`)。

UI 測試支援：`RootNavigationScreen.isMoreDestinationForegroundReady` 納入 `Customers.listLoadFailureRetryButton` (主對話判定，比照 `load-failure-reload-loop` 把分析頁失敗重試鍵納入就緒判斷；t17 指出本 change 規劃的測試不會走到，屬一致性補強)。

新測試檔 `apps/ios/BuyLedgerUITests/Tests/Customers/CustomersLoadStateTests.swift`：

- `LaunchOptions(loadFailure: .orders)`：以 `CustomersScreen.open` 開啟客戶頁，先確認 `listEmptyState` 不存在 (訊息寫明「訂單讀取失敗時顯示了尚無客戶的空狀態」)，再等 `listLoadFailure` 出現後穩定取樣 (`assertLoadStateStaysStable`，重試鍵存在、`listLoading` 與 `listEmptyState` 不存在)。進入時客戶頁 `.task` 會經 Root 再請求一次訂單，可能有極短的載入中瞬間 (t17 觀察 4)，與既有訂單清單失敗測試同一種結構。
- `LaunchOptions(loadFailure: .ordersDelayed)`：先切到訂單分頁等第一次延遲失敗 (最多 15 秒)，再開啟客戶頁，讓客戶頁自己發起讀取 (修正經過見「實作與實測紀錄」3.2)；先確認 `listEmptyState` 不存在 (同上訊息)，再以 `waitForExistence` 確認 `listLoading` (時間窗不存在時以診斷訊息失敗)；等 `listLoadFailure` 出現後穩定取樣；點重試鍵，`listLoading` 出現後再轉為 `listLoadFailure`。先查空狀態是 t17 觀察 5 的建議：修改前的失敗訊息直接點出缺陷，不必翻診斷樹。

修改前預期 (3.2 先寫測試、主對話在修改 `CustomersView` 前於 iPhone 17 跑一次)：兩條都在「顯示了尚無客戶的空狀態」失敗。

既有測試連帶 (t17 必修 1)：`LoadFailureReloadLoopTests` 的離開客戶頁案例以 `.ordersDelayed` 啟動，現在以 `Customers.listEmptyState` 出現當作「已進入發起讀取的畫面」的證據；改動後客戶頁在每次讀取都失敗時不會顯示空狀態，這條必定失敗。進入證據改成以 `waitForExistence` 等 `Customers.listLoading` (剛進入時可能先顯示上一次的失敗，等 Root 讀完主檔目錄、請求訂單後才轉為載入中)，doc comment 同步。

### 移除訂單清單的 isLoading 投影

刪除 `OrderListFeature.State.isLoading` 與 `init` 的 `isLoading` 參數，`OrdersFeature.State.init` 不再傳入 `SharedReader(load.$isLoading)`。`OrderListFeatureTests.task_各種載入旗標_記錄日期並委派載入` 改為只以 `hasLoaded` 參數化 (方法名與 doc comment 同步)；`OrdersFeatureListRequestsTests` 刪除 `#expect(store.state.list.isLoading == false)`。

`OrdersLoadFeature.State.isLoading` 不動 (去重仍靠它)。移除後它是沒有外部讀取者的 `@Shared`，暫時維持 `@Shared`：測試以 `load.$isLoading.withLock` 寫預期的地方很多，降成一般屬性要一併改，留到下次動 `OrdersLoadFeature` 時處理 (t1p 觀察 2，主對話判定)。

### 規則同步

依 t1p 建議 1、4、6 改寫 (主對話判定)：

- `.claude/rules/ios-navigation.md`「根導覽與啟動」的 `.task` 條目：不另加「更多工具的讀取只送出」一句 (同一個堆疊內的主檔管理與設定頁仍合法等待 `finish()`，會互相矛盾)，改以去重形式為判準：
    - 「以只由回應清除的載入中旗標去重的載入器」那一個次 bullet 的清單併入 `FxFeature`、`QuoteRateFeature` 的匯率讀取，補一句判準：State 在畫面消失後仍保留 (根分頁、堆疊元素) 時，effect 的壽命不可短於去重旗標所在的 State。
    - 豁免條件的次 bullet 補一句：寫豁免理由前先確認 reducer 不以載入中旗標去重 (以 `hasLoaded` 這類成功後才設的旗標去重，或不去重，才可等待)。
    - 補一句：堆疊路徑只由宿主 Feature 的 reducer 改動，父層要改時送宿主的請求 action，不直接呼叫宿主 State 的方法；元素移除時由 `forEach` 取消其 effect，附守門測試名 `MoreFeatureToolLoadCancellationTests`、`RootFeatureToolLoadCancellationTests`。
- `.claude/rules/ios-data-layer.md`「跨檔不變式」：共享範圍清單補上 `MoreFeature.State` 的訂單載入狀態投影，寫入規則併入 `MoreFeature.State.orders` 那一條 (只由 Root 寫、客戶頁以 `SharedReader` 接)；補判準：Root 的投影目的地是推入或呈現時才建立的元素、且顯示期間要跟著更新時，才用宿主持有的無鍵 `@Shared` 加元素的 `SharedReader`，常駐的子 State (總覽、分析) 用副本；這份投影不是載入狀態的來源，「更多」內不得寫入。
- `apps/ios/CLAUDE.md` 列舉無鍵 `@Shared` 的那一行 (目前只寫 `MoreFeature.State.orders` 是客戶頁讀取的訂單投影) 補上載入狀態投影 (t1p 建議 6)。
- 只寫現行規則與理由，不寫本次經過。

## Implementation Contract

- **行為**：
    - 匯率頁、報價頁讀取中切到其他根分頁再切回，讀取結束後顯示結果 (成功為匯率、失敗為失敗訊息與重試鍵)，不再停在「更新匯率中」；返回、換工具與訂單頁的 AI 設定深連結移除工具時都會取消讀取，回應不送給已移除的元素。
    - 客戶頁在訂單讀取中顯示進度指示器、失敗時顯示失敗原因與重試鍵 (`BLLoadFailureView`)，兩者都不顯示「尚無客戶」；重試會經 Root 再讀一次訂單；訂單已載入才顯示空狀態或清單。
    - 其他畫面、訂單清單行為不變。
- **介面與資料形狀**：
    - `BLUITestLoadFailure.exchangeRatesDelayed`、`LaunchOptions.LoadFailure.exchangeRatesDelayed` (`rawValue` 相同)；`BLUITestErrorFactory` 新增建立匯率傳輸層錯誤的工廠。
    - `BLAccessibilityID.Fx.loading`／`loadFailure`／`retryButton`、`Quote.loading`／`loadFailure`、`Customers.listLoading`／`listLoadFailure`／`listLoadFailureRetryButton`，值見上方各節。
    - `MoreFeature.Action.settingsRequested` (父層請求)；`MoreFeature.State.ordersLoadState: OrdersLoadState` (`@Shared`)；`CustomersFeature.State.loadState` (`@SharedReader`)、`CustomersFeature.State.screenState`、`init(orders:loadState:)`；`CustomersFeature.Action.View.retryTapped`。
    - `OrderListFeature.State` 移除 `isLoading` 與對應 `init` 參數。
- **失敗模式**：匯率與報價的失敗訊息沿用 `FxFeature.userMessage(for:)`／`QuoteRateFeature.userMessage(for:)`；客戶頁失敗訊息沿用訂單載入的 `errorMessage`。不新增自動重試。
- **驗收**：
    - `ToolLoadTabSwitchTests` 兩條：修改前在 iPhone 17 連跑 3 次、iPad Air 跑 1 次都在第 3 步失敗，修改後在 iPhone 17 與 iPad Air 11-inch (M4) 連跑 3 次通過。
    - `MoreFeatureToolLoadCancellationTests` 通過；`RootFeatureToolLoadCancellationTests` 在 7.1 前失敗、7.1 後通過，`RootFeatureDeepLinksTests` 通過；`FxFeatureTests`、`FxFeatureCurrencyCodesTests`、`QuoteFeatureTests`、`QuoteFeatureCurrencyCodesTests` 不改預期值通過；`TaskFinishConventionScanTests` 通過。
    - `CustomersLoadStateTests` 兩條修改前失敗、修改後在兩台連跑 3 次通過；`CustomersTests`、`SnapshotCustomersTests` 不改預期值、不重錄通過；`LoadFailureReloadLoopTests` 兩台通過。
    - `RootFeatureCustomersLoadStateTests` (新)：訂單讀取失敗後 `more.ordersLoadState` 為 `.failed`、成功後為 `.loaded`，已推入的客戶頁元素讀到同一值；`CustomersFeatureTests` 補 `retryTapped` 送出 `delegate(.ordersLoadRequested)` 與 `screenState` 四列參數化測試。
    - `ProjectionWriteBoundaryGuardsTests` 對新投影的違規案例轉紅、合法案例通過。
    - `OrderListFeatureTests`、`OrdersFeatureListRequestsTests` 通過。
    - 完整 `BuyLedgerTests` 在 iPhone 17 0 失敗、snapshot 不重錄；完整 UI 回歸在 iPhone 17 與 iPad Air 各一次通過 (既有預期失敗與依版面略過除外)。
- **範圍**：只改 proposal Impact 所列檔案與規則；不改載入器去重、讀取時機、橫幅樣式、其他豁免畫面與開團詳情。

## Risks / Trade-offs

- [工具頁缺陷的「切分頁取消 `.task`」一環只是推論] → 2.1 先在兩種版面重現；沒重現就停下回報，不以「構造上成立」直接改。
- [Root 直接改「更多」堆疊時取消延後] → 2.2 的 (d) 實測確認後，7.1 改由「更多」的請求 action 處理 (使用者選定)；規則寫明堆疊路徑只由宿主 reducer 改動。
- [匯率頁每次出現都重讀] → 只送出後，切回時若前一次已結束會再讀一次，與現行行為相同；UI 測試以經過時間檢查區分。
- [UI 測試時間窗依估計值] → 8 秒延遲、2／5／10／12 秒等待都是估計值，實作後以 result bundle 時間軸記錄實際間隔；時間窗檢查失敗時回 design 調整，不放寬斷言。
- [客戶頁新增共用引用] → 寫入邊界由擴充後的 `ProjectionWriteBoundaryGuardsTests` 守住，判準寫進 `ios-data-layer.md`。
- [Root 層測試漏補斷言只在執行期失敗] → 3.1 依 `(dashboard|insights)\.loadState` 找齊 8 個檔，驗證範圍含 `CampaignIntegrationTests`。
- [`CustomersFeature.State.init` 改為兩個必填參數] → 建立處 (2026-11-11 計數：production 的 `MoreFeature` 1 處與 `CustomersView` 的 `#Preview` 2 處、測試 7 個檔共 19 處) 都要改，靠編譯錯誤找齊；`ProjectionWriteBoundaryGuardsTests` 另有 2 處是掃描用的字串樣本，依守門案例需要調整。

## 提案審查紀錄 (2026-11-11)

使用者 2026-11-11 指示送四方審查：t9 (codex-luna-max-impl) 唯讀 style 閘門、t17 (`opus-xhigh-reviewer`) 正確性、t1p (`fable-arch-reviewer`) 架構與長期維護，主對話同時審查。審查前後 `git status --short` 與 change 文件雜湊一致。取捨都由主對話判定，需要使用者決定的只有 2.2 (d) 的路由 (在 apply 時依測試結果再問)。

- t9：必修 3、建議 1，全部採納。requirement 的破折號改成半形括號；proposal 把修改前的「連跑 3 次失敗」改寫為驗收目標；核心選擇與 Non-Goals 補決策來源；3.1、3.2 補測試命名要求。
- t17：必修 2、建議 6、觀察 5。
    - 採納：既有 `testLeaveCustomers_…` 改以載入中當作進入證據 (必修 1)；Root 層測試的連帶斷言 (必修 2，與 t1p 必修 2 合併)；Context 改為「TCA 文件與實作已確認」(建議 1)；2.2 改用 production 路徑 (建議 2)；規格新增句改成描述結果、並限定整個畫面由共用讀取推導 (建議 3、4)；UI 測試時間窗與失敗訊息具體化 (建議 5)；Impact 補 `BLUITestErrorFactory.swift` (建議 6)；`goToMore` 的理由改正 (觀察 1)；Root 直接改堆疊的路徑 (觀察 2，與 t1p 建議 2 合併)；修改前在 iPad 另跑 1 次 (觀察 3)；客戶頁測試先查空狀態 (觀察 5)。
    - 只記錄：觀察 4 (`.orders` 失敗案例的極短載入中瞬間，與既有測試同結構，風險低)。
- t1p：必修 2、建議 6、觀察 4。
    - 採納：規格新增句不規範機制 (必修 1)；Root 層測試檔補進 3.1 與 Impact (必修 2)；規則以去重形式為判準 (建議 1)；2.2 改測 production 路徑並新增 Root 層案例，路由改不改交使用者 (建議 2)；客戶頁 `screenState` 放進 State (建議 3)；投影掃描器改表驅動、`ios-data-layer.md` 寫判準 (建議 4)；寫明 A 沒重現時的分支 (建議 5)；同步 `apps/ios/CLAUDE.md` (建議 6)；`OrdersLoadFeature.State.isLoading` 暫維持 `@Shared` 的說明 (觀察 2)。
    - 只記錄：觀察 1 (兩份匯率載入器，已列 Non-Goals)、觀察 3 (載入狀態投影的初值分散三處，再加第四個消費者時在 Root 的 `init` 統一同步)、觀察 4 (2.2 與 3.1 同派 t1n，實際是先後)。
- 主對話：投影掃描器必須擴充 (與 t1p 建議 4 相同)；「更多」前景就緒判斷納入客戶頁失敗重試鍵。

## 實作與實測紀錄

全部在模擬器執行，實作者交回前都跑過 `swiftc -parse`，建置與測試由主對話執行。

- 1.1 (t8 實作，2026-11-11)：`BLAccessibilityID+More.swift` 新增 8 個常數。完整 `BuyLedgerTests` 在 iPhone 17 (iOS 26.5) 建置通過，`BLAccessibilityIDTests` 通過。
- 4.1 (t8 實作)：`OrderListFeatureTests` 的參數化測試改名為 `task_各種已載入旗標_記錄日期並委派載入(hasLoaded:)` (t8 選擇)。`rg 'list\.isLoading|OrderListFeature.*isLoading' apps/ios` 沒有結果；完整 `BuyLedgerTests` 中 Orders 與 Root 的測試類別全部通過。
- 2.1 (t16 實作)：替身延遲寫成 `applyNetworkOverrides` 內的具名區域常數 `readDelay` (8 秒)，錯誤工廠為 `BLUITestErrorFactory.exchangeRateLoadFailed()`；測試的等待秒數集中在 `ToolLoadTabSwitchTests.Timing`，兩條測試共用 `fileprivate struct ToolLoadElements` 與兩個 private helper (t16 選擇)。修改 `FxView`／`QuoteView` 前的重現 (實測)：
    - iPhone 17 (iOS 26.5)，`-test-iterations 3`：兩條各 3 次重複、6 次全部失敗，訊息都是「切回後 10 秒內未顯示失敗訊息，載入中仍存在」(第 3 步)。
    - iPad Air 11-inch (M4) (iPadOS 27.0)，1 次：兩條都以同一訊息失敗，寬版「更多」分欄的詳情欄同樣重現。
    - 推論鏈中只能靠實測的「切根分頁會取消 `.task`」在兩種版面都成立；缺陷確定存在，不是預防性修正。
    - `FxTests`、`QuoteTests` 在 iPhone 17 共 8 條通過。
- 2.2 (t1n 實作)：替身以三個 `AsyncStream<Void>` 控制讀取開始、放行與取消記錄，未被取消時固定拋 `.http(statusCode: 503)`，讓遲到的回應會被 exhaustive `TestStore` 抓到 (t1n 選擇)。完整 `BuyLedgerTests` 在 iPhone 17 共 2052 條：2048 通過、3 條既有預期失敗、1 條失敗。
    - (a) 至 (c) 通過：經 `view(.entrySelected(nil))` 返回、經 `view(.entrySelected(.quote))` 換工具時，讀取都被取消。
    - (d) 失敗 (實測)：Root 處理 `.orders(.delegate(.aiSettingsRequested))` 直接呼叫 `state.more.showSettings()` 後放行讀取，TCA 回報「A "forEach" … received an action for a missing element」，action 為 `MoreFeature.Path.Action.fx(.ratesResponse(.failure(...)))`。這條路徑在 2.3 之後才走得到；正式版靜默丟棄，DEBUG 出現執行期警告。
    - 同一種測試形狀在「移除不經過 `forEach`」時失敗，已證明它抓得到「移除時沒有取消」，不另對 (a) 至 (c) 做變異確認 (主對話判定)。
    - 使用者 2026-11-11 選定改由 Root 送「更多」的專用請求 action，所有堆疊變更都經過 `forEach`；(d) 維持現在的斷言，在 2.4 改完後轉為通過。
- 2.3 (t16 實作)：`.task` 改為只送出，註解為「工具狀態隨更多堆疊保留，讀取不隨畫面消失而取消」。修改後 `ToolLoadTabSwitchTests` 在 iPhone 17 以 `-test-iterations 3` 跑，兩條 6 次全部通過；從開啟工具後第一次查詢載入中，到切回後開始等失敗訊息，間隔 6.15 至 6.66 秒 (實測，result bundle 活動時間)，短於 8 秒延遲，時間窗餘裕約 1.3 至 1.8 秒。iPad Air 11-inch (M4) (iPadOS 27.0) 以 `-test-iterations 3` 跑，兩條 6 次全部通過，同一間隔為 6.50 至 6.75 秒 (實測)。`FxTests`、`QuoteTests`、`CurrencyPickerTests` 兩台通過，`SnapshotToolsTests` 不重錄通過。
- 3.1 (t1n 實作)：掃描器改為表驅動，函式改名為 `sharedProjectionViolations`，表與資料列為 `sharedProjections`／`SharedProjection` (t1n 選擇)。
    - 共享斷言的位置：派工單原本要求與 `dashboard.loadState` 寫在同一個 closure，與 `.claude/rules/ios-unit-tests.md` 的共享變更規則不符，t1n 提出後由主對話改為依規則放置；之後 `RootFeatureLoadCancellationTests` 仍有一處不符，因為同一條 effect 鏈的既有共享斷言 (`orders.load.$isLoading`) 寫在觸發的 `send` closure，`more.$ordersLoadState` 移到同一個 `send` 後通過 (主對話判定)。
    - 首次建置失敗：`CustomersFeatureTests` 改成型別層 `@MainActor` 後，參數化資料 `screenStateScenarios` 被隔離，`@Test(arguments:)` 讀不到；比照 `PaymentMethodCorrectionFeatureConfirmationTests` 改為 `nonisolated` 後通過。
    - 完整 `BuyLedgerTests` (iPhone 17)：2056 條，修正後除 2.2 的 (d) (7.1 處理) 外全部通過，3 條既有預期失敗；`SnapshotCustomersTests` 不重錄通過。
    - 變異確認 (實測，量完以備份還原、雜湊一致)：暫時拿掉 Root 的 `more.$ordersLoadState.withLock` 時 `RootFeatureCustomersLoadStateTests` 兩條失敗；暫時在 `MoreFeature` 寫入 `$ordersLoadState` 時 `sharedProjectionViolations_掃描正式原始碼_沒有投影寫入或可寫參考外傳` 回報 `MoreFeature.swift` 違規。
- 3.2 修改前 (t16 寫測試，主對話執行)：`CustomersLoadStateTests` 兩條在 iPhone 17 都失敗在「訂單讀取失敗時顯示了尚無客戶的空狀態」(實測)。
- 7.1 (t1n 實作)：`MoreFeature.Action.settingsRequested` 與 Root 改送 `.more(.settingsRequested)`；`RootFeatureDeepLinksTests` 兩個案例改為先在 `orders.delegate.aiSettingsRequested` 斷言 `selectedTab`，再在 `more.settingsRequested` 斷言堆疊變更，(d) 只調整接收順序、三個取消斷言保留。完整 `BuyLedgerTests` (iPhone 17)：2056 條，2053 通過、0 失敗、3 條既有預期失敗，snapshot 未重錄。變異確認 (實測，量完以備份還原、雜湊一致)：Root 暫時改回直接呼叫 `state.more.showSettings()` 時，(d) 失敗在「received an action for a missing element」。
- 5.1 (t8 實作)：`ios-navigation.md` 4 處 (去重載入器清單與 State 壽命判準、豁免前先確認去重方式、堆疊路徑只由宿主 reducer 改動、深連結改經 `settingsRequested`)；`ios-data-layer.md` 2 處 (共享範圍與投影判準、`ordersLoadState` 的寫入規則)；`apps/ios/CLAUDE.md` 1 處 (無鍵 `@Shared` 清單)。依文件同步鐵則確認 `apps/ios/README.md` 不需更新 (`-BLUITestLoadFailure` 的說明以省略號列舉，主對話判定)。
- 3.2 (t16 實作)：`CustomersView.content` 依 `screenState` 單層 `switch`，載入中與失敗以 `.containerRelativeFrame(.vertical)` 撐高；`#Preview` 補載入中與載入失敗。`LoadFailureReloadLoopTests` 的離開客戶頁案例改等 `Customers.listLoading`，`RootNavigationScreen` 就緒清單加客戶頁重試鍵。
    - 修改後第一輪：`.orders` 那條兩台各 3 次通過；`.ordersDelayed` 那條兩台 6 次全部失敗在「開啟客戶頁後未顯示載入中，時間窗不存在」。result bundle 時間軸 (實測)：App 啟動到前景約 6.2 秒，客戶頁出現時已是啟動後約 13 秒，啟動的 8 秒讀取只剩不到 1 秒；客戶頁 `.task` 因讀取中被去重，讀取結束後直接顯示失敗。屬測試時間窗設計錯誤，不是畫面缺陷 (主對話判定)。
    - 修正：這條的 Given 比照 `testLeaveCustomers`，先切到訂單分頁等第一次延遲失敗 (15 秒，估計值)，再開啟客戶頁，讓客戶頁自己發起讀取 (t16 實作)。修改前的失敗不重跑：它失敗在空狀態檢查，這一步在時間相依的步驟之前，修改前的畫面無論時序都顯示空狀態 (主對話判定)。
    - 修正後 `CustomersLoadStateTests` 在 iPhone 17 與 iPad Air 各以 `-test-iterations 3` 跑，兩條 12 次全部通過。`CustomersTests`、`LoadFailureReloadLoopTests` 與工具頁相關類別在兩台各 40 條通過；`SnapshotCustomersTests` 不重錄通過。

## 審查紀錄 (6.1)

審查者都未參與實作：t9 (codex-luna-max-impl) 唯讀 style 閘門、t17 (`opus-xhigh-reviewer`) 正確性、t1p (`fable-arch-reviewer`) 架構與長期維護，主對話同時審查。審查前後 `git status --short` 與 49 個變更檔的雜湊一致。取捨都由主對話判定。

- t9：必修 2 類 (新增的 3 行超過 100 字元，與主對話的檢查結果相同)，建議 1 (守門測試註解措辭)，全部採納。
- t17：必修 0、建議 3、觀察 6。production 路徑 (切分頁、返回、換工具、AI 設定深連結) 讀碼未見錯誤。
    - 採納：客戶頁元素接 `ordersLoadState` 的接線改由 `MoreFeatureTests` 改寫來源後斷言 (建議 1)；載入中情境的 GIVEN／WHEN 改成與修正後的 UI 測試一致，字面「開啟時沿用他處已在進行的讀取」由 `screenState` 參數化測試的 `loading` 列涵蓋 (建議 2)；`ios-unit-tests.md` 補「整條鏈只有同步 `.send` 時共享寫入在觸發的 `send` closure 就看得到」(建議 3，依文件同步鐵則納入本 change)；就緒判斷補 `Customers.listLoading` (觀察 2)；`orders` 的守門案例還原並另加組合案例 (觀察 3)；刪除 (c) 的恆真斷言 (觀察 4)；補設定頁已開啟時的深連結案例 (觀察 5)；design 第 50 行的過時敘述 (觀察 6)。
    - 只記錄：觀察 1 (`ToolLoadTabSwitchTests` 的經過時間以第一次看到載入中為起點，比讀取實際開始晚一個輪詢延遲；修改後若原讀取已結束，切回時會發起新讀取，測試仍會通過，但修改後的行為本身正確，所以不影響判定修正與否)。
- t1p：必修 2、建議 3、觀察 5，production 無架構問題。
    - 採納：「堆疊路徑只由宿主 reducer 改動」限縮為元素會發起非同步 effect 的堆疊 (目前只有「更多」)，並寫明開團與訂單詳情的現況與觸發條件，`apps/ios/CLAUDE.md` 的 `RootNavigationOperations` 條目同步 (必修 1 方案 A)；`projectionOwners` 的 `MoreFeature` 補 `orders`、`ordersLoadState`，守門涵蓋直接賦值 (必修 2)；`ios-data-layer.md` 補「新增投影要在掃描器加列」與常駐子層讀同一份引用的判準 (建議 2)；`apps/ios/CLAUDE.md` 的 `onChange` 目的地清單補載入狀態的目的地 (建議 3)；`ScreenState` 比照總覽與分析移進 `State` (觀察 2)。
    - 記進 roadmap：「更多」路徑變更的掃描守門 (建議 1，觸發條件是新增下一個「更多」深連結)；開團與訂單詳情堆疊改經宿主 reducer (必修 1 方案 B，觸發條件是詳情元素要加 `.run`)；主檔寫入結果不隨元素移除而中斷 (觀察 4)；第二個「更多」深連結出現時改為 `entryRequested(MoreFeature.Entry)` (觀察 1)；載入狀態投影初值統一由 Root 的 `init` 同步 (觀察 3)。
    - 只記錄：觀察 5 (可控匯率替身重複四份，再有使用處時抽到 `Support/`)。
- 修正 (t1n 實作測試與掃描器 8 項、t8 實作文件 5 項、t16 實作就緒判斷 1 項，主對話改規格情境與本文件)：完整 `BuyLedgerTests` (iPhone 17) 2058 條，2055 通過、0 失敗、3 條既有預期失敗，snapshot 未重錄。
    - 直接賦值守門的變異確認 (實測，量完以備份還原、雜湊一致)：在 `MoreFeature` 的 `settingsRequested` 暫時寫 `state.ordersLoadState = .loaded`，修正後的掃描器以 `findViolations_掃描正式原始碼_只有根功能寫入投影` 回報 `MoreFeature.swift:357 (ordersLoadState)`；同一變異下把 `projectionOwners` 改回修正前，專案掃描沒有抓到，只有新增的案例表失敗，證實修正前有這個缺口。
    - t9 複查修正處：無必修、無建議。複查前後 `git status --short` 與雜湊一致。

## 回歸紀錄 (6.2)

主對話執行 (2026-11-12)，受測版本是 6.1 修正與 t9 複查後的工作樹，兩台模擬器外觀鎖淺色，回歸前後 `git status --short` 一致。

- 完整 `BuyLedgerTests` (iPhone 17，iOS 26.5)：沿用 6.1 修正後的結果，2058 條，2055 通過、0 失敗、3 條既有預期失敗，snapshot 未重錄；之後只有唯讀複查，沒有再改檔。
- 完整 UI 回歸 (`-only-testing:BuyLedgerUITests`，略過 `LaunchPerformanceTests`)：
    - iPhone 17 (iOS 26.5)：202 通過、0 失敗、49 條依版面宣告略過。
    - iPad Air 11-inch (M4) (iPadOS 27.0)：先單獨跑 `KeyboardDismissTests` 2 條通過，全跑 227 通過、0 失敗、24 條依版面宣告略過。
- 中斷與重跑 (都是環境問題，沒有測試失敗)：iPhone 第一輪跑到第 166 條時磁碟寫滿，測試工具寫 log 失敗中止，清出空間後整輪重跑。iPad 前兩次啟動在十幾秒內失敗，訊息是連不上 test runner (testmanagerd 的 socket 不存在)，模擬器關機再開機後先跑 `KeyboardDismissTests` 再全跑。

## 收尾審查紀錄

archive 前由 `/spectra-verify`、`/spectra-review` (主對話) 與 t1p (`fable-arch-reviewer`，審查前清空 context) 三方審查，t1p 審查前後 50 個變更檔的雜湊一致。取捨都由主對話判定。

- verify：Critical 0、Warning 1、Suggestion 2。review：沒有需要修的問題。t1p：必修 0、建議 3、觀察 4，production 無架構問題。
- 採納 (只改文件與註解)：本文件客戶頁延遲讀取測試的步驟改成現行寫法 (verify Warning 1)；`CustomersFeature.State.ScreenState.failed` 的 doc comment 參數名改為 `message`，與總覽、分析一致 (verify Suggestion 1)；`ios-data-layer.md` 共享範圍那句的副本例子改成 Root 實際投影的副本 (t1p 建議 1)；`ios-unit-tests.md` 的共享斷言主句限定為「鏈經過 `.run` 時」，與同條次 bullet 一致 (t1p 觀察 3)；`apps/ios/CLAUDE.md` 的 `.task` 條目補「State 比畫面活得久且以載入中旗標去重的讀取」(t1p 觀察 2)；`OrdersLoadState` 的 doc comment 補客戶畫面。
- 記進 roadmap：UI 測試延遲秒數沒有單一來源，與「更多」就緒清單逐一列舉 identifier 併入 UI 測試穩定性項目 (t1p 建議 2、觀察 4)；載入狀態改由單一共用來源提供、兩份匯率載入器合併、可控匯率替身抽到 `Support/` (t1p 建議 3)；投影規則在 `ios-data-layer.md` 獨立成一條 (t1p 觀察 1，縮減 rules 時處理)。
- 不採納：可控匯率替身重複 (verify Suggestion 2，維持 6.1 的決定)；`screenState` 改用 `orders.isEmpty` 判斷 (review 列為可選，每次更新的成本與修改前相同，且與客戶彙總的結果是否永遠一致沒有驗證)。
- t9 (codex-luna-max-impl) 複查上列 6 處修改：逐處逐條符合，無必修、無建議；複查前後 `git status --short` 與雜湊一致。
