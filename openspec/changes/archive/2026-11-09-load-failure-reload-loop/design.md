## Context

`localization-resource-unification` 的 4.3 實測 (2026-11-08，iPhone 17 iOS 26.5 模擬器) 發現：以 `-BLUITestLoadFailure orders` 啟動後依「訂單 → 更多 → 訂單」切換分頁，訂單清單停在載入中；以 `1837124` 建置重做症狀相同，屬既有缺陷，使用者 2026-11-08 決定另開本 change。兩條可能的機制見 proposal 的 Root Cause。2026-11-08 規劃先經五位 agent 唯讀審查，再經 `opus-arch-reviewer` 架構審查，本文件依兩輪結論與使用者的決定改寫。

官方與框架依據 (2026-11-08 查證)：

- Apple `Group` 文件：修飾器套用到 group 的所有成員，而不是 group 本身；把 `onAppear` 套在包著 `if` 的 group 上，條件每次改變都會執行。一般 `@ViewBuilder` 條件內容 (沒有 `Group`) 或 body 為條件內容的自訂 View 是否同樣分給各分支，文件沒有明確保證。
- Apple `View.task` 文件：view 消失或身分改變時，SwiftUI 會取消尚未完成的工作。
- TCA 1.26.2 原始碼 (`Core.swift` 的 send 迴圈與回傳 `Task`、`Effect.swift` 的 `Send.callAsFunction`)：一次 `send` 衍生的 effect，以及 effect 內再送出的 action 所產生的 task，都併入同一份清單；回傳的 task 被取消時清單內全部一起取消；`Send` 在 `Task.isCancelled` 時直接丟棄 action。所以等待 `finish()` 的 `.task` 被取消，會連帶取消它經 Root 串起的共用讀取，並遺失 `loadResponse`。

現況 (2026-11-08 讀原始碼確認)：

- `DashboardView`、`InsightsView` 的 `body` 都是 `NavigationStack { content.frame(...).background(...).task { await store.send(.view(.task)).finish() }.rootNavigationTitle(...) }`，`content` 為 `Group { switch store.screenState { ... } }`；兩個 Feature 的 `view(.task)` 與 `view(.retryTapped)` 都送 `delegate(.refresh)`。兩頁在 `RootNavigationLayout` 的 `sidebarAdaptable` `TabView` 裡各自是單欄 `NavigationStack`。
- `CustomersView` 的 `.task` 是 `await store.send(.view(.task)).finish()`，`CustomersFeature` 的 `view(.task)` 送 `delegate(.ordersLoadRequested)`，經 `MoreFeature` 與 Root 觸發同一條主檔 → 訂單讀取 (`RootFeatureLoadRequestsTests` 已把客戶頁當成設計上的訂單載入發起者)。`CustomersFeature` 沒有載入狀態，訂單載入失敗或載入中時顯示「尚無客戶」。
- `OrdersLoadFeature.loadRequested` 只在 `isLoading` 為 `false` 且 `hasLoaded` 為 `false` 時開始讀取，開始時清空 `errorMessage`；`isLoading` 只在 `loadResponse` 時設回 `false`。`LookupCatalogFeature`、`CampaignLoadFeature` 也以「只由回應清除的 `isLoading`」去重；`LookupCatalogFeature` 在讀取中收到請求直接回 `.none`、不送 `loadFinished`。
- `CampaignListView` 的 `body` 是 `content.task { store.send(.view(.task)) }...`，`content` 是 `@ViewBuilder` 的 `switch store.loadState`；只送出、不等待。
- 訂單清單 (`OrdersCompactView`、`OrdersRegularListContent`) 的 `.task` 掛在 `OrdersCompactListView`／`OrdersRegularListColumn` 上、只送出不等待；兩個 view 的 body 根是單一容器 (`List`／`VStack`)，載入狀態只在內部切換，所以不會重跑。清單內容由三個獨立來源決定：載入中看 `isLoading`，失敗看 `loadState`，空狀態看資料是否為空；失敗只發生在第一次成功之前，此時訂單一定為空，所以失敗訊息下方一定同時出現「沒有符合的訂單」空狀態。兩個 view 各有一份等價的失敗 `Text`，沒有重試鍵 (`OrderListFeature` 的 `view(.retryTapped)` 沒有畫面送出)。既有 snapshot 不含訂單清單的失敗狀態。
- `RootNavigationScreen.isForegroundDestinationReady(for: .insights)` 只認 `rangePicker`、`trendTotalProfit`、`emptyState`；總覽與開團已納入各自的失敗重試鍵。`InsightsView` 的載入中、失敗與重試 identifier 是內聯的 `Common.loading("insights")` 等字串 key，沒有具名常數。
- UI 測試替身 (`DependencyValues+BLUITestOverrides.swift`，`DEBUG` only) 的 `.orders` 每次讀取立即失敗、`.ordersFirstReadOnly` 只有第一次失敗；`BLUITestStubs` 已有以 `Task.sleep` 延遲回應的先例。
- Features 內在 `.task` 裡 `await ... .finish()` 的 view (2026-11-08 grep)：`DashboardView`、`InsightsView`、`CustomersView` (本 change 修正)，以及 `RootView`、`AISummaryView`、`CampaignView`、`FxView`、`QuoteView`、`LookupManagementView`、`SettingsView`。

