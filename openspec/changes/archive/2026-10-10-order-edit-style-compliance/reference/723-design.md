# 7.23 Root 子 Feature 設計

Haiku 唯讀提案 (2026-10-09)，主對話審查後採用。第五節待決事項的裁決：

- **D1**：採候選 A，新增無 View 的 `RootLaunchFeature` 承接啟動幣別載入與重大時間變更監聽。
- **D2**：`RootFeature` 估計 297 行，實作後以 `style_checks.py` 實測；超過 300 才加採 E2 (`refreshDateContexts` 併入 `RootNavigationOperations`)。
- **D3**：`@Shared(.currencyCodes)` 由子層宣告 (keyed shared，key 不變)。
- **D4**：時間變更多一個 delegate action，行為語意不變，接受。
- **D5**：既有 Root 測試 1:1 改路徑、`receiveLaunchLoadRequests` 改為五筆，子層另補字面值測試。
- **D6**：文件同步併入 7.21；`design.md` 的檔案位置與拆檔表已改指 7.23。
- **D7**：`OSLog`、`Foundation` 是否可移除由 build 判定 (7.21)。
- **次序**：與 7.16、7.22 共用 `RootFeatureTests` 系列，排在兩者之後實作。


派工單：scratchpad/r71/723-design-task.md
基準副本：scratchpad/haiku723/repo (主 worktree 副本，唯讀；本設計未修改任何檔案，未 build、未 test、未碰模擬器)
行數口徑：style_checks.py LEN (不含前 7 行檔頭與空行的非空行數)。標「實測」者為 style_checks 量得；標「估計」者為依草稿或結構推算，實作後須以 style_checks 重測。
TCA：1.26.2 (專案 Package.resolved 與 DerivedData checkout 的 revision 377da40 一致)，執行次序以 checkout 原始碼確認。

一、結論

1. 推薦候選 A：新增無 View 子 Feature RootLaunchFeature，承接「啟動時幣別快取載入」與「系統重大時間變更監聽」。Root 的 view(.task) 改送 .launch(.loadRequested)；時間變更以子層 delegate 回到 Root，由 Root 既有的 refreshDateContexts 重寫日期脈絡。RootLaunchOperations 保留，擴充為啟動 effect 的唯一出口。
2. 行數：RootFeature.swift 實測 312，候選 A 估計 297 (餘 3 行)；RootLaunchFeature.swift (新檔) 估計 71；RootLaunchOperations.swift 實測 25，估計 43。三檔皆不超過 300。
3. 測試：既有 Root 測試 1:1 路徑改寫 23 行、6 檔；RootFeatureTests+Fixtures.swift 的啟動助手 +3 行；新增 RootLaunchFeatureTests.swift，5 條字面值測試 (估計約 110 行)。
4. 其餘候選：B (只抽幣別) 估計 Root 306，不達標；C (跨分頁投影同步) 與 D (跨分頁導覽轉送) 無法獨立成子 Feature，helper 化幾乎不減行數，不採；E 為不新增子 Feature 的其他手段，E2 可作為餘量選項。
5. 主要 TCA 風險是「多一跳」：啟動 effect 晚一個 action 開始，時間變更多一個 delegate action。onChange 投影鏈、CombineReducers 次序、uuid() 與 date.now 的消耗次序皆不變；StoreTask 的 finish 與取消語意不變 (見三之 A-7)。
6. 待主對話決定的事項見七。

二、現況與約束

(一) RootFeature.swift 實測 312 行，超過 300。非空行分段如下：
- 檔頭、import 與型別宣告 (L8-L14)：6
- State (L16-L83，含 init)：56
- Action (L85-L155)：56
- Dependencies (L157-L172)：11
- Body (L174-L246，含 CombineReducers 與尾端五個 onChange)：66；其中 onChange 鏈 (L208-L245) 38
- core 與 Private Method (L249-L385)：107；其中 core 內的跨分頁轉送 case (L301-L369) 51
- refreshDateContexts (L387-L394)：8
- 兩個結尾括號 (L247、L395)：2