## Goals / Non-Goals

**Goals:**

- 載入持續失敗時切換分頁，總覽、分析、訂單清單、開團清單都穩定停在失敗畫面，不再自動重新讀取成迴圈。
- 共用訂單讀取進行中離開發起讀取的畫面 (分析分頁、客戶頁)，結果仍送達，所有畫面不卡在載入中。
- 訂單清單的載入失敗附上重試鍵，且失敗時不再顯示「沒有符合的訂單」空狀態。
- 以 UI 測試、TestStore 測試與原始碼掃描守門守住上述行為與寫法。
- 把規則寫進 `.claude/rules/ios-navigation.md`，避免再犯。

**Non-Goals:**

- 不改 `RootView` 的根層 `.task` (見「後續待辦」)。
- 不改 `OrdersLoadFeature`、`LookupCatalogFeature`、`CampaignLoadFeature` 的去重規則，也不在 reducer 加「已失敗就不再載入」的旗標。
- 不改匯率、報價、AI 摘要、主檔管理、設定、開團根畫面等其他等待 `finish()` 的 view，只在掃描守門中為它們寫明豁免理由。
- 不為客戶頁新增載入狀態。
- 不改畫面出現時的載入時機，也不新增自動重試或退避。

## Decisions

### 載入用的 .task 掛在不隨載入狀態換分支的容器上

總覽與分析把 `.task` 從 `content` 移到 `NavigationStack` 這一層 (`NavigationStack { ... }.task { ... }`)，`.frame`、`.background`、`.rootNavigationTitle` 仍留在 `content` 上。`NavigationStack` 的身分不隨 `screenState` 改變，`.task` 只在分頁出現時執行一次。

替代方案：在 `DashboardFeature`／`InsightsFeature` 判斷已失敗時忽略 `view(.task)`，會讓畫面重新出現時不再重讀，且掩蓋 view 層的根因，不採用。

### 觸發共用讀取的 .task 只送出不等待 finish

總覽、分析與客戶頁的 `.task` 改成 `store.send(.view(.task))`，比照訂單清單與開團清單，符合既有規則「清單的 `.task` 只呼叫 `store.send(.view(.task))`，不等待 `finish()`」：它們都經 Root 觸發多個畫面共用的訂單讀取，不能因離開畫面而取消。三個 Feature 的 `view(.task)` 只回 delegate，沒有應隨畫面取消的長效 effect，`DashboardFeatureTests`、`CustomersFeatureTests` 等 exhaustive `TestStore` 已守住這個前提。

替代方案：在讀取端讓 effect 不受發起者取消影響。TCA 1.26.2 沒有這種機制：reducer 端沒有「被上層取消時回報或重設旗標」的掛鉤，`.cancellable(id:)` 只能由 reducer 主動取消，擋不住上層 task 的取消，所以做不到，不只是範圍較大。

不採用 TCA 1.18 遷移指南「在 `.run` 內另開非結構化 `Task { ... }` 讓工作撐過 store 生命週期」的做法：那只適用不需回報結果的 fire-and-forget 工作 (例如分析事件)。訂單讀取必須把 `loadResponse` 送回 reducer 才能清掉 `isLoading`，而在 effect 結束後從非結構化 `Task` 用 `send` 送出，會觸發 TCA 的執行期警告「An action was sent from a completed effect」(`Core.swift`)，官方明示不要這樣用。2026-11-08 查證時 TCA 最新正式版即專案使用的 1.26.2，沒有讓 effect 不受發起者取消影響、又能送回結果的機制；官方的設計是由發起端選擇，`await store.send(...).finish()` 綁定畫面生命週期，只 `store.send(...)` 則不綁定。

### 開團清單一律以單一容器掛 .task

`CampaignListView.body` 以單一容器包住 `content` 後再掛 `.task` (與 `.rootNavigationTitle`、`.toolbar`)，不依重現測試結果決定 (使用者 2026-11-08 決定)：本 change 的規則禁止把 `.task` 掛在條件內容上，若依當下 OS 的取樣結果保留舊寫法，規則與程式碼會說兩套，且官方沒有保證這個行為不隨 SwiftUI 版本改變。重現測試照跑，修改前在 iPhone 17 與 iPad Air 的結果記錄在本節，作為官方文件沒寫的實測紀錄。在 `CampaignView` 呼叫端掛 `.task` 不夠：body 為條件內容的自訂 View，從外面掛修飾器可能與 `Group` 相同 (推論)。

修改前實測 (2026-11-09，`CampaignListLoadFailureLoopTests`，`-test-iterations 3`)：iPhone 17 (iOS 26.5) 3/3 通過、iPad Air 11-inch (M4) (iPadOS 27.0) 3/3 通過。在這兩個系統版本上，`.task` 掛在沒有 `Group` 的 `@ViewBuilder` `switch` 上，往返分頁時失敗畫面持續穩定，沒有觀察到重跑；依上述決定仍改成單一容器。

實作與實測紀錄 (2026-11-09)：容器用 `ZStack { content }` (主對話指定，不加尺寸修飾)。修改後 `CampaignListLoadFailureLoopTests` 在 iPhone 17 與 iPad Air 通過，`CampaignFlowTests` 不改預期通過 (依版面宣告略過的既有案例照舊略過)，`SnapshotCampaignsTests` 不重錄通過。

### 訂單清單的失敗態由載入狀態單一推導並附重試鍵

使用者 2026-11-08 決定本 change 補上重試鍵，並讓失敗時不顯示空狀態：

- 抽出共用的 `OrdersListLoadFailureRow` (放 `apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Views/`)，內含失敗訊息與重試鍵 (`common.action.button.retry`，送 `view(.retryTapped)`)，水平內距由呼叫端傳入；compact 與 regular 都改用它，只留一份定義 (比照 `ios-navigation.md` 對多選工具列與可勾選列「只有一份定義」的規則)。
- 兩個 view 的清單內容改由 `store.loadState` 單一推導：`.loading` 顯示載入中、`.failed` 只顯示失敗列與重試鍵、`.loaded` 才顯示空狀態或訂單列。`loadState` 為 `.loaded` 後 `OrdersLoadFeature` 不再發起讀取，所以「已載入時又在讀取中」不會出現。
- identifier：`BLAccessibilityID.Orders.listLoadFailure` (失敗訊息)、`listLoading` (載入中)、`listLoadFailureRetryButton` (重試鍵)，掛在 `Text`、`ProgressView`、按鈕本身，位於列修飾之前。重試鍵的觸控區與樣式依 `.claude/rules/ios-design-system.md`。
- 既有 snapshot 若因「尚未載入時改顯示載入中而非空狀態」而改變，停下請使用者目視裁決，不自行重錄。

實作與實測紀錄 (2026-11-09)：失敗列放在清單內容區 (取代原本篩選區下方的失敗文字)，重試鍵比照 `QuoteStatusBanner` 的文字按鈕並用 `.borderless` 把觸控範圍限在標籤；水平內距 compact 傳 `BLSpacing.large`，regular 傳與篩選區相同的 `listHorizontalInset` (sonnet 選擇)。`OrderListLoadFailureTests` 在 iPhone 17 與 iPad Air 通過；`SnapshotOrdersTests`、`SnapshotOrdersBaselineTests`、`SnapshotOrderFilterEmptyStatesTests` 不重錄通過 (沒有變化，不需裁決)；`OrdersListTests` 與 `OrderListFeatureTests` 通過。兩個 view 不再讀 `OrderListFeature.State.isLoading`，欄位保留 (範圍外)。

### UI 測試支援層與延遲失敗情境

- `BLAccessibilityID+Insights` 新增具名常數 `loading`、`loadFailure`、`loadFailureRetryButton` (值與現有內聯 key 相同)，`InsightsView` 與 UI 測試改引用常數；`RootNavigationScreen.isForegroundDestinationReady(for: .insights)` 納入 `loadFailureRetryButton`，比照總覽與開團。
- 新增 UI 測試情境 `BLUITestLoadFailure.ordersDelayed` 與 `LaunchOptions.LoadFailure.ordersDelayed` (`rawValue` 對齊)：訂單每次讀取先以 `Task.sleep` 等待後失敗 (初始估計 3 秒，實作後記錄採用值)，被取消時仍回傳同樣的失敗；只在 `DEBUG`。延遲先做成列舉 case，出現第二種延遲變體 (例如延遲後成功) 時再拆成與失敗來源正交的獨立參數 (主對話代選)。

實作紀錄 (2026-11-09)：延遲寫成 `makeOrderService` 分支內的具名區域常數 `readDelay` (haiku 選擇：kit 規定 static stored property 不放 extension)。先以 3 秒實作，`-BLUITestLoadFailure ordersDelayed` 啟動後截圖確認約 3 秒時總覽為載入骨架、約 9 秒為失敗畫面與重試鍵。2.1 修正後離開發起讀取的兩個案例紅在前提檢查「離開時訂單清單不在載入中」：時間軸顯示從點分析分頁到檢查訂單清單約 5.6 秒，XCUITest 每次點擊後的等待閒置約 1.3 至 1.6 秒，3 秒讀取在檢查前已結束。主對話改採 8 秒 (主對話代選)，涵蓋兩次切分頁與客戶頁推入的等待，並保留 1.7 重試後 10 秒取樣逾時內的餘裕。

### 重現測試依關注點分檔

測試依 `ios-dev-kit` UI 測試樣板、`BLUITestCase`、Given／When／Then (旅程測試可多組)，命名 `<方法>_<情境>_<預期>`、後兩段正體中文。共同的穩定取樣：先 `waitForExistence` 等目標失敗元素第一次出現 (初始估計 10 秒)，再約 3 秒內每約 0.2 秒以立即的 `exists` 檢查一次、至少 10 次，每次都要求失敗元素 (與重試鍵) 存在、載入中元素不存在；數字是初始估計，實作後記錄採用值。

- `apps/ios/BuyLedgerUITests/Tests/Navigation/LoadFailureReloadLoopTests.swift`：
  - **切換分頁迴圈**：`LaunchOptions(loadFailure: .orders)`，依 spec 情境「Switching tabs after a load failure does not start a reload loop」切換，訂單、總覽、分析三頁各自穩定取樣。
  - **離開發起讀取的畫面**：`LaunchOptions(loadFailure: .ordersDelayed)`，先等第一次失敗出現 (此時啟動載入鏈已結束)，再切到分析分頁讓它發起新讀取，切到訂單分頁後立刻斷言 `Orders.listLoading` 存在 (證明確實在讀取中離開)，再斷言延遲後轉成 `listLoadFailure` 並穩定取樣；客戶頁同樣做一次 (更多 → 客戶 → 讀取中返回 → 訂單分頁)。修改前分析頁與客戶頁都在等待 `finish()`，預期必定卡在載入中。