(二) 決定切法的約束
1. 投影寫入只能在 RootFeature.swift。ProjectionWriteBoundaryTests 以 rootFeatureRelativePath 豁免該檔；其他檔寫入 state.<根鍵>.<投影屬性>，或寫 $orders.withLock，都會判違規 (ProjectionWriteBoundaryTests+RootProjections 的 RootNavigationOperations 案例即此)。design.md:175 與拆檔表 L255 也規定投影寫入留在 RootFeature.swift。
2. 投影的 onChange 留在 RootFeature.body 尾端 (apps/ios/CLAUDE.md:76)。
3. 子 Feature 的 reducer 只能讀寫自己的 State，碰不到兄弟 State 或 selectedTab。跨 feature 意圖以 delegate 交給 Root，由 Root 的 core 處理，不以 .send 轉成另一個根 case (apps/ios/CLAUDE.md:80)。
4. 父層不攔截子層的 view action；父層要求子層載入時送專用請求 action (apps/ios/CLAUDE.md:77-78)。
5. RootFeature.State.currencyCodes 是 @Shared(.currencyCodes) (記憶體內 key)，只由 Root 寫入。OrdersFeature.swift:31 以 @SharedReader(.currencyCodes) 讀同一 key，與寫入者位置無關。
6. .currencyCodesResponse 與 .significantTimeChanged 不被任何 View 送出，只有 RootLaunchOperations 與測試使用。RootView.swift:65-66 只送 .view(.task)，形式為 .task { await store.send(.view(.task)).finish() }。

三、候選切法

候選 A (推薦)：RootLaunchFeature (啟動幣別快取與重大時間監聽)

A-1 子 Feature 的 State、Action、Delegate
- 無 View，不設 view 分組 (apps/ios/CLAUDE.md:82)。
- State：@Shared(.currencyCodes) var currencyCodes: [CurrencyCode]。與現行 Root 的宣告相同，無其他欄位。
- Action：
  - loadRequested：Root 的 view(.task) 轉送來的載入請求，屬於請求 action (apps/ios/CLAUDE.md:78)。
  - currencyCodesResponse(Result<[CurrencyCode], CurrencyMetadataServiceError>)：內部回應，保留具體錯誤型別 (7.1 第二輪裁決 2)。
  - delegate(Delegate)
- Delegate (@CasePathable、Equatable)：significantTimeChanged，通知 Root 重寫日期脈絡。
- Dependencies：currencyMetadataService、significantTimeChangeService (自 Root 搬來)。
- body：Reduce(core)，無子層。

A-2 子 Feature core 的 case 清單 (依 Action 宣告次序；每個 case 皆不超過十行，不需抽方法)
1. loadRequested：RootLaunchOperations(service:timeChangeService:).start()
2. currencyCodesResponse(.success(codes)) where !codes.isEmpty：寫入 $currencyCodes，回傳 .none
3. currencyCodesResponse：保留原清單，記錄既有的警告文字，回傳 .none
4. delegate：回傳 .none

A-3 父層 RootFeature 的改法
- body：在 CombineReducers 內，Scope(appLock) 之後新增 Scope(state: \.launch, action: \.launch) { RootLaunchFeature() }。其餘次序、Reduce(core).ifLet(\.$persistenceFailure, ...)、尾端五個 onChange 完全不動。
- State：刪除 currencyCodes (2 行)；新增 var launch = RootLaunchFeature.State()，含 1 行文件註解。
- Action：刪除 currencyCodesResponse 與 significantTimeChanged；新增 case launch(RootLaunchFeature.Action)，置於 orders 之後，與 core 次序一致。
- Dependencies：刪除 currencyMetadataService 與 significantTimeChangeService。date、uuid、calendar 不變。
- import：AppLogger 移出後 OSLog 無用，刪除。Foundation 保留，以 build 判定。
- core：
    case .view(.task):
        return .merge(
            .send(.campaigns(.loadRequested)),
            .send(.orders(.loadRequested)),
            .send(.launch(.loadRequested))
        )
  刪除 currencyCodesResponse 的兩個 case 與 significantTimeChanged 的 case，於 orders 之後新增：
    case .launch(.delegate(.significantTimeChanged)):
        refreshDateContexts(state: &state)
        return .none

    case .launch:
        return .none
- refreshDateContexts(state:) 不動。它寫入兄弟 Feature，只能留在 Root。