- `apps/ios/BuyLedgerUITests/Tests/Orders/OrderListLoadFailureTests.swift`：`LaunchOptions(loadFailure: .ordersDelayed)`，訂單清單失敗後斷言 `listEmptyState` 不存在；按 `listLoadFailureRetryButton` 後斷言 `listLoading` 出現再回到 `listLoadFailure`，之後穩定取樣。
- `apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListLoadFailureLoopTests.swift`：`LaunchOptions(loadFailure: .campaigns)`，在開團分頁與其他分頁間來回切換，等 `Campaigns.listLoadFailure` 出現後穩定取樣 (載入中以 scoped `progressIndicators` 判斷)；與既有 `CampaignFlowTests` 的差別是持續取樣。

修改前的判定：切換分頁迴圈與離開發起讀取兩組案例在 iPhone 17 連跑 3 次都要因目標缺陷失敗 (失敗發生在載入狀態的斷言，不是導覽 helper 逾時、identifier 不存在或執行 0 條)，記錄每次失敗是斷言失敗還是逾時；時好時壞或修改前就通過時停下回報使用者，不放寬斷言。訂單清單案例修改前因找不到重試鍵、且空狀態存在而失敗。開團案例只記錄修改前結果，不作為修正與否的依據。主對話另外以變異確認：只還原分析頁、只還原總覽、只還原客戶頁的舊 `.task` 時，對應案例各自失敗。

實作決定 (主對話代選)：

- 穩定取樣抽成共用的 `apps/ios/BuyLedgerUITests/Support/XCTestCase+LoadStateSampling.swift` (`assertLoadStateStaysStable`)，三個新測試檔共用，不各寫一份；採用值為第一次出現逾時 10 秒、每 0.2 秒取樣 15 次，另可傳入沒有 identifier 的元素 (開團清單的 scoped `progressIndicators`)。失敗訊息標明「逾時」或「斷言失敗，第 N 次取樣」，用來記錄失敗型態。
- 切根分頁用 `AppNavigator.selectTab` (只點擊)，不用會等前景就緒的 `RootNavigationScreen.goTo…`：分析頁卡在載入中時，後者會先以導覽 helper 逾時失敗。
- 切換分頁迴圈與離開發起讀取兩組案例中，訂單清單的取樣只要求失敗訊息存在、載入中不存在，不檢查重試鍵與空狀態：兩者屬訂單清單案例與 2.3，放進來會讓這兩組在修改前因別的原因紅，2.1 修正後也綠不了。2.3 完成後把 `Orders.listLoadFailureRetryButton` 加進這兩組的訂單清單取樣，補齊 spec 情境「keeps showing that message with a retry control」。

修改前實測 (2026-11-09，iPhone 17 iOS 26.5，`-test-iterations 3`)：

- 切換分頁迴圈 (`testTabSwitch_…三頁穩定顯示失敗畫面`)：3/3 失敗，都在訂單清單取樣「逾時，`orders.list.loadFailure` 在 10 秒內未出現」，失敗當下畫面為「載入訂單」(`orders.list.loading` 存在)，即卡在載入中。
- 離開發起讀取 (分析頁、客戶頁各一)：3/3 失敗，都停在前提步驟「啟動後訂單清單未顯示第一次延遲讀取失敗」(15 秒)，畫面同樣停在載入中。原因：啟動後立刻切到訂單分頁時，總覽本身就是等待 `finish()` 的發起者，它的讀取在切走時被取消，還輪不到分析頁或客戶頁。仍屬目標缺陷 (卡在載入中)，各頁的區分改由 2.1 的變異確認負責。
- 訂單清單 (`OrderListLoadFailureTests`)：3/3 失敗，同樣停在「訂單讀取失敗後清單未顯示載入失敗訊息」，畫面停在載入中，不是預期的「空狀態存在、找不到重試鍵」。紅燈原因被 2.1 的缺陷蓋住，所以 2.1 修正後、2.3 修改前再跑一次，取得空狀態與重試鍵的紅燈 (主對話代選)。2.1 修正後 (延遲 8 秒) 在 iPhone 17 失敗於「訂單載入失敗時仍顯示沒有符合的訂單空狀態」，即預期的紅燈。
- 同次 `DashboardLaunchLoadingTests` 3/3 通過。

2.1 修正後實測 (2026-11-09，延遲 8 秒)：