A-4 RootLaunchOperations.swift (保留並擴充；比照 LookupItemOperations 的持有依賴值 struct 寫法)
- 新增依賴 timeChangeService: SignificantTimeChangeService。
- loadCurrencyCodes() 的回傳型別改為 Effect<RootLaunchFeature.Action>，內容不變。
- 新增 observeSignificantTimeChanges()：.run { for await _ in timeChangeService.changes() { await send(.delegate(.significantTimeChanged)) } }。
- 新增 start()：.merge(loadCurrencyCodes(), observeSignificantTimeChanges())。

A-5 各檔行數 (LEN 口徑)
- RootFeature.swift：現況 312 (實測)，候選 A 297 (估計)。估計的變化量為 Action -2、Dependencies -4、Body +3、.view(.task) -5、core -6、import -1、State 0，合計 -15。
- RootLaunchFeature.swift (新)：估計 71 (依草稿計數)。
- RootLaunchOperations.swift：現況 25 (實測)，估計 43 (依草稿計數)。
- RootFeatureTests+Fixtures.swift：現況 226 (實測)，估計 229 (助手 +3 行)。
- 其餘 6 個 Root 測試檔為 1:1 替換，行數不變：RootFeatureTests 145、+CampaignLoading 138、+CurrencyCodes 212、+Foreground 147、+LoadRequests 271、+NewOrderOptions 275 (現況皆為實測)。
- RootLaunchFeatureTests.swift (新)：估計約 110。

A-6 測試影響 (grep 計數，列檔名與行號)
- 送出 Root view(.task) 的測試共 8 處：RootFeatureTests:143、+CampaignLoading:74、+CurrencyCodes:58/113/161/219、+Foreground:145、+LoadRequests:62。這 8 處都經 receiveLaunchLoadRequests 接收 (呼叫點 RootFeatureTests:146、+CampaignLoading:82、+CurrencyCodes:61/116/164/222、+Foreground:148、+LoadRequests:65；定義於 +Fixtures:20)。
- 助手改動：+Fixtures:21 的 for _ in 0..<4 改為 0..<5；判斷式加入 .launch(.loadRequested) (3 行)；+Fixtures:17 的文件註解「共四筆」改為「共五筆」。
- receive(\.currencyCodesResponse...) 共 8 行，改為 \.launch.currencyCodesResponse...：RootFeatureTests:148、+CampaignLoading:117、+CurrencyCodes:63/118/166/224、+Foreground:150、+LoadRequests:67。
- receive(\.significantTimeChanged) 共 1 行，改為 \.launch.delegate.significantTimeChanged：+Foreground:153。
- 根層 currencyCodes 讀寫共 14 行，改為 launch.currencyCodes：+CurrencyCodes 9 行 (64、69、86、120、132、168、187、225、230)，+NewOrderOptions 5 行 (75、136、151、179、283)。
- 依賴覆寫不需改，因為鍵不變：$0.currencyMetadataService 共 16 行、$0.significantTimeChangeService 共 8 行。
- 不受影響：ProjectionWriteBoundaryTests (不含 currencyCodes，Root 投影不變)、ActionGroupingScanTests (未引用 RootFeature)、LayerBoundaryTests (StoreOf<RootFeature> 只由三個根導覽宿主持有)、SnapshotTests (未引用 RootFeature)。
- 合計：1:1 替換 23 行 (6 檔)，助手 +3 行 (+Fixtures)，新增 1 檔。

A-7 TCA 執行次序風險與驗證 (以 TCA 1.26.2 checkout 原始碼確認，未 build)
原始碼依據：
- _OnChangeReducer._reduce (Reducer/Reducers/OnChange.swift L128-L131)：先執行 base，也就是整個 CombineReducers (含子層與 core)，之後才比較新舊值並執行 closure。
- _Sequence._reduce (Reducer/ReducerBuilder.swift L115-L117)：依序執行 r0 與 r1，再合併 effect。
- IfLetReducer._reduce (Reducer/Reducers/IfLetReducer.swift L156-L161)：子先父後。persistenceFailure 的 ifLet 行為不變。
- Effect.send (Effect.swift L147-L149) 為 .publisher(Just(action))。Core.send 把巢狀 send 回傳的 Task 收進外層的 tasks (Core.swift L137-L140、L184-L187)；外層 Task 等待這些 Task，並在取消時連帶取消 (L201-L215)。因此 StoreTask.finish() 與取消語意不因多一層 send 而改變。
- TCA 文件未明寫 Scope 與父 core 的先後。本設計不依賴該先後，子層只作用於自己的 action。