- iPhone 17 (iOS 26.5)：切換分頁迴圈與離開發起讀取三個案例通過；`DashboardLaunchLoadingTests`、`InsightsLaunchLoadingTests`、`CustomersTests` 不改預期通過；`SnapshotDashboardTests`、`SnapshotInsightsTests`、`SnapshotCustomersTests` 不重錄通過。
- iPad Air 11-inch (M4) (iPadOS 27.0)：先單獨跑 `KeyboardDismissTests` 通過，再跑上述 UI 類別加 `OrderListLoadFailureTests`、`OrdersListTests` 全部通過 (`OrdersListTests` 三條只適用窄版的 `testCloseSearch_…` 依版面宣告略過)。
- 變異確認 (iPhone 17，`LoadFailureReloadLoopTests`，跑完以修正版覆蓋並逐位元組比對還原)：只還原分析頁 → 只有離開分析頁案例失敗，失敗在離開後「`orders.list.loadFailure` 10 秒內未出現」；只還原總覽 → 三個案例全部失敗 (切換分頁迴圈在訂單清單取樣逾時，兩個離開案例在啟動後第一次失敗未出現)；只還原客戶頁 → 只有離開客戶頁案例失敗，失敗位置同分析頁。
- 2.3 完成後，三個案例的訂單清單取樣已加入 `Orders.listLoadFailureRetryButton`，iPad 上述執行即含此條件並通過。

`_printChanges(.actionLabels)` 暫時觀察 (iPhone 17，`-BLUITestLoadFailure orders`，觀察後已還原)：

- 啟動後停在總覽：啟動讀取失敗後 12 秒內沒有再收到 `dashboard(.view(.task))`，總覽在前景時沒有看到迴圈。
- 依「訂單 → 更多 → 訂單」切換：第二次回到訂單時訂單清單發起新讀取，總覽此時是隱藏分頁，卻隨載入狀態互換連續收到 3 次 `dashboard(.view(.task))`；其中由它發起的那次讀取沒有收到 `loadResponse`，之後每次請求都在 `orders(.load(.loadRequested))` 被去重擋下，切回總覽與分析也一樣，所有畫面停在載入中。兩條機制都有出現：分支互換讓隱藏分頁的 `.task` 重跑，重跑又取消了前一次發起的共用讀取。

### 取消機制以 TestStore 固定為確定性證據

新增 `apps/ios/BuyLedgerTests/Features/App/RootFeatureLoadCancellationTests.swift`：讓 `fetchOrders` 停在可控的 continuation，`send(.insights(.view(.task)))` 取得 task 後 `cancel()`，斷言 `OrdersLoadFeature` 的 `isLoading` 維持 `true`，下一次 `refresh` 不再發起讀取。這條測試釘住的是 TCA 的取消語意 (不受 SwiftUI 時序影響)，說明為何觸發共用讀取的 `.task` 不能等待 `finish()`；doc comment 寫明它是特性測試，TCA 若改變行為會轉紅，屆時規則要重審。

實測紀錄 (2026-11-09)：iPhone 17 iOS 26.5 通過，取消後 `isLoading` 維持 `true`、第二次請求未發起讀取，TCA 這一半的前提成立。測試釘住的是第三方框架語意，沒有可變異的正式程式碼，不做變異確認 (主對話代選)。

### .task 等待 finish 的掃描守門

新增 `apps/ios/BuyLedgerTests/Guards/TaskFinishConventionScanTests.swift`，沿用 `BuyLedgerTests/Guards/Scanning/` 的掃描工具：`apps/ios/BuyLedger/Features/` 的 view 檔中，`.task` closure 內出現 `.finish()` 時，同一行或上一行必須有 `// task-finish-exempt: <理由>` (比照 `design-system-scan-exempt:`，理由不可空)。合成樣本涵蓋：沒有標記判違規、理由空白判違規、有理由判合法、`.task` 內只送出判合法。既有 7 個保留 `finish()` 的 view 逐一寫明理由 (例如 AI 摘要串流隨畫面取消、`RootView` 為已知例外待後續 change)；寫不出合理理由的 (預期為匯率與報價) 理由寫成「已知風險，待後續 change」並列入「後續待辦」。

實作與實測紀錄 (2026-11-09)：7 個標記的分類：`AISummaryView` (串流只在畫面呈現期間執行)、`CampaignView` (提醒連結以成功後才設的 `hasLoadedLinks` 擋重讀，取消後重返會再讀)、`SettingsView` (幣別選項只供設定頁)、`LookupManagementView` (只讀本頁主檔種類，以 `hasLoaded` 擋重讀，不經共用目錄的載入旗標) 屬合理豁免；`RootView`、`FxView`、`QuoteView` 寫成「已知風險，待後續 change」，三者已在「後續待辦」。`LookupManagementView` 原由 codex 標成已知風險，主對話讀 `LookupManagementFeature` 確認它沒有只由回應清除的載入中旗標後改寫為合理豁免 (主對話代選)。守門與合成樣本 8 條在 iPhone 17 通過；變異確認刪掉 `FxView` 的標記時 repo 掃描轉紅並列出 `BuyLedger/Features/FX/Presentation/Root/FxView.swift:48`，還原後逐位元組比對一致。

### 規則寫進 ios-navigation.md

把 `.claude/rules/ios-navigation.md` 現有兩處相關條目 (「根導覽與啟動」下「清單的 `.task` 只呼叫 `store.send(.view(.task))`，不等待 `finish()`」，以及 sheet 段「需要隨畫面取消的長效 effect 改由 reducer 以 cancel id 管理」) 合併成一條獨立主 bullet，依決策寫：

1. `.task` 掛在 body 根為單一、非條件容器的 view 上；不掛在 `Group`、`switch`、`if` 內容上 (包括 body 是條件內容的自訂 View)，否則分支互換會重跑 `.task`。
2. 結果要給其他畫面用、或必須比畫面活得久的工作，只送出不等待。
3. 只該在畫面存在時執行的工作，才等待 `finish()` 或由 reducer 以 cancel id 管理，並加 `// task-finish-exempt: <理由>`。
4. 以「只由回應清除的載入中旗標」去重的載入器，不可在會被取消的 `.task` 底下發起：一次被取消的回應會讓它永久卡住。
5. 已知例外：`RootView` 根層 `.task` (待後續 change)。

sheet 段原條目若仍需保留其情境說明 (容器直接設定 `destination` 呈現的 sheet)，只留情境、改指向新主 bullet。

### 後續待辦

以下不在本 change 處理，archive 前開成後續項目 (主對話代選)；已記在 repo 外的工作順序紀錄，不另開 change 或 issue (使用者決定)：

- **`RootView` 根層 `.task`**：`mainContent` 是 `Group` 包 `if appLock.isLocked`，鎖定與解鎖互換時根層 `.task` 重跑並取消前一次，整條啟動鏈 (主檔 → 訂單、開團、幣別) 都掛在它底下。開啟 App 鎖的使用者冷啟動時若 Face ID 在啟動讀取完成前通過，回應可能全部遺失，主檔卡住後所有訂單載入與重試都不會再發生 (推論，正式路徑可能發生)。不能直接套本 change 的修法：根層 `.task` 現在隱性地在每次解鎖時重試失敗的載入、重新整理幣別、重啟時間監聽，`RootLaunchOperations` 的時間監聽沒有 cancel id。方向：`.task` 移到不隨鎖定換分支的容器並保留 `finish()`、時間監聽補 cancel id、解鎖時要不要重試改由 reducer 明確決定；驗證可沿用 `ordersDelayed` 加生物辨識延遲替身。
- **匯率與報價頁**：`FxView`、`QuoteView` 等待 `finish()`，網路讀取中切走可能讓各自的 `isLoading` 卡住、切回時被去重擋下 (推論，局部影響)。
- **客戶頁載入狀態**：`CustomersFeature` 沒有載入狀態，訂單載入失敗或載入中時顯示「尚無客戶」，與本 requirement 第一句不符。
- **載入器自我恢復**：三個載入器的正確性仍建立在「所有發起者都不在可取消的等待中送出」這個慣例上；可選方向是改成 `.cancellable(id:, cancelInFlight: true)` 並只以 `hasLoaded` 去重 (代價是同時請求會重啟讀取、錯誤訊息閃爍)。觸發條件：`RootView` 後續 change 無法讓根層發起端不可取消，或出現第三個會被取消的發起者。
- **訂單清單的 `isLoading` 投影**：2.3 後兩個清單 view 改由 `loadState` 推導，`OrderListFeature.State.isLoading` 已沒有畫面讀取，只剩 `OrdersFeature` 建立時傳入與 `OrdersFeatureListRequestsTests` 引用；可連同建立處與測試一起移除 (主對話代選列入)。
- **由 Root 負責「分頁出現就載入」**：新增依共用資料的根分頁目前要同時做到穩定容器、不等待、經 Root 路由、投影 `loadState` 與就緒判斷；可改由 `RootFeature` 在 `view(.tabSelected)` 與啟動時送載入請求。觸發條件：再新增一個依共用資料的根分頁，或同類缺陷再出現。

### 驗收實測 (3.1)

2026-11-09，iPhone 17 (iOS 26.5) 模擬器，`-BLUITestLoadFailure orders` 啟動，以 `mobilebuildmcp ui-automation` 依 proposal 的重現步驟切換「訂單 → 更多 → 訂單 → 總覽 → 分析」：

- 訂單清單每次回到前景都顯示 `orders.list.loadFailure` 與 `orders.list.loadFailure.retryButton`，沒有 `orders.list.loading` 也沒有 `orders.list.emptyState`；截圖為篩選列下方的紅字失敗訊息與「重試」，沒有「沒有符合條件的訂單」。
- 總覽與分析各自顯示失敗畫面與重試鍵，切換後 3 秒再取樣仍相同。
- 訂單清單、分析、總覽各按一次重試後，連續 4 至 6 次取樣都回到失敗畫面與重試鍵，沒有自動重試或停在載入中 (立即失敗的情境看不到載入中；重試會先顯示載入中由 `OrderListLoadFailureTests` 以延遲失敗情境驗證)。
- 完整單元回歸 (iPhone 17 iOS 26.5)：2049 條，2046 通過、0 失敗、3 條既有的預期失敗 (known issue)，snapshot 未重錄。

### 審查紀錄 (3.2)

2026-11-09，審查者依當下 `hc ls` 選審查用終端 t17 (未參與實作)，唯讀審查全部 27 個變更檔並逐檔逐條做 style 閘門；主對話同步審查架構、正確性、測試與風格。審查前後比對 32 個工作樹檔案的雜湊一致。