風險與驗證：
R1 啟動 effect 晚一個 action 開始。.send(.launch(.loadRequested)) 取代了原本直接在 merge 內啟動的 .run。狀態語意不變。風險是 TestStore 需接收第五個 action，已由助手吸收。驗證：8 條送 Root view(.task) 的測試通過；變異見六之 M7。
R2 時間變更多一跳。子層的 .run 送出 .delegate，子層 reducer 回傳 .none，Root core 在同一個 action 內執行 refreshDateContexts。date.now 每次變更仍讀一次，次序不變；此路徑不呼叫 uuid()。驗證：task_停在前景跨日_開團日期脈絡改為新的一天 通過；變異見六之 M5、M6。
R3 onChange 投影鏈不變。onChange 在 base 之後比較 (OnChange L128-L131)。launch 子層的 currencyCodes 不在任何 onChange 的觀察路徑上，那些路徑觀察的是 orders.orders、campaigns.campaigns、orders.loadState、preferences、appLock.biometryType。驗證：RootFeatureTests+SharedOrders、+DefaultCurrency、+AISummaryProjection、+LookupSync、+Cascade 與 ProjectionWriteBoundaryTests 通過。
R4 子層插入位置。Scope(launch) 置於 appLock 之後。.launch action 只由 launch 子層處理，對其他子層及 persistenceFailure 的 ifLet 次序無影響。驗證：RootFeatureTests+AppShell、+Sidebar、+DetailNavigation 通過。
R5 @Shared 搬遷。in-memory key 相同。子 State 的預設值與 RootFeature.State 的預設值在同一次 init 內建立，因此測試以 withDependencies { $0.defaultInMemoryStorage = InMemoryStorage() } 隔離 State 的寫法不變。驗證：RootFeatureTests+NewOrderOptions 的參數化測試 orders_共用幣別清單非空或為空_帶入快取或常用幣別，以及 +CurrencyCodes 的四條測試通過。
R6 TestStore 窮舉。三個新 action 都必須 receive，不得關閉 exhaustivity (TestSuiteIntegrityTests)。
R7 生命週期與去重。不新增 CancelID，沿用現況。loadRequested 不去重，與現行 view(.task) 相同。巢狀 send 的 Task 被收進外層，finish 與取消語意不變 (見 A-7 原始碼依據)。
R8 UI。DashboardLaunchLoadingTests 等啟動相關 UI 測試，需由主對話於 iPhone 17 執行。

候選 B (只抽幣別，時間監聽留在 Root)
- 子層：State 與 Action 同 A，但沒有 Delegate，只依賴 currencyMetadataService。
- Root：保留 .run 監聽與 significantTimeChanged。.view(.task) 只把 RootLaunchOperations(...).loadCurrencyCodes() 換成 .send(.launch(.loadRequested))。
- 行數估計：Root 312 變為 306 (Dependencies -2、Body +3、core -6、import -1，其餘 0)。仍超過 300；加上 E2 才可能約 298。
- 測試影響：與 A 相同的 1:1 改寫 22 行 (8 行 currencyCodesResponse 的 receive、14 行根層 currency 讀寫，分佈於 RootFeatureTests、+CampaignLoading、+CurrencyCodes、+Foreground、+LoadRequests、+NewOrderOptions 六檔)，助手 +3 行 (+Fixtures)；不改 +Foreground:153 的 significantTimeChanged。子層測試只需 4 條 (無時間測試)。
- 結論：不採。減行量只有 A 的 40% (-6 對 -15)，而且 Root 仍保留時間監聽與刷新分支。風險與 A 的 R1、R3 至 R6 相同，沒有 R2。

候選 C (跨分頁投影同步：RootFeature.body 尾端的五個 onChange，L208-L245，38 行)
- 不能獨立成子 Feature：子 reducer 無法寫兄弟 State；投影寫入只能在 RootFeature.swift (守門)；onChange 必須留在 body 尾端 (apps/ios/CLAUDE.md:76)。
- 改為同檔 private 方法：行數不減，方法簽章與文件註解反而增加。
- 五層 onChange 的巢狀次序與「base 之後才比較」是觀察語意。搬動會改變觀察點，風險高。
- 測試影響：無 (不改動)。若硬搬，RootFeatureTests 全系列與 ProjectionWriteBoundaryTests 都要重驗。
- 結論：不採，可減 0 行。