- 功能面：沒有發現載入流程的正確性回歸；7 個豁免理由與各 Feature 的 `view(.task)` 實際行為相符；`RootFeatureLoadCancellationTests` 經真實 action 鏈啟動讀取，不是恆真。
- 守門 (t17 發現)：F-01 字串內的 marker 會被當成豁免 (偽陰性)，改為只從真正的 `//` 行註解取理由；F-02 enum 比較式 `if work == .task {` 會被當成 modifier (偽陽性)，改為 `.task` 必須是該行第一個 token，或同一行緊接在 `)`、`}`、`]` 之後 (依 kit「modifier 一行一個」)。兩者各補合成反例，含 `Work.task` 寫法。
- style 閘門 11 項 (3 項 Blocker：失敗列 body 未抽 Private Views、重試鍵命中區缺最小寬度、守門測試缺 `- Throws:`)，依「改到的檔整檔對齊」連同改到檔案內的既有違規一起修：modifier 四組順序、未達條件的換行、trailing closure、成員依首次呼叫排序、清單與分析頁補齊各載入狀態的具名 Preview、取樣 helper 的巢狀型別與功能區名、UI 測試覆寫檔的功能區名等。
- 取捨與決策來源：審查結論全部採納 (主對話)；修正依原實作者分派 (sonnet、codex-luna、haiku，取樣 helper 由主對話)；主對話另把 regular 清單的 `contentMargins` 順序與 compact 對齊、私有區名定為 `UI Test Override Steps`、移除分析頁新預覽多餘的 `return`、`#expect(isLoading)` 改為直接斷言。t17 複核確認 S-01 至 S-11 與 F-01 已修正，F-02 剩完整型別名的同類反例，由主對話依上述規則修正並以反例測試驗證，不再開下一輪審查。
- 修正後驗證：完整單元回歸 2052 條 0 失敗 (3 條既有預期失敗)，snapshot 未重錄；守門 11 條通過，刪掉 `FxView` 標記時轉紅後還原。

### 完整回歸 (3.3)

2026-11-09，審查修正後的工作樹，回歸期間未改原始碼，前後 `git status` 一致 (沒有建置副作用)：

- 完整單元回歸 (iPhone 17 iOS 26.5)：2052 條，2049 通過、0 失敗、3 條既有預期失敗，snapshot 未重錄。
- 完整 UI 回歸 iPhone 17 (排除 `LaunchPerformanceTests`)：246 條，196 通過、0 失敗、49 略過 (只在 regular 版面成立的案例)、1 條既有預期失敗 (`NavigationScenarioUITests` 的 App 鎖定診斷案例，以 `XCTExpectFailure` 固定)。
- iPad Air 11-inch (M4) iPadOS 27.0 全跑：預跑 `KeyboardDismissTests` 2 條有 1 條失敗，回歸腳本沒有因此停下 (流程缺口，之後預跑失敗時應先修環境再全跑)。全跑 246 條，180 通過、41 失敗、24 略過、1 條預期失敗。41 條全在鍵盤輸入類別，訊息只有「數字鍵盤或 Popover 未能收起 (呈現方式：浮動數字面板)」27 條與「點欄位左側後，未取得鍵盤焦點或鍵盤與數字 Popover 框線未穩定」14 條，即 `ios-ui-tests.md` 記載的硬體鍵盤狀態症狀。
- 環境判定與復原 (主對話)：該台 Safari 網址列取得焦點後沒有軟體鍵盤；`toggle-connect-hardware-keyboard` 回報已送出但無效；Device Hub 的 Simulate Hardware Keyboard 顯示未勾，先勾上再取消後 Safari 出現軟體鍵盤，`KeyboardDismissTests` 2 條通過。進入硬體鍵盤狀態的原因未查。
- 重跑有失敗的 9 個類別整類 (`EditorTextInputFocusUITests`、`FxTests`、`OrderCreateTests`、`OrderEditInputFocusUITests`、`QuoteInputFocusUITests`、`QuoteTests`、`SearchInputFocusUITests`、`SettingsGoalInputTests`、`ToolsInputFocusUITests`)：53 條，49 通過、1 條依設計略過 (費率再次點左側，iPad 數字 Popover)、3 條 `OrderEditInputFocusUITests` 單條超過 10 分鐘逾時且逾時前沒有斷言失敗；三條各單獨重跑一次都通過 (63、51、285 秒)。
- iPad 合併結果：0 失敗，220 通過、25 略過 (只在 compact 版面成立的案例，加上 1 條 iPad 數字 Popover)、1 條既有預期失敗。鍵盤類別以外的 191 條沿用全跑結果，因為硬體鍵盤狀態只影響軟體鍵盤輸入。
- 三個新 UI 測試檔在兩台都通過：`LoadFailureReloadLoopTests` 3 條、`OrderListLoadFailureTests` 1 條、`CampaignListLoadFailureLoopTests` 1 條。

### 驗證與審查 (verify／review)

2026-11-09，`/spectra-verify` 與 `/spectra-review` 都沒有 Critical，也沒有擋住封存的問題。

- verify 警告：「後續待辦」尚未開成後續項目；修改後的 requirement 仍有已知不符 (客戶頁失敗只顯示「尚無客戶」、`RootView`、`FxView`、`QuoteView` 等待 `finish()`)，已列在 Non-Goals 與後續待辦。使用者決定把 6 項後續待辦記在 repo 外的工作順序紀錄，不另開 change 或 issue，上述不符由其中前三項負責。
- 使用者選定修正 4 項建議：
  - review：`ios-navigation.md` 的理由原本把 `switch`、`if` 也寫成「修飾器會分給各分支」，與本 design 的官方依據 (只有 `Group` 有保證) 及開團清單的修改前實測矛盾；規則不變，理由改為 `Group` 有官方說明、其他條件內容沒有保證而比照處理。
  - verify：proposal 的新檔清單補上 `XCTestCase+LoadStateSampling.swift`。
  - verify：`LoadFailureReloadLoopTests` 三個案例最後一步的 `guard … else { return }` 改成直接呼叫 (helper 有 `@discardableResult`，失敗時已先記錄失敗)。
  - verify：`RootFeatureLoadCancellationTests` 的 `release` 改名 `neverReleased` 並註明讀取只在 effect 被取消時結束。
- 未採納 (主對話)：verify 提到訂單清單「重試後成功」沒有端到端 UI 測試；重試鍵接線、狀態推導與成功後的內容狀態已分別有測試，不算缺口，不加。
- 修正後驗證：`RootFeatureLoadCancellationTests` 1 條通過 (iPhone 17)；`LoadFailureReloadLoopTests` iPhone 17 與 iPad Air 各 3 條通過。style 閘門交給未參與修正的審查用終端 t17，4 處逐條檢查全部通過，審查前後 32 個變更檔雜湊一致。

## Implementation Contract

**行為**：讀取持續失敗時，切換分頁只讓出現的畫面各送一次載入請求，畫面在載入中與失敗之間切換不再送新請求，失敗畫面、訊息與重試鍵保持顯示。共用訂單讀取進行中離開發起它的畫面 (分析、總覽、客戶頁)，結果仍送達並更新所有畫面。訂單清單失敗時只顯示失敗列與重試鍵，不顯示空狀態，按重試重新讀取一次。開團清單同樣不因載入狀態互換重送請求。

**介面**：不改任何 Feature 的 State、Action 或 delegate。新增 `OrdersListLoadFailureRow` view；`BLAccessibilityID.Orders.listLoadFailure`、`listLoading`、`listLoadFailureRetryButton`；`BLAccessibilityID.Insights.loading`、`loadFailure`、`loadFailureRetryButton`；`BLUITestLoadFailure.ordersDelayed` 與 `LaunchOptions.LoadFailure.ordersDelayed`；原始碼標記 `// task-finish-exempt: <理由>`。

**失敗模式**：切換分頁迴圈或離開發起讀取的案例修改前時好時壞或通過時，停下回報使用者，不放寬斷言。訂單清單改由載入狀態推導後，既有 snapshot 若改變，停下請使用者裁決。延遲失敗替身被取消時仍回傳同樣的讀取失敗。

**驗收**：

- 兩組訂單重現案例修改前在 iPhone 17 連跑 3 次都因目標缺陷失敗；修改後所有新案例在 iPhone 17 (iOS 26.5) 與 iPad Air 11-inch (M4) (iPadOS 27.0) 通過，選擇性執行確認實際執行數大於 0。
- 只還原分析頁、總覽或客戶頁其中一處的舊 `.task` 時，對應案例失敗 (主對話變異確認後還原)。
- `RootFeatureLoadCancellationTests` 通過；`TaskFinishConventionScanTests` 在 repo 上通過、合成樣本判讀正確，刪掉任一既有豁免標記時轉紅。
- `DashboardLaunchLoadingTests`、`InsightsLaunchLoadingTests`、`CampaignFlowTests`、`CustomersTests` 等既有測試不改預期即通過；完整單元與完整 UI 回歸 0 失敗，既有 snapshot 不重錄。
- 以 `mobilebuildmcp ui-automation` 依 proposal 的重現步驟實測，訂單清單顯示失敗訊息與重試鍵、沒有空狀態。

**範圍**：

- 範圍內：`DashboardView`、`InsightsView`、`CustomersView`、`CampaignListView` 的 `.task`；`OrdersCompactListView`、`OrdersRegularListColumn` 與新 `OrdersListLoadFailureRow`；`BLAccessibilityID+Orders`、`BLAccessibilityID+Insights`；UI 測試替身與 `LaunchOptions` 的延遲失敗情境；`RootNavigationScreen`；三個新 UI 測試檔、`RootFeatureLoadCancellationTests`、`TaskFinishConventionScanTests`；7 個保留 `finish()` 的 view 的豁免註解；`.claude/rules/ios-navigation.md`。
- 範圍外：見 Non-Goals 與「後續待辦」。

## Risks / Trade-offs

- [`.task` 移動後，iPad 寬版的分頁或側邊欄切換可能改變它的出現時機] → 所有案例與既有載入測試都在 iPad Air 跑；完整 UI 回歸在 3.3。
- [UI 取樣對一閃即過的迴圈不可靠，持續迴圈時查詢也可能等閒置而逾時] → 先等失敗第一次出現再取樣、紅燈記錄失敗型態；造成問題的寫法另由掃描守門擋下。
- [延遲時間太短，離開畫面的時間窗不夠] → 切走後立刻斷言仍在載入中，證明時間窗存在；初始估計 3 秒，依實測調整並記錄。
- [`RootFeatureLoadCancellationTests` 釘住的是框架語意] → doc comment 寫明是特性測試，TCA 改變行為時轉紅並重審規則。
- [訂單清單改由載入狀態推導，可能改變尚未載入時的畫面] → 既有 snapshot 變化時停下請使用者裁決。