候選 D (跨分頁導覽轉送：Root core 內 campaigns、dashboard、insights、more、orders 的 delegate 分支，L301-L369，51 行)
- 不能獨立成子 Feature：這些 case 直接改 Root 的 selectedTab、orders、campaigns、more，子層拿不到這些 State。apps/ios/CLAUDE.md:80 規定跨 feature delegate 由 Root 的 core 處理。
- helper 化 (例如擴充 RootNavigationOperations)：每個 case 本體已只有 1 至 2 行，core 仍需逐一列出 case，估計變化 0 至 -4 行。RootNavigationOperations 也在投影守門的掃描範圍內，不能寫投影。
- 測試影響：若 helper 化，行為不變，RootFeatureTests 的路徑與斷言都不需改，但收益近零。
- 結論：不採。

候選 E (其他手段，不新增子 Feature)
- E1 把 RootFeature.State.init 移到 extension 檔。init 本體約 24 行，含投影初值寫入 (dashboard.monthlyProfitGoalTWD、orders.defaultCurrency、orders.aiSummarySettings)，違反 design.md:175「投影寫入留在 RootFeature.swift」。不採。
- E2 (餘量選項) 把 refreshDateContexts(state:) (8 行) 改由 RootNavigationOperations 承接。建構時帶入 referenceDate 與 calendar，呼叫端為 navigation.refreshDateContexts(state: &state)，date.now 讀取次數不變。Root 估計再減 8 行，A 之後約 289；RootNavigationOperations 由 53 增至約 61 (估計)。代價：該檔文件註解「處理跨功能導覽」需改寫為涵蓋跨功能操作。
- E3 父層持有 @Shared(.currencyCodes)，建立子 State 時以 Shared 傳入 (ios-dev-kit 的寫法)。Root 需保留 currencyCodes (+2 行) 並在 init 傳入 (+1 行)，估計約 300，零餘量。不採，除非主對話要求嚴格照 kit 寫法。

四、推薦理由
- A 是唯一能在不改守門、不改投影寫入位置的前提下，把 RootFeature 壓回 300 以內的切法，減行 -15。
- 子層是實質獨立的區塊：只依賴自己的服務與共用幣別 key，不寫任何兄弟 State。
- 對子層的介面不變。既有子層 action 不變，新增的 launch 只由 Root 的 view(.task) 與自身 delegate 使用，View 完全不受影響。
- 代價：TCA 多一次 action 與測試 receive；餘量只有 3 行 (估計)。

五、文件同步清單 (實作時一併處理，依根 CLAUDE.md 的文件同步鐵則)
1. apps/ios/CLAUDE.md:115：「Root 於 view(.task) 起監聽並送 significantTimeChanged」改為 RootLaunchFeature 由 .launch(.loadRequested) 起監聽，以 delegate 送回 Root 重寫日期脈絡。
2. apps/ios/CLAUDE.md:170：「Root 載入幣別快取，非空才寫入 .currencyCodes」改為由 RootLaunchFeature 載入。
3. .claude/rules/ios-data-layer.md:5 (paths frontmatter)：加入 "apps/ios/BuyLedger/Features/App/RootLaunch{Feature,Operations}.swift"，否則編輯子層時不會載入幣別規則。
4. .claude/rules/ios-data-layer.md:50：「Root 在 refreshIfStale 後讀一次 fetchCodes」改為 RootLaunchFeature (經 RootLaunchOperations)。
5. .claude/rules/ios-navigation.md:13：現文仍正確，可選擇補上 .launch(.loadRequested)。
6. apps/ios/README.md:38：App/ 目錄說明加入 RootLaunchFeature；RootLaunchOperations 的括號說明改為「幣別載入與時間監聽」。
7. apps/ios/README.md:255：「幣別快取載入到 @Shared(.currencyCodes)」補上 RootLaunchFeature。
8. design.md:175 與拆檔表 L255 已過時：它們寫「298」與「只把幣別載入 effect 移到 operations 檔」，但實測為 312，而且 7.1 第二輪裁決 5 已改為抽子 Feature。建議由主對話於 7.21 或設計修訂時更新。
9. openspec/specs 正文沒有這段描述，只有 @trace 區塊提及 RootFeature.swift，依規則不手改。因此不需要規格 delta。
10. apps/ios/CLAUDE.md:76、:78、:80 的規則文字仍成立，不需改寫。

六、驗證計畫 (實作後執行；本設計未執行任何 build 或 test)
- 語法 (實作者)：以 swiftc -parse 逐檔檢查 RootFeature.swift、RootLaunchFeature.swift、RootLaunchOperations.swift、RootLaunchFeatureTests.swift，以及 RootFeatureTests 系列的改動檔。
- 行數：style_checks.py 以明確清單執行，TOTAL 只含不計失敗的代碼；RootFeature.swift 與 RootLaunchFeature.swift 都不超過 300。
- 單元 (主對話)：RootFeatureTests 全系列、RootLaunchFeatureTests、ProjectionWriteBoundaryTests、ActionGroupingScanTests、LayerBoundaryTests、TestSuiteIntegrityTests，以及完整單元回歸。
- 新子層測試 (字面值；命名依 ios-dev-kit 三段式，第一段為子層 action)：
  - loadRequested_啟動載入_以七天期限刷新後讀取快取：TTL 為 604_800，回應為 success。
  - loadRequested_收到重大時間變更_送出時間變更委派：送出 delegate(.significantTimeChanged)。
  - currencyCodesResponse_成功且非空_寫入共用幣別清單：寫入 [.twd, .jpy, EUR]。
  - currencyCodesResponse_成功但為空_保留原共用清單：維持 [.usd]。
  - currencyCodesResponse_讀取失敗_保留原共用清單：維持 [.usd]。
  - 建立 State 時以 defaultInMemoryStorage 隔離；涉及時間的測試，currency 回應以 gate 延後，與既有寫法一致。
- 變異 (每條至少一個，確認轉紅)：
  - M1 拿掉 where !codes.isEmpty：currencyCodesResponse_成功但為空 應紅。
  - M2 拿掉 withLock 寫入：currencyCodesResponse_成功且非空 應紅。
  - M3 失敗分支改寫入 []：currencyCodesResponse_讀取失敗 應紅。
  - M4 TTL 604_800 改值：loadRequested_啟動載入 與 task_啟動根功能_以七天期限刷新幣別快取 應紅。
  - M5 start() 拿掉 observeSignificantTimeChanges()：loadRequested_收到重大時間變更 與 task_停在前景跨日_開團日期脈絡改為新的一天 應紅。
  - M6 Root 的 .launch(.delegate) 拿掉 refreshDateContexts：task_停在前景跨日_開團日期脈絡改為新的一天 應紅。
  - M7 Root 的 view(.task) 拿掉 .send(.launch(.loadRequested))：8 條 receiveLaunchLoadRequests 測試應紅。
- UI (iPhone 17，主對話)：DashboardLaunchLoadingTests、InsightsTests、CampaignFlowTests、OrdersListTests。版面不變，不需重錄 snapshot。

七、需要主對話決定的事項
- D1 (必決)：採用候選 A？
- D2 (必決)：餘量。A 估計 297 (餘 3 行)，是否接受？或加採 E2 (約 289)？
- D3 (必決)：幣別 @Shared 由子層宣告 (A)，或由父層宣告再傳入 (E3，約 300)？
- D4：時間變更多一跳 (子層 delegate 到 Root) 與多一個 action 是否接受？行為語意不變。
- D5：測試策略。建議既有 Root 測試路徑改寫 (23 行) 加上 5 條子層字面值測試；不建議把幣別相關的 Root 測試整組搬到 RootLaunchFeatureTests，改動較大。
- D6：第五節的文件同步是否併入 7.21？並修正 design.md:175 與 L255 的過時敘述。
- D7：import OSLog (Root 刪除、子層保留) 與 Root 的 Foundation 是否可移除，由 build 判定。

八、附註
- 派工單要求至少兩個候選：已評估 A 到 E。A 是唯一能獨立切出的子 Feature；B 是 A 的縮減版，不達標；C 與 D 因結構限制不可獨立；E 是非子 Feature 的手段。
- 所有估計值依草稿計數。實作後須以 style_checks.py 實測確認。
