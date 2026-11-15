## Context

- 2026-11-14 兩位審查者唯讀重掃 `apps/ios/BuyLedgerUITests` 113 檔 (Support 31、Screens 23、Tests 59)，依據 ios-dev-kit 4.2.4 與專案規則 (`.claude/rules/ios-ui-tests.md`、`apps/ios/CLAUDE.md`)；t17 負責 `Tests/**`，t1p 負責 `Screens/**` 與 `Support/**`。同日兩位再做提案審查 (t1p 架構、t17 正確性)，修正了下列幾個數字。以下為靜態閱讀與腳本掃描的結果，未經 build：
  - 回傳 `Bool` 的 helper 151 個：合規 53，不合規 98 (Screens／Support 92、Tests 6)；帶 `@discardableResult` 的 40 個。失敗處理有四種寫法：回傳 Void 且內部失敗、回傳 `Bool` 不失敗、回傳 `Bool` 又內部失敗、`throws` 加內部失敗；另有 `assert*` 內部失敗不丟錯、`is…Layout` 判不出來就失敗兩種。呼叫端因此有三種寫法，可能同一次失敗報兩次 (例：`LookupManagementScreen` 對已自行失敗的 `goToMore` 再呼叫一次 `failWithDiagnostics`；實際記成幾筆未實測，由任務 4.1 量測)。
  - 型別與檔名：46 個 `*Tests` 加 5 個 `*SmokeTests`，扣掉 2 個依 kit 保留的例外，共 49 個要改；另有 8 個 `*UITests`，其中 `OrderEditInputFocusUITests`、`QuoteInputFocusUITests` 已符合 `<Screen><行為>UITests`，其餘 6 個以行為命名。測試名稱第一段不是程式碼名稱的約 65 個。
  - Given／When／Then：Given 內以 `XCTAssert*` 驗前置 23 處、When 內 2 處；Then 夾帶動作 8 處；標記寫在 helper 內 1 處；多組 When／Then 39 個 (旅程 22、前提型 7、可拆型 10)。
  - 重複：Tests 內 18 組 (例：`openOrders` 8 份、3 種簽章)，Screens／Support 內 9 組 (例：返回鍵 5 種策略、`isFinite` 框線判斷分散在 9 檔共 34 處)。手寫 deadline 迴圈 Screens／Support 21 處、空期望等待 21 處，Tests 內另有空期望 4 處與 `RunLoop.run` 1 處；Tests 內 `pollUntil` 呼叫 63 處。
  - 無呼叫端：Screens 26 個、Support 14 個 (含 `ValueParsing.swift` 整檔與 `LaunchOptions.CalendarAccess.denied`)。
  - 規則與程式矛盾：`AppNavigator.rootTabElement(for:)` 在五個根分頁都查無 identifier 時依按鈕順序退回，規則檔寫「不依按鈕順序取值」，spec `ui-test-element-identity` 的 Tab bar 情境則允許。`sheetGrabber`、`assertAlertMessage`、`XCTestCase+PlatformScope` 的索引取樣不在受控例外清單；`InsightsScreen` 固定 8 次盲滑。
  - 測試檔裡以文字或位置定位的受控例外：導覽列標題 (`NavigationScenarioUITests`、`OrderRegularColumnScopeTests`、`OrdersNavigationSmokeTests`、`OrdersListTests`、`OrderRegularSearchBarTests`)、搜尋欄系統結束鈕 (`OrdersListTests` 3 處)、注音鍵與候選字及按鍵是否存在 (`OrderEditInputFocusUITests`)、依位置取搜尋欄 (`SearchInputFocusUITests`、`OrdersListTests`)、以位置點系統返回鍵 (`NavigationScenarioUITests`、`MoreNavigationSmokeTests`)。另有約 50 處直接查系統容器 (alert 是否呈現 14、鍵盤 8、視窗／分頁列／狀態列／導覽列框線約 26)。
  - 第二輪提案審查以 grep 估計 (多行寫法未計)：Tests 內在已有 Page Object 的畫面上直接以 identifier 查詢約 140 處 (Navigation 52、Orders 48、Campaigns 10、More 6、Dashboard 6、其餘 18)；直接呼叫 `goTo*` 123 處、`selectTab(` 20 處；直接呼叫 `failWithDiagnostics(` Support 43 處、Screens 82 處、Tests 43 檔 307 處 (多數為 `if !條件 { failWithDiagnostics(...) }`)；Screens 自己的手寫等待約 20 處 (`OrdersScreen` 8、`RootNavigationScreen`、`LookupManagementScreen`、`OrderFilterSheetScreen`、`OptionPickerScreen` 各 3)；Tests 內有約 40 個本地導覽或前置 helper。
  - 其他：`OrientationLayoutTests` 三個測試的 Then 只附截圖、沒有斷言；外部型別 extension 檔的 MARK 有兩套寫法 (六區名 16 檔、功能名 4 檔)。
- App 端：付款方式管理列 (`LookupItemRow.classifiedRow`) 把分類徽章併進 `.accessibilityElement(children: .combine)`，訂單編輯幣別列 (`OrderEditStatusSection.currencyPickerRow`，本體是帶 identifier 的 `Button`) 只顯示 `CurrencyDisplayName` 文字。報價頁幣別按鈕 (`QuoteInputsCard`) 已以 `.accessibilityValue(currencyCode)` 帶出 ISO 代碼，`QuoteScreen.sourceCurrencyCode` 讀它。訂單詳情根 (`OrderDetailContentView`) 已以 `.accessibilityValue(Text(verbatim: order.id))` 帶出顯示中的訂單識別碼，`OrdersScreen` 的路徑投影讀它；種子訂單編號都在 15 字內，`displayID` 等於 `id`。
- `LookupNameEditorSheet` 的捨棄確認是自訂 SwiftUI `.alert`，按鈕沒有 identifier；`BLAccessibilityID.LookupManagement` 宣告在 `BLAccessibilityID+More.swift`。
- 延遲讀取：`DependencyValues+BLUITestOverrides` 對 `ordersDelayed` 與 `exchangeRatesDelayed` 各寫死 `Duration.seconds(8)`；UI 端 `ToolLoadTabSwitchTests.Timing.readDelay = 8`，`CustomersLoadStateTests.Timing` 的註解寫「涵蓋 8 秒讀取延遲」。`BLUITestConfiguration.value(for:in:)` 在旗標不存在時直接回 `nil`、不警告；只有缺值、後面接到其他旗標或值無效時才警告 (由 `BLUITestConfigurationInvalidValuesTests` 守住)。
- 預期失敗：`NavigationScenarioUITests` 唯一一條以嚴格 `XCTExpectFailure` 包住 `navigator.selectTab(.orders)`，預期它記錄失敗後繼續執行 Then (`BLUITestCase` 設了 `continueAfterFailure = false`)。
- 單元測試：`.claude/rules/ios-unit-tests.md` 已規定 Feature 測試一律用 `TestStore`、binding 測試送畫面實際送出的 action；`BuyLedgerTests/Features/` 有 15 檔 26 處 `Store(` (snapshot 測試除外)，其中 `OrdersFeatureMergePrefillTests`、`OrderEditFeaturePhotosTests` 經 `@Bindable` 與 `.scope` 驅動子 store。TCA 1.26.2 支援 `\.presentation.destination.edit.binding.draft` 這類路徑 (t17 對照 `PresentationReducer` 與 `BindingAction` 原始碼確認)。`TestSuiteIntegrityTests` 有三條守門，關閉窮舉檢查恆為 0 處；它的 `countMatches` 先刪整行註解再接回，只回傳計數。
- 執行順序：`BuyLedgerUITests.xctestplan` 依字母序執行，改名會整個重排順序；兩份 UI 測試計畫與 CI 只引用 `LaunchPerformanceTests`，改名不必修改它們。三個 target 資料夾都是同步資料夾，改名與新增檔不必改專案檔。
- 基準：`main` 上次兩平台完整 UI 回歸在 `ui-test-disable-view-animations` 任務 4.4 (2026-11-14：iPad 252 條跑 227 通過，其餘為版面 skip；iPhone 第一輪 22 條轉向失敗屬模擬器環境，重跑後 0 失敗)，之後 `main` 只多了版號 commit；本 change 以它當基準，改名前另由任務 4.7 在 iPad 重跑一次。

## Goals / Non-Goals

**Goals:**

- UI 測試會失敗的函式只有一種契約，同一次失敗只記錄一次，失敗位置指向測試裡的呼叫行。
- UI 測試型別、檔名與方法名依 kit；Given／When／Then 依 kit 與使用者 10/27 的旅程測試裁決。
- 每種共用操作的每種策略在 Support／Page Object 只有一份實作；進入畫面只經 Page Object；刪除無呼叫端的 helper。
- 規則檔、spec 與程式碼對受控例外的描述一致，例外都收在共用 helper。
- 「日圓」與「貨到付款」兩處改以 `accessibilityValue` 斷言；自訂 alert 按鈕以 identifier 定位；延遲讀取秒數只有一個來源。
- Feature 單元測試全部經 `TestStore`；`Store(`、UI 測試檔名與可丟棄的 `Bool` helper 由常駐的掃描守門擋住。

**Non-Goals:**

- 約 40 處以鎖定語言的顯示文字比對預期值維持現狀 (使用者 11/14 裁決)，只寫進規則檔。
- 其他以 `label CONTAINS` 比對使用者輸入資料的列 (`OrderEditAddOptionTests` 的來源與付款方式列、`AdaptiveNavigationContinuityUITests` 的篩選鈕) 不為它們新增 App 端的 value：比對的是使用者資料，不隨 App 語言變 (使用者 11/14 選定的推薦)。
- App 鎖定替身的 3 秒與 4 秒延遲 (`BLUITestStubs`) 不在本次單一來源範圍，已記到 roadmap 的未排序項 (主對話代選)。
- 字串型別的 ID 參數與對照表 (`InsightsScreen`、`OrderFilterSheetScreen`) 等到 App 端改名造成漏改再處理 (主對話代選，t1p 重掃觀察 11)。
- 移除 `AppNavigator` 的依順序退回：本 change 只量測它是否仍會發生 (主對話代選，見「規則與程式矛盾以 spec 為準修正」)。
- 「有 Page Object 的畫面一律經它」與「`goTo*` 只給根導覽測試」不做常駐守門，只在收尾以 grep 檢查；之後審查發現回流時再加掃描 (主對話代選)。
- 查系統容器是否存在與量框線 (alert、鍵盤、視窗、分頁列、狀態列、導覽列；導覽列標題仍經共用 helper) 不收進共用 helper，允許留在測試檔：它們不是 App 內容，也沒有以文字定位 (使用者 11/14 選定的推薦)。
- 「無呼叫端的 helper 要刪除」不做常駐守門：掃描要解析呼叫關係，成本高；改由 8.1 收尾時重掃一次 (主對話代選)。
- `LaunchPerformanceTests` 不改成經 `BLUITestCase.launch(_:)` 啟動：它量測正式冷啟動路徑，帶 `-BLUITest` 會改成量測 harness 路徑 (主對話代選)；在規則檔寫明例外。
- 不搬測試資料夾：拆出的類別留在原資料夾，`Tests/Forms/` 維持以輸入焦點為主題的分組 (主對話代選)。
- snapshot 測試的 `Store`、`RootFeature` 改名、只被呼叫一次的短 private helper 內聯 (roadmap 第 7、8 項) 不在範圍內。

## Decisions

### 動作 helper 失敗時附診斷並 throws

使用者 2026-11-14 裁決 (採主對話推薦)。Support 與 Page Object 中會讓測試失敗的函式 (點擊、捲動露出、取得焦點、切換分頁、收鍵盤、關閉 sheet、選單選項、轉向、進入畫面、`assert*` 斷言、版面判定) 在元素或條件於逾時內不成立時，記錄失敗並附截圖與可及性樹，再丟出錯誤讓測試停在該呼叫；不再以 `Bool` 表達成敗。下列細節為主對話代選，依兩份提案審查修正：

- 錯誤型別為 Support 頂層的 `enum UITestError: Error`，只有 `case stopped(message: String)` (kit：`<領域>Error`、case 帶除錯上下文)。現有的 `XCTestCase.UIAssertionError`、`OrdersScreen.InteractionError`、`XCUIApplication.NativeBackButtonError` 全部改成它，所有會丟錯的函式標 `throws(UITestError)`。
- `XCUIApplication.stopWithDiagnostics(_:file:line:) throws(UITestError) -> Never` 是唯一的丟錯出口；`requireCondition`／`requireValue` 改以它實作。每個會失敗的函式帶 `file: StaticString = #filePath, line: UInt = #line` 並往下傳，失敗位置指向測試的呼叫行。
- 記錄方式 (任務 4.1 量測，見「實作與驗證」)：`stopWithDiagnostics` 呼叫 `failWithDiagnostics` 再丟錯，失敗位置保留呼叫行。`continueAfterFailure = false` 時 `XCTFail` 當下就中止測試，`throw` 不會執行，xcresult 只記 1 筆；`throw` 讓呼叫端在編譯期標 `try`，也供允許繼續執行的預期失敗區塊接住。
- 版面判定改成回傳列舉的方法 (例：`ordersLayout(in:file:line:) throws(UITestError) -> OrdersLayout`)，判不出來時失敗；測試自己比對值後宣告 skip。六個 `is…Layout`、`AppNavigator.isSidebarLayout` 與 `rootLayout` 都改成這個形狀。
- 預期失敗的測試：區塊前把 `continueAfterFailure` 設為 `true`、區塊後設回 `false`，在 `XCTExpectFailure` 區塊內以 `do { try … } catch {}` 接住丟出的錯誤，記錄的失敗由預期涵蓋，測試接著執行 Then (主對話代選，依 4.1 量測：維持 `false` 時預期失敗一記錄測試就結束，`catch` 與 Then 都不執行)。
- typed throws 的寫法：不在 `forEach`、`map`、`XCTContext.runActivity` 的 closure 內 `try` 會丟錯的函式，改用 `for` 迴圈或在 closure 外處理；`Polling.wait` 的條件 closure 不丟錯；`Polling`、`CategoryGridInteraction` 標 `@MainActor`，`UITestError` 不標。
- 呼叫端由 `try requireCondition(screen.tapEdit(), in: app, "...")` 改為 `try screen.tapEdit()`，不再二次回報。
- `UITestError` 是停止訊號：失敗在丟出前已記錄，接住後繼續不會撤銷失敗，所以測試與 helper 都不接住它來繼續 (預期失敗的區塊除外)。有備援路徑的 helper (`tapMenuItem` 先 identifier 後標籤、`tapRootTab` 先分頁列後側邊欄、`dismissNumericKeyboard` 分段) 先以不會失敗的 `wait*`／`is*` 試各個備援，最後一個也不成立才 `stopWithDiagnostics`；可忽略的收尾動作改用不會失敗的等待 (例：`CampaignFlowTests` 以 `try?` 呼叫 `rotateToPortrait` 的收尾)。
- 4.1 量到 2 筆時，除了 `stopWithDiagnostics` 的寫法，還要同步改：spec「Helpers cannot silently absorb a missing element」本文的「record the failure … and throw」與「except inside an expected-failure block」兩句、spec「A failed navigation is recorded once」的失敗位置、spec「An expected failure is caught inside the expectation」與本節預期失敗的接法 (改為不用 `XCTExpectFailure`，以 `XCTAssertThrowsError` 驗證錯誤訊息)、Goals 與 Implementation Contract「行為」的失敗位置。這些都在 4.1 內改完再開始 4.2。
- 單次記錄依賴 `BLUITestCase` 的 `continueAfterFailure = false` (預期失敗區塊的暫時開啟是唯一例外)：會失敗的 helper 只在 `BLUITestCase` 子類別使用 (`LaunchPerformanceTests`、`AdaptiveLayoutCheckCounterexampleTests` 不繼承它，目前也不呼叫這些 helper)，規則檔寫明。
- `requireCondition` 的條件參數改為 `@autoclosure () throws(UITestError) -> Bool`，呼叫端只補 `try`；4.2 以建置確認 typed throws 的 autoclosure 可編譯，不行就維持不丟錯並在呼叫端拆成兩行，結果記進「實作與驗證」。
- `BLUITestCase.launch(_:)` 也是會失敗的函式 (App 未進入前景時失敗)，4.4 改成 `throws(UITestError)`，Tests 內約 223 處 `launch(` 呼叫補 `try`。
- 4.4 期間，回傳 `Bool` 的 Screens 函式呼叫到改成丟錯的 Support helper 時，一律在簽章加 `throws(UITestError)` 往上傳，Tests 呼叫端補 `try`、還不是 `throws` 的測試方法補 `throws`；不以 `do`／`catch` 回傳 `false` (會讓呼叫端再報一次)。
- `failWithDiagnostics` 的地位 (使用者 11/14 選定的推薦)：Support 與 Page Object 內只經 `stopWithDiagnostics` 記錄失敗，不直接呼叫 `failWithDiagnostics` (兩個 Diagnostics 檔除外)，由 6.1 的第三條掃描守住；測試的 Given、When 一律以 `try requireCondition`／`requireValue` 建立前置，Tests 內屬 Given、When 的 `failWithDiagnostics` 由第 5 組改寫；Then 照舊用 `XCTAssert*`，需要截圖與可及性樹時才用 `failWithDiagnostics(in:)`。
- 替代方案：改成 Void 並依賴 `continueAfterFailure = false` 中止。不採用：編譯器不會要求呼叫端標 `try`，讀測試時看不出哪一步可能停止。

### wait helper 保留 Bool 並禁止丟棄結果

使用者 2026-11-14 裁決。`wait*` 比照 `waitForExistence(timeout:)` 回傳 `Bool` 並保留名稱，移除 `@discardableResult`，讓 spec「A waiting result cannot be dropped」由編譯器守住。kit `coding-style.md` 的「對齊系統 API」例外原文只限鏡像系統 API 的方法，套用到自訂 `wait*` 是本專案的解讀，6.2 寫進 `apps/ios/CLAUDE.md` 的 kit 差異。

- 純查詢 (不做動作、不失敗) 改成 `is`／`has` 開頭或 `contains` 這類述詞動詞；命名合規但實際在等待的 `isSettleConfirmationPresented` 等改成 `wait*` 或會失敗的動作 (主對話代選)。
  - 7.1 審查後的取捨 (主對話代選)：5.1 方法表另定的等待型述詞 `has…(timeout:)` (逾時內成立回傳 `true`，立即判斷傳 `0`) 與狀態讀取 `is…(file:line:) throws(UITestError)` (必要元素不存在即失敗) 保留，寫成規則檔的第四、五種形狀，因為呼叫端多、誤讀的代價是等滿逾時而不是假通過；述詞與狀態讀取都不做捲動或點擊，需要先露出的改由 `reveal…` 動作在 Given／When 呼叫；點名的 `isSettleConfirmationPresented`、`isConfirmationDismissed` 改為 `waitFor…`。
- 含等待或失敗副作用的 computed property (t1p 列出的 13 處) 改成方法；`OrderEditScreen.currencyCode()` 這類讀值方法等待元素出現，找不到回 `nil`，不帶 `file:line:`。
- 讀值、框線查詢回傳 Optional，區分「不存在」與「空值」，維持現行 spec。

### UI 測試類別與方法依 kit 命名

使用者 2026-11-14 裁決 (類別與方法都改)。命名規則寫進規則檔並指向 kit，不寫進 spec (使用者選定的推薦：避免 kit、規則檔、spec 三處各有一份)。下列細節為主對話代選：

- 型別與檔名：`<Screen>UITests`；同一畫面有多個測試型別時用 `<Screen><行為>UITests`。`<Screen>` 取該畫面 Page Object 名稱去掉 `Screen` (例：`OrderFilterSheetScreen` → `OrderFilterSheetUITests`)；流程跨越根目的地的歸 `RootNavigation<行為>UITests`；`SmokeTests` 後綴改為 `UITests` 並拿掉 `Smoke`。一個型別涵蓋多個畫面時依畫面拆型別，拆出的檔留在原資料夾。
- 保留原名：`LaunchPerformanceTests` (kit 的 `<TypeUnderTest>PerformanceTests`)；`AdaptiveLayoutCheckCounterexampleTests` (不啟動 App，對 Support 的四個純值檢查型別餵反例，以檢查群組命名；UI target 不能 `import Testing`，所以用 XCTest)。
- 方法：`test<Member>_<情境>_<預期>`，`<Member>` 依序取：App reducer 對應的 view Action 名稱 (例 `testOrderRowTapped_`)；App 端沒有對應 Action 的 (版面量測、轉向、系統手勢) 取 Page Object 方法名；旅程測試取連續性的主體 (使用者選定的推薦)。
- 沒有 Page Object 的受測對象 (「更多」入口清單、App 啟動、UI 測試 harness) 以受測對象命名：「更多」入口清單屬根導覽，歸 `RootNavigation<行為>UITests`；其餘在 5.1 取名並寫明依據 (主對話代選)。
- 新舊類別對照、拆檔對應、所在資料夾、各資料夾 TestSupport 的型別名，以及每個要改的方法名，由主對話在任務 5.1 定稿成本檔「實作與驗證」的對照表，可依資料夾分節產出，盤點草稿可先派唯讀審查終端做、主對話定稿並標示決策來源；第 5 組實作者只照表實作，表上沒有的情況停下回報。被 Given 或 When 呼叫的 private helper，本體依呼叫它的步驟歸類 (例：Given 用的前置 helper 內的失敗改 `requireCondition`)。

### 前置併入 Given、可拆型拆開、旅程保留

使用者 2026-11-14 裁決 (多組 When／Then 的處理)。

- Given／When 內以 `XCTAssert*` 驗前置的 25 處改為 `requireCondition`／`requireValue`。
- 前提型多組 When／Then (7 個) 把前面幾組改寫成 Given；可拆型 (10 個) 拆成各自的測試，名稱各自描述行為；旅程型 (22 個) 保留，每個 When 配自己的 Then，允許條件寫進規則檔與 `apps/ios/CLAUDE.md` 的 kit 差異 (kit 原文「一個測試只允許一組 When／Then」)。
- Then 夾帶動作的 8 處移到 When 或 Given 的收尾；標記寫在 helper 內的 1 處 (`ToolLoadTabSwitchTests`) 移回測試本體。
- 下列為主對話代選：版面 skip 在到達判斷版面的畫面後立刻宣告 (6 處要提前)；要轉向後才能判斷的 2 處在轉向後立刻宣告 (t17 重掃標為需裁決)；`OrientationLayoutTests` 三個只附截圖的測試補上版面斷言 (以版面判定或框線檢查，預期值寫字面值)，截圖附件保留供人工對照，因為 Then 沒有斷言的測試屬假測試。

### 預期值以鎖定語言的字面值比對

使用者 2026-11-14 裁決。定位一律用 identifier；定位到之後的內容比對，預期值寫 zh-Hant／TW 的字面值 (呼應 10/09 的「預期值字面值」裁決)，不從 production 格式化程式推導。下列為主對話代選：spec 原本「以執行地區格式化比對」的情境改寫為此規則；沒有呼叫端的 `ValueParsing.swift` 與 `combinedTextContains` 刪除。

例外：App 端已把測試要驗證的狀態放進合併列 `accessibilityValue` 的 (幣別列、付款方式列、訂單詳情根)，測試讀整個值比對，不在 label 裡找子字串 (見「App 端以 accessibilityValue 帶出測試要驗的狀態」)。

### Page Object 以同形狀的進入點開啟畫面

主對話代選 (t1p 重掃建議 4，依提案審查修正)，其中「單一畫面只在沒有 Page Object 時才直接查詢」是使用者選定的推薦。

- 根導覽可抵達的畫面提供 `static func open(in app: XCUIApplication, file:line:) throws(UITestError) -> Self`：切到目的地、等目的地前景就緒 (內容、空狀態、載入失敗或已推入的詳情，沿用 `RootNavigationScreen.isForegroundDestinationReady(for:)` 與 `MoreDestinationIdentifiers` 的元素組) 才回傳，不等內容的根 identifier。開團、總覽、分析的根 identifier 只在有內容時存在，等它會讓空資料與載入失敗的測試在進入點逾時 (t1p 第三輪審查)；需要內容的測試再 `try requireCondition(screen.waitUntilReady(), …)`，與現行 `goTo*` 加 `waitUntilReady` 的兩步相同 (主對話代選)。需要對象參數的畫面在 `in:` 前多一個參數 (例：主檔管理 `open(_ kind:in:file:line:)`)。要有進入點的畫面：`DashboardScreen`、`OrdersScreen`、`CampaignsScreen`、`InsightsScreen`、`CustomersScreen`、`FxScreen`、`QuoteScreen`、`SettingsScreen`、`LookupManagementScreen`；驗收逐一確認。
- 由其他畫面呈現或推入的畫面，由呈現它的 Page Object 動作在新畫面就緒後回傳 (例：`OrdersScreen.tapAddOrder(file:line:) throws(UITestError) -> OrderEditScreen`、`CampaignsScreen.openDetail(campaignID:file:line:)`)。
- 導覽只放 Page Object；資料夾的 TestSupport 只放該資料夾專用的斷言與固定值；`XCTestCase` extension 放需要 `XCTestCase` 的 `require*`、共用斷言、版面判定與轉向。
- 測試裡重寫 Page Object 已提供導覽的 helper (`openOrders`、`openOrdersList`、`openOrderEdit`、`openOrderDetail`、`openCampaignDetail`、`openQuote`、`openInsights`、開客戶頁、`openSelectedOrder` 等) 改呼叫進入點或呈現動作後刪除；只串接 Page Object 呼叫、供單一測試型別 Given 使用的多步前置 (例：`prepareSavedCardlessOrder`、`openMergeCandidateSheet`) 可留作該型別的 private 成員。每個本地導覽 helper 的去向列在 5.1 的對照表。新的 Page Object 方法與測試裡同簽章的本地方法在同一次修改刪除 (`XCTestCase` 子類別不能覆寫 extension 成員)。
- 回傳 Page Object 的呈現動作可標 `@discardableResult` (守門只禁回傳 `Bool` 的)，讓不使用回傳值的呼叫端不產生警告。
- `RootNavigationScreen.goTo*` 只給 `open(in:)` 內部，以及受測對象就是根導覽的測試使用；其他測試進畫面一律用 `<Screen>.open(in:)`。Tests 內 123 處 `goTo*` 與 20 處 `selectTab(` 由第 5 組改寫，5.1 的對照表標出受測對象是根導覽 (含「更多」入口清單) 的類別。判準：When 是切換根分頁本身的測試 (讀取期間切分頁、分頁切換的連續性、回到保有堆疊的分頁) 屬根導覽受測對象，保留 `selectTab`／`goTo*`，因為改走進入點會多出等待就緒與點入口的步驟，吃掉這類測試的時間窗 (主對話代選，t17 第三輪審查)。
- 測試只有在畫面沒有 Page Object 時才直接以 identifier 查詢 App 元素；有 Page Object 的畫面一律經它 (使用者 11/14 選定的推薦：既有約 140 處全部遷移)。5.1 依資料夾盤點這些查詢與所需的 Page Object 方法，5.2 (訂單畫面) 與 5.3 (其他畫面) 補方法，第 5 組再改呼叫。查系統容器是否存在與量框線、把 identifier 或前綴值當參數傳給共用 Support 斷言 (例 `assertEmptyState`、`assertLoadStateStaysStable`) 不在此限，盤點時分成「沒有 Page Object」「要遷移」「共用斷言的參數 (保留)」三類。補的方法優先是語意方法 (`is…`／`has…` 查詢、`wait…`、會失敗的動作、讀值)，只有測試要量框線或交給 Support 的輸入 helper 時才提供元素；同一元素的多處查詢合併成一個方法 (主對話代選，t1p 第三輪審查)。
- 不把進入點放進 `ScreenProtocol` 的需求：protocol 需求不能帶 `file`、`line` 的預設值，也沒有泛型的使用者 (t1p 提案審查)。
- `Screen` protocol 改名 `ScreenProtocol` (kit：描述角色的 protocol 用名詞加 `Protocol`)，檔名一併改。

### 共用 helper 依呼叫範圍放置

主對話代選，依 kit `file-templates.md` tests 一節：只有一個測試型別用的寫成該型別的 private 成員；同資料夾多個測試型別共用的放 `<TypeUnderTest>TestSupport.swift` (無 case 的 `enum`、成員 `static`，一個受測型別只有一個 TestSupport)；跨資料夾共用的移到 `Support/` 或 Page Object。

- 跨資料夾：`assertListedOrderIDs`、`allOrderIDs` 等 Filters 與 Regular 共用的訂單固定值、`isAbove`、詳情是否顯示指定訂單 (讀詳情根的 value)、搜尋後收鍵盤與清除搜尋、合併測試的訂單編號常數、導覽列標題讀取、注音鍵與候選字的點擊、搜尋欄系統結束鈕。
- 同資料夾：`assertTrigger` (Filters)、系統生物辨識彈窗檢查 (Smoke)。型別名在 5.1 的對照表定稿。TestSupport 的斷言比照 Support 契約，失敗時經 `stopWithDiagnostics` 丟錯，由 6.1 的第三條掃描一併檢查 (主對話代選)。`openSelectedOrder` 是導覽，改為 `OrdersScreen.open(in:)` 加回傳詳情的動作。
- 放置規則 (TestSupport 與 private 的分層) 只寫進規則檔並指向 kit，不寫進 spec (延伸使用者 11/14 第 4 項的決定，主對話代選)。
- 只單一型別使用的 Support helper 移回該型別：`assertHorizontalBounds` (只被 `OrderRegularColumnScopeTests` 用)；`LoadStateSampling` 改 private。`OrderRegularColumnScopeTests.requireDetailColumnLeadingEdge` 改用 `foregroundOrdersDetailFrame(in:)`。
- 四月韓國團 id 一律用 `CampaignSeedFixture.koreaCampaignID` (`CampaignCrudTests`、`CampaignDetailTests`、`CampaignProgressAccessibilityTests`、`DashboardLaunchLoadingTests`、`HarnessSelfCheckTests`、`EditorTextInputFocusUITests` 六處)；Then 的預期值字面值依 10/09 裁決保留。
- `CampaignSeedFixture` 留在 `Support/`：它是種子資料的識別值，不是 kit 所指的 Model fixture。

### OrdersScreen 不再當共用 helper 宿主

主對話代選 (t1p 重掃建議 5)。

- 類別格的查詢、組標題與捲動露出 (`filterCategoryCell`、`filterGroupHeader`、`revealFilterCategory`、`revealElement`、`scrollToTappable` 與其 private 支援) 抽成 Support 的 `CategoryGridInteraction` struct，由 `OrdersScreen`、`OrderFilterSheetScreen`、`OrderCategoryPickerScreen` 各自持有；`OptionPickerScreen` 不再依賴 `Orders/`。
- `hittableSearchField()`、`typeSearchText` 與搜尋欄系統結束鈕的點擊移到 Support 的 `XCUIApplication+SearchInteraction.swift`，規則檔的引用同步改。

### Support 的輪詢、框線、返回鍵與鍵盤焦點各收成一處

主對話代選 (t1p 重掃建議 6、7，依提案審查修正)。

- 輪詢：全域函式 `pollUntil` 收進無 case 的 `@MainActor enum Polling`：`wait(timeout:interval:until:) -> Bool` (不可丟棄) 是條件等待；`pause(for:)` 只給刻意的固定時長觀察窗 (例：`LoadFailureReloadLoopTests` 確認載入狀態在一段時間內不變)，呼叫點要寫理由。兩者內部以單一私有函式用 `XCTWaiter` 等待空期望，這是 UI target 唯一允許空期望等待的地方。Support 的手寫等待在 4.4 改；Screens 自己的手寫等待 (約 20 處，見 Context) 在 4.5、4.6 改；Tests 內 4 處空期望 (Navigation) 與 1 處 `RunLoop.run` (`OrderRegularSearchBarTests`) 由第 5 組改。
- 框線有效性：新增 `Support/CGRect+Validity.swift` 的 `isUsableFrame` (座標與尺寸為有限值且非空)，取代 9 檔各自的 `isFinite` 判斷；`OrdersScreen.currentFrame`／`isValidFrame` 改用 `snapshotFrame`。
- 返回鍵：只留兩種策略，都在 `XCUIApplication+NavigationBackInteraction.swift`：唯一可點的系統返回鍵 (現有 `tapUniqueNativeBackButton`)，與含指定 identifier 元素的導覽列上的返回鍵 (新增)。五種現行策略改用其一；`SettingsScreen.goBack` 用前者，因為設定頁導覽列沒有帶 identifier 的元素可當錨點。
- 鍵盤：`isKeyboardFocused` 改成 internal 屬性 `hasKeyboardFocus`，`hasKeyboardFocus` 述詞字面值 (Screens／Support 12 處、Tests 5 處) 改用它；「送 return 收鍵盤」與「點第一行取得焦點」各收成一個 Support helper；注音鍵與候選字的點擊，以及「某個按鍵是否存在」的查詢，收成 `XCUIApplication+TextInput.swift` 的 helper (受控例外)。
- 「拖曳到位置簽章不變」的 reveal 5 份收成 Support 的一個 helper，`InsightsScreen` 的固定 8 次盲滑改用它。捲動露出的其餘策略 (`scrollToHittable`、`scrollToHittableGently`、`scrollToFullyVisibleGently`、`scrollToHittableHorizontally`) 各留一份，依規則檔各自的用途。
- 導覽列標題的讀取收成 Support 的一個唯讀 helper (受控例外)，測試檔不再直接查導覽列標題；「是否有可互動的搜尋欄」的查詢放 `XCUIApplication+SearchInteraction.swift` (4.5)，取代測試檔依位置取搜尋欄。

### 「更多」目的地 identifier 與版面判定各留一份

主對話代選 (roadmap 第 5 項併入的 11/12 t1p 建議與 t1p 重掃建議 8)。

- 新增 Support 的 `MoreDestinationIdentifiers` (無 case 的 `enum`)，以 `foreground`、`rowPrefixes` 兩個 `static let` 列出入口列、各工具頁的根 identifier 與可互動前景元素；`RootNavigationScreen` 與 `XCTestCase+PlatformScope` 都改讀它。工具頁有根 identifier 的改列根 identifier，沒有的保留現行元素。
- `XCTestCase+PlatformScope` 同一套版面判定演算法的兩份合成一個帶錨點 closure 的版本，兩個 case 相同的 enum 合一，並改成上一節的回傳列舉形狀。

### 規則與程式矛盾以 spec 為準修正

主對話代選，其中「導覽列固定標題列為例外」「新建列以使用者資料比對列為例外」是使用者選定的推薦。

- 受控例外分兩類寫進 spec 與規則檔：會操作的 (共用 helper、依位置時順序來自 App 端列舉、以 identifier、系統控制項消失或讀回以 identifier 定位元素的值或框線確認結果) 與只讀量測的 (共用 helper、不操作)；另列「以執行期 ID 為鍵的列，以 identifier 前綴加使用者輸入的文字定位」。spec 以舉例描述類別與條件，逐項清單只放規則檔。以文字、label 或位置定位的例外都收在 Support 的共用 helper 或單一 Page Object 內 (spec 原文；7.1 審查後補「或單一 Page Object」，主對話代選)，測試檔不直接查詢；查系統容器是否存在與量框線允許留在測試檔 (使用者選定的推薦)。
- `AppNavigator` 依順序退回：spec 允許，保留程式，規則檔改寫為退回條件。只在真的點下退回元素時 (`tapRootTab`、`tapRootTabFromSidebar`) 以 `print` 輸出固定標記 `[BLUITest] root tab fallback used`，最終回歸以 grep Build Logs 計次；查詢與輪詢路徑不輸出。兩台都是 0 次時，把「移除退回與 spec 情境」記到 roadmap。
- 系統表單把手 (`sheetGrabber`)、TCA `AlertState` 的訊息比對 (`assertAlertMessage`)、量框線的錨點取樣、導覽列標題讀取補進例外清單。
- `LookupManagementTests` 以 `alert.buttons[文字]` 判斷呈現的 4 處，改用現有的 `alertPresented()`／`alertDismissed()` 與 `tapAlertButton(label:)`；`CampaignFlowTests` 以索引列舉 alert 內文的 2 處改用 `assertAlertMessage`。
- 測試以 label 定位 App 元素的 12 處 (t17 重掃 B1) 依類型處理：導覽列固定標題 (3 處) 改用導覽列標題 helper；詳情顯示的訂單 (4 處) 改讀詳情根的 value (App 已提供，不必改 App；使用者選定的推薦原為補 identifier，主對話查到現成的 value 後改用它)；新建開團列與訂單列 (2 處) 改用 Page Object 的「依名稱找列」方法；`CampaignFlowTests` 查不應存在的開團列改用 identifier 前綴加名稱；自訂 alert 的 2 處改用 identifier。以位置點系統返回鍵的 2 處改用共用返回鍵 helper，依位置取搜尋欄的 2 處改用「是否有可互動的搜尋欄」查詢。
- `assertAlertMessage` 比對失敗時改走 `stopWithDiagnostics`。

### App 端以 accessibilityValue 帶出測試要驗的狀態

使用者 2026-10-22 決定方向，值的形式由主對話代選。

- 訂單編輯幣別列：`currencyPickerRow` 加 `.accessibilityValue(store.draft.currency.rawValue)`，帶出 ISO 代碼，比照報價頁先例；`OrderEditScreen.currencyCode()` 讀它，測試比對 `"JPY"`。
- 付款方式管理列：`classifiedRow` 的分類徽章標 `.accessibilityHidden(true)`，改由列的 `.accessibilityValue` 帶出已啟用的分類名稱：各名稱以 `AppLanguage.resolve(_:locale:)` 依 `@Environment(\.locale)` (App 語言) 解析，再以 `ListFormatStyle` 套用同一個 locale 串接，不手寫分隔符號、不用系統 locale。`LookupManagementScreen` 提供讀取該 value 的方法，測試比對 `"貨到付款"`。
  - 分類不用語言無關的代碼：value 會被 VoiceOver 朗讀，讀出內部代碼是無障礙退步；這一處因此仍依賴鎖定語言。
- `LookupNameEditorSheet` 的「捨棄變更」與「繼續編輯」按鈕掛 identifier，常數加在 `BLAccessibilityID+More.swift` 的 `LookupManagement` (形狀依 `AccessibilityIdentifierScanTests`，建議 `lookupManagement.discardAlert.discardButton`、`lookupManagement.discardAlert.keepEditingButton`)；測試改用 `tapAlertButton(_:)`。
- App 端改完付款方式列後，既有以 label 比對徽章的測試會失敗，所以任務 3.1 排在契約鏈之後、與改寫該測試的 5.5 相鄰。

### 延遲讀取秒數由 LaunchOptions 傳給 App

主對話代選 (roadmap 第 5 項併入的 11/12 t1p 建議，依提案審查修正)。

- `LaunchOptions` 新增 `readDelaySeconds: Int`，預設 8；`loadFailure` 是 `ordersDelayed` 或 `exchangeRatesDelayed` 時輸出 `-BLUITestReadDelaySeconds <秒數>`。由它推導的逾時 (例：失敗畫面出現的逾時 = 延遲 + 餘裕) 做成 `LaunchOptions` 的計算屬性，四個資料夾的測試共用，不各自加餘裕。
- App 端 `BLUITestConfiguration` 解析成 `readDelay: Duration?`：載入失敗是延遲情境且參數缺少或不是正整數時印警告、值為 `nil`、不延遲；帶了參數但載入失敗不是延遲情境時印警告並忽略；兩者都不在時不警告。`DependencyValues+BLUITestOverrides` 的兩處寫死的 `Duration.seconds(8)` 刪除，改讀它，至少等待該時長後失敗。
- UI 端 `ToolLoadTabSwitchTests.Timing.readDelay` 刪除，各測試的註解不再寫死 8 秒。
- 只有在 3.3 已完成、4.2 還沒完成的期間，延遲情境沒有延遲 (舊 App 會忽略沒看過的參數、照舊延遲 8 秒)，這段期間不跑延遲情境的類別。
- `ToolLoadTabSwitchTests` (改名後) 的 Then 加正式斷言「從觸發讀取的動作之前 (呼叫工具頁進入點之前；重試則點重試鍵之前) 記下的時間，到觀察到失敗的間隔不小於 `readDelaySeconds`」，讓 spec 的「至少等待」由測試本身守住。起點不用「看到載入中」的時間：看到載入中比讀取開始晚，間隔會小於實際延遲而偶發失敗 (主對話代選，兩位審查者第三輪)。
- 替代方案：把常數放進同時編入兩個 target 的共用檔。不採用：`BuyLedgerAccessibilityIDs/` 的宣告由 identifier 掃描守門檢查形狀；另開共用資料夾要改專案檔的 target membership。

### 單元測試改用 TestStore 並以掃描守門

使用者 2026-11-05 決定遷移，掃描守門與下列細節由主對話代選。

- 15 檔 26 處 `Store(` 改成 `TestStore`，依 `ios-unit-tests.md`：頂層欄位與可寫 computed property 送 `store.send(\.binding.<欄位>, 值)`；巢狀欄位送整個 `draft`；預期值寫字面值；有 effect 的以 `receive` 接收；不新增 `exhaustivity = .off`。
- `.scope` 與 `@Bindable` 驅動子 store 的 2 檔改為對父 `TestStore` 送子層 binding action，斷言父狀態。
- 每條 binding 測試在「實作與驗證」記下對應畫面綁定 (`$store.<路徑>`) 所在的檔與行，審查時逐條比對送出的 key path；摘要或名稱提到「經 `@Bindable`」的改寫成現況。驗證 binding 會觸發反應的測試，缺少「改其他欄位不觸發」的對照時補上。
- `TestSuiteIntegrityTests` 新增第四條守門：以 `Guards/Scanning/SwiftSourceFiles` 列舉檔案，逐行讀 `BuyLedgerTests/` 中 `SnapshotTests/` 以外的檔案，略過整行註解，出現 `Store(`、`Store<…>(`、`StoreOf<…>(` 建立呼叫 (避開 `TestStore(`、`seedV15Store(` 等) 即失敗，訊息列出原檔的檔名與行號；掃到的檔數必須大於 0。其他寫法 (例：以 `.init` 搭型別標註) 抓不到，規則檔寫明人工複核。樣式比照既有的窮舉檢查守門寫成 raw regex，避免守門掃到自己的字串。

### UI 測試規範以常駐掃描守門

使用者選定的推薦 (t1p 提案審查 S8)。在 `BuyLedgerTests/Guards/` 新增一個子資料夾，比照 `ActionGrouping/` 分成掃描器、掃描測試與案例三檔，以 `Guards/Scanning/SwiftSourceFiles` 列舉 UI target 原始碼 (經 `TestPaths.iosRoot`)，三條守門：

- `BuyLedgerUITests/Tests/**` 的檔名只能是 `*UITests.swift` 或 `*TestSupport.swift`；例外以檔名列出並寫理由：`LaunchPerformanceTests.swift`、`AdaptiveLayoutCheckCounterexampleTests.swift`。
- `BuyLedgerUITests/**` 中 `@discardableResult` 後接回傳 `Bool` 的函式為 0 個；以整個宣告 (到左大括號為止) 比對，因為簽章多跨數行。
- `BuyLedgerUITests/Support/**`、`Screens/**` 與各資料夾的 `*TestSupport.swift` 中，兩個 Diagnostics 檔以外沒有 `failWithDiagnostics(`、`XCTFail(`、`XCTAssert` 的呼叫 (使用者 11/14 選定的推薦，延伸第 6 項；TestSupport 與後兩個樣式為主對話代選)。
- 三條都回報檔名與行號，掃到的檔數必須大於 0，樣式寫成不會命中自己的形式。改名與遷移完成 (第 5 組) 後才能轉綠，所以排在 6.1，文件在其後的 6.2。

### 刪除無呼叫端 helper

主對話代選 (t1p 重掃建議 3，依提案審查修正)。「無呼叫端」指整個 UI target 都沒有呼叫 (只被其他 Support 函式呼叫的內部 helper 不算)，刪除前以全 repo 搜尋再確認。t1p 列出的 40 個中刪除 38 個，連帶只被死碼使用的 private 成員一起刪；`ValueParsing.swift` 整檔刪除。例外：

- `scrollToHittableHorizontally` 保留並接到 `OrdersScreen.selectRegularDateChip`，讓最大輔助字級時點得到欄外的日期膠囊 (roadmap 第 5 項)。
- `LaunchOptions.CalendarAccess.denied` 保留：它是 harness 兩端對應的啟動選項 (App 端 `BLUITestCalendarAccess.denied` 與其單元測試都在)，「拒絕行事曆權限沒有 UI 測試」記為缺口。
- `XCUIElement+ValueParsing.swift` 刪掉 `combinedTextContains` 後只剩 `combinedText`，檔名改為符合內容的 `XCUIElement+CombinedText.swift`。

### 外部型別 extension 檔依功能分區

主對話依 kit 原文決定。kit `formatting.md` 規定替非自己的型別加功能的檔案「檔內依功能以 `// MARK: - <功能>` 分區」，六區名只適用頂層型別；Support 內用六區名的 16 檔改成功能名 (以 `XCUIApplication+TextInput.swift` 現行寫法為準，同一檔不混用語言)。`BLUITestCase` 與各 Page Object 是自己的型別，維持六區名。其餘 t1p 重掃的 H 類 (全域宣告、`private extension` 內逐一加 `private`、未命名附件、文件註解、缺 MARK、多餘 import、續行縮排) 隨所在檔整檔對齊。

### 驗證分層：中途只建置與跑受影響類別，最終兩平台完整回歸

依使用者 2026-10-18 的驗證分層裁決；改名前加跑一次 iPad 完整 UI 回歸是使用者選定的推薦 (該裁決對全 App 共用元件的例外)。

- 實作者交回前只跑 `swiftc -parse`；主對話在沒有其他實作者半成品時才建置 (組 A、B、C 共用工作樹)，每個任務在 iPhone 17 iOS 26.5 建置並跑改到的測試類別與冒煙類別 (`LaunchSmokeTests`，改名後用新名)，確認執行數大於 0。`OrientationLayoutTests` 在 iPhone 有轉向不生效的環境前例，只在要驗轉向的任務跑，失敗時先依規則檔重開模擬器。
- 寬版限定的資料夾 (`Tests/Orders/Regular/**`、`Tests/Navigation/**`) 改在 iPad Air 11-inch (M4) iPadOS 27.0 跑；compact 限定的 `Tests/Orders/Filters/**` 在 iPhone 跑。
- 契約鏈 (4.1 至 4.6) 完成、改名之前 (類別名與執行順序同基準)，在 iPad 跑一次完整 UI 回歸 (任務 4.7)，把契約改動與改名重整分成兩次驗證。
- 4.5、4.6 的 iPhone 驗證除了改到的資料夾，也跑使用到該任務所改 Page Object 的其他資料夾類別 (例：`OrderEditInputFocusUITests`、`SearchInputFocusUITests`、`CurrencyPickerTests` 使用訂單畫面與選項選擇器)。
- 4.7 依類別記錄執行數 (含 skip)，第 5 組以「4.7 的該資料夾數量 + 新增 + 拆分新增 - 刪除」核對。
- 「Given／When 內沒有 `XCTAssert`」沒有可執行的檢查，由主對話逐條人工檢視。
- 單元測試任務跑改到的類別；完整單元回歸與兩平台完整 UI 回歸在第 8 組。

## Implementation Contract

### 行為

- UI 測試在元素或條件不成立時停在呼叫的那一行，xcresult 該測試只記錄一筆失敗，附件含「失敗畫面」截圖與「失敗時的可及性樹」。
- 測試報表中的 UI 測試類別除兩個例外外都是 `*UITests`，方法名第一段是程式碼名稱。
- App 在 UI 測試模式下，延遲讀取至少等待 `LaunchOptions.readDelaySeconds` 秒；正式模式行為不變。
- 訂單編輯幣別列與付款方式管理列的 VoiceOver 朗讀內容維持相同資訊 (幣別列多讀出 ISO 代碼)；畫面外觀不變，snapshot 不重錄。
- 單元測試中建立 `Store` 只出現在 `SnapshotTests/`；UI 測試檔名、可丟棄的 `Bool` helper 與 Support／Page Object 直接呼叫 `failWithDiagnostics` 由守門擋住。

### 介面

- Support：`UITestError` (`case stopped(message: String)`)；`XCUIApplication.stopWithDiagnostics(_:file:line:) throws(UITestError) -> Never`；`Polling.wait(timeout:interval:until:) -> Bool`、`Polling.pause(for:)`；`CGRect.isUsableFrame`；`XCUIElement.hasKeyboardFocus`；返回鍵兩種策略；導覽列標題讀取；注音鍵與候選字點擊與按鍵是否存在的查詢；`XCUIApplication.hittableSearchField(file:line:) throws(UITestError) -> XCUIElement`、是否有可互動搜尋欄的查詢與搜尋欄系統結束鈕點擊；`requireCondition` 的可丟錯 autoclosure；`CategoryGridInteraction`；`MoreDestinationIdentifiers`；版面判定的回傳列舉。
- Page Object：`ScreenProtocol`；上列九個畫面的 `static func open(in:file:line:) throws(UITestError) -> Self` (主檔管理多一個種類參數)；動作的形狀 `func <動作>(…, file: StaticString = #filePath, line: UInt = #line) throws(UITestError)` (呈現新畫面時回傳該 Page Object)；`OrderEditScreen.currencyCode() -> String?`；`LookupManagementScreen` 的分類值讀取；`OrdersScreen` 的導覽列標題、依客戶名找列與詳情訂單讀取；`CampaignsScreen.openDetail(campaignID:file:line:)` 與依名稱找列；5.2、5.3 依 5.1 盤點補上的 Page Object 方法 (名稱記在對照表)。
- `LaunchOptions.readDelaySeconds: Int` 與其推導的逾時計算屬性；啟動參數 `-BLUITestReadDelaySeconds`；`BLUITestConfiguration.readDelay: Duration?`。
- `BLAccessibilityID.LookupManagement` 新增兩個 alert 按鈕常數 (在 `BLAccessibilityID+More.swift`)。

### 失敗模式

- 會失敗的函式：記錄一次失敗並丟出 `UITestError`，不回傳。
- `wait*` 逾時：回傳 `false`，由呼叫端決定 (多半包在 `requireCondition`)；不可丟棄。
- 版面判定判不出：失敗並丟錯，不回傳另一種版面。
- 延遲參數缺少或無效：延遲情境印警告、不延遲，依賴載入中狀態的測試因看不到載入中而失敗。
- 掃描守門讀不到檔案：失敗，不以 0 筆通過。

### 驗收

- 建置：`BuyLedger` 與 `BuyLedgerUITests` scheme 在 iPhone 17 iOS 26.5 與 iPad Air 11-inch (M4) iPadOS 27.0 模擬器建置成功，0 個新警告。
- 搜尋檢查 (主對話執行並記錄結果)：
  - `grep -rn 'requireCondition(' apps/ios/BuyLedgerUITests` 的結果中，包住會自行失敗的動作或進入點的為 0 處 (逐條檢視)。
  - `find apps/ios/BuyLedgerUITests/Tests -name '*Tests.swift' ! -name '*UITests.swift'` 只列出兩個例外檔。
  - `grep -rn 'pollUntil\|RunLoop.current.run' apps/ios/BuyLedgerUITests` 為 0 處；`XCTestExpectation()` 只出現在 `Polling` 的檔案。
  - `ValueParsing.swift`、`XCUIElement+ValueParsing.swift` 不存在。
  - 上列九個畫面各有一個 `static func open(` 宣告；`static func open(from:`、`static func navigate(in:` 為 0 處。
  - `grep -rn 'UIAssertionError\|InteractionError\|NativeBackButtonError' apps/ios/BuyLedgerUITests` 為 0 處。
  - `grep -rnE '\.goTo[A-Z]|selectTab\(' apps/ios/BuyLedgerUITests/Tests` 只出現在 5.1 對照表標為根導覽的類別。
  - `grep -rnE '\bcatch\b|try\?' apps/ios/BuyLedgerUITests` 只剩預期失敗的那一處與 `snapshot()` 相關的呼叫 (逐條檢視)。
  - `hasKeyboardFocus` 的述詞字面值與 `isFinite` 只出現在定義 `hasKeyboardFocus` 與 `isUsableFrame` 的檔案。
  - `grep -rn 'BLAccessibilityID\.' apps/ios/BuyLedgerUITests/Tests` 的結果逐條對照 5.1 的盤點：剩下的只屬沒有 Page Object 的畫面，或是傳給共用 Support 斷言的參數與前綴值。
  - 8.1 重掃 `Support/`、`Screens/` 的無呼叫端 helper，結果為 0 個或逐項記錄理由。
- 變異檢查 (暫改後還原，雜湊一致)：
  - 在一個 Feature 測試加 `_ = Store(initialState: SettingsFeature.State()) { SettingsFeature() }` (以可編譯為準)：只有 `TestSuiteIntegrityTests` 的新守門失敗，訊息的檔名與行號等於加入的那一行；同一行加在 `SnapshotTests/` 時不失敗。
  - 在 `Tests/` 下新增空的 `ProbeTests.swift`：UI 檔名守門失敗並列出該檔；在一個多行簽章、回傳 `Bool` 的 Support 函式前加回 `@discardableResult`：helper 結果守門失敗並列出該行；在一個 Page Object 方法內加一行 `app.failWithDiagnostics("probe")`：diagnostics 守門失敗並列出該行。
  - 拿掉幣別列的 `accessibilityValue`：日圓幣別的兩條測試失敗。
  - 付款方式列的 value 改成不含分類：付款方式補勾貨到付款的測試失敗。
  - 拿掉其中一個 alert 按鈕的 identifier：對應測試失敗。
  - `LaunchOptions.readDelaySeconds` 改為 12：延遲讀取匯率的測試仍通過 (其 Then 斷言間隔不小於 `readDelaySeconds`)；把 App 端改成忽略參數、固定延遲 2 秒時，同一條測試的間隔斷言失敗。
  - 把一個進入點的目的地 identifier 改成不存在的值：該測試在呼叫進入點的那一行失敗，xcresult 只有 1 筆失敗。
  - 暫時讓 `selectRegularDateChip` 不經水平捲動：最大輔助字級的日期膠囊測試失敗。
  - 暫時把 `OrientationLayoutTests` 改名後的其中一條預期版面改成另一種：該測試失敗。
- 測試：iPhone 17 完整單元回歸 0 失敗 (既有預期失敗除外)；兩平台完整 UI 回歸 0 失敗，測試數 = 4.7 的測試數 + 新增數 + 拆分新增數 - 刪除數 (依類別逐項記錄)；`AppNavigator` 退回標記的次數記錄於「實作與驗證」。
- 審查：獨立審查者逐檔逐條的 style 閘門與主對話審查都沒有未處理的必修項。

### 範圍

- 在範圍內：`apps/ios/BuyLedgerUITests/` 全部檔案；proposal 列出的 App 端檔案；15 個單元測試檔、`TestSuiteIntegrityTests` 與新的 UI 規範掃描測試；`BLUITestConfigurationTests`、`BLUITestConfigurationInvalidValuesTests`；snapshot 測試中引用 UI 測試類別名的註解；規則與文件。
- 不在範圍內：Non-Goals 所列；UI 測試以外的 App 畫面行為；snapshot 基準圖；測試資料夾搬移。

## Risks / Trade-offs

- [diff 很大，審查負擔重] → 契約鏈拆成量測、Support 擴充、Support 整理、Support 契約、訂單畫面、其他畫面六個依序任務，Page Object 補方法分兩個平行任務，Tests 依資料夾分批，改名與契約改動分在不同任務。
- [範圍隨第二輪決定擴大 (約 140 處直接查詢、123 處 `goTo*`、Given／When 的 `failWithDiagnostics` 都要改)] → 由 5.1 先盤點並列出每個資料夾的工作量，數字是 grep 估計，5.1 實際盤點後更新本節；單一資料夾任務塞不進一個 context 時，5.1 拆成更小的任務再分派。
- [機械式改呼叫端出錯] → 實作者交回前 `swiftc -parse`，主對話每個任務都建置；`throws` 讓漏改的呼叫端在編譯期報錯。4.4 只替 Screens 的呼叫端補 `try` 並往上傳 `throws`，Screens 的契約與手寫等待留給 4.5、4.6。
- [「只記錄一筆」的前提不成立] → 4.1 先在未修改的建置上量測，再決定 `stopWithDiagnostics` 的寫法，結果不符時先更新本節與 Decisions 再開始 4.2。
- [改名讓執行順序整個重排，順序相依的模擬器狀態問題換地方出現] → 4.7 在改名前跑一次 iPad 完整回歸當中間基準；8.3 失敗時先比對 4.7 的結果判斷是否為順序問題，重開模擬器後重跑。
- [拆測試讓 UI 回歸變長] → 可拆型 10 個拆開後，每個新測試多一次啟動 (估計每個約 40 秒，未量測)；8.3 記錄實際總時長。
- [改名讓既有指令與記憶中的 `-only-testing` 名稱失效] → 對照表記進本檔，規則、`apps/ios/CLAUDE.md`、README 與 snapshot 測試註解同步改；記憶由主對話收尾時更新。
- [付款方式列的 VoiceOver 朗讀順序改變] → 只是分類從 label 移到 value，內容相同；以 UI 測試讀 value 驗證，8.3 另以 `mobilebuildmcp ui-automation snapshot-ui` 確認兩列的 label 與 value。
- [中途不跑完整回歸，問題延到最後才發現] → 每個任務跑改到的類別與冒煙，寬版資料夾在 iPad 跑，4.7 與 8.3 兩次完整回歸；有失敗時先回報，不在本 change 內放寬等待。

## Open Questions

無。使用者已於 2026-11-14 決定四項裁決、第一輪提案審查後的七項推薦與第二輪後的三項推薦；其餘決策標明為主對話代選，apply 前使用者可推翻。

## 實作與驗證

### 1.1 準備

- 分支：自 `main` (`9c21300`) 開 `features/test-suite-convention-alignment`；開工時工作樹只有本 change 目錄未追蹤。
- 終端 (2026-11-14 `hc ls`，與 tasks 的分工相同，不需改派)：t8 claude-haiku-max-impl、t9 codex-luna-max-impl、t16 claude-sonnet-xhigh-impl、t1n codex-sol-xhigh-impl、t17 (Opus 5.5，唯讀審查)、t1p (Fable 5.2，唯讀架構審查)。
- 磁碟：`/` 可用 73 GiB (約 32%)，高於 5%。
- 基準：沿用 Context 所記 `ui-test-disable-view-animations` 任務 4.4 的兩平台完整 UI 回歸；改名前由 4.7 在 iPad 重跑一次。

### 2.1 Feature 測試改用 TestStore

- 15 檔 26 處 `Store(` 全改 `TestStore` (t16 實作)；`grep` 確認 `SnapshotTests/` 以外 0 處，`exhaustivity = .off`／`withExhaustivity(.off)` 只剩守門自身的註解。
- 主對話建置時修一處編譯錯誤：`OrderPercentConversionTests` 參數化測試在 `#expect` 擷取 `var draft` (Swift 6 Sendable 擷取檢查)，改成先組好再以 `let` 保存。
- iPhone 17 iOS 26.5 跑 15 個類別加 `TestSuiteIntegrityTests`、`BLUITestConfigurationTests`、`BLUITestConfigurationInvalidValuesTests`、`AccessibilityIdentifierScanTests`：161 條執行、0 失敗。
- 刪除 6 條測試 (主對話代選，查證畫面綁定後接受 t16 的提議)：
  - `OrderEditFeatureBindingTests` 的分類與幣別兩條：畫面沒有 `$store.draft.categories`／`$store.draft.currency` 綁定，兩者經 `pickers` 的 view action，行為由 `OrderEditFeatureCategoriesTests`、`OrderEditFeatureOrderSourceAndCurrencyTests` 覆蓋。
  - `OrderListFeatureCategoryPickerSyncTests`、`OrderListFeatureDestinationTests` 各一條改 `selectedCategories` 的 binding 測試：沒有畫面綁定它；已套用類別在面板開啟時改變的實際路徑是 `clearFiltersTapped`，由 `OrderListFeatureClearFilterPresentationTests` 兩條覆蓋 (同一段 `syncCommittedSelection`)。
  - `LookupRenameFormFeatureTests`、`PaymentMethodEditFormFeatureTests` 各一條：改成 `TestStore` 後與同檔既有測試完全相同。
- 新增 1 條對照 `OrderEditFeaturePhotosTests.binding_修改顧客名稱_不觸發照片匯入`；`OrderEditFeatureBindingTests` 的成本欄參數化案例補上畫面有綁定的 `foreignDomesticShipping`、`paymentFeeRate` (5 → 7 案例)。
- `@Test` 數 118 → 113：Settings 9→9、LookupAdd 16→16、LookupRename 16→15、PaymentMethodEdit 13→12、CampaignEdit 12→12、CampaignEditBinding 3→3、CategoryPickerSearch 4→4、PercentConversion 5→5、EditMerge 4→4、CategoryPickerSync 4→3、FilterQueries 8→8、MergePrefill 2→2、ListDestination 5→4、EditPhotos 11→12、EditBinding 6→4。
- `OrderFilterFeatureQueriesTests` 的日期與付款方式兩條改送畫面實際送出的 view action (`.sending(\.view.filterPending…Selected)`)，名稱改為 action 名；`OrderPercentConversionTests` 以記錄寫入的 `Binding` 取得換算後的草稿再送 `\.binding.draft`，讀取後寫回的那條沒有寫入就不送 action，改成只驗 `Binding`。
- binding 測試與畫面綁定 (路徑相對 `apps/ios/BuyLedger/Features/`)：

| 測試 | 送出 | 畫面綁定 |
| --- | --- | --- |
| `OrderEditFeatureBindingTests.binding_顧客名稱改變_同步更新草稿` | `\.binding.draft` | `Orders/Presentation/OrderEdit/Views/Sections/OrderEditBasicSection.swift:48` |
| `OrderEditFeatureBindingTests.binding_訂單狀態改變_同步更新草稿` | `\.binding.draft` | `…/Sections/OrderEditStatusSection.swift:39` |
| `OrderEditFeatureBindingTests.binding_實收金額改變_同步更新草稿` | `\.binding.chargedAmount` | `…/Sections/OrderEditPaymentSection.swift:45` |
| `OrderEditFeatureBindingTests.binding_成本欄位改變_同步更新草稿(field:)` | `\.binding.draft` | `…/Sections/OrderEditCostSection.swift:45、52、59、66`；`…/Sections/OrderEditFeesSection.swift:51、59、67` |
| `OrderEditFeatureMergeTests.binding_合併訂單編輯金額與費率欄位_允許更新` | `\.binding.chargedAmount`／`\.binding.draft` | `OrderEditPaymentSection.swift:45`、`OrderEditCostSection.swift:45`、`OrderEditFeesSection.swift:51` |
| `OrderPercentConversionTests.percentageBinding_輸入範例百分比_送出捨入後的費率並顯示捨入值(example:field:)` | `\.binding.draft` | `OrderEditFeesSection.swift:51、59、67` 經 `Views/OrderEditPercentField.swift:69` |
| `OrdersFeatureMergePrefillTests.presentation_合併確認修改顧客名稱_才判定已修改` | `\.presentation.destination.presented.edit.binding.draft` | `OrderEditBasicSection.swift:48` |
| `OrderEditFeaturePhotosTests.photos_選取照片_清除舊失敗數並送達匯入服務` 等選取照片測試 | `\.photos.binding.photoPickerSelection` | `Orders/Presentation/OrderEditPhotos/OrderEditPhotosSection.swift:104` |
| `OrderEditFeaturePhotosTests.binding_修改顧客名稱_不觸發照片匯入` | `\.binding.draft` | `OrderEditBasicSection.swift:48` |
| `OrderEditFeaturePhotosTests.pickers_關閉照片檢視_清除照片檢視路徑` | `\.pickers.binding.pickerRoute` (`nil`) | `Orders/Presentation/OrderEdit/Views/OrderEditView.swift:142` |
| `OrderCategoryPickerFeatureSearchTests.binding_輸入搜尋文字_保留暫存集合與未變更狀態` | `\.binding.searchText` | `Orders/Presentation/OrderCategoryPicker/OrderCategoryPickerSheet.swift:29` |
| `OrderCategoryPickerFeatureSearchTests.binding_搜尋欄取得焦點_保留選取與未變更狀態` | `\.binding.isSearchFieldFocused` | `OrderCategoryPickerSheet.swift:28` |
| `OrderFilterFeatureQueriesTests.binding_輸入篩選搜尋文字_更新子層搜尋` | `\.binding.filterSheetSearchText` | `Orders/Presentation/OrderFilter/Views/OrderFilterCategorySection.swift:29` |
| `CampaignEditFeatureBindingTests.binding_修改名稱_更新草稿並清除重名訊息`、`CampaignEditFeatureTests.binding_修改名稱_清除過期重名訊息` | `\.binding.draftName` | `Campaigns/Presentation/CampaignEdit/CampaignEditView.swift:62` |
| `CampaignEditFeatureBindingTests.binding_切換提醒_保留重名訊息`、`CampaignEditFeatureTests.binding_切換提醒意圖_更新草稿提醒開關(isReminderWanted:)` | `\.binding.draft` | `CampaignEditView.swift:99` |
| `CampaignEditFeatureBindingTests.binding_修改日期_保留重名訊息` | `\.binding.draft` | `CampaignEditView.swift:78` |
| `CampaignEditFeatureTests.binding_修改提醒時間_更新草稿提醒時間` | `\.binding.draft` | `CampaignEditView.swift:105` |
| `SettingsFeatureTests.binding_連續修改月度目標_依輸入順序儲存` | `\.binding.monthlyProfitGoalTWD` | `Settings/Presentation/Root/SettingsView.swift:179` |
| `LookupAddFormFeatureTests` 名稱型與付款方式型的名稱、銀行匯款旗標、捨棄確認 | `\.binding.draftName`／`\.binding.isDraftBankTransfer`／`\.binding.isDiscardConfirmationPresented` | `Lookups/Presentation/Root/Views/LookupManagementPresentations.swift:108、80、82、85、110` |
| `LookupRenameFormFeatureTests` 名稱、焦點、捨棄確認 | `\.binding.draftName`／`\.binding.isNameFieldFocused`／`\.binding.isDiscardConfirmationPresented` | `LookupManagementPresentations.swift:145、146、147` |
| `PaymentMethodEditFormFeatureTests` 名稱、貨到付款旗標、捨棄確認 | `\.binding.draftName`／`\.binding.isDraftCashOnDelivery`／`\.binding.isDiscardConfirmationPresented` | `LookupManagementPresentations.swift:176、179、181` |

### 2.2 Store 建立守門

- `TestSuiteIntegrityTests` 新增 `storeConstructions_快照測試以外建立Store_不存在()` (t8 實作)，樣式 `#"(?<![A-Za-z0-9_.])(?:StoreOf|Store)(?:<(?:[^<>\n]|<[^<>\n]*>)*>)?\("#` (允許一層巢狀泛型)，逐行比對並略過整行註解，掃描 `SnapshotTests/` 以外 494 檔。
- 變異檢查：在 `Features/Settings/SettingsFeatureTests.swift` 與 `SnapshotTests/SnapshotMoreTests.swift` 同時加入 `_ = Store(initialState: SettingsFeature.State()) { SettingsFeature() }`，只有新守門失敗 (其餘 3 條通過)，訊息只列 `Features/Settings/SettingsFeatureTests.swift:20` (加入的那行)；還原後兩檔雜湊一致，`TestSuiteIntegrityTests` 4 條 0 失敗。

### 3.1 App 端以 accessibilityValue 帶出幣別與付款方式分類

- t8 實作。`OrderEditStatusSection.currencyPickerRow` 加 `.accessibilityValue(store.draft.currency.rawValue)`，值落在 `OrderEditSelectionRow` 帶 identifier 的 `Button` 上 (比照 `QuoteInputsCard` 的幣別鈕)。`LookupItemRow.classifiedRow` 的三個分類徽章標 `accessibilityHidden(true)`，列以 `.accessibilityValue(_:isEnabled:)` 帶出已啟用的分類名稱：沿用徽章原有的三個 key，各以 `AppLanguage.resolve(_:locale:)` 依 `@Environment(\.locale)` 解析，再以 `.list(type: .and).locale(locale)` 串接；沒有分類啟用時 `isEnabled` 為 `false`，不帶出空字串值 (t8 選擇)。未新增 catalog key，`.xcstrings` 未改。
- 主對話修正：三處註解的識別字補反引號，比照 `CustomersView` 的同類註解。
- 驗證：建置成功；iPhone 17 跑 `SnapshotLookupsTests`、`SnapshotOrderEditSectionsTests`、`SnapshotOrderEditTests`、`LocalizationCatalogTests`、`LocalizationCatalogSourceGuardsTests` 共 47 條，全數通過、0 失敗，snapshot 基準圖未重錄 (`git status` 前後相同)；本輪 5 則編譯警告都在本 change 未改的 `OrdersViewLayoutTests`、`ColorContrast`。UI 端讀到的 `JPY` 與 `貨到付款` 在 5.5 驗證；`OrderDetailTests` 補勾貨到付款那條以列的 label 找徽章文字，5.5 改寫前預期會失敗 (未跑)。

### 3.2 自訂 alert 按鈕 identifier

- `BLAccessibilityID.LookupManagement.discardAlertDiscardButton` (`lookupManagement.discardAlert.discardButton`) 與 `discardAlertKeepEditingButton` (`lookupManagement.discardAlert.keepEditingButton`) 掛在 `LookupNameEditorSheet` 兩個按鈕 (t8 實作，另把名稱欄位修飾子的縮排對齊 kit)。
- 前提不成立：掛上 identifier 後兩條 `LookupManagementTests` 以 `tapAlertButton(label:)` 點擊失敗 (按鈕以兩層同 identifier、同 label 的 Button 出現，多重比對)。主對話代選把這兩處點擊改用 `tapAlertButton(_:)` 與新 identifier (原排在 5.10)；之後 iPhone 17 跑 `LookupManagementTests` 與 `LaunchSmokeTests` 15 通過、1 條依版面 skip、0 失敗。`AccessibilityIdentifierScanTests` 0 失敗 (見 2.1 的同一輪)。

### 3.3 延遲秒數由啟動參數傳入

- `BLUITestConfiguration.readDelay` 解析 `-BLUITestReadDelaySeconds`，兩處 `Duration.seconds(8)` 刪除 (t1n 實作；`grep` 0 行)；新增 5 個測試方法、24 個參數化案例 (8 → 8 秒、12 → 12 秒；缺旗標、缺值、`0`、`-1`、`abc`、`1.5`、空字串、溢位皆 `nil`；非延遲情境帶秒數被忽略)。兩個類別在 2.1 的同一輪 0 失敗。

### 4.1 失敗記錄筆數量測

- 在 `LaunchSmokeTests` 暫加探針，iPhone 17 iOS 26.5 實測 (未修改的 Support)：
  - (a) `failWithDiagnostics` 後接 `throw`：xcresult 只記 1 筆失敗，位置是呼叫行；`failWithDiagnostics` 之後的 `print` 與 `throw` 都沒有執行 (`continueAfterFailure = false` 由 `XCTFail` 當下中止)。
  - (b) `XCTExpectFailure` 區塊內呼叫「記錄失敗再丟錯」的函式並以 `do`／`catch` 接住：預期失敗比對成功，但 `catch`、區塊之後的 `print` 與刻意失敗的斷言都沒有執行，測試以「預期失敗」通過。現行 `NavigationScenarioUITests.testSelectTab_App鎖定時根分頁不可用_記錄診斷失敗` 的 Then 因此從未執行，由 4.4 依下一條修正。
  - (c) 同 (b)，但區塊前設 `continueAfterFailure = true`、區塊後設回 `false`：預期失敗比對成功，`catch` 接到錯誤，區塊後的斷言有執行 (刻意失敗的 `XCTAssertEqual` 被記錄)。
- 採用：`stopWithDiagnostics` 照 design 現行寫法 (`failWithDiagnostics` 後丟錯)；預期失敗的接法改為 (c)，已改寫 Decisions 該節與 spec「An expected failure is caught inside the expectation」(主對話代選)。
- 探針刪除後 `LaunchSmokeTests.swift` 雜湊與修改前一致 (`5a246449…`)。
- 同一輪記下 UI target 現有 24 則編譯警告 (`Screen.swift` 10、`XCTestCase+Assertions.swift` 7、`CampaignsScreen.swift` 6、`XCTestCase+Diagnostics.swift` 1，皆為 main actor 隔離)，作為 4.2 起「0 個新警告」的基準。

### 4.2 Support 共用基礎

- t9 實作。新增：`Support/UITestError.swift`、`Polling.swift`、`CGRect+Validity.swift`、`XCUIApplication+NavigationBarTitle.swift`、`XCUIApplication+Reveal.swift`、`MoreDestinationIdentifiers.swift`；修改：`XCUIApplication+Diagnostics.swift` (`stopWithDiagnostics`)、`XCTestCase+Assertions.swift` (三個 `require*` 改以它實作並標 `@MainActor`)、`XCUIApplication+NavigationBackInteraction.swift` (`tapBackButton(inNavigationBarContaining:)`)、`XCUIElement+TextInput.swift` (`hasKeyboardFocus`、`dismissKeyboardByReturn(in:)`、`focusFromFirstLine(in:)`)、`XCUIApplication+TextInput.swift` (`waitForKeyboardKey`、`tapKeyboardKey`、`tapKeyboardCandidate`)、`LaunchOptions.swift` (`readDelaySeconds`、`delayedReadFailureTimeout` = 延遲 + 7 秒)、`Screens/Orders/OrdersScreen.swift` (移除 `InteractionError`)。
- `MoreDestinationIdentifiers` 除 `foreground`、`rowPrefixes` 外多 `listAnchors` (入口清單錨點) 與 `detailRoots` (詳情欄工具根)，供 `XCTestCase+PlatformScope` 使用 (t9 選擇)。
- `isUsableFrame`：非 null、非無限、非空，且 origin、尺寸與四邊皆為有限值。
- typed throws 的 autoclosure (`requireCondition`、`requireValue`) 可編譯；只有 `OrderRegularColumnScopeTests` 一處把未標型別的 `throws` 函式直接傳進 `requireValue`，主對話改成先取值再傳入。
- 驗證：iPhone 17 建置 `BuyLedgerUITests` 成功，`LaunchSmokeTests` 2 通過、1 條依版面 skip；`grep` 三個舊錯誤型別 0 處；警告 24 → 17 (`XCTestCase+Assertions` 的 7 則因改 `@MainActor` 消失)，0 則新增。

### 4.3 Support 整理

- t9 實作。刪除 (全 repo 搜尋只剩宣告)：`assertMinimumHitTarget`、`assertHorizontalFill`、`alertExists`、五個 `combinedTextContains` 多載與 `ValueParsing.swift` 整檔 (四個 `format*` 只被前者呼叫)；保留 `scrollToHittableHorizontally` (4.5 接上) 與 `LaunchOptions.CalendarAccess.denied` (harness 兩端對應)；t1p 清單外沒有新的無呼叫端 Support helper。
- `XCUIElement+ValueParsing.swift` 改名 `XCUIElement+CombinedText.swift`；16 檔外部型別 extension 的 MARK 改正體中文功能名；`assertHorizontalBounds` 兩個多載移回 `OrderRegularColumnScopeTests` 的 private extension；`LoadStateSampling` 改 `private`；H1 (`excludedTriggerIdentifiers`、`pollFrameStable` 收進型別)、H3、H5 (三個附件命名)、H8、H9 (`BoundsCheck` 改 `import CoreGraphics`)、H10 隨檔對齊。
- 驗證：iPhone 17 建置成功，`LaunchSmokeTests` 與 `AdaptiveLayoutCheckCounterexampleTests` 7 通過、1 條依版面 skip，警告維持 17 則；iPad Air 11-inch (M4) iPadOS 27.0 跑 `OrderRegularColumnScopeTests` 12 通過。

### 4.4 Support 失敗契約與呼叫端

- t9 實作。Support 會失敗的函式改 `throws(UITestError)`、帶 `file:line:`、失敗出口改 `stopWithDiagnostics`；原本以 Bool 表示動作成敗的 helper 改回傳 Void，`waitUntilHittableOrFail` 改名 `requireHittable`；`AppNavigator.isSidebarLayout`／`rootLayout` 改成 throwing 方法，`rootLayout()` 回傳非 optional 的 `RootLayout`；`XCTestCase+PlatformScope` 的六個 `is…Layout` 與兩套演算法合成 `ListDetailLayout` 列舉與 `ordersLayout(in:)`、`moreLayout(in:)`、`campaignLayout(in:)`；`AppNavigator` 點下位置退回元素時印 `[BLUITest] root tab fallback used`；`BLUITestCase.launch` 改 throwing，Tests 內 223 處補 `try`；22 個 Screen 檔只在呼叫到丟錯 helper 的函式加 `throws(UITestError)`；`NavigationScenarioUITests` 的預期失敗照 4.1 的寫法接住；`CampaignFlowTests` 收尾改用不會失敗的 `waitForPortraitWindow`。
- 第一輪交回後主對話建置失敗 (14 個型別錯誤，`swiftc -parse` 不做型別檢查)，主對話直接修正：漏補的 `try`／`throws` (`OrderCreateTests`、`OrderDetailTests`、`CustomersLoadStateTests`)、`PhotoViewerScreen.swipeToNextPhoto` 未跟上 `requireHittable` 改名、`AdaptiveNavigationContinuityUITests` 兩處對 Bool 套 `.compact` 改成 `_ = try campaignLayout(in:)`／`moreLayout(in:)` (能回傳即恰有一種版面)；40 檔 118 行 `)  throws{` 排版；對不丟錯呼叫加的 `try` 與忽略 Bool 等待結果造成的 9 則新警告。
- 第一輪 iPhone `KeyboardDismissTests` 失敗於「拖曳後目標仍未就緒：orderEdit.chargedAmountField」。比對 HEAD 確認改寫拿掉了多條備援路徑，違反「有備援路徑的 helper 先以不會失敗的等待試完」：`typeChargedAmount` 捲不到時退回點欄位、`stableVisibleFrame` 與 `SettingsScreen.navigate` 的輕拖後一般捲動、開團詳情 reveal 迴圈每圈單拖、`loadMissingElements`／`hasOngoingCampaign`／`OrientationLayoutTests.scrollIntoView` 的盡力捲動、`dismissNumericKeyboard` 的兩段流程與「完成鍵存在但不可點時點 frame 中心」、`tapMenuItem` 只在 identifier 元素不存在時才用標籤回退。退回 t9 修正 (原則：只換失敗出口、不改控制流程)；捲動 helper 分兩層 (主對話代選)：不會失敗的 `waitUntilHittableByScrolling`、`waitUntilHittableByScrollingHorizontally`、`waitUntilHittableByGentleDrag`、`waitUntilFullyVisibleByGentleDrag` 給備援與查詢，原本的 `scrollTo…` 保留 throwing 給「捲不到即失敗」的呼叫點。t9 另在清單外修回 `OrderEditScreen.tapPhotoThumbnail` 的一般捲動備援。
- 驗證：`grep` 確認 `pollUntil` 全 repo 0 處、Support 內 `RunLoop.current.run` 0 處、`XCTestExpectation()` 只在 `Polling.swift`、`failWithDiagnostics(` 只在兩個 Diagnostics 檔、`XCTFail` 只在 `XCUIApplication+Diagnostics.swift`、Support 的 `@discardableResult` 只剩回傳 App 的 `launch`、`catch` 只有預期失敗一處、`try?` 四處都是暫時取不到的 snapshot。iPhone 17 跑冒煙、`AppLockTests`、`KeyboardDismissTests`、`NavigationScenarioUITests` 與 `Tests/Forms/**`、`Tests/Customers/**`、`Tests/Dashboard/**` 共 13 類別：56 通過、0 失敗、2 skip；iPad Air 11-inch (M4) iPadOS 27.0 跑 `Tests/Navigation/**` 5 類別：27 通過、0 失敗、5 skip (皆為版面限定)。編譯警告沒有新增。
- 執行期另出現 XCTest 警告「Invalid frame dimension (negative or non-finite)」(iPhone 26 則、iPad 3 則)，result bundle 的活動紀錄顯示都在點擊文字欄或列之後的「Wait for app to idle」內由 XCTest 發出，不是測試碼讀取框線；本 change 之前沒有這些類別的執行紀錄可比對，4.7 完整回歸時統計次數。

### 4.5 訂單畫面 Page Object

- t1n 實作。刪除無呼叫端的 `OrdersScreen.isEmptyStateShown`、`OrderDetailScreen.openStatusMenu`／`confirmDelete`、`AISummaryScreen.tapRetry`；`Screens/Screen.swift` 改名 `ScreenProtocol.swift` (協定同名，所有遵循行跟進)，`waitUntilReady` 移除 `@discardableResult`，新增 `requireReady(file:line:)`。新增 `OrdersScreen.open(in:file:line:)`；呈現動作改成新畫面就緒後回傳 Page Object (`tapAddOrder` → `OrderEditScreen`、`tapOrder` → `OrderDetailScreen`、`openFilterSheet`、`openCategoryPicker`、`OrderDetailScreen.tapEdit`／`tapMerge`／`openEdit`／`openMerge`、`OrderEditScreen` 各選擇器與 `tapPhotoThumbnail`、`MergeFlowScreen.tapCandidate`)；新增 `OrderEditScreen.currencyCode()`、`OrderDetailScreen.displayedOrderID()` (讀詳情根的 value)、`OrdersScreen.navigationBarTitle`、`orderRow(customerName:)`、`searchAndDismissKeyboard`。
- 從 `OrdersScreen` 移出共用 helper：類別格查詢與 reveal 收成 `Support/CategoryGridInteraction.swift` (三個訂單畫面各自持有)；搜尋欄查詢、逐字輸入、收鍵盤、清除與系統結束鈕收成 `Support/XCUIApplication+SearchInteraction.swift`；跨 Filters／Regular 的種子固定值與合併訂單編號收成 `Support/OrdersSeedFixture.swift`；`assertListedOrderIDs` 與 `requireDetailShows` 收成 `Support/XCTestCase+OrdersAssertions.swift`。Tests 25 檔的 `openOrders`、`openOrdersList`、`openOrderEdit`、`openOrderDetail`、`assertListedOrderIDs` 等本地副本刪除並改呼叫；只串接 Page Object 的單一型別多步前置 (`prepareSavedCardlessOrder`、`saveAndReopenOrderEdit`、`settleSearchText`) 留作 private。
- 給 4.6 沿用的形狀 (t1n 選擇)：刪除確認用 `waitForDeleteConfirmation(timeout:)`／`waitForDeleteConfirmationDismissal(timeout:)` 回傳 Bool，`tapDelete` 為 throwing Void；`focusFromLeft` 的方向參數為 `isSwipingUp: Bool` (true 為向上手勢露出下方內容)。
- `OrdersScreen.open(in:)` 的就緒條件沿用 HEAD `RootNavigationScreen` 的訂單元素組，含工具列新增鈕 (主對話代選)：延遲讀取情境要在載入中取得畫面，拿掉新增鈕會在載入中等滿逾時才失敗；spec 列的就緒狀態 (內容、空狀態、載入失敗、已推入的詳情) 都在條件內。
- 主對話修正：`OrdersNavigationSmokeTests` 刪掉 `detailRoot` 區域變數後仍引用 (唯一編譯錯誤)，改用 `detailScreen.rootElement`，詳情編號斷言改成直接比對 `displayedOrderID()`；`OrdersScreen.tapAISummary` 被改成等總結 sheet 就緒才回傳，但未開啟 AI 時呈現的是提示 alert，`AISummaryTests` 的未開啟案例因此失敗，改回 throwing Void 動作並註明兩種呈現由呼叫端判斷；`OrdersScreen` 三處 doc comment 中間的空行。
- 驗證：`grep` 確認 `OrderFilterSheetScreen`、`OrderCategoryPickerScreen`、`OptionPickerScreen` 不再引用 `OrdersScreen`，`Screens/Orders/**` 中 `XCTestExpectation()`、`RunLoop.current.run`、`failWithDiagnostics(` 0 處，`Tests/**` 中五個本地宣告 0 個，`Screens/Orders` 與 `ScreenProtocol.swift` 帶 `@discardableResult` 的 Bool 函式 0 個。建置成功，編譯警告 16 則 (都在原本就有的 `ScreenProtocol.swift`、`CampaignsScreen.swift`、`XCTestCase+Diagnostics.swift`)。iPhone 17 跑冒煙、`OrderEditInputFocusUITests`、`SearchInputFocusUITests`、`CurrencyPickerTests` 與 `Tests/Orders/**` 非 Regular 資料夾共 22 類別：93 通過、1 失敗 (上述 `AISummaryTests`)、12 skip (皆為 regular 版面限定)，修正後 `AISummaryTests` 2 通過；iPad Air 11-inch (M4) iPadOS 27.0 跑 `Tests/Orders/Regular/**` 5 類別：24 通過、0 失敗。

### 4.6 其餘畫面 Page Object

- t9 實作。刪除無呼叫端的 `CampaignDetailScreen.confirmSettle`、`CampaignEditScreen.tapCancel`、`CampaignsScreen.isEmptyStateShown`、`DashboardScreen` 四個 frame helper 與 `tapSeeAllRecentOrders`／`tapRecentOrder`、`InsightsScreen` 六個 frame helper、兩個畫面只給這些 helper 用的 `frame(for:)`、`SettingsScreen.versionText`／`setMonthlyGoal`／`toggleAISummary`、`QuoteScreen.tapRetry`／`tapPrincipalField`、`FxScreen.tapAmountField`、`OptionPickerScreen.tapDone`。`RootNavigationScreen.goTo*` 由回傳 Bool 改為 throwing Void，新增 `requireForeground(identifiers:identifierPrefixes:message:timeout:file:line:)` 供「更多」目的地等待前景元素。
- 進入點：`DashboardScreen`、`CampaignsScreen`、`InsightsScreen`、`CustomersScreen`、`FxScreen`、`QuoteScreen`、`SettingsScreen` 新增 `static func open(in:file:line:) throws(UITestError) -> Self`，`LookupManagementScreen` 為 `open(_ kind: Kind, in:file:line:)` (`.categories`／`.paymentMethods`)，連同 4.5 的 `OrdersScreen` 共九個；舊的 `open(from:)`、`navigate(in:)`、`openCategoryManagement`、`openPaymentMethodManagement` 移除。總覽、開團、分析沿用 HEAD `RootNavigationScreen` 該分頁的元素組 (開團含工具列新增鈕，空資料與載入失敗時可回傳)；客戶、匯率、報價、主檔管理在 HEAD 只點入口不等待，改為點入口後等該目的地的前景元素 (客戶：列、頂端卡片、空狀態、載入中、載入失敗；匯率與報價：結果值與狀態橫幅；主檔：根容器、新增鈕、載入失敗、列)，載入中仍可回傳，延遲讀取情境不受影響。
- 新增方法：`CampaignsScreen.openDetail(campaignID:file:line:)` (詳情就緒後回傳) 與 `campaignRow(named:)` (由 `CampaignCrudTests` 內的同一查詢搬入)；`CampaignDetailScreen.tapEdit` 改為回傳就緒的 `CampaignEditScreen`；`LookupManagementScreen.paymentMethodClassification(named:)` 讀付款方式列的 `accessibilityValue` (使用端待 3.1、5.5)、`beginEditPaymentMethod` 回傳 `PaymentMethodEditorScreen`；等待型 computed property 改為帶 `timeout` 的方法 (`nameFieldValue(timeout:)`、`monthlyGoalFieldValue(timeout:)`、匯率與報價的結果與欄位值)；`InsightsScreen.prepareLayoutSnapshot` 的類別改由呼叫端傳入；`FxScreen.typeAmount`、`QuoteScreen.typePrincipal` 移除多餘的 `in app:` 參數。
- 收斂 (形狀依 4.5)：刪除確認改為 `waitForDeleteConfirmation`／`waitForDeleteConfirmationDismissal` 回傳 Bool，`CampaignDetailScreen.tapDelete`、`LookupManagementScreen.beginDeletion` 在確認框未出現時失敗；`CampaignEditScreen.focusFromLeft` 方向參數改為 `isSwipingUp`；兩份 `appendName` 都改為「保留原文、未聚焦時才點擊後接續輸入」(t9 選擇)；`SettingsScreen.goBack` 改用 `tapUniqueNativeBackButton`；`InsightsScreen` 讀值前的 8 次盲滑改用 `reveal` (手勢上限 8、只要求可見)，8 次後仍未露出改為失敗；`CampaignEditScreen.dismissNameKeyboard`、`LookupManagementScreen.dismissKeyboard(for:)` 改用 `dismissKeyboardByReturn`，`focusNotesFromFirstLine` 改用 `focusFromFirstLine`，五個 `is…FieldFocused` 改讀 `hasKeyboardFocus`。Toggle 切換確認只剩 `CampaignEditScreen` 一份 (`SettingsScreen.toggleAISummary` 無呼叫端已刪)；`isSaveEnabled` 的另一份在 `OrderEditScreen`，不在本次範圍，兩份各自保留 (t9 選擇)。
- 測試端：`openCampaignDetail` (`XCTestCase+CampaignFlow`、`CampaignCrudTests`、`CampaignDetailTests`)、`EditorTextInputFocusUITests.openCampaignEdit`、Dashboard 與 Insights 版面測試的本地 `isAbove` (收成 `CGRect.isAbove`)、各處開報價、匯率、分析、客戶頁的導覽副本刪除並改呼叫 Page Object；`InsightsLayoutSmokeTests.openInsights(seed:)` 保留作 private (負責啟動與種子)。`goTo*` 改成 Void 後，Campaigns、Insights、Smoke、More、Navigation 與 Orders 的呼叫端一併移除 Bool 判斷。
- 主對話修正：
  - `RootNavigationScreen` 的總覽、分析元素組被加入載入中識別碼，`goToDashboard`／`goToInsights` 會在載入中就回傳；沒有任何延遲讀取測試經這兩個進入點，移除回到 HEAD 元素組 (主對話代選)。
  - `CampaignEditScreen.focusNotesFromFirstLine` 改用共用 helper 時漏掉 HEAD 先捲動露出備註欄的步驟，補回 `revealField`。
  - `LookupManagementScreen.open` 以 `let row = switch kind` 運算式賦值，違反平台規則，改為先宣告再於各分支賦值。
  - `OptionPickerScreen.optionLabel` 改為丟錯後不會回 `nil`，回傳型別改為 `String`、文件同步。
  - 匯率、報價、客戶、設定、選項選擇器共 12 處 `try app.scrollToHittable(…)` 未傳 `file:line:`，失敗位置會指向 Screen 檔，補上；`FxScreen`／`QuoteScreen` 移除參數後殘留的 `self.app` 改回 `app`。
- 驗證：`grep` 確認 `Screens/**` 有九個 `static func open(`、`static func open(from:`／`static func navigate(in:` 0 處、`XCTestExpectation()`／`RunLoop.current.run`／`failWithDiagnostics(` 0 處、帶 `@discardableResult` 的函式 26 個且皆回傳 Page Object (Bool 0 個)。暫時測試 (量完即刪、刪除後雜湊一致)：空資料種子進開團、空資料種子進分析、開團載入失敗進開團，3 條都在進入點逾時 10 秒內回傳並看到空狀態或重試鍵。建置成功，`CampaignsScreen.swift` 的警告隨 `isEmptyStateShown` 刪除由 6 則降為 3 則，無新警告。iPhone 17 跑 `Tests/Campaigns/**`、`Tests/More/**`、`Tests/Tools/**`、`Tests/Insights/**`、`Tests/Customers/**`、`Tests/Dashboard/**`、`Tests/Forms/**`、`Tests/Smoke/**` (含 `AppLockTests`)，另加經過 `goTo*` 的 `LoadFailureReloadLoopTests`、`NavigationScenarioUITests`、`ReadableWidthUITests`、`AdaptiveNavigationContinuityUITests` 與四個訂單類別，共 38 類別：157 通過、0 失敗、1 預期失敗 (`NavigationScenarioUITests` 以 `XCTExpectFailure` 嚴格模式驗證鎖定時選分頁會失敗)、16 skip (皆為 regular 版面限定)，約 72 分鐘。主對話修正後重編的檔案沒有編譯警告；執行期的 42 則警告全是「Invalid frame dimension (negative or non-finite)」，4.7 一併統計。

### 4.7 契約鏈完成後的 iPad 回歸

- 主對話執行。4.6 完成後、改名前，類別名與執行順序都與基準相同；回歸期間 `apps/**` 137 個改動檔的雜湊與開跑前一致，`git status --short` 不變。
- iPad Air 11-inch (M4) iPadOS 27.0 先單獨跑 `KeyboardDismissTests`：2 通過、0 失敗，約 222 秒。
- 完整 UI 回歸 (`-only-testing:BuyLedgerUITests`、`-skip-testing:BuyLedgerUITests/LaunchPerformanceTests`)：58 類別 252 條，227 通過、0 失敗、24 skip (皆為版面限定)、1 預期失敗 (`NavigationScenarioUITests` 的 `XCTExpectFailure` 嚴格模式)，與基準的 252 條、227 通過相同；總時長約 2 小時 12 分 (7,937 秒)。
- `AppNavigator` 退回標記 `[BLUITest] root tab fallback used` 在 Build Logs 中 0 次。標記只在畫面上找不到任何帶 identifier 的根分頁時輸出；xcresult 的 activities 不含標準輸出，Build Logs 是唯一來源，8.3 判斷「兩台皆 0 次」前，主對話以一次暫時觸發確認標記會寫進 Build Logs (主對話代選)。
- 執行期警告 43 則，全是「Invalid frame dimension (negative or non-finite)」：`OrderEditInputFocusUITests` 11、`QuoteInputFocusUITests` 6、`CurrencyPickerTests` 6、`ToolsInputFocusUITests` 5、`FxTests` 4、`QuoteTests` 3、`SettingsGoalInputTests` 2、`AdaptiveNavigationContinuityUITests` 2、`SearchInputFocusUITests`、`ReadableWidthUITests`、`OrderCreateTests`、`KeyboardDismissTests` 各 1。本輪沒有重編 UI target，沒有編譯警告。
- 各資料夾與類別的執行數 (含 skip；5.4a 至 5.10 的「4.7 的該資料夾數量」以此為準)：
  - `Tests/Campaigns/` 20 (skip 2)：`CampaignCrudTests` 2、`CampaignDetailTests` 1、`CampaignEditDateRowTests` 2、`CampaignFlowTests` 11 (skip 2)、`CampaignListLoadFailureLoopTests` 1、`CampaignListTests` 1、`CampaignProgressAccessibilityTests` 2
  - `Tests/Customers/` 5：`CustomersLoadStateTests` 2、`CustomersTests` 3
  - `Tests/Dashboard/` 4：`DashboardLaunchLoadingTests` 2、`DashboardLayoutSmokeTests` 2
  - `Tests/Forms/` 37：`EditorTextInputFocusUITests` 4、`OrderEditInputFocusUITests` 15、`QuoteInputFocusUITests` 6、`SearchInputFocusUITests` 6、`ToolsInputFocusUITests` 6
  - `Tests/Insights/` 6：`InsightsLaunchLoadingTests` 1、`InsightsLayoutSmokeTests` 2、`InsightsTests` 3
  - `Tests/More/` 15 (skip 1)：`LookupManagementTests` 13、`MoreNavigationSmokeTests` 2 (skip 1)
  - `Tests/Navigation/` 33 (skip 5、預期失敗 1)：`AdaptiveLayoutCheckCounterexampleTests` 5、`AdaptiveNavigationContinuityUITests` 17 (skip 2)、`LoadFailureReloadLoopTests` 5、`NavigationScenarioUITests` 5 (skip 3、預期失敗 1)、`ReadableWidthUITests` 1
  - `Tests/Orders/` 根層 15 (skip 4)：`OrderListLoadFailureTests` 1、`OrdersListTests` 6 (skip 3)、`OrdersNavigationSmokeTests` 8 (skip 1)
  - `Tests/Orders/Detail/` 9：`AISummaryTests` 2、`OrderDetailMenuTests` 3、`OrderDetailTests` 2、`OrderMergeTests` 1、`PhotoViewerPagingTests` 1
  - `Tests/Orders/Edit/` 14：`KeyboardDismissTests` 2、`OrderCreateTests` 6、`OrderEditAddOptionTests` 2、`OrderEditDateRowTests` 1、`OrderEditDirtyTests` 3
  - `Tests/Orders/Filters/` 20 (skip 12)：`OrderCategoryPickerLargeTests` 1、`OrderCategoryPickerTests` 5、`OrderFilterSheetLargeTests` 1 (skip 1)、`OrderFilterSheetTests` 11 (skip 11)、`OrderPaymentMethodMenuTests` 2
  - `Tests/Orders/Regular/` 24：`OrderRegularAccessibilitySizeTests` 4、`OrderRegularClearFiltersTests` 2、`OrderRegularColumnScopeTests` 12、`OrderRegularColumnWidthTests` 2、`OrderRegularSearchBarTests` 4
  - `Tests/Smoke/` 14：`AppLockTests` 3、`HarnessSelfCheckTests` 4、`LaunchSmokeTests` 3、`OrientationLayoutTests` 4 (另有 `LaunchPerformanceTests` 1 條依指令排除)
  - `Tests/Tools/` 36：`CurrencyPickerTests` 24、`FxTests` 4、`QuoteTests` 4、`SettingsGoalInputTests` 2、`ToolLoadTabSwitchTests` 2

### 5.1 對照表與盤點

- 主對話定稿。t17 唯讀產出盤點草稿 (類別與方法對照、`BLAccessibilityID.` 引用與導覽、各任務的重掃項目)，主對話裁決、以腳本驗證後定稿。行號以 4.6 完成後的工作樹為準；第 5 組動工前 `Tests/**` 不改，行號有效。
- 出處前綴：`F:` 為 `apps/ios/BuyLedger/Features/`、`S:` 為 `apps/ios/BuyLedgerUITests/Screens/`、`U:` 為 `apps/ios/BuyLedgerUITests/Support/`。「現行檔」是 `apps/ios/BuyLedgerUITests/Tests/` 之後的路徑；新型別的檔名為「型別名.swift」，留在現行檔所在的資料夾。
- 歸屬與命名判準 (t17 建議，主對話採用)：
  - K1 受測畫面是被驗證行為所屬的畫面：通常是 When 呼叫的 Page Object；When 開啟另一畫面且 Then 只驗新畫面內容時歸新畫面；同一 Feature 樹內呈現的選擇器、付款方式編輯器與 alert 屬宿主畫面，Then 只驗選擇器本身 (搜尋、標籤) 時才歸選擇器。
  - K2 When 是根導覽操作 (切分頁、「更多」入口、根側邊欄)，或 Then 驗根導覽狀態 (跨分頁保留、跨根目的地跳轉) 的歸 `RootNavigation<行為>UITests`；Given 內的切分頁不影響歸屬。
  - K3 同一畫面可有一個不帶行為的主型別 `<Screen>UITests`，其餘帶行為；拆出的測試在同資料夾已有同畫面型別時併入。
  - K4 方法第一段依序取 App view Action、AlertState Action、Page Object 方法、Support 方法；輸入、焦點、Picker 選取這類 binding 不算 view Action，改取 Page Object 方法；alert 上沒有 action 的按鈕 (取消、知道了、繼續編輯) 取 `tapAlertButton`。
  - K5 旅程測試的第一段取旅程中重複的 App Action (例 `tabSelected`、`detailSelectionChanged`)；沒有時取連續性主體的 State 屬性 (例 `draft`、`draftName`)，再沒有才取 Page Object 或 Support 方法。
  - K6 TestSupport 名為 `<Screen>UITestSupport` (kit「受測型別名去掉 Tests」)，不與單元測試的 `*FeatureTestSupport` 撞名，檔名符合 6.1 守門的 `*TestSupport.swift`；只在拆型別後無法內聯時建立。
  - 第一段首字大寫，縮寫照原拼法只改首字 (`aiSummaryTapped` 寫成 `testAiSummaryTapped_`)。
- 裁決 (主對話代選)：
  1. 判準 K1 至 K6 採用。
  2. 「商品類別改名後新訂單選擇器只顯示新名稱」的 When 在訂單編輯開選擇器，依「一個型別涵蓋多個畫面時依畫面拆型別」拆到 `OrderEditRenamedCategoryUITests` (留在 More 資料夾)。
  3. `OrderMergeTests` 改名 `MergeFlowUITests` (Page Object 為 `MergeFlowScreen`)。
  4. `ReadableWidthUITests` 不拆型別 (When 是「更多」入口選取，屬根導覽受測，與 K2 一致)；`OrientationLayoutTests` 的四條分別驗根導覽、總覽、訂單、分析的版面，依畫面拆成四個型別加 `RootNavigationOrientationUITestSupport`。
  5. `OrderRegularColumnScopeTests` 的三條根導覽受測測試拆到 `RootNavigationRegularColumnsUITests`，兩個型別共用的斷言收進 `OrdersRegularColumnScopeUITestSupport`。
  6. `ToolLoadTabSwitchTests` 的重試段是同一次切回後工具頁狀態的連續性，視為旅程，不拆。
  7. 刪除三個收尾動作 (不是斷言；取消與方向已由其他測試或下一次啟動涵蓋)：`LookupManagementTests` 「刪除失敗提示關閉後再刪除」最後按取消保留項目的一組、`CampaignFlowTests` 「刪除失敗提示關閉後再刪除」尾端的取消刪除與確認框消失、`ReadableWidthUITests` 尾端轉回直向。
  8. `OrderEditInputFocusUITests.prepareSavedCardlessOrder` 的多條件 guard 合成一行 (合行後約 96 字)；`AdaptiveLayoutCheckCounterexampleTests` 與 `LaunchPerformanceTests` 方法名不改；`RootNavigationRegularColumnsUITests` 側邊欄測試的 skip 由實作者提前，主對話在 5.4b 的 iPad 執行確認，判不出版面時改回原位並記錄。
  9. 5.4、5.6、5.7、5.9 各拆成 a、b 兩個任務 (檔案互斥，同一實作者依序做)，tasks.md 已更新。
  10. D1：Dashboard、Insights 版面快照以 identifier 為鍵讀框線的 14 筆歸「共用斷言的參數 (保留)」，識別值清單由 Page Object 的 `prepareLayoutSnapshot` 提供。
  11. D2：App 元素的框線一律由 Page Object 提供元素 (design「只有測試要量框線或交給 Support 的輸入 helper 時才提供元素」)，只有系統容器 (根側邊欄、視窗、導覽列) 留在測試。
  12. D3：`OrderRegularAccessibilitySizeTests` 的 private `tapHeaderGap` 搬進 `OrdersScreen.tapRegularHeaderGap(file:line:)`。
  13. D4：4.6 漏改四個呈現動作的回傳形狀 (design「由呈現它的 Page Object 動作在新畫面就緒後回傳」)：`CampaignsScreen.tapAdd`、`FxScreen.openCurrencyPicker`、`QuoteScreen.openCurrencyPicker`、`SettingsScreen.openDefaultCurrency` 仍回傳 Void，併入 5.3 補成回傳 Page Object (下表 S1 至 S4)。
  14. D5：`NavigationScenarioUITests` 切換語言那條先 `SettingsScreen.open(in:)` 再判斷「更多」版面，主對話在 5.7b 的 iPad 執行確認；判不出版面時改回 `goToMore` 並列為根導覽保留的例外。
  15. D6：自訂 alert 按鈕 identifier 與語言選項保留為 Support helper 的參數，不包成 Page Object 方法。
  16. D7：列表空狀態「等出現」改用共用 `assertEmptyState`，只為「立即判斷不存在」新增 `hasEmptyState`。
  17. P20 改為兩個屬性 `listRootCount`、`detailRootCount`，形狀比照 `presentedRootCount` 與 `LookupManagementScreen.presentedSheetCount`，不回傳 tuple。
  18. 5.4b 新增的欄外日期膠囊測試依 K4 取 view Action，定名 `testDatePeriodSelected_最大輔助字級_選取欄外日期膠囊`。
- 驗證 (主對話以腳本重跑)：
  - 現行 59 檔 253 條 `func test` 在方法對照表中各恰好出現一次，表上沒有不存在的檔或方法；59 檔都在類別對照表。
  - 新型別 76 個加 TestSupport 4 個，排序後 `uniq -d` 為空；與 App、`BuyLedgerTests`、Support、Screens、`BuyLedgerAccessibilityIDs` 的 1309 個型別名 `comm -12` 為空 (以 `OrderMergeTests`、`OrdersScreen` 做陽性對照，兩者都命中)。類別對照表、方法對照表與排序清單的型別集合一致；同一型別內方法新名不重複。
  - 方法新名第一段：對照表的出處行逐條讀出，該行含第一段的宣告 (Action case、State 屬性、Page Object 或 Support 方法)。例外 5 條：`testKpiTile_`、`testBatchStatusMenuButton_`、`testTapRegularHeaderGap_` 的第一段是 5.3、5.2 要新增的 Q10、P16、P19，新增後再確認；`AdaptiveLayoutCheckCounterexampleTests` 五條與 `LaunchPerformanceTests` 一條依裁決 8 保留原名，前四條第一段為 Support 受測型別名，`testLayoutChecks_` 與 `testLaunch_` 不對應程式碼名稱。
  - `grep -rn 'BLAccessibilityID\.' apps/ios/BuyLedgerUITests/Tests` 的 230 行逐行都在盤點表中標了分類：沒有 Page Object 15、要遷移 134、共用斷言的參數 81。
  - `grep -rnE '\.goTo[A-Z]|selectTab\(|tapRootTab\(' apps/ios/BuyLedgerUITests/Tests` 116 處：根導覽受測型別保留 61、改用進入點或刪除 55。
  - 抽查「改用現有方法」的目標 (`chargedAmountValue`、`currencyCode`、`itemRow(named:)`、`beginEditPaymentMethod`、`openEdit`、`openPaymentPicker` 等 35 個) 都存在；5.2、5.3 要新增的 58 個方法名在 Screens 與 Support 都還沒有 (`tapRetry`、`addButton` 已有的是別的畫面，形狀一致)。
  - 測試數：253 加可拆型 10 條、5.4b 新增 1 條，共 264。

#### 類別對照 (59 檔)
| 現行檔 | 現行型別 | 新型別與新檔 | 說明 |
| --- | --- | --- | --- |
| Campaigns/CampaignCrudTests.swift | CampaignCrudTests | CampaignEditUITests | 改名；testCancelDelete_ 移到 CampaignDetailUITests；併入 CampaignFlowTests 的 testSaveButtonTapped_ (拆 A／B)、testRotated_ |
| Campaigns/CampaignDetailTests.swift | CampaignDetailTests | CampaignDetailUITests | 改名；併入 CampaignCrudTests 的 testCancelDelete_ 與 CampaignFlowTests 的 6 條 |
| Campaigns/CampaignEditDateRowTests.swift | CampaignEditDateRowTests | CampaignEditDateRowUITests | 改名 |
| Campaigns/CampaignFlowTests.swift | CampaignFlowTests | (整檔刪除) | 11 條分到 CampaignsUITests 2、CampaignDetailUITests 6、CampaignEditUITests 2、RootNavigationCampaignLoadFailureUITests 1 |
| Campaigns/CampaignListLoadFailureLoopTests.swift | CampaignListLoadFailureLoopTests | RootNavigationCampaignLoadFailureUITests | 改名；併入 CampaignFlowTests 的 testRetryTapped_重試後_分頁仍可切換 |
| Campaigns/CampaignListTests.swift | CampaignListTests | CampaignsUITests | 改名；併入 CampaignFlowTests 2 條 |
| Campaigns/CampaignProgressAccessibilityTests.swift | CampaignProgressAccessibilityTests | CampaignsProgressAccessibilityUITests | 改名 |
| Customers/CustomersLoadStateTests.swift | CustomersLoadStateTests | CustomersLoadStateUITests | 改名 |
| Customers/CustomersTests.swift | CustomersTests | CustomersUITests；RootNavigationCustomerOrdersUITests (新檔) | 拆型別 |
| Dashboard/DashboardLaunchLoadingTests.swift | DashboardLaunchLoadingTests | DashboardLaunchLoadingUITests | 改名 |
| Dashboard/DashboardLayoutSmokeTests.swift | DashboardLayoutSmokeTests | DashboardLayoutUITests | 改名 |
| Forms/EditorTextInputFocusUITests.swift | EditorTextInputFocusUITests | CampaignEditInputFocusUITests；LookupManagementInputFocusUITests (新檔) | 拆型別 |
| Forms/OrderEditInputFocusUITests.swift | OrderEditInputFocusUITests | OrderEditInputFocusUITests | 保留原名 |
| Forms/QuoteInputFocusUITests.swift | QuoteInputFocusUITests | QuoteInputFocusUITests | 保留原名 |
| Forms/SearchInputFocusUITests.swift | SearchInputFocusUITests | OrdersSearchInputFocusUITests；MergeFlowInputFocusUITests (新檔)；OptionPickerInputFocusUITests (新檔) | 拆型別 |
| Forms/ToolsInputFocusUITests.swift | ToolsInputFocusUITests | FxInputFocusUITests；SettingsInputFocusUITests (新檔) | 拆型別 |
| Insights/InsightsLaunchLoadingTests.swift | InsightsLaunchLoadingTests | InsightsLaunchLoadingUITests | 改名 |
| Insights/InsightsLayoutSmokeTests.swift | InsightsLayoutSmokeTests | InsightsLayoutUITests | 改名 |
| Insights/InsightsTests.swift | InsightsTests | InsightsUITests | 改名 |
| More/LookupManagementTests.swift | LookupManagementTests | LookupManagementUITests；OrderEditRenamedCategoryUITests (新檔，裁決 2) | 拆型別 |
| More/MoreNavigationSmokeTests.swift | MoreNavigationSmokeTests | RootNavigationMoreUITests | 改名 |
| Navigation/AdaptiveLayoutCheckCounterexampleTests.swift | AdaptiveLayoutCheckCounterexampleTests | AdaptiveLayoutCheckCounterexampleTests | 保留原名 (design) |
| Navigation/AdaptiveNavigationContinuityUITests.swift | AdaptiveNavigationContinuityUITests | RootNavigationContinuityUITests；OrdersAdaptiveLayoutUITests、OrderEditDraftRotationUITests、CampaignsAdaptiveLayoutUITests、DashboardAdaptiveLayoutUITests (新檔) | 拆型別 |
| Navigation/LoadFailureReloadLoopTests.swift | LoadFailureReloadLoopTests | RootNavigationLoadFailureUITests；AppLockLoadFailureUITests (新檔) | 拆型別 |
| Navigation/NavigationScenarioUITests.swift | NavigationScenarioUITests | RootNavigationScenarioUITests；OrdersSelectionUITests、SettingsLanguageUITests (新檔) | 拆型別 |
| Navigation/ReadableWidthUITests.swift | ReadableWidthUITests | RootNavigationReadableWidthUITests | 改名 (裁決 4 不拆型別) |
| Orders/OrderListLoadFailureTests.swift | OrderListLoadFailureTests | OrdersLoadFailureUITests | 改名 |
| Orders/OrdersListTests.swift | OrdersListTests | OrdersUITests | 改名 |
| Orders/OrdersNavigationSmokeTests.swift | OrdersNavigationSmokeTests | OrdersNavigationUITests；OrderEditRotationUITests (新檔) | 拆型別 |
| Orders/Detail/AISummaryTests.swift | AISummaryTests | AISummaryUITests | 改名 |
| Orders/Detail/OrderDetailMenuTests.swift | OrderDetailMenuTests | OrderDetailMoreMenuUITests | 改名 |
| Orders/Detail/OrderDetailTests.swift | OrderDetailTests | OrderDetailUITests | 改名 |
| Orders/Detail/OrderMergeTests.swift | OrderMergeTests | MergeFlowUITests | 改名 (裁決 3) |
| Orders/Detail/PhotoViewerPagingTests.swift | PhotoViewerPagingTests | PhotoViewerUITests | 改名 |
| Orders/Edit/KeyboardDismissTests.swift | KeyboardDismissTests | OrderEditKeyboardDismissUITests | 改名 |
| Orders/Edit/OrderCreateTests.swift | OrderCreateTests | OrderEditCreateUITests | 改名 |
| Orders/Edit/OrderEditAddOptionTests.swift | OrderEditAddOptionTests | OrderEditAddOptionUITests | 改名 |
| Orders/Edit/OrderEditDateRowTests.swift | OrderEditDateRowTests | OrderEditDateRowUITests | 改名 |
| Orders/Edit/OrderEditDirtyTests.swift | OrderEditDirtyTests | OrderEditDirtyUITests | 改名 |
| Orders/Filters/OrderCategoryPickerLargeTests.swift | OrderCategoryPickerLargeTests | OrderCategoryPickerLargeUITests | 改名 |
| Orders/Filters/OrderCategoryPickerTests.swift | OrderCategoryPickerTests | OrderCategoryPickerUITests | 改名 |
| Orders/Filters/OrderFilterSheetLargeTests.swift | OrderFilterSheetLargeTests | OrderFilterSheetLargeUITests | 改名 |
| Orders/Filters/OrderFilterSheetTests.swift | OrderFilterSheetTests | OrderFilterSheetUITests | 改名 |
| Orders/Filters/OrderPaymentMethodMenuTests.swift | OrderPaymentMethodMenuTests | OrdersPaymentMethodMenuUITests | 改名 |
| Orders/Regular/OrderRegularAccessibilitySizeTests.swift | OrderRegularAccessibilitySizeTests | OrdersRegularAccessibilitySizeUITests | 改名 |
| Orders/Regular/OrderRegularClearFiltersTests.swift | OrderRegularClearFiltersTests | OrdersRegularClearFiltersUITests | 改名 |
| Orders/Regular/OrderRegularColumnScopeTests.swift | OrderRegularColumnScopeTests | OrdersRegularColumnScopeUITests；RootNavigationRegularColumnsUITests (新檔，裁決 5 方案 A) | 拆型別 |
| Orders/Regular/OrderRegularColumnWidthTests.swift | OrderRegularColumnWidthTests | OrdersRegularColumnWidthUITests | 改名 |
| Orders/Regular/OrderRegularSearchBarTests.swift | OrderRegularSearchBarTests | OrdersRegularSearchBarUITests | 改名 |
| Performance/LaunchPerformanceTests.swift | LaunchPerformanceTests | LaunchPerformanceTests | 保留原名 (design) |
| Smoke/AppLockTests.swift | AppLockTests | AppLockUITests | 改名 |
| Smoke/HarnessSelfCheckTests.swift | HarnessSelfCheckTests | BLUITestConfigurationUITests | 改名 |
| Smoke/LaunchSmokeTests.swift | LaunchSmokeTests | RootNavigationLaunchUITests | 改名 |
| Smoke/OrientationLayoutTests.swift | OrientationLayoutTests | RootNavigationOrientationUITests；DashboardOrientationUITests、OrdersOrientationUITests、InsightsOrientationUITests (新檔，裁決 4) | 拆型別 |
| Tools/CurrencyPickerTests.swift | CurrencyPickerTests | OptionPickerCurrencyUITests | 改名 |
| Tools/FxTests.swift | FxTests | FxUITests | 改名 |
| Tools/QuoteTests.swift | QuoteTests | QuoteUITests | 改名 |
| Tools/SettingsGoalInputTests.swift | SettingsGoalInputTests | SettingsGoalInputUITests | 改名 |
| Tools/ToolLoadTabSwitchTests.swift | ToolLoadTabSwitchTests | RootNavigationToolLoadUITests | 改名 |
新增型別檔 18 個 (上表標「新檔」者)：RootNavigationCustomerOrdersUITests、LookupManagementInputFocusUITests、MergeFlowInputFocusUITests、OptionPickerInputFocusUITests、SettingsInputFocusUITests、OrderEditRenamedCategoryUITests、OrdersAdaptiveLayoutUITests、OrderEditDraftRotationUITests、CampaignsAdaptiveLayoutUITests、DashboardAdaptiveLayoutUITests、AppLockLoadFailureUITests、OrdersSelectionUITests、SettingsLanguageUITests、OrderEditRotationUITests、RootNavigationRegularColumnsUITests、DashboardOrientationUITests、OrdersOrientationUITests、InsightsOrientationUITests。
新增 TestSupport 檔 4 個：Orders/Filters/OrdersUITestSupport.swift (assertTrigger；篩選固定值已由 4.5 收進 `Support/OrdersSeedFixture.swift`)；Orders/Regular/OrdersRegularColumnScopeUITestSupport.swift (assertListControls、listColumnBounds、assertHorizontalBounds、layoutScopeReason)；Smoke/BLUITestConfigurationUITestSupport.swift (assertNoSystemPrompt(in:file:line:))；Smoke/RootNavigationOrientationUITestSupport.swift (attachScreenshot：四個 Orientation 型別共用的「確認橫向後附截圖」；其餘 capture*／assert* 只各被一個型別用，留 private；Q10、Q14、P21、P22 取代 filterButton／rows／scrollIntoView)。
檔案數：59 − 1 (刪 CampaignFlowTests) ＋ 18 ＝ 76 型別檔，加 4 個 TestSupport 檔。


#### 方法對照
##### Campaigns (20 → 21)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Campaigns/CampaignCrudTests.swift | testTapSave_新增開團並輸入名稱_列表出現開團 | CampaignEditUITests | testSaveButtonTapped_新增開團並輸入名稱_列表出現開團 | F:Campaigns/Presentation/CampaignEdit/CampaignEditFeature.swift:167 | 改名 |
| Campaigns/CampaignCrudTests.swift | testCancelDelete_刪除確認選取消_停留在開團詳情 | CampaignDetailUITests | 不變 | S:Campaigns/CampaignDetailScreen.swift:309 | 不變 (移型別) |
| Campaigns/CampaignDetailTests.swift | testCancelSettle_結團確認選取消_停留詳情且未結團 | CampaignDetailUITests | 不變 | S:Campaigns/CampaignDetailScreen.swift:273 | 不變 |
| Campaigns/CampaignEditDateRowTests.swift | testDateRows_新增開團_顯示開團與結單日期列且無提醒時間列 | CampaignEditDateRowUITests | testNewCampaignTapped_新增開團_顯示開團與結單日期列且無提醒時間列 | F:Campaigns/Presentation/CampaignList/CampaignListFeature.swift:163 | 改名 |
| Campaigns/CampaignEditDateRowTests.swift | testReminderDateRow_開啟訂購提醒_出現提醒時間列 | CampaignEditDateRowUITests | testToggleReminder_開啟訂購提醒_出現提醒時間列 | S:Campaigns/CampaignEditScreen.swift:202 | 改名 (binding 取 Page Object) |
| Campaigns/CampaignListTests.swift | testGoToCampaigns_空資料_顯示空狀態 | CampaignsUITests | testTask_空資料_顯示空狀態 | F:Campaigns/Presentation/CampaignList/CampaignListFeature.swift:147 | 改名 |
| Campaigns/CampaignListLoadFailureLoopTests.swift | testTabSwitch_開團每次載入皆失敗_返回清單仍穩定顯示失敗畫面 | RootNavigationCampaignLoadFailureUITests | testTabSelected_開團每次載入皆失敗_返回清單仍穩定顯示失敗畫面 | F:App/Presentation/Root/RootFeature.swift:143 | 改名、旅程 |
| Campaigns/CampaignProgressAccessibilityTests.swift | testCampaignRowLabel_正體中文_進度標題後接目前值 | CampaignsProgressAccessibilityUITests | testCampaignRow_正體中文_進度標題後接目前值 | S:Campaigns/CampaignsScreen.swift:115 | 改名 |
| Campaigns/CampaignProgressAccessibilityTests.swift | testCampaignRowLabel_英文_進度標題為英文且後接目前值 | CampaignsProgressAccessibilityUITests | testCampaignRow_英文_進度標題為英文且後接目前值 | S:Campaigns/CampaignsScreen.swift:115 | 改名 |
| Campaigns/CampaignFlowTests.swift | testRetryTapped_每次載入皆失敗_仍顯示失敗畫面與重試鍵 | CampaignsUITests | 不變 | F:Campaigns/Presentation/CampaignList/CampaignListFeature.swift:150 | 不變 (移型別) |
| Campaigns/CampaignFlowTests.swift | testRetryTapped_重試後_分頁仍可切換 | RootNavigationCampaignLoadFailureUITests | testTabSelected_開團重試後_分頁仍可切換 | F:App/Presentation/Root/RootFeature.swift:143 | 改名 (When 是切分頁) |
| Campaigns/CampaignFlowTests.swift | testSaveButtonTapped_開團寫入失敗_表單關閉後顯示失敗提示 | CampaignEditUITests | A 不變；B testTapAlertButton_開團寫入失敗提示按知道了_回到空列表且不含失敗開團 | A F:Campaigns/Presentation/CampaignEdit/CampaignEditFeature.swift:167；B U:XCUIApplication+AlertInteraction.swift:85 | 可拆 (A／B)：A 的 Then 止於提示內容；B 的 Given 重做 A 並以 requireCondition(app.alertPresented()) 收尾 |
| Campaigns/CampaignFlowTests.swift | testConfirmDelete_失敗提示關閉後再次刪除_確認框仍可開啟 | CampaignDetailUITests | testDeleteTapped_刪除失敗提示關閉後再刪除_確認框仍可開啟 | F:Campaigns/Presentation/CampaignDetail/CampaignDetailFeature.swift:106 | 前提併入 Given (確認刪除、失敗提示、關閉提示改 requireCondition)；C3 L146-147 的 cancelDelete＋alertDismissed 刪除 (裁決 7) |
| Campaigns/CampaignFlowTests.swift | testConfirmDelete_詳情確認刪除_返回列表並移除該列 | CampaignDetailUITests | 不變 | F:Campaigns/Presentation/CampaignPresentation/CampaignPresentationFeature+Destination.swift:51 | 不變 |
| Campaigns/CampaignFlowTests.swift | testReceiptToggleTapped_未收款訂單標記收款_已收更新且應收不變 | CampaignDetailUITests | 不變 | F:Campaigns/Presentation/CampaignDetail/CampaignDetailFeature.swift:111 | 不變 |
| Campaigns/CampaignFlowTests.swift | testReceiptToggleTapped_已收款再切換_已收還原 | CampaignDetailUITests | 不變 | F:Campaigns/Presentation/CampaignDetail/CampaignDetailFeature.swift:111 | 不變 |
| Campaigns/CampaignFlowTests.swift | testUnpaidOnlyToggled_開啟_隱藏已收款客戶列 | CampaignDetailUITests | 不變 | F:Campaigns/Presentation/CampaignDetail/CampaignDetailFeature.swift:116 | 不變 |
| Campaigns/CampaignFlowTests.swift | testTapCampaign_返回後再進入_保留未收款篩選 | CampaignDetailUITests | testDetailSelectionChanged_返回後再進入_保留未收款篩選 | F:Campaigns/Presentation/Root/CampaignFeature.swift:175 | 改名 |
| Campaigns/CampaignFlowTests.swift | testBackTapped_收合版面返回後清空選取_展開顯示空詳情提示 | CampaignsUITests | testDetailSelectionChanged_收合版返回後轉橫向_清空選取並顯示空詳情提示 | F:Campaigns/Presentation/Root/CampaignFeature.swift:175 | 改名、旅程；L325 的 skip 已在轉向後，不移 |
| Campaigns/CampaignFlowTests.swift | testRotated_輸入草稿後_名稱與焦點保留且可續打 | CampaignEditUITests | testDraftName_輸入草稿後轉向往返_名稱與焦點保留且可續打 | F:Campaigns/Presentation/CampaignEdit/CampaignEditFeature.swift:43 | 改名、旅程 |

##### Customers (5 → 6)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Customers/CustomersLoadStateTests.swift | testOpenCustomers_訂單每次讀取皆失敗_顯示失敗訊息與重試鍵而非空狀態 | CustomersLoadStateUITests | testTask_訂單每次讀取皆失敗_顯示失敗訊息與重試鍵而非空狀態 | F:Customers/Presentation/Root/CustomersFeature.swift:111 | 改名 |
| Customers/CustomersLoadStateTests.swift | testOpenCustomers_訂單延遲讀取失敗_讀取中顯示載入中且完成後顯示失敗訊息與重試鍵 | CustomersLoadStateUITests | A testTask_訂單延遲讀取失敗_讀取中顯示載入中且完成後顯示失敗訊息與重試鍵；B testRetryTapped_訂單延遲讀取失敗後重試_重新顯示載入中且再次失敗 | A F:Customers/Presentation/Root/CustomersFeature.swift:111；B F:Customers/Presentation/Root/CustomersFeature.swift:114 | 可拆 (A／B)：B 的 Given 以 requireCondition 收在失敗畫面穩定 |
| Customers/CustomersTests.swift | testTapCustomer_有客戶排行資料_切到訂單清單 | RootNavigationCustomerOrdersUITests | testCustomerTapped_有客戶排行資料_切到訂單清單 | F:Customers/Presentation/Root/CustomersFeature.swift:119 | 改名 (不是根導覽受測，Given 用 CustomersScreen.open(in:)) |
| Customers/CustomersTests.swift | testOpenCustomers_空資料_顯示空狀態 | CustomersUITests | testTask_空資料_顯示空狀態 | F:Customers/Presentation/Root/CustomersFeature.swift:111 | 改名 |
| Customers/CustomersTests.swift | testTapCustomer_AX5字級_列仍可點選切到訂單 | RootNavigationCustomerOrdersUITests | testCustomerTapped_AX5字級_列仍可點選切到訂單 | F:Customers/Presentation/Root/CustomersFeature.swift:119 | 改名 |

##### Dashboard (4 → 4)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Dashboard/DashboardLaunchLoadingTests.swift | testDashboardLaunch_停在首頁_開團卡列出進行中開團 | DashboardLaunchLoadingUITests | testTask_冷啟動停在首頁_開團卡列出進行中開團 | F:Dashboard/Presentation/Root/DashboardFeature.swift:142 | 改名 |
| Dashboard/DashboardLaunchLoadingTests.swift | testDashboardRetry_首次訂單讀取失敗_重試後顯示訂單資料 | DashboardLaunchLoadingUITests | testRetryTapped_首次訂單讀取失敗_重試後顯示訂單資料 | F:Dashboard/Presentation/Root/DashboardFeature.swift:145 | 改名 |
| Dashboard/DashboardLayoutSmokeTests.swift | testDashboardLayout_標準字級_四項KPI兩欄且內容順序固定 | DashboardLayoutUITests | testPrepareLayoutSnapshot_標準字級_四項KPI兩欄且內容順序固定 | S:Dashboard/DashboardScreen.swift:59 | 改名 |
| Dashboard/DashboardLayoutSmokeTests.swift | testDashboardLayout_最大輔助字級_四項KPI單欄且數值可由輔助功能讀取 | DashboardLayoutUITests | testPrepareLayoutSnapshot_最大輔助字級_四項KPI單欄且數值可由輔助功能讀取 | S:Dashboard/DashboardScreen.swift:59 | 改名 |

##### Forms 之一 (Editor 4、OrderEdit 15；Forms 合計 37 → 38)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Forms/EditorTextInputFocusUITests.swift | testFocusCampaignNameFromLeft_既有開團名稱接續輸入_新增文字接在尾端 | CampaignEditInputFocusUITests | testFocusFromLeft_既有開團名稱接續輸入_新增文字接在尾端 | S:Campaigns/CampaignEditScreen.swift:81 | 改名 |
| Forms/EditorTextInputFocusUITests.swift | testFocusCampaignNotesFromFirstLine_多行備註接續輸入_新增文字接在尾端 | CampaignEditInputFocusUITests | testFocusNotesFromFirstLine_開團多行備註接續輸入_新增文字接在尾端 | S:Campaigns/CampaignEditScreen.swift:104 | 改名 |
| Forms/EditorTextInputFocusUITests.swift | testFocusLookupNameFromLeft_既有主檔名稱接續輸入_新增文字接在尾端 | LookupManagementInputFocusUITests | testTapLeftToFocus_既有主檔名稱接續輸入_新增文字接在尾端 | U:XCUIElement+FocusTap.swift:24 | 改名 |
| Forms/EditorTextInputFocusUITests.swift | testFocusPaymentMethodNameFromLeft_既有付款方式接續輸入_新增文字接在尾端 | LookupManagementInputFocusUITests | testTapLeftToFocus_既有付款方式接續輸入_新增文字接在尾端 | U:XCUIElement+FocusTap.swift:24 | 改名 |
| Forms/OrderEditInputFocusUITests.swift | testFocusChargedAmountFromLeft_零值輸入_即時取代且失焦保留 | OrderEditInputFocusUITests | 不變 | S:Orders/OrderEditScreen.swift:381 | 不變 (When 現呼叫 tapLeftToFocus，改呼叫 focusChargedAmountFromLeft 讓名實一致) |
| Forms/OrderEditInputFocusUITests.swift | testFocusCustomerFromLeft_既有名稱接續輸入_新增文字接在尾端 | OrderEditInputFocusUITests | 不變 | S:Orders/OrderEditScreen.swift:180 | 不變 |
| Forms/OrderEditInputFocusUITests.swift | testFocusCustomerFromLeft_逐鍵注音組字_保留原文並追加候選字 | OrderEditInputFocusUITests | 不變 | S:Orders/OrderEditScreen.swift:180 | 不變 |
| Forms/OrderEditInputFocusUITests.swift | testFocusChargedAmountFromLeft_未輸入即失焦_還原原值且直接取消 | OrderEditInputFocusUITests | 不變 | S:Orders/OrderEditScreen.swift:381 | 不變 |
| Forms/OrderEditInputFocusUITests.swift | testFocusChargedAmountFromLeft_輸入後全部刪除_還原原值且直接取消 | OrderEditInputFocusUITests | 不變 | S:Orders/OrderEditScreen.swift:381 | 不變 |
| Forms/OrderEditInputFocusUITests.swift | testFocusCustomerFromLeft_再次點左側_原文保留且新字不在尾端 | OrderEditInputFocusUITests | 不變 | S:Orders/OrderEditScreen.swift:180 | 不變 |
| Forms/OrderEditInputFocusUITests.swift | testFocusCardFeeRate_再次點左側_保留已輸入文字 | OrderEditInputFocusUITests | testTapLeftToFocus_刷卡費率再次點左側_保留已輸入文字 | U:XCUIElement+FocusTap.swift:24 | 改名 |
| Forms/OrderEditInputFocusUITests.swift | testFocusItemUnitPrice_從品項名稱直接點單價_輸入取代原值 | OrderEditInputFocusUITests | testFocusFromLeft_從品項名稱直接點單價_輸入取代原值 | S:Orders/OrderEditScreen.swift:233 | 改名 |
| Forms/OrderEditInputFocusUITests.swift | testFocusNotesFromFirstLine_多行備註_新增文字接在尾端 | OrderEditInputFocusUITests | 不變 | S:Orders/OrderEditScreen.swift:289 | 不變 |
| Forms/OrderEditInputFocusUITests.swift | testFocusCardFeeRate_小數輸入_收鍵盤後依格式捨入 | OrderEditInputFocusUITests | testDismissNumericKeyboard_刷卡費率輸入小數_依格式捨入 | U:XCUIElement+TextInput.swift:87 | 改名 |
| Forms/OrderEditInputFocusUITests.swift | testFocusCardlessDeduction_超過實付金額_保留輸入並提示調整 | OrderEditInputFocusUITests | A testFocusFromLeft_無卡折抵超過實付金額_保留輸入並提示調整；B testFocusFromLeft_無卡折抵改回實付以內_提示消失且可儲存 | S:Orders/OrderEditScreen.swift:233 | 可拆 (A／B)：B 的 Given 做到折抵 5000、紅字出現、儲存停用並 requireCondition |
| Forms/OrderEditInputFocusUITests.swift | testFocusChargedAmountFromLeft_已有折抵時提高實付_存檔重開保留折抵 | OrderEditInputFocusUITests | 不變 | S:Orders/OrderEditScreen.swift:381 | 不變 |
| Forms/OrderEditInputFocusUITests.swift | testFocusChargedAmountFromLeft_已有折抵時輸入再刪空_還原折抵且直接取消 | OrderEditInputFocusUITests | 不變 | S:Orders/OrderEditScreen.swift:381 | 不變 |
| Forms/OrderEditInputFocusUITests.swift | testFocusCardFeeRate_零值輸入_即時取代 | OrderEditInputFocusUITests | testFocusFromLeft_刷卡費率零值輸入_即時取代 | S:Orders/OrderEditScreen.swift:233 | 改名；Given 末行 focusFromLeft 移入 When |
| Forms/OrderEditInputFocusUITests.swift | testFocusCardFeeRate_未輸入即失焦_還原原值 | OrderEditInputFocusUITests | testFocusFromLeft_刷卡費率未輸入即失焦_還原原值 | S:Orders/OrderEditScreen.swift:233 | 改名 |
本檔另一處 (裁決 8)：private prepareSavedCardlessOrder 的 L490-491 多條件 guard 合成一行 (合行後約 96 字，未超過 100)。


##### Forms 之二 (Quote 6、Search 6、Tools 6)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Forms/QuoteInputFocusUITests.swift | testFocusFieldFromLeft_既有本金重新輸入_取代原值並更新售價 | QuoteInputFocusUITests | 不變 | S:Tools/QuoteScreen.swift:146 | 不變 |
| Forms/QuoteInputFocusUITests.swift | testFocusFieldFromLeft_本金直接換到運費_運費清空後輸入且本金不變 | QuoteInputFocusUITests | 不變 | S:Tools/QuoteScreen.swift:146 | 不變 |
| Forms/QuoteInputFocusUITests.swift | testFocusFieldFromLeft_本金未輸入即失焦_聚焦清空且恢復原值 | QuoteInputFocusUITests | 不變 | S:Tools/QuoteScreen.swift:146 | 不變 |
| Forms/QuoteInputFocusUITests.swift | testFocusFieldFromLeft_零值本金輸入中_未失焦即更新建議售價 | QuoteInputFocusUITests | 不變 | S:Tools/QuoteScreen.swift:146 | 不變 |
| Forms/QuoteInputFocusUITests.swift | testFocusFieldFromLeft_零值刷卡費率輸入_取代原值並恢復一位小數 | QuoteInputFocusUITests | 不變 | S:Tools/QuoteScreen.swift:146 | 不變 |
| Forms/QuoteInputFocusUITests.swift | testFocusFieldFromLeft_本金輸入小數_失焦後保留小數值 | QuoteInputFocusUITests | 不變 | S:Tools/QuoteScreen.swift:146 | 不變 |
| Forms/SearchInputFocusUITests.swift | testFocusCategorySearchFromLeft_既有保養輸入品_接續在尾端 | OrdersSearchInputFocusUITests | testTapLeftToFocus_類別搜尋既有保養輸入品_接續在尾端 | U:XCUIElement+FocusTap.swift:24 | 改名 (private focusSearchFromLeft 內聯後 When 直接呼叫) |
| Forms/SearchInputFocusUITests.swift | testFocusOrderListSearchFromLeft_既有林輸入書_接續在尾端 | OrdersSearchInputFocusUITests | testTapLeftToFocus_訂單搜尋既有林輸入書_接續在尾端 | U:XCUIElement+FocusTap.swift:24 | 改名 |
| Forms/SearchInputFocusUITests.swift | testFocusOrderListSearchFromLeft_深連結取代既有文字_接續在新文字尾端 | OrdersSearchInputFocusUITests | testTapLeftToFocus_訂單搜尋深連結取代既有文字_接續在新文字尾端 | U:XCUIElement+FocusTap.swift:24 | 改名 |
| Forms/SearchInputFocusUITests.swift | testFocusMergeCandidateSearchFromLeft_既有林書宇輸入小_接續在尾端 | MergeFlowInputFocusUITests | testTapLeftToFocus_合併候選搜尋既有林書宇輸入小_接續在尾端 | U:XCUIElement+FocusTap.swift:24 | 改名 |
| Forms/SearchInputFocusUITests.swift | testFocusOptionPickerSearchFromLeft_既有新台輸入幣_接續在尾端 | OptionPickerInputFocusUITests | testTapLeftToFocus_選項搜尋既有新台輸入幣_接續在尾端 | U:XCUIElement+FocusTap.swift:24 | 改名 |
| Forms/SearchInputFocusUITests.swift | testOpenSourcePicker_訂單來源選擇器_不呈現搜尋欄 | OptionPickerInputFocusUITests | testOrderSourcePickerTapped_訂單來源選擇器_不呈現搜尋欄 | F:Orders/Presentation/OrderEditPickers/OrderEditPickersFeature.swift:130 | 改名 |
| Forms/ToolsInputFocusUITests.swift | testFocusAmountFromLeft_輸入5_取代預設金額 | FxInputFocusUITests | 不變 | S:Tools/FxScreen.swift:186 | 不變 |
| Forms/ToolsInputFocusUITests.swift | testFocusAmountFromLeft_只聚焦不輸入_收鍵盤後還原預設金額 | FxInputFocusUITests | 不變 | S:Tools/FxScreen.swift:186 | 不變 |
| Forms/ToolsInputFocusUITests.swift | testTapPresetAmount_未聚焦時點按鈕_金額欄顯示該金額 | FxInputFocusUITests | testQuickAmountTapped_未聚焦時點按鈕_金額欄顯示該金額 | F:FX/Presentation/Root/FxFeature.swift:121 | 改名 |
| Forms/ToolsInputFocusUITests.swift | testFocusMonthlyGoalFromLeft_輸入1_取代原值 | SettingsInputFocusUITests | 不變 | S:More/SettingsScreen.swift:159 | 不變 |
| Forms/ToolsInputFocusUITests.swift | testFocusMonthlyGoalFromLeft_只聚焦不輸入_收鍵盤後還原80000 | SettingsInputFocusUITests | 不變 | S:More/SettingsScreen.swift:159 | 不變 |
| Forms/ToolsInputFocusUITests.swift | testFocusMonthlyGoalFromLeft_輸入後全部刪除_返回再進仍為80000 | SettingsInputFocusUITests | 不變 | S:More/SettingsScreen.swift:159 | 不變 |

##### Insights (6 → 6)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Insights/InsightsLaunchLoadingTests.swift | testInsightsLaunch_先開分析頁_每團毛利排行列出開團 | InsightsLaunchLoadingUITests | testTask_冷啟動先開分析頁_每團毛利排行列出開團 | F:Insights/Presentation/Root/InsightsFeature.swift:144 | 改名 |
| Insights/InsightsLayoutSmokeTests.swift | testInsightsLayout_沒有開團資料_卡片固定順序且隱藏開團 | InsightsLayoutUITests | testPrepareLayoutSnapshot_沒有開團資料_卡片固定順序且隱藏開團 | S:Insights/InsightsScreen.swift:51 | 改名 |
| Insights/InsightsLayoutSmokeTests.swift | testInsightsLayout_有開團資料_開團卡位於成本與熱力圖之間 | InsightsLayoutUITests | testPrepareLayoutSnapshot_有開團資料_開團卡位於成本與熱力圖之間 | S:Insights/InsightsScreen.swift:51 | 改名 |
| Insights/InsightsTests.swift | testSelectRange_依序切換三個期間_畫面就緒且分段選取 | InsightsUITests | 不變 | S:Insights/InsightsScreen.swift:82 | 不變 (Picker 為 binding) |
| Insights/InsightsTests.swift | testRevenueAttribution_合併訂單_總覽趨勢類別與開團獲利一致 | InsightsUITests | testTask_合併訂單_總覽趨勢類別與開團獲利一致 | F:Insights/Presentation/Root/InsightsFeature.swift:144 | 改名 |
| Insights/InsightsTests.swift | testGoToInsights_空資料_顯示空狀態 | InsightsUITests | testTask_空資料_顯示空狀態 | F:Insights/Presentation/Root/InsightsFeature.swift:144 | 改名 |

##### More (15 → 19)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| More/LookupManagementTests.swift | testAddItem_新增商品類別_清單出現新名稱 | LookupManagementUITests | testSaveButtonTapped_新增商品類別_清單出現新名稱 | F:Lookups/Presentation/LookupAddForm/LookupAddFormFeature.swift:117 | 改名 |
| More/LookupManagementTests.swift | testRenameItem_商品類別改名_管理清單只顯示新名稱 | LookupManagementUITests | testSaveButtonTapped_商品類別改名_管理清單只顯示新名稱 | F:Lookups/Presentation/LookupRenameForm/LookupRenameFormFeature.swift:90 | 改名 |
| More/LookupManagementTests.swift | testRenameItem_商品類別改名_新訂單選擇器只顯示新名稱 | OrderEditRenamedCategoryUITests | testCategoryPickerTapped_商品類別改名後_新訂單選擇器只顯示新名稱 | F:Orders/Presentation/OrderEditPickers/OrderEditPickersFeature.swift:133 | 改名、前提併入 Given (改名、清單只顯示新名稱、OrdersScreen.open(in:).tapAddOrder())；When 只留 openCategoryPicker() |
| More/LookupManagementTests.swift | testDeleteItem_確認刪除商品類別_清單移除該名稱 | LookupManagementUITests | testConfirmDelete_確認刪除商品類別_清單移除該名稱 | F:Lookups/Presentation/Root/LookupManagementFeature+Destination.swift:71 | 改名 |
| More/LookupManagementTests.swift | testRequestDeletion_刪除寫入失敗_顯示提示並保留項目 | LookupManagementUITests | A testConfirmDelete_刪除寫入失敗_顯示操作失敗提示；B testTapAlertButton_刪除失敗提示按知道了_保留項目且筆數不變 | A F:Lookups/Presentation/Root/LookupManagementFeature+Destination.swift:71；B U:XCUIApplication+AlertInteraction.swift:85 | 可拆 (A／B)：B 的 Given 重做 A 並以 requireCondition(app.alertPresented()) 收尾 |
| More/LookupManagementTests.swift | testRequestDeletion_長按選單刪除寫入失敗_項目保留且筆數不變 | LookupManagementUITests | A testConfirmDelete_長按選單刪除寫入失敗_顯示操作失敗提示；B testTapAlertButton_長按選單刪除失敗提示按知道了_保留項目且筆數不變 | A F:Lookups/Presentation/Root/LookupManagementFeature+Destination.swift:71；B U:XCUIApplication+AlertInteraction.swift:85 | 可拆 (A／B)：B 的 Given 重做 A 並以 requireCondition(app.alertPresented()) 收尾 |
| More/LookupManagementTests.swift | testRequestDeletion_寫入失敗提示關閉後再刪除_重新呈現確認框 | LookupManagementUITests | testDeleteButtonTapped_刪除失敗提示關閉後再刪除_重新呈現確認框 | F:Lookups/Presentation/Root/LookupManagementFeature.swift:140 | 改名、前提併入 Given (W1、W2)；W4 (按取消保留「服飾」) 刪除 (裁決 7) |
| More/LookupManagementTests.swift | testRequestDeletion_滑動刪除後取消_項目保留且筆數不變 | LookupManagementUITests | testTapAlertButton_刪除確認按取消_項目保留且筆數不變 | U:XCUIApplication+AlertInteraction.swift:85 | 改名、前提併入 Given (W1) |
| More/LookupManagementTests.swift | testAddItem_新增寫入失敗_顯示提示且清單不出現新名稱 | LookupManagementUITests | A testSaveButtonTapped_新增寫入失敗_顯示操作失敗提示；B testTapAlertButton_新增失敗提示按知道了_清單不出現新名稱 | A F:Lookups/Presentation/LookupAddForm/LookupAddFormFeature.swift:117；B U:XCUIApplication+AlertInteraction.swift:85 | 可拆 (A／B) |
| More/LookupManagementTests.swift | testOpenCategoryManagement_首次載入失敗_顯示載入錯誤文字 | LookupManagementUITests | testTask_首次載入失敗_顯示載入錯誤文字 | F:Lookups/Presentation/Root/LookupManagementFeature.swift:132 | 改名 |
| More/LookupManagementTests.swift | testRenameForm_旋轉後續輸入_草稿保留且單層sheet | LookupManagementUITests | testDraftName_改名表單轉向後續輸入_草稿保留且單層sheet | F:Lookups/Presentation/LookupRenameForm/LookupRenameFormFeature.swift:25 | 改名、旅程 |
| More/LookupManagementTests.swift | testAddForm_未儲存取消_顯示捨棄確認且繼續編輯保留草稿 | LookupManagementUITests | A testCancelButtonTapped_新增表單有未儲存內容_顯示捨棄確認；B testTapAlertButton_捨棄確認選繼續編輯_保留草稿且單層sheet | A F:Lookups/Presentation/LookupAddForm/LookupAddFormFeature.swift:107；B U:XCUIApplication+AlertInteraction.swift:58 (identifier 版) | 可拆 (A／B)：B 的 Given 到捨棄確認出現 |
| More/LookupManagementTests.swift | testAddForm_確認捨棄_關閉表單不新增項目 | LookupManagementUITests | testDiscardChangesButtonTapped_確認捨棄_關閉表單不新增項目 | F:Lookups/Presentation/LookupAddForm/LookupAddFormFeature.swift:110 | 改名 |
| More/MoreNavigationSmokeTests.swift | testMoreNavigation_寬版同工具重開保留_不同工具替換 | RootNavigationMoreUITests | testEntrySelected_寬版同工具重開保留_不同工具替換 | F:More/Presentation/Root/MoreFeature.swift:174 | 改名、旅程 |
| More/MoreNavigationSmokeTests.swift | testMoreNavigation_收合版原生返回_清空目前工具 | RootNavigationMoreUITests | testEntrySelected_收合版原生返回_清空目前工具 | F:More/Presentation/Root/MoreFeature.swift:174 | 改名 (返回送 nil) |

##### Navigation 之一 (Counterexample 5、Reload 5；Navigation 合計 33 → 34)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Navigation/AdaptiveLayoutCheckCounterexampleTests.swift | testIdentifierCheck_錯ID_檢查失敗 | AdaptiveLayoutCheckCounterexampleTests | 不變 | U:IdentifierCheck.swift:9 (受測型別名) | 保留 (裁決 8) |
| Navigation/AdaptiveLayoutCheckCounterexampleTests.swift | testKPIPresenceCheck_成本缺失_檢查失敗 | AdaptiveLayoutCheckCounterexampleTests | 不變 | U:KPIPresenceCheck.swift:9 | 保留 (裁決 8) |
| Navigation/AdaptiveLayoutCheckCounterexampleTests.swift | testBoundsCheck_越界frame_檢查失敗 | AdaptiveLayoutCheckCounterexampleTests | 不變 | U:BoundsCheck.swift:11 | 保留 (裁決 8) |
| Navigation/AdaptiveLayoutCheckCounterexampleTests.swift | testPathCheck_More路徑丟失_檢查失敗 | AdaptiveLayoutCheckCounterexampleTests | 不變 | U:PathCheck.swift:9 | 保留 (裁決 8) |
| Navigation/AdaptiveLayoutCheckCounterexampleTests.swift | testLayoutChecks_正常結果_全部通過 | AdaptiveLayoutCheckCounterexampleTests | 不變 | 四個檢查型別 (第一段不是程式碼名稱) | 保留 (裁決 8) |
| Navigation/LoadFailureReloadLoopTests.swift | testTabSwitch_訂單每次讀取皆失敗_三頁穩定顯示失敗畫面 | RootNavigationLoadFailureUITests | testTabSelected_訂單每次讀取皆失敗_三頁穩定顯示失敗畫面 | F:App/Presentation/Root/RootFeature.swift:143 | 改名、旅程 |
| Navigation/LoadFailureReloadLoopTests.swift | testLeaveInsights_訂單延遲讀取失敗_離開後清單仍收到失敗結果 | RootNavigationLoadFailureUITests | testTabSelected_訂單延遲讀取中離開分析頁_清單仍收到失敗結果 | F:App/Presentation/Root/RootFeature.swift:143 | 改名 |
| Navigation/LoadFailureReloadLoopTests.swift | testLeaveCustomers_訂單延遲讀取失敗_離開後清單仍收到失敗結果 | RootNavigationLoadFailureUITests | testTabSelected_訂單延遲讀取中離開客戶頁_清單仍收到失敗結果 | F:App/Presentation/Root/RootFeature.swift:143 | 改名 |
| Navigation/LoadFailureReloadLoopTests.swift | testColdStartUnlock_訂單延遲讀取失敗_解鎖後總覽收到失敗結果 | AppLockLoadFailureUITests | testScenePhaseChanged_冷啟動解鎖時訂單延遲讀取失敗_總覽收到失敗結果 | F:App/Presentation/AppLock/AppLockFeature.swift:67 | 改名 |
| Navigation/LoadFailureReloadLoopTests.swift | testBackgroundLock_訂單延遲讀取失敗_回前景解鎖後總覽收到失敗結果 | AppLockLoadFailureUITests | testScenePhaseChanged_背景上鎖回前景解鎖_總覽收到失敗結果 | F:App/Presentation/AppLock/AppLockFeature.swift:67 | 改名 |


##### Navigation 之二 (Adaptive 17、Scenario 5、ReadableWidth 1)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testSidebarPreferenceSurvivesTabChange_側邊欄展開_目的地與徽章正確 | RootNavigationContinuityUITests | testTabSelected_側邊欄展開後切分頁與轉向_樣式目的地與徽章正確 | F:App/Presentation/Root/RootFeature.swift:143 | 改名、旅程 |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testRootStyleChangeKeepsOrders_側邊欄展開_訂單選取與篩選不變 | RootNavigationContinuityUITests | testRevealSidebarIfCollapsed_訂單已選取並套用篩選_選取與篩選不變 | U:AppNavigator.swift:234 | 改名 |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testSelectionSurvivesLayoutChange_並排且已選取_路徑與詳情同為當前訂單 | OrdersAdaptiveLayoutUITests | testDetailSelectionChanged_並排選取後反覆轉向與改選_路徑與詳情同為當前訂單 | F:Orders/Presentation/Root/OrdersFeature.swift:222 | 改名、旅程；H2：L373 的 skip 上移到轉直向後的下一行 (仍在 Then 之前) |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testOrdersStartUnselected_首次進入訂單_旋轉後仍未選取 | OrdersAdaptiveLayoutUITests | testDetailSelectionChanged_首次進入訂單並轉向_點選前維持未選取 | F:Orders/Presentation/Root/OrdersFeature.swift:222 | 改名、旅程 |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testMoreStartsUnselected_首次進入更多_寬版顯示提示且收合版顯示入口列 | RootNavigationContinuityUITests | testTabSelected_首次進入更多_寬版顯示提示且收合版顯示入口列 | F:App/Presentation/Root/RootFeature.swift:143 | 改名 |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testSearchKeepsOrClearsSelection_訂單清單並排_命中保留選取且排除後清空 | OrdersAdaptiveLayoutUITests | testSearchTextChanged_並排已選取後搜尋命中與排除_命中保留選取且排除後清空 | F:Orders/Presentation/OrderList/OrderListFeature.swift:252 | 改名、旅程 |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testMoreSettingsSurvivesRoundTrip_更多設定頁前景_設定頁保留 | RootNavigationContinuityUITests | testTabSelected_更多設定頁在前景時往返分頁_設定頁保留 | F:App/Presentation/Root/RootFeature.swift:143 | 改名、旅程 |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testMoreCustomerSurvivesRoundTrip_更多客戶頁已選取客戶_客戶頁與搜尋保留 | RootNavigationContinuityUITests | testTabSelected_更多客戶頁已選取客戶時往返分頁_客戶頁與搜尋保留 | F:App/Presentation/Root/RootFeature.swift:143 | 改名、旅程 |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testCampaignFilterSurvivesTabSwitch_開團詳情已套用未收款篩選_未收款篩選保留 | RootNavigationContinuityUITests | testTabSelected_開團詳情已套用未收款篩選_往返分頁後篩選保留 | F:App/Presentation/Root/RootFeature.swift:143 | 改名 |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testDraftSurvivesRotation_新增訂單草稿已輸入_同欄且單一sheet | OrderEditDraftRotationUITests | testDraft_新增訂單草稿轉向後續打_同欄且單一sheet | F:Orders/Presentation/OrderEdit/OrderEditFeature.swift:25 | 改名、旅程 |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testDashboardKPIMatchesAcrossSizes_標準與輔助字級_四項數值一致且成本存在 | DashboardAdaptiveLayoutUITests | testKpiValue_標準與輔助字級_四項數值一致且成本存在 | S:Dashboard/DashboardScreen.swift:147 | 改名 |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testSidebarReservedRegion_橫向訂單前景_膠囊與新增鈕在保留區外 | RootNavigationContinuityUITests | testRevealSidebarIfCollapsed_橫向訂單前景_膠囊與新增鈕在保留區外 | U:AppNavigator.swift:234 | 改名、旅程 |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testCapsuleReachable_iPhone收合版_膠囊可捲動點選且不進入系統列 | OrdersAdaptiveLayoutUITests | testStatusFilterSelected_iPhone收合版_膠囊可捲動點選且不進入系統列 | F:Orders/Presentation/OrderList/OrderListFeature.swift:228 | 改名 |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testOrdersLayoutCombination_訂單已選取_路徑保留且並排框線不重疊 | OrdersAdaptiveLayoutUITests | testRotateToLandscape_訂單已選取轉向往返_路徑保留且並排框線不重疊 | U:XCTestCase+Orientation.swift:19 | 改名、旅程 |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testCampaignRowSelected_並排選取開團_目前開團列帶選取特徵 | CampaignsAdaptiveLayoutUITests | testDetailSelectionChanged_並排選取開團_目前開團列帶選取特徵 | F:Campaigns/Presentation/Root/CampaignFeature.swift:175 | 改名 |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testCampaignAndMoreKeepTarget_開團與更多已選取目的地_目的地保留 | RootNavigationContinuityUITests | testRotateToLandscape_開團與更多已選取目的地轉向往返_目的地保留 | U:XCTestCase+Orientation.swift:19 | 改名、旅程 |
| Navigation/AdaptiveNavigationContinuityUITests.swift | testReadableRegionCentered_寬版總覽_內容未佔滿且左右等距 | DashboardAdaptiveLayoutUITests | testKpiTile_寬版總覽_內容未佔滿且左右等距 | Q10 DashboardScreen.kpiTile(_:) (待 5.3) | 改名 (原 kpiTileFrame 已隨 4.6 刪除) |
| Navigation/NavigationScenarioUITests.swift | testBatchControls_寬版多選已選取訂單_批次鈕與筆數位於視窗上半部 | OrdersSelectionUITests | testBatchStatusMenuButton_寬版多選已選取訂單_批次鈕與筆數位於視窗上半部 | P16 OrdersScreen.batchStatusMenuButton (待 5.2) | 改名 |
| Navigation/NavigationScenarioUITests.swift | testSelectionCount_收合版多選選取兩筆_筆數只在導覽列標題出現一次 | OrdersSelectionUITests | testOrderSelectionToggled_收合版多選選取兩筆_筆數只在導覽列標題出現一次 | F:Orders/Presentation/OrderList/OrderListFeature.swift:273 | 改名 |
| Navigation/NavigationScenarioUITests.swift | testSettings_收合版更多進入設定_左緣拖曳返回入口清單 | RootNavigationScenarioUITests | testEntrySelected_收合版設定頁左緣拖曳_返回入口清單 | F:More/Presentation/Root/MoreFeature.swift:174 | 改名 (返回送 nil) |
| Navigation/NavigationScenarioUITests.swift | testBackButton_切換語言後返回再進設定_標籤為目前語言的更多 | SettingsLanguageUITests | testOpenLanguagePicker_切換語言後返回再進設定_標籤為目前語言的更多 | S:More/SettingsScreen.swift:102 | 改名；D5：先 SettingsScreen.open(in:) 再判斷 moreLayout，5.7b 在 iPad 確認 |
| Navigation/NavigationScenarioUITests.swift | testSelectTab_App鎖定時根分頁不可用_記錄診斷失敗 | RootNavigationScenarioUITests | 不變 | U:AppNavigator.swift:103 | 不變 (預期失敗接法沿用 4.4) |
| Navigation/ReadableWidthUITests.swift | testMoreReadableWidth_商品類別與設定_限寬並置中 | RootNavigationReadableWidthUITests | A testEntrySelected_寬版開啟商品類別_內容限寬並置中；B testEntrySelected_寬版開啟設定_內容限寬並置中 | F:More/Presentation/Root/MoreFeature.swift:174 | 可拆 (A／B)；C3 L108 收尾 rotateToPortrait 刪除 (裁決 7) |

##### Orders 根層 (15 → 16)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Orders/OrderListLoadFailureTests.swift | testRetryTapped_訂單每次讀取皆失敗_顯示失敗與重試鍵且不顯示空狀態 | OrdersLoadFailureUITests | testRetryTapped_訂單每次讀取皆失敗_重新讀取後仍顯示失敗與重試鍵 | F:Orders/Presentation/OrderList/OrderListFeature.swift:223 | 改名、前提併入 Given (OrdersScreen.open(in:)＋失敗畫面、無空狀態改 requireCondition) |
| Orders/OrdersListTests.swift | testSelectStatusChip_選已確認_留下已確認訂單並篩掉集運中訂單 | OrdersUITests | testStatusFilterSelected_選已確認_留下已確認訂單並篩掉集運中訂單 | F:Orders/Presentation/OrderList/OrderListFeature.swift:228 | 改名 |
| Orders/OrdersListTests.swift | testSearch_輸入客戶名稱_留下該客戶訂單並篩掉他人訂單 | OrdersUITests | testSearchTextChanged_輸入客戶名稱_留下該客戶訂單並篩掉他人訂單 | F:Orders/Presentation/OrderList/OrderListFeature.swift:252 | 改名 |
| Orders/OrdersListTests.swift | testCloseSearch_窄版輸入後關閉搜尋_標題恢復且搜尋欄回到原位 | OrdersUITests | testTapSearchEndButton_窄版輸入後關閉搜尋_標題恢復且搜尋欄回到原位 | U:XCUIApplication+SearchInteraction.swift:149 | 改名 (6.2 同步 ios-navigation.md) |
| Orders/OrdersListTests.swift | testCloseSearch_窄版收鍵盤後關閉搜尋_標題恢復且搜尋欄回到原位 | OrdersUITests | testTapSearchEndButton_窄版收鍵盤後關閉搜尋_標題恢復且搜尋欄回到原位 | U:XCUIApplication+SearchInteraction.swift:149 | 改名 |
| Orders/OrdersListTests.swift | testCloseSearch_窄版清除文字後關閉搜尋_標題恢復且搜尋欄回到原位 | OrdersUITests | testTapSearchEndButton_窄版清除文字後關閉搜尋_標題恢復且搜尋欄回到原位 | U:XCUIApplication+SearchInteraction.swift:149 | 改名 |
| Orders/OrdersListTests.swift | testSearch_沒有符合的訂單_顯示空狀態 | OrdersUITests | testSearchTextChanged_沒有符合的訂單_顯示空狀態 | F:Orders/Presentation/OrderList/OrderListFeature.swift:252 | 改名 |
| Orders/OrdersNavigationSmokeTests.swift | testOrders_選取訂單詳情與原生返回_Mika周017營收4980且path清空 | OrdersNavigationUITests | testDetailSelectionChanged_收合版選取訂單後原生返回_詳情顯示營收4980且path清空 | F:Orders/Presentation/Root/OrdersFeature.swift:222 | 改名、旅程 |
| Orders/OrdersNavigationSmokeTests.swift | testOrders_選取訂單後_path與詳情同步 | OrdersNavigationUITests | testDetailSelectionChanged_選取訂單_path與詳情同步 | F:Orders/Presentation/Root/OrdersFeature.swift:222 | 改名 |
| Orders/OrdersNavigationSmokeTests.swift | testOrders_改選另一筆訂單_path與詳情同步 | OrdersNavigationUITests | testDetailSelectionChanged_改選另一筆訂單_path與詳情同步 | F:Orders/Presentation/Root/OrdersFeature.swift:222 | 改名；H2：L142 的 skip 移到 open 之後、第一次 tapOrder 之前 |
| Orders/OrdersNavigationSmokeTests.swift | testOrders_搜尋排除詳情後清除path_恢復結果不自動選取 | OrdersNavigationUITests | testSearchTextChanged_搜尋排除詳情後恢復結果_清除path且不自動選取 | F:Orders/Presentation/OrderList/OrderListFeature.swift:252 | 改名、旅程；H2：L177 的 skip 移到 open 之後、第一次 tapOrder 之前 |
| Orders/OrdersNavigationSmokeTests.swift | testOrders_清除排除詳情的類別篩選_不自動選取訂單 | OrdersNavigationUITests | testClearFiltersTapped_類別篩選已排除詳情_清除後不自動選取訂單 | F:Orders/Presentation/OrderList/OrderListFeature.swift:247 | 改名、前提併入 Given (類別篩選排除詳情、path 清空)；H2：L232 的 skip 移到 open 之後、第一次 tapOrder 之前 |
| Orders/OrdersNavigationSmokeTests.swift | testOrders_編輯草稿與焦點_方向改變後保留單一Sheet | OrderEditRotationUITests | testDraft_編輯草稿與焦點轉向往返_保留草稿焦點與單一Sheet | F:Orders/Presentation/OrderEdit/OrderEditFeature.swift:25 | 改名、旅程；接續輸入的 typeText("X") 改 appendText (H5) |
| Orders/OrdersNavigationSmokeTests.swift | testOrders_編輯訂單取消_返回同筆詳情 | OrdersNavigationUITests | testCancelTapped_由詳情開啟編輯後取消_返回同筆詳情 | F:Orders/Presentation/OrderEdit/OrderEditFeature.swift:334 | 改名、前提併入 Given (開編輯、單一編輯根、客戶欄值) |
| Orders/OrdersNavigationSmokeTests.swift | testOrders_新增訂單單一Sheet_取消後回到訂單清單 | OrdersNavigationUITests | A testNewOrderTapped_訂單清單點新增_只呈現一層表單；B testCancelTapped_新增表單未修改取消_回到訂單清單 | A F:Orders/Presentation/OrderList/OrderListFeature.swift:260；B F:Orders/Presentation/OrderEdit/OrderEditFeature.swift:334 | 可拆 (A／B)：B 的 Given 到單一表單已呈現 |

##### Orders/Detail (9 → 9)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Orders/Detail/AISummaryTests.swift | testTapAISummary_AI未開啟_顯示提示且可關閉 | AISummaryUITests | testAiSummaryTapped_AI未開啟_顯示提示且可關閉 | F:Orders/Presentation/OrderList/OrderListFeature.swift:292 | 改名；C3：L35 tapAlertButton 移到 When 末尾 (受測動作 → requireCondition(呈現) → 關閉)，Then 只驗關閉後狀態與先存的提示內容 |
| Orders/Detail/AISummaryTests.swift | testTapAISummary_AI已開啟_推出總結且可關閉 | AISummaryUITests | testAiSummaryTapped_AI已開啟_推出總結且可關閉 | F:Orders/Presentation/OrderList/OrderListFeature.swift:292 | 改名；C3：L62 tapClose 移到 When 末尾，Then 只驗關閉後狀態與先存的總結內容 |
| Orders/Detail/OrderDetailMenuTests.swift | testOrderDetailMoreMenu_點編輯後取消_返回原訂單詳情 | OrderDetailMoreMenuUITests | testCancelTapped_由更多選單開啟編輯後取消_返回原訂單詳情 | F:Orders/Presentation/OrderEdit/OrderEditFeature.swift:334 | 改名 |
| Orders/Detail/OrderDetailMenuTests.swift | testOrderDetailMoreMenu_點合併後取消_返回原訂單詳情 | OrderDetailMoreMenuUITests | testCancelTapped_由更多選單開啟合併後取消_返回原訂單詳情 | F:Orders/Presentation/OrderMerge/OrderMergeFeature.swift:149 | 改名 |
| Orders/Detail/OrderDetailMenuTests.swift | testOrderDetailMoreMenu_點刪除後取消_保留原訂單詳情 | OrderDetailMoreMenuUITests | testCancelDelete_刪除確認選取消_保留原訂單詳情 | S:Orders/OrderDetailScreen.swift:164 | 改名 |
| Orders/Detail/OrderMergeTests.swift | testDismissSheetBySwipe_合併確認未修改_關閉表單並回到詳情 | MergeFlowUITests | 不變 | U:XCUIApplication+SheetInteraction.swift:23 | 不變 (移型別) |
| Orders/Detail/OrderDetailTests.swift | testOpenDetail_完整資料訂單_摘要卡顯示營收成本與獲利 | OrderDetailUITests | testDetailSelectionChanged_完整資料訂單_摘要卡顯示營收成本與獲利 | F:Orders/Presentation/Root/OrdersFeature.swift:222 | 改名 |
| Orders/Detail/OrderDetailTests.swift | testRelaunch_補勾貨到付款後重啟_獲利持久化為五百一十元 | OrderDetailUITests | testLaunch_補勾貨到付款後重啟_獲利持久化為五百一十元 | U:BLUITestCase.swift:29 | 改名 |
| Orders/Detail/PhotoViewerPagingTests.swift | testSwipeToNextPhoto_檢視器顯示第一張_換到第二張後可返回編輯表單 | PhotoViewerUITests | 不變 | S:Orders/PhotoViewerScreen.swift:40 | 不變；C3：L43 tapBack 移到 When 末尾 |

##### Orders/Edit (14 → 14)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Orders/Edit/KeyboardDismissTests.swift | testSubmitCustomerName_文字鍵盤顯示中_按return收起鍵盤 | OrderEditKeyboardDismissUITests | 不變 | S:Orders/OrderEditScreen.swift:164 | 不變 |
| Orders/Edit/KeyboardDismissTests.swift | testTapNumericKeyboardDone_數字鍵盤顯示中_收起鍵盤 | OrderEditKeyboardDismissUITests | 不變 | S:Orders/OrderEditScreen.swift:446 | 不變 |
| Orders/Edit/OrderEditDateRowTests.swift | testOrderDateRow_編輯既有訂單_顯示日期列與頁尾時間戳 | OrderEditDateRowUITests | testEditTapped_編輯既有訂單_顯示日期列與頁尾時間戳 | F:Orders/Presentation/OrderDetail/OrderDetailFeature.swift:144 | 改名 |
| Orders/Edit/OrderEditDirtyTests.swift | testCancel_進過選擇器返回且未修改_關閉表單 | OrderEditDirtyUITests | testCancelTapped_進過選擇器返回且未修改_關閉表單 | F:Orders/Presentation/OrderEdit/OrderEditFeature.swift:334 | 改名 |
| Orders/Edit/OrderEditDirtyTests.swift | testCancel_有變更後選繼續編輯_停留在表單 | OrderEditDirtyUITests | testTapAlertButton_有變更後取消選繼續編輯_停留在表單 | U:XCUIApplication+AlertInteraction.swift:85 | 改名 (繼續編輯沒有 AlertState action) |
| Orders/Edit/OrderEditDirtyTests.swift | testCancel_有變更後選捨棄變更_關閉表單並回到清單 | OrderEditDirtyUITests | testDiscard_有變更後取消選捨棄變更_關閉表單並回到清單 | F:Orders/Presentation/OrderEdit/OrderEditFeature.swift:372 | 改名 |
| Orders/Edit/OrderEditAddOptionTests.swift | testAddOrderSource_從訂單來源選擇器輸入名稱新增_關閉選擇器並選取新來源 | OrderEditAddOptionUITests | testAddOrderSourceTapped_從訂單來源選擇器輸入名稱新增_關閉選擇器並選取新來源 | F:Orders/Presentation/OrderEditPickers/OrderEditPickersFeature.swift:90 | 改名 |
| Orders/Edit/OrderEditAddOptionTests.swift | testAddPaymentMethod_從付款方式選擇器新增_回到選擇器且表單保留 | OrderEditAddOptionUITests | testAddPaymentMethodTapped_從付款方式選擇器新增_回到選擇器且表單保留 | F:Orders/Presentation/OrderEditPickers/OrderEditPickersFeature.swift:122 | 改名；C3：L91 picker.tapBack 移到 When 末尾 |
| Orders/Edit/OrderCreateTests.swift | testTapAddOrder_預設幣別日圓_幣別顯示日圓 | OrderEditCreateUITests | testNewOrderTapped_預設幣別日圓_幣別顯示日圓 | F:Orders/Presentation/OrderList/OrderListFeature.swift:260 | 改名；H8：assertCurrencyIsJapaneseYen 內的 submitCustomerName 移到 When 末尾 |
| Orders/Edit/OrderCreateTests.swift | testOpenCategoryPicker_預設幣別日圓_新訂單類別選擇器保留主檔選項 | OrderEditCreateUITests | testCategoryPickerTapped_預設幣別日圓_新訂單類別選擇器保留主檔選項 | F:Orders/Presentation/OrderEditPickers/OrderEditPickersFeature.swift:133 | 改名 |
| Orders/Edit/OrderCreateTests.swift | testTapCreateFirstOrder_預設幣別日圓_幣別顯示日圓 | OrderEditCreateUITests | testNewOrderTapped_首頁建立第一筆訂單且預設幣別日圓_幣別顯示日圓 | F:Dashboard/Presentation/Root/DashboardFeature.swift:153 | 改名；H8：assertCurrencyIsJapaneseYen 內的 submitCustomerName 移到 When 末尾 |
| Orders/Edit/OrderCreateTests.swift | testOpenCategoryPicker_預設幣別日圓_首頁建單後類別選擇器保留主檔選項 | OrderEditCreateUITests | testCategoryPickerTapped_預設幣別日圓_首頁建單後類別選擇器保留主檔選項 | F:Orders/Presentation/OrderEditPickers/OrderEditPickersFeature.swift:133 | 改名 |
| Orders/Edit/OrderCreateTests.swift | testSelectOption_客戶與來源已填後選商品類別_儲存按鈕轉為可用 | OrderEditCreateUITests | testCategorySelected_客戶與來源已填後選商品類別_儲存按鈕轉為可用 | F:Orders/Presentation/OrderEditPickers/OrderEditPickersFeature.swift:100 | 改名 |
| Orders/Edit/OrderCreateTests.swift | testTapSave_填寫必填與實付金額_清單出現新訂單 | OrderEditCreateUITests | testSaveTapped_填寫必填與實付金額_清單出現新訂單 | F:Orders/Presentation/OrderEdit/OrderEditFeature.swift:337 | 改名 |

##### Orders/Filters (20 → 20)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Orders/Filters/OrderCategoryPickerLargeTests.swift | testCategoryPickerLargeApply_捲到末格並選開團中類別_觸發鈕顯示兩項 | OrderCategoryPickerLargeUITests | testDoneTapped_捲到末格並選開團中類別_觸發鈕顯示兩項 | F:Orders/Presentation/OrderCategoryPicker/OrderCategoryPickerFeature.swift:154 | 改名 |
| Orders/Filters/OrderCategoryPickerTests.swift | testCategoryPickerMultiSelect_同列點兩格並完成_觸發鈕顯示兩項 | OrderCategoryPickerUITests | testDoneTapped_同列點兩格並完成_觸發鈕顯示兩項 | F:Orders/Presentation/OrderCategoryPicker/OrderCategoryPickerFeature.swift:154 | 改名 |
| Orders/Filters/OrderCategoryPickerTests.swift | testCategoryPickerSwipeDown_有未套用變更_不關閉 | OrderCategoryPickerUITests | testCategoryPickerBlocksSwipeDismiss_有未套用變更_不關閉 | S:Orders/OrderCategoryPickerScreen.swift:202 | 改名 |
| Orders/Filters/OrderCategoryPickerTests.swift | testCategoryPickerCancel_捨棄確認選繼續編輯_留在選擇器 | OrderCategoryPickerUITests | testTapDiscardKeepEditing_類別選擇器捨棄確認選繼續編輯_留在選擇器 | S:Orders/OrdersScreen.swift:560 | 改名 |
| Orders/Filters/OrderCategoryPickerTests.swift | testCategoryPickerSearch_輸入文字_顯示相符並隱藏不符類別 | OrderCategoryPickerUITests | testTypePickerSearch_輸入文字_顯示相符並隱藏不符類別 | S:Orders/OrderCategoryPickerScreen.swift:142 | 改名 (binding 取 Page Object) |
| Orders/Filters/OrderCategoryPickerTests.swift | testCategoryPickerSearch_清除搜尋_恢復被篩掉的類別並清空搜尋欄 | OrderCategoryPickerUITests | testSearchClearTapped_清除搜尋_恢復被篩掉的類別並清空搜尋欄 | F:Orders/Presentation/OrderCategoryPicker/OrderCategoryPickerFeature.swift:151 | 改名 |
| Orders/Filters/OrderFilterSheetLargeTests.swift | testFilterSheetLargeApply_展開已收單捲到末格_觸發鈕兩項且結果兩筆 | OrderFilterSheetLargeUITests | testFilterApplyTapped_展開已收單捲到末格_觸發鈕兩項且結果兩筆 | F:Orders/Presentation/OrderFilter/OrderFilterFeature.swift:173 | 改名 |
| Orders/Filters/OrderFilterSheetTests.swift | testFilterSheetCategoryCells_同列點兩格_兩格都被選取且其他格不變 | OrderFilterSheetUITests | testFilterPendingCategoryToggled_同列點兩格_兩格都被選取且其他格不變 | F:Orders/Presentation/OrderFilter/OrderFilterFeature.swift:148 | 改名 |
| Orders/Filters/OrderFilterSheetTests.swift | testFilterSheetCategoryCells_再點其中一格取消_只保留另一格 | OrderFilterSheetUITests | testFilterPendingCategoryToggled_再點其中一格取消_只保留另一格 | F:Orders/Presentation/OrderFilter/OrderFilterFeature.swift:148 | 改名 |
| Orders/Filters/OrderFilterSheetTests.swift | testFilterSheetApply_本月信用卡與兩類別_觸發鈕顯示兩項且結果為四筆 | OrderFilterSheetUITests | testFilterApplyTapped_本月信用卡與兩類別_觸發鈕顯示兩項且結果為四筆 | F:Orders/Presentation/OrderFilter/OrderFilterFeature.swift:173 | 改名 |
| Orders/Filters/OrderFilterSheetTests.swift | testFilterSheetClearThenApply_清除後套用_回到全部 | OrderFilterSheetUITests | testFilterClearTapped_清除後套用_回到全部 | F:Orders/Presentation/OrderFilter/OrderFilterFeature.swift:164 | 改名 |
| Orders/Filters/OrderFilterSheetTests.swift | testFilterSheetClear_值皆為預設_清除鈕停用 | OrderFilterSheetUITests | testFilterSheetTapped_值皆為預設_清除鈕停用 | F:Orders/Presentation/OrderList/OrderListFeature.swift:244 | 改名 |
| Orders/Filters/OrderFilterSheetTests.swift | testFilterSheetSwipeDown_有未套用變更_不關閉且保留選取 | OrderFilterSheetUITests | testFilterSheetBlocksSwipeDismiss_有未套用變更_不關閉且保留選取 | S:Orders/OrderFilterSheetScreen.swift:288 | 改名 |
| Orders/Filters/OrderFilterSheetTests.swift | testFilterSheetSwipeDown_無變更_可關閉 | OrderFilterSheetUITests | testDismissFilterSheetBySwipe_無變更_可關閉 | S:Orders/OrderFilterSheetScreen.swift:270 | 改名 |
| Orders/Filters/OrderFilterSheetTests.swift | testFilterSheetSwipeDown_選後再切回原狀_可關閉 | OrderFilterSheetUITests | testDismissFilterSheetBySwipe_選後再切回原狀_可關閉 | S:Orders/OrderFilterSheetScreen.swift:270 | 改名 |
| Orders/Filters/OrderFilterSheetTests.swift | testFilterSheetDiscard_繼續編輯_留在篩選畫面 | OrderFilterSheetUITests | testTapDiscardKeepEditing_篩選捨棄確認選繼續編輯_留在篩選畫面 | S:Orders/OrdersScreen.swift:560 | 改名；C3：L242 tapFilterApply 移到 When 末尾 (tapDiscardKeepEditing → requireCondition(sheet 仍開啟) → tapFilterApply)，Then 只留 assertTrigger |
| Orders/Filters/OrderFilterSheetTests.swift | testFilterSheetSearch_輸入文字_顯示相符並隱藏不符類別 | OrderFilterSheetUITests | testTypeFilterSearch_輸入文字_顯示相符並隱藏不符類別 | S:Orders/OrderFilterSheetScreen.swift:198 | 改名 |
| Orders/Filters/OrderFilterSheetTests.swift | testFilterSheetSearch_清除搜尋_恢復被篩掉的類別並清空搜尋欄 | OrderFilterSheetUITests | testFilterSearchClearTapped_清除搜尋_恢復被篩掉的類別並清空搜尋欄 | F:Orders/Presentation/OrderFilter/OrderFilterFeature.swift:170 | 改名 |
| Orders/Filters/OrderPaymentMethodMenuTests.swift | testPaymentMethodMenu_選信用卡_清單只列信用卡八筆 | OrdersPaymentMethodMenuUITests | testPaymentMethodFilterSelected_選信用卡_清單只列信用卡八筆 | F:Orders/Presentation/OrderList/OrderListFeature.swift:238 | 改名 |
| Orders/Filters/OrderPaymentMethodMenuTests.swift | testPaymentMethodMenu_選信用卡_觸發鈕標記已選取 | OrdersPaymentMethodMenuUITests | testPaymentMethodFilterSelected_選信用卡_觸發鈕標記已選取 | F:Orders/Presentation/OrderList/OrderListFeature.swift:238 | 改名 |

##### Orders/Regular (24 → 25，另新增 1 條 → 26)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Orders/Regular/OrderRegularAccessibilitySizeTests.swift | testRegularFilters_直向最大輔助字級_篩選區在清單捲動範圍內且不重疊 | OrdersRegularAccessibilitySizeUITests | testTask_直向最大輔助字級_篩選區在清單捲動範圍內且不重疊 | F:Orders/Presentation/OrderList/OrderListFeature.swift:220 | 改名 (When 只開清單) |
| Orders/Regular/OrderRegularAccessibilitySizeTests.swift | testRegularFilters_橫向最大輔助字級_篩選區在清單捲動範圍內且不重疊 | OrdersRegularAccessibilitySizeUITests | testRotateToLandscape_最大輔助字級_篩選區在清單捲動範圍內且不重疊 | U:XCTestCase+Orientation.swift:19 | 改名 |
| Orders/Regular/OrderRegularAccessibilitySizeTests.swift | testRegularFilters_標準字級_篩選區固定在清單捲動範圍上方 | OrdersRegularAccessibilitySizeUITests | testTask_標準字級_篩選區固定在清單捲動範圍上方 | F:Orders/Presentation/OrderList/OrderListFeature.swift:220 | 改名 |
| Orders/Regular/OrderRegularAccessibilitySizeTests.swift | testRegularFilters_最大輔助字級點標頭空白處_篩選不變且清除鈕仍可清除 | OrdersRegularAccessibilitySizeUITests | A testTapRegularHeaderGap_最大輔助字級點標頭空白處_篩選條件不變；B testClearFiltersTapped_最大輔助字級點標頭空白處後_清除鈕仍可清除 | A P19 OrdersScreen.tapRegularHeaderGap (待 5.2)；B F:Orders/Presentation/OrderList/OrderListFeature.swift:247 | 可拆 (A／B)：B 的 Given 做到點空白處且篩選不變並 requireCondition |
| (新增) | (無) | OrdersRegularAccessibilitySizeUITests | testDatePeriodSelected_最大輔助字級_選取欄外日期膠囊 | F:Orders/Presentation/OrderList/OrderListFeature.swift:233 | 5.4b 新增 (tasks 5.4)；依 K4 取 view Action，When 呼叫 S:Orders/OrdersScreen.swift:433 selectRegularDateChip |
| Orders/Regular/OrderRegularClearFiltersTests.swift | testRegularClearFilters_有篩選條件_三項回到預設且狀態維持 | OrdersRegularClearFiltersUITests | testClearFiltersTapped_有篩選條件_三項回到預設且狀態維持 | F:Orders/Presentation/OrderList/OrderListFeature.swift:247 | 改名 |
| Orders/Regular/OrderRegularClearFiltersTests.swift | testRegularClearFilters_無篩選條件_按鈕停用 | OrdersRegularClearFiltersUITests | testIsRegularClearFiltersEnabled_無篩選條件_按鈕停用 | S:Orders/OrdersScreen.swift:25 | 改名 |
| Orders/Regular/OrderRegularColumnScopeTests.swift | testRegularColumns_直向_清單控制項只在清單欄內 | OrdersRegularColumnScopeUITests | testDetailSelectionChanged_直向_清單控制項只在清單欄內 | F:Orders/Presentation/Root/OrdersFeature.swift:222 | 改名 |
| Orders/Regular/OrderRegularColumnScopeTests.swift | testRegularColumns_橫向_清單控制項只在清單欄內 | OrdersRegularColumnScopeUITests | testRotateToLandscape_已選取訂單_清單控制項只在清單欄內 | U:XCTestCase+Orientation.swift:19 | 改名 |
| Orders/Regular/OrderRegularColumnScopeTests.swift | testRegularColumns_直向_可見欄位依序並排且不重疊 | OrdersRegularColumnScopeUITests | testDetailSelectionChanged_直向_可見欄位依序並排且不重疊 | F:Orders/Presentation/Root/OrdersFeature.swift:222 | 改名 |
| Orders/Regular/OrderRegularColumnScopeTests.swift | testRegularColumns_直向叫出收起的側邊欄_覆蓋清單且不推移清單欄 | RootNavigationRegularColumnsUITests | testRevealSidebarIfCollapsed_直向叫出收起的側邊欄_覆蓋清單且不推移清單欄 | U:AppNavigator.swift:234 | 改名、移型別；H2：L96 的 XCTSkipIf 由實作者提前，主對話在 5.4b 的 iPad 執行確認 (裁決 8) |
| Orders/Regular/OrderRegularColumnScopeTests.swift | testRegularColumns_橫向_三欄依序並排且不重疊 | OrdersRegularColumnScopeUITests | testRotateToLandscape_已選取訂單_三欄依序並排且不重疊 | U:XCTestCase+Orientation.swift:19 | 改名 |
| Orders/Regular/OrderRegularColumnScopeTests.swift | testRegularColumns_選取訂單_詳情導覽列承載客戶與選單 | OrdersRegularColumnScopeUITests | testDetailSelectionChanged_選取訂單_詳情導覽列承載客戶與選單 | F:Orders/Presentation/Root/OrdersFeature.swift:222 | 改名 |
| Orders/Regular/OrderRegularColumnScopeTests.swift | testRegularColumns_進入多選_清單控制項與詳情導覽列各自獨立 | OrdersRegularColumnScopeUITests | testSelectionModeToggled_進入多選_清單控制項與詳情導覽列各自獨立 | F:Orders/Presentation/OrderList/OrderListFeature.swift:268 | 改名 |
| Orders/Regular/OrderRegularColumnScopeTests.swift | testRegularColumns_直向多選勾選一筆_清單欄頂部顯示已選筆數 | OrdersRegularColumnScopeUITests | testOrderSelectionToggled_直向多選勾選一筆_清單欄頂部顯示已選筆數 | F:Orders/Presentation/OrderList/OrderListFeature.swift:273 | 改名 |
| Orders/Regular/OrderRegularColumnScopeTests.swift | testRegularColumns_橫向多選勾選一筆_清單欄頂部顯示已選筆數 | OrdersRegularColumnScopeUITests | testRotateToLandscape_多選勾選一筆_清單欄頂部顯示已選筆數 | U:XCTestCase+Orientation.swift:19 | 改名 |
| Orders/Regular/OrderRegularColumnScopeTests.swift | testRegularColumns_搜尋無符合訂單_詳情只顯示空狀態 | OrdersRegularColumnScopeUITests | testSearchTextChanged_搜尋無符合訂單_詳情只顯示空狀態 | F:Orders/Presentation/OrderList/OrderListFeature.swift:252 | 改名 |
| Orders/Regular/OrderRegularColumnScopeTests.swift | testRegularColumns_切到總覽_訂單欄位消失且總覽佔滿 | RootNavigationRegularColumnsUITests | testTabSelected_切到總覽_訂單欄位消失且總覽佔滿 | F:App/Presentation/Root/RootFeature.swift:143 | 改名、移型別 |
| Orders/Regular/OrderRegularColumnScopeTests.swift | testRegularColumns_切回訂單_清單控制項歸屬正確且詳情保留 | RootNavigationRegularColumnsUITests | testTabSelected_切回訂單_清單控制項歸屬正確且詳情保留 | F:App/Presentation/Root/RootFeature.swift:143 | 改名、移型別 (assertListControls 經 OrdersRegularColumnScopeUITestSupport) |
| Orders/Regular/OrderRegularColumnWidthTests.swift | testRegularColumns_橫向訂單列與詳情摘要_可互動且不重疊 | OrdersRegularColumnWidthUITests | testOrderRow_橫向訂單列與詳情摘要_可互動且不重疊 | S:Orders/OrdersScreen.swift:347 | 改名；H2：L28 的 skip 移到 rotateToLandscape 後、tapOrder 前 |
| Orders/Regular/OrderRegularColumnWidthTests.swift | testRegularColumns_狀態膠囊可點_保留符合條件的path | OrdersRegularColumnWidthUITests | testStatusFilterSelected_狀態膠囊可點_保留符合條件的path | F:Orders/Presentation/OrderList/OrderListFeature.swift:228 | 改名；H2：L71 的 skip 移到 open 後、tapOrder 前 |
| Orders/Regular/OrderRegularSearchBarTests.swift | testRegularSearch_直向收鍵盤_標題保留且位置不變 | OrdersRegularSearchBarUITests | testSearchAndDismissKeyboard_直向收鍵盤_標題保留且位置不變 | S:Orders/OrdersScreen.swift:266 | 改名 |
| Orders/Regular/OrderRegularSearchBarTests.swift | testClearSearch_直向搜尋後清除文字_標題保留且位置不變 | OrdersRegularSearchBarUITests | testClearSearchText_直向搜尋後清除文字_標題保留且位置不變 | U:XCUIApplication+SearchInteraction.swift:138 | 改名 |
| Orders/Regular/OrderRegularSearchBarTests.swift | testRegularSearch_橫向收鍵盤_標題保留且位置不變 | OrdersRegularSearchBarUITests | testSearchAndDismissKeyboard_橫向收鍵盤_標題保留且位置不變 | S:Orders/OrdersScreen.swift:266 | 改名 |
| Orders/Regular/OrderRegularSearchBarTests.swift | testClearSearch_橫向搜尋後清除文字_標題保留且位置不變 | OrdersRegularSearchBarUITests | testClearSearchText_橫向搜尋後清除文字_標題保留且位置不變 | U:XCUIApplication+SearchInteraction.swift:138 | 改名 |
新增測試依 K4 取 view Action 定名 `testDatePeriodSelected_` (主對話代選)，When 呼叫 `selectRegularDateChip`。

##### Performance (1 → 1)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Performance/LaunchPerformanceTests.swift | testLaunch_冷啟動_量測啟動時間 | LaunchPerformanceTests | 不變 | XCUIApplication.launch() (XCTest API，Performance/LaunchPerformanceTests.swift:20) | 保留 (裁決 8)；只做 kit 排版對齊，維持正式啟動路徑 |


##### Smoke (14 → 14)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Smoke/AppLockTests.swift | testTapRetry_驗證替身失敗_重試後仍停在鎖定畫面 | AppLockUITests | testRetryUnlockTapped_驗證替身失敗_重試後仍停在鎖定畫面 | F:App/Presentation/AppLock/AppLockFeature.swift:62 | 改名 |
| Smoke/AppLockTests.swift | testLaunch_App鎖定啟用且驗證成功_自動解鎖顯示一般內容 | AppLockUITests | testScenePhaseChanged_App鎖定啟用且驗證成功_冷啟動自動解鎖顯示一般內容 | F:App/Presentation/AppLock/AppLockFeature.swift:67 | 改名 |
| Smoke/AppLockTests.swift | testLaunch_未啟用App鎖定_直接顯示一般內容 | AppLockUITests | testScenePhaseChanged_未啟用App鎖定_冷啟動直接顯示一般內容 | F:App/Presentation/AppLock/AppLockFeature.swift:67 | 改名 |
| Smoke/HarnessSelfCheckTests.swift | testRelaunch_有資料後改以空資料重啟_總覽顯示空狀態 | BLUITestConfigurationUITests | testLaunch_有資料後改以空資料重啟_總覽顯示空狀態 | U:BLUITestCase.swift:29 | 改名 |
| Smoke/HarnessSelfCheckTests.swift | testRelaunch_英文啟動後不指定語言重啟_不沿用英文且顯示中文 | BLUITestConfigurationUITests | testLaunch_英文啟動後不指定語言重啟_不沿用英文且顯示中文 | U:BLUITestCase.swift:29 | 改名 |
| Smoke/HarnessSelfCheckTests.swift | testLaunch_指定固定參考時間_日期副標題符合該時間且列出種子訂單 | BLUITestConfigurationUITests | 不變 | U:BLUITestCase.swift:29 | 不變 |
| Smoke/HarnessSelfCheckTests.swift | testTapSave_行事曆替身授予權限_不出現系統權限彈窗 | BLUITestConfigurationUITests | testSaveButtonTapped_行事曆替身授予權限_不出現系統權限彈窗 | F:Campaigns/Presentation/CampaignEdit/CampaignEditFeature.swift:167 | 改名；彈窗檢查改呼叫 BLUITestConfigurationUITestSupport.assertNoSystemPrompt |
| Smoke/LaunchSmokeTests.swift | testAdaptiveRoot_首次啟動_顯示五個原生分頁 | RootNavigationLaunchUITests | testVisibleRootTabCount_首次啟動_顯示五個原生分頁 | U:AppNavigator.swift:291 | 改名 |
| Smoke/LaunchSmokeTests.swift | testAdaptiveRoot_原生More與側邊欄切換_顯示品牌標記及五個入口 | RootNavigationLaunchUITests | testTabSelected_原生More與側邊欄切換_顯示品牌標記及五個入口 | F:App/Presentation/Root/RootFeature.swift:143 | 改名 |
| Smoke/LaunchSmokeTests.swift | testGoToDashboard_依序切過其他四個分頁後_總覽畫面就緒 | RootNavigationLaunchUITests | testTabSelected_依序切過其他四個分頁後_總覽畫面就緒 | F:App/Presentation/Root/RootFeature.swift:143 | 改名 |
| Smoke/OrientationLayoutTests.swift | testRotateToLandscape_含開團與訂單資料_根導覽與訂單篩選符合裝置版面 | RootNavigationOrientationUITests | 不變 | U:XCTestCase+Orientation.swift:19 | 不變 (Given 改 OrdersScreen.open(in:)) |
| Smoke/OrientationLayoutTests.swift | testRotateToLandscape_含開團與訂單資料_首頁附上橫向截圖 | DashboardOrientationUITests | testRotateToLandscape_含開團與訂單資料_首頁符合裝置版面 | U:XCTestCase+Orientation.swift:19 | 改名、拆型別 (裁決 4)；補版面斷言，截圖保留 |
| Smoke/OrientationLayoutTests.swift | testRotateToLandscape_含開團與訂單資料_訂單頁附上橫向截圖 | OrdersOrientationUITests | testRotateToLandscape_含開團與訂單資料_訂單頁符合裝置版面 | U:XCTestCase+Orientation.swift:19 | 改名、拆型別 (裁決 4)；補版面斷言，截圖保留 |
| Smoke/OrientationLayoutTests.swift | testRotateToLandscape_含開團與訂單資料_分析頁附上橫向截圖 | InsightsOrientationUITests | testRotateToLandscape_含開團與訂單資料_分析頁符合裝置版面 | U:XCTestCase+Orientation.swift:19 | 改名、拆型別 (裁決 4)；補版面斷言，截圖保留 |

##### Tools 之一 (Fx 4、Quote 4、SettingsGoal 2、ToolLoad 2；Tools 合計 36 → 36)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Tools/FxTests.swift | testTypeAmount_選美元後輸入金額_依固定匯率換算 | FxUITests | 不變 | S:Tools/FxScreen.swift:128 | 不變 |
| Tools/FxTests.swift | testTypeAmount_重複輸入相同金額_換算結果只計一次 | FxUITests | 不變 | S:Tools/FxScreen.swift:128 | 不變 |
| Tools/FxTests.swift | testContinueTyping_旋轉後續輸入_金額寫回同一欄 | FxUITests | testAmount_轉向後續輸入_金額寫回同一欄 | F:FX/Presentation/Root/FxFeature.swift:25 | 改名、旅程 |
| Tools/FxTests.swift | testKeyboardDismissal_收鍵盤後旋轉_鍵盤保持收起 | FxUITests | testRotateToLandscape_收鍵盤後轉向_鍵盤保持收起 | U:XCTestCase+Orientation.swift:19 | 改名 |
| Tools/QuoteTests.swift | testTypePrincipal_輸入商品本金_顯示建議售價 | QuoteUITests | 不變 | S:Tools/QuoteScreen.swift:202 | 不變 |
| Tools/QuoteTests.swift | testSelectOption_選取非預設幣別_報價頁套用來源幣別 | QuoteUITests | testCurrencySelected_選取非預設幣別_報價頁套用來源幣別 | F:Quote/Presentation/Root/QuoteFeature.swift:203 | 改名 |
| Tools/QuoteTests.swift | testContinueTyping_旋轉後續輸入_本金寫回同一欄 | QuoteUITests | testItemPrice_轉向後續輸入_本金寫回同一欄 | F:Quote/Presentation/Root/QuoteFeature.swift:25 | 改名、旅程 |
| Tools/QuoteTests.swift | testKeyboardDismissal_收鍵盤後旋轉_鍵盤保持收起 | QuoteUITests | testRotateToLandscape_收鍵盤後轉向_鍵盤保持收起 | U:XCTestCase+Orientation.swift:19 | 改名 |
| Tools/SettingsGoalInputTests.swift | testContinueTyping_旋轉後續輸入_目標金額寫回同一欄 | SettingsGoalInputUITests | testMonthlyProfitGoalTWD_轉向後續輸入_目標金額寫回同一欄 | F:Settings/Presentation/Root/SettingsFeature.swift:31 | 改名、旅程 |
| Tools/SettingsGoalInputTests.swift | testKeyboardDismissal_收鍵盤後旋轉_鍵盤保持收起 | SettingsGoalInputUITests | testRotateToLandscape_收鍵盤後轉向_鍵盤保持收起 | U:XCTestCase+Orientation.swift:19 | 改名 |
| Tools/ToolLoadTabSwitchTests.swift | testTabSwitch_匯率延遲讀取中切分頁後切回_讀取完成後顯示失敗訊息且可重試 | RootNavigationToolLoadUITests | testTabSelected_匯率延遲讀取中切分頁後切回_讀取完成後顯示失敗訊息且可重試 | F:App/Presentation/Root/RootFeature.swift:143 | 改名、旅程 (裁決 6，重試段不拆)；C3／C4：assertReadFailureShownAndRetryable 內的 When／Then 標記移回本體 (L33) |
| Tools/ToolLoadTabSwitchTests.swift | testTabSwitch_報價延遲讀取中切分頁後切回_讀取完成後顯示失敗訊息且可重試 | RootNavigationToolLoadUITests | testTabSelected_報價延遲讀取中切分頁後切回_讀取完成後顯示失敗訊息且可重試 | F:App/Presentation/Root/RootFeature.swift:143 | 改名、旅程 (裁決 6，重試段不拆)；C3／C4：assertReadFailureShownAndRetryable 內的 When／Then 標記移回本體 (L55) |


##### Tools 之二 (CurrencyPicker 24 → 24)
| 現行檔 | 現行方法名 | 新型別 | 新方法名 | 第一段出處 | 處理 |
| --- | --- | --- | --- | --- | --- |
| Tools/CurrencyPickerTests.swift | testOptionLabel_設定頁正體中文_顯示名稱 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:72 | 不變 |
| Tools/CurrencyPickerTests.swift | testSearch_設定頁正體中文輸入代碼_只保留新台幣列 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:50 | 不變 |
| Tools/CurrencyPickerTests.swift | testSearch_設定頁正體中文輸入名稱_只保留新台幣列 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:50 | 不變 |
| Tools/CurrencyPickerTests.swift | testOptionLabel_設定頁英文_顯示代碼 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:72 | 不變 |
| Tools/CurrencyPickerTests.swift | testSearch_設定頁英文輸入代碼_只保留新台幣列 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:50 | 不變 |
| Tools/CurrencyPickerTests.swift | testSearch_設定頁英文輸入名稱_只保留新台幣列 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:50 | 不變 |
| Tools/CurrencyPickerTests.swift | testOptionLabel_報價頁正體中文_顯示名稱 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:72 | 不變 |
| Tools/CurrencyPickerTests.swift | testSearch_報價頁正體中文輸入代碼_只保留新台幣列 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:50 | 不變 |
| Tools/CurrencyPickerTests.swift | testSearch_報價頁正體中文輸入名稱_只保留新台幣列 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:50 | 不變 |
| Tools/CurrencyPickerTests.swift | testOptionLabel_報價頁英文_顯示代碼 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:72 | 不變 |
| Tools/CurrencyPickerTests.swift | testSearch_報價頁英文輸入代碼_只保留新台幣列 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:50 | 不變 |
| Tools/CurrencyPickerTests.swift | testSearch_報價頁英文輸入名稱_只保留新台幣列 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:50 | 不變 |
| Tools/CurrencyPickerTests.swift | testOptionLabel_匯率頁正體中文_顯示名稱 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:72 | 不變 |
| Tools/CurrencyPickerTests.swift | testSearch_匯率頁正體中文輸入代碼_只保留新台幣列 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:50 | 不變 |
| Tools/CurrencyPickerTests.swift | testSearch_匯率頁正體中文輸入名稱_只保留新台幣列 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:50 | 不變 |
| Tools/CurrencyPickerTests.swift | testOptionLabel_匯率頁英文_顯示代碼 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:72 | 不變 |
| Tools/CurrencyPickerTests.swift | testSearch_匯率頁英文輸入代碼_只保留新台幣列 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:50 | 不變 |
| Tools/CurrencyPickerTests.swift | testSearch_匯率頁英文輸入名稱_只保留新台幣列 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:50 | 不變 |
| Tools/CurrencyPickerTests.swift | testOptionLabel_訂單編輯正體中文_顯示名稱 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:72 | 不變 |
| Tools/CurrencyPickerTests.swift | testSearch_訂單編輯正體中文輸入代碼_只保留新台幣列 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:50 | 不變 |
| Tools/CurrencyPickerTests.swift | testSearch_訂單編輯正體中文輸入名稱_只保留新台幣列 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:50 | 不變 |
| Tools/CurrencyPickerTests.swift | testOptionLabel_訂單編輯英文_顯示代碼 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:72 | 不變 |
| Tools/CurrencyPickerTests.swift | testSearch_訂單編輯英文輸入代碼_只保留新台幣列 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:50 | 不變 |
| Tools/CurrencyPickerTests.swift | testSearch_訂單編輯英文輸入名稱_只保留新台幣列 | OptionPickerCurrencyUITests | 不變 | S:Shared/OptionPickerScreen.swift:50 | 不變 |
(openPicker(_:language:) 的 .settings 與 .orderEdit 分支依下方「本地導覽 helper 的去向」改用 SettingsScreen.open(in:)、OrdersScreen.open(in:).tapAddOrder()；採 S2-S4 後四分支都取回傳的 OptionPickerScreen)


#### 新型別排序清單 (76 型別＋4 TestSupport＝80)
AdaptiveLayoutCheckCounterexampleTests AISummaryUITests AppLockLoadFailureUITests AppLockUITests BLUITestConfigurationUITests BLUITestConfigurationUITestSupport CampaignDetailUITests CampaignEditDateRowUITests CampaignEditInputFocusUITests CampaignEditUITests CampaignsAdaptiveLayoutUITests CampaignsProgressAccessibilityUITests CampaignsUITests CustomersLoadStateUITests CustomersUITests DashboardAdaptiveLayoutUITests DashboardLaunchLoadingUITests DashboardLayoutUITests DashboardOrientationUITests FxInputFocusUITests FxUITests InsightsLaunchLoadingUITests InsightsLayoutUITests InsightsOrientationUITests InsightsUITests LaunchPerformanceTests LookupManagementInputFocusUITests LookupManagementUITests MergeFlowInputFocusUITests MergeFlowUITests OptionPickerCurrencyUITests OptionPickerInputFocusUITests OrderCategoryPickerLargeUITests OrderCategoryPickerUITests OrderDetailMoreMenuUITests OrderDetailUITests OrderEditAddOptionUITests OrderEditCreateUITests OrderEditDateRowUITests OrderEditDirtyUITests OrderEditDraftRotationUITests OrderEditInputFocusUITests OrderEditKeyboardDismissUITests OrderEditRenamedCategoryUITests OrderEditRotationUITests OrderFilterSheetLargeUITests OrderFilterSheetUITests OrdersAdaptiveLayoutUITests OrdersLoadFailureUITests OrdersNavigationUITests OrdersOrientationUITests OrdersPaymentMethodMenuUITests OrdersRegularAccessibilitySizeUITests OrdersRegularClearFiltersUITests OrdersRegularColumnScopeUITests OrdersRegularColumnScopeUITestSupport OrdersRegularColumnWidthUITests OrdersRegularSearchBarUITests OrdersSearchInputFocusUITests OrdersSelectionUITests OrdersUITests OrdersUITestSupport PhotoViewerUITests QuoteInputFocusUITests QuoteUITests RootNavigationCampaignLoadFailureUITests RootNavigationContinuityUITests RootNavigationCustomerOrdersUITests RootNavigationLaunchUITests RootNavigationLoadFailureUITests RootNavigationMoreUITests RootNavigationOrientationUITests RootNavigationOrientationUITestSupport RootNavigationReadableWidthUITests RootNavigationRegularColumnsUITests RootNavigationScenarioUITests RootNavigationToolLoadUITests SettingsGoalInputUITests SettingsInputFocusUITests SettingsLanguageUITests

檢查 (在 apps/ios 下以 bash 執行，NEW 為上列 80 個名稱)：
- `printf '%s\n' $NEW | sort | uniq -d` → 空；`wc -l` → 80；`grep -c 'TestSupport$'` → 4；上列順序與 sort 結果相同。
- `EX=$(grep -rhoE '(class|struct|enum|protocol|actor) [A-Z][A-Za-z0-9_]*' BuyLedger BuyLedgerTests BuyLedgerUITests/Support BuyLedgerUITests/Screens BuyLedgerAccessibilityIDs | awk '{print $NF}' | sort -u)` (1309 個型別名)；`comm -12 <(printf '%s\n' $NEW | sort) <(echo "$EX")` → 空。
- 陽性對照：同一個 EX 對 OrderMergeTests、BLUITestConfigurationTests、OrdersScreen 做 comm -12，三個都命中，確認比對有效。


#### 測試數與任務分組
指令：`grep -rc 'func test' apps/ios/BuyLedgerUITests/Tests | awk -F: '{s+=$2} END {print s}'` → 253 (59 檔)。
算式：253 ＋ 可拆型 10 ＋ 5.4b 新增 1 − 刪除 0 ＝ 264。可拆型 10 條：CampaignFlowTests 的 testSaveButtonTapped_、CustomersLoadStateTests 的延遲讀取那條、OrderEditInputFocusUITests 的 testFocusCardlessDeduction_、LookupManagementTests 4 條 (testRequestDeletion_刪除寫入失敗、testRequestDeletion_長按選單刪除寫入失敗、testAddItem_新增寫入失敗、testAddForm_未儲存取消)、ReadableWidthUITests、OrderRegularAccessibilitySizeTests 的點標頭空白處、OrdersNavigationSmokeTests 的新增訂單單一Sheet。裁決 7 刪的是步驟，不是測試；CampaignFlowTests 整檔刪除但 11 條全部移出；ToolLoad 依裁決 6 不拆。
| 任務 | 範圍 | 4.7 數量 | 新增 | 拆分新增 | 刪除 | 結果 |
| --- | --- | --- | --- | --- | --- | --- |
| 5.4a | Orders/Filters | 20 | 0 | 0 | 0 | 20 |
| 5.4b | Orders/Regular | 24 | 1 | 1 | 0 | 26 |
| 5.5 | Orders/Detail＋Orders/Edit | 23 | 0 | 0 | 0 | 23 |
| 5.6a | Orders 根層 | 15 | 0 | 1 | 0 | 16 |
| 5.6b | Smoke＋Performance | 15 | 0 | 0 | 0 | 15 |
| 5.7a | Navigation/AdaptiveNavigationContinuityUITests | 17 | 0 | 0 | 0 | 17 |
| 5.7b | Navigation 其餘 4 檔 | 16 | 0 | 1 | 0 | 17 |
| 5.8 | Campaigns＋Customers | 25 | 0 | 2 | 0 | 27 |
| 5.9a | Forms | 37 | 0 | 1 | 0 | 38 |
| 5.9b | Tools | 36 | 0 | 0 | 0 | 36 |
| 5.10 | Dashboard＋Insights＋More | 25 | 0 | 4 | 0 | 29 |
| 合計 | | 253 | 1 | 10 | 0 | 264 |
新型別的落點：5.10 的 More 資料夾含 OrderEditRenamedCategoryUITests (1 條)；5.4b 含 RootNavigationRegularColumnsUITests (3 條)；5.6b 含 4 個 Orientation 型別與 2 個 TestSupport。

驗證狀態：表中 App Action、State、Page Object、Support 的出處行號都在現行工作樹以 grep 對過宣告行；P16、P19、Q10 待 5.2／5.3 新增後才 grep 得到。沒有 build／test。完。

#### identifier 引用盤點

##### 分類規則 (t17 建議，主對話採用)
- N 沒有 Page Object：「更多」入口清單 (More.root、More.row(...))、更多分欄的詳情提示 (更多頁的 Common.detailEmptyState)、更多選取標記 (Common.selectedItem(.more))。依據：`ls Screens/More` 只有 LookupManagementScreen、SettingsScreen，沒有入口清單的 Page Object；design 也把「更多」入口清單列為沒有 Page Object 的受測對象。
- M 要遷移：受測畫面有 Page Object 的直接查詢，含把 identifier 交給測試檔本地 helper／本地型別的 (例 ToolLoadElements、OrientationLayoutTests.rows)。量 App 元素框線時由 Page Object 提供元素 (design「只有測試要量框線或交給 Support 的輸入 helper 時才提供元素」)。目標寫「現有 X」或新增方法編號：P = 5.2、Q = 5.3、S = 5.3 的既有方法回傳形狀補正 (第 7、8 段)。
- K 共用斷言的參數 (保留)：傳給 Support 的 `assertEmptyState`、`assertLoadStateStaysStable`、`tapAlertButton(_:)`、`tapMenuItem(_:label:)`；Support 單一快照 `framesInSingleSnapshot` 結果的鍵 (裁決 D1)；餵給 Support 純值檢查型別的值；系統容器 (根側邊欄) 的存在與框線；KPI／SummaryTile 列舉的型別標註 (Page Object 方法的參數型別，不是查詢)。
- 計數單位是 grep 的「行」：OrderListLoadFailureTests:43 一行兩個 identifier 算 1 筆。

##### 總數
指令：`grep -rn 'BLAccessibilityID\.' apps/ios/BuyLedgerUITests/Tests | wc -l` → 230；各資料夾以 `grep -rnc` 加總核對。
| 資料夾 | 筆數 | N | M | K |
| --- | --- | --- | --- | --- |
| Campaigns | 14 | 0 | 7 | 7 |
| Customers | 10 | 0 | 5 | 5 |
| Dashboard | 8 | 0 | 0 | 8 |
| Forms | 2 | 0 | 2 | 0 |
| Insights | 7 | 0 | 0 | 7 |
| More | 12 | 4 | 6 | 2 |
| Navigation | 79 | 10 | 30 | 39 |
| Orders 根層 | 20 | 0 | 16 | 4 |
| Orders/Detail | 10 | 0 | 9 | 1 |
| Orders/Edit | 8 | 0 | 8 | 0 |
| Orders/Filters | 1 | 0 | 1 | 0 |
| Orders/Regular | 40 | 0 | 39 | 1 |
| Performance | 0 | 0 | 0 | 0 |
| Smoke | 10 | 1 | 8 | 1 |
| Tools | 9 | 0 | 3 | 6 |
| 合計 | 230 | 15 | 134 | 81 |
(design 估「約 140 處全部遷移」，實數 134；其中 CampaignFlowTests:104、OrdersNavigationSmokeTests:191 遷移後改傳給 `assertEmptyState`，仍留 identifier 字面但屬 K)

##### Campaigns (14：N 0／M 7／K 7)
| 檔:行 | 查詢 | 類 | 目標 |
| --- | --- | --- | --- |
| CampaignListTests:22 | Campaigns.listEmptyState | K | assertEmptyState |
| CampaignFlowTests:27、50 | Campaigns.listLoadFailure | M | Q1 waitForLoadFailure |
| CampaignFlowTests:28、51 | listLoadFailureRetryButton | M | Q2 waitForRetryButton (可點前置與 Then)＋Q3 tapRetry |
| CampaignFlowTests:80 | Campaigns.addButton | M | 現有 `CampaignsScreen.tapAdd()` (tapAfterWaiting 的失敗出口涵蓋「不可點」；open(in:) 的就緒條件已含新增鈕)，刪 L81 前置；採 S1 時接回傳的 CampaignEditScreen |
| CampaignFlowTests:104 | Campaigns.listEmptyState | M | 現有 Support `assertEmptyState(BLAccessibilityID.Campaigns.listEmptyState, in:)` |
| CampaignListLoadFailureLoopTests:20 | Common.selectedItem(.campaigns) | M | Q4 destinationContainer (guard 等容器、`.progressIndicators.firstMatch` 交給 absentElements) |
| CampaignListLoadFailureLoopTests:35、36、49、50、63、64 | listLoadFailure／RetryButton | K | assertLoadStateStaysStable |

##### Customers (10：N 0／M 5／K 5)
| 檔:行 | 查詢 | 類 | 目標 |
| --- | --- | --- | --- |
| CustomersLoadStateTests:28、63 | Customers.listEmptyState (`!exists`) | M | Q5 hasEmptyState(timeout: 0) |
| CustomersLoadStateTests:48 | Orders.listLoadFailure (Given) | M | P1 OrdersScreen.waitForLoadFailure |
| CustomersLoadStateTests:70 | Customers.listLoading | M | Q6 waitForLoading |
| CustomersLoadStateTests:86 | listLoadFailureRetryButton | M | Q7 tapRetry |
| CustomersLoadStateTests:148、149、151、152 | 失敗／重試／載入中／空狀態 | K | assertLoadStateStaysStable (private assertLoadFailureStaysStable 內) |
| CustomersTests:47 | Customers.listEmptyState | K | assertEmptyState |

##### Dashboard (8：N 0／M 0／K 8)
| 檔:行 | 查詢 | 類 | 目標 |
| --- | --- | --- | --- |
| DashboardLayoutSmokeTests:163、168、173、179、185、191、202、209 | `snapshot.frames[...]` 的鍵 (日期副標、四項 KPI 卡、淨利 hero、開團列、近期訂單列) | K | Support `framesInSingleSnapshot` 結果的鍵；identifier 清單由現有 `DashboardScreen.prepareLayoutSnapshot(campaignID:orderID:)` 提供 (裁決 D1) |

##### Forms (2：N 0／M 2／K 0)
| 檔:行 | 查詢 | 類 | 目標 |
| --- | --- | --- | --- |
| SearchInputFocusUITests:176 | Orders.filterSearchField | M | P30 `OrderFilterSheetScreen.filterSearchField` (取 `openFilterSheet()` 的回傳值；欄位交給 Support 的 tapLeftToFocus／dismissSearchKeyboard) |
| SearchInputFocusUITests:180 | Orders.categoryPickerSearchField | M | P32 `OrderCategoryPickerScreen.pickerSearchField` (取 `openCategoryPicker()` 的回傳值) |

##### Insights (7：N 0／M 0／K 7)
| 檔:行 | 查詢 | 類 | 目標 |
| --- | --- | --- | --- |
| InsightsLayoutSmokeTests:137、144、149、154、159、164 | `snapshot.frames[...]` 的鍵 (開團排行、期間選擇器、趨勢、類別排行、成本圓餅、熱力圖) | K | 同 Dashboard (D1)；清單由現有 `InsightsScreen.prepareLayoutSnapshot(category:campaignID:)` 提供 |
| InsightsTests:126 | Insights.emptyState | K | assertEmptyState |

##### More (12：N 4／M 6／K 2)
| 檔:行 | 查詢 | 類 | 目標 |
| --- | --- | --- | --- |
| LookupManagementTests:84 | OptionPicker.root | M | 現有 `OrderEditScreen.openCategoryPicker()` 已回傳就緒的 OptionPickerScreen (L85 的等待刪除) |
| LookupManagementTests:87 | OptionPicker.optionRow("衣著") | M | Q15 hasOption |
| LookupManagementTests:93 | OptionPicker.optionRow("服飾") (`!exists`) | M | Q15 hasOption(_, timeout: 0) |
| LookupManagementTests:373、398 | LookupManagement.discardAlert…Button | K | Support `tapAlertButton(_:)` (5.10 只做變異檢查；裁決 D6) |
| MoreNavigationSmokeTests:26、28、69、73 | More.row(.fx／.quote／.settings／.fx) | N | 更多入口清單 |
| MoreNavigationSmokeTests:30 | Fx.root | M | 現有 `FxScreen(app:).waitUntilReady()`、`isDisplayed` (L35、42、53) |
| MoreNavigationSmokeTests:31 | Quote.root | M | 現有 `QuoteScreen(app:).waitUntilReady()` |
| MoreNavigationSmokeTests:71 | Settings.root | M | 現有 `SettingsScreen(app:).waitUntilReady()` |

##### Navigation 之一 (Counterexample 11、Adaptive 31)
AdaptiveLayoutCheckCounterexampleTests:19、20、34、40、45、123、124、146、147、148、149 → K 全部：純值餵給 Support 的 IdentifierCheck／KPIPresenceCheck／PathCheck (含 KPI 型別標註)，不啟動 App、不查元素。

AdaptiveNavigationContinuityUITests (31：N 7／M 18／K 6)
| 行 | 查詢 | 類 | 目標 |
| --- | --- | --- | --- |
| 130、461、555 | More.row(.settings) | N | 更多入口清單 |
| 471 | More.row(.fx) | N | 更多入口清單 |
| 758 | More.row(.customers) | N | 更多入口清單 |
| 454 | Common.detailEmptyState (更多寬版) | N | 更多詳情欄提示 |
| 1530 | Common.selectedItem(.more) | N | 更多選取標記 (private requireMoreSelection) |
| 282 | Orders.paymentMethodMenuButton | M | P9 paymentMethodTrigger (存在、label 等待；label 讀值續用現有 paymentMethodTriggerLabel()) |
| 285 | Orders.categoryFilterButton | M | P10 categoryTrigger |
| 564 | Settings.root | M | 現有 SettingsScreen 的 waitUntilReady()／rootElement.waitForDisappearance／isDisplayed (L567、706、729、732) |
| 571 | Settings.monthlyGoalField | M | 現有 `monthlyGoalField`＋`monthlyGoalFieldValue(timeout:)` (L574-579、624-629、682-687) |
| 767 | Customers.listRoot | M | 現有 `CustomersScreen(app:).waitUntilReady()` |
| 774 | Customers.listEmptyState (`!exists`) | M | Q5 hasEmptyState(timeout: 0) |
| 779 | Customers.row(customerName:) | M | Q8 customerRowLabel |
| 801、804 | Orders.listRoot／detailRoot 計數 | M | P20 listRootCount／detailRootCount |
| 822 | Orders.orderCountLabel (L888 重用) | M | P14 orderCountLabel |
| 1008 | OrderEdit.customerField | M | 現有 `OrderEditScreen.customerField`／`customerValue` |
| 1129、1226 | Orders.statusChip("all"／"shipping") | M | P7 statusChip |
| 1136 | Orders.addButton | M | P12 addButton |
| 1328 | Campaigns.row(campaignID:) | M | 現有 `CampaignsScreen.campaignRow(campaignID:)`.isSelected |
| 1408 | Dashboard.kpiTile(kpi) 框線 | M | Q10 kpiTile |
| 1515 | Orders.detailEmptyState | M | P5 hasDetailEmptyState |
| 1590 | Orders.listRoot 框線 | M | 現有 `OrdersScreen.rootElement` |
| 1064、1405、1555、1556、1561 | Dashboard.KPI 型別標註 | K | 現有 `kpiValue(_:)` 的參數型別 |
| 1119 | Root.sidebar 框線 | K | 系統側邊欄範圍 (AppNavigator 的 marker 為 private，屬 Support) |


##### Navigation 之二 (Reload 29、Scenario 6、ReadableWidth 2；Navigation 合計 79：N 10／M 30／K 39)
LoadFailureReloadLoopTests (29：N 0／M 8／K 21)
| 行 | 查詢 | 類 | 目標 |
| --- | --- | --- | --- |
| 28-30、40-42、52-54、88-90、127-129、162-164、210-212 | 訂單／總覽／分析的失敗、重試、載入中 | K | assertLoadStateStaysStable |
| 65、101 | Orders.listLoadFailure (Given) | M | P1 OrdersScreen.waitForLoadFailure |
| 81、120 | Orders.listLoading | M | P2 OrdersScreen.waitForLoading |
| 73 | Insights.loading | M | Q13 InsightsScreen.waitForLoading |
| 111 | Customers.listLoading | M | Q6 CustomersScreen.waitForLoading |
| 153、182 | Dashboard.loading | M | Q9 DashboardScreen.waitForLoading |

NavigationScenarioUITests (6：N 2／M 3／K 1)
| 行 | 查詢 | 類 | 目標 |
| --- | --- | --- | --- |
| 32 | Orders.selectionSummary (label 等待、框線) | M | P15 selectionSummary |
| 41 | Orders.batchStatusMenuButton (框線、可點) | M | P16 batchStatusMenuButton |
| 120、150 | More.root | N | 更多入口清單 |
| 122 | Settings.root (消失) | M | 現有 `settings.rootElement.waitForDisappearance(timeout:)` (同一測試已有 `settings` 變數) |
| 146 | Settings.languageOption(...) | K | Support `tapMenuItem(_:label:)` (D6) |

ReadableWidthUITests (2：N 1／M 1／K 0)
| 行 | 查詢 | 類 | 目標 |
| --- | --- | --- | --- |
| 65 | More.root (入口清單欄框線) | N | 更多入口清單 |
| 102 | Settings.defaultCurrencyRow (交給 assertCenteredRow 量框線) | M | Q17 SettingsScreen.defaultCurrencyRow |

##### Orders 根層 (20：N 0／M 16／K 4)
| 檔:行 | 查詢 | 類 | 目標 |
| --- | --- | --- | --- |
| OrderListLoadFailureTests:21 | Orders.listLoadFailure | M | P1 waitForLoadFailure |
| OrderListLoadFailureTests:22 | Orders.listEmptyState (`!exists`，L31) | M | P4 hasEmptyState(timeout: 0) |
| OrderListLoadFailureTests:23 | Orders.listLoading | M | P2 waitForLoading |
| OrderListLoadFailureTests:24 | listLoadFailureRetryButton | M | P3 tapRetry (L32 的「可點」前置由 tapRetry 的失敗出口涵蓋；L41-43 的取樣仍檢查重試鍵常駐) |
| OrderListLoadFailureTests:41、42、43 | 失敗／重試／載入中＋空狀態 | K | assertLoadStateStaysStable |
| OrdersListTests:157 | Orders.listEmptyState | K | assertEmptyState |
| OrdersNavigationSmokeTests:42、159、393 | Orders.detailMoreButton (等可點) | M | P23 OrderDetailScreen.moreButton＋Support waitUntilHittable |
| OrdersNavigationSmokeTests:58 | 以 detailMoreButton 錨定導覽列讀動態標題 | M | 現有 `OrdersScreen.navigationBarTitle("Mika 周")` (Support 標題 helper；5.6「導覽列動態標題改用共用 helper」) |
| OrdersNavigationSmokeTests:191 | Orders.listEmptyState | M | 現有 Support `assertEmptyState(BLAccessibilityID.Orders.listEmptyState, in:)` |
| OrdersNavigationSmokeTests:199 | Orders.detailEmptyState (存在且有快照框線) | M | P5 hasDetailEmptyState |
| OrdersNavigationSmokeTests:283、372 | OrderEdit.customerField | M | 現有 `OrderEditScreen.customerField`／`customerValue` |
| OrdersNavigationSmokeTests:364、428 | OrderEdit.root 計數 == 1 | M | P26 presentedRootCount |
| OrdersNavigationSmokeTests:385、440 | OrderEdit.root 消失 | M | 現有 `OrderEditScreen.rootElement`＋waitForDisappearance |

##### Orders/Detail (10：N 0／M 9／K 1)
| 檔:行 | 查詢 | 類 | 目標 |
| --- | --- | --- | --- |
| AISummaryTests:64 | AISummary.root (消失) | M | 現有 `AISummaryScreen.rootElement`＋waitForDisappearance |
| PhotoViewerPagingTests:44 | PhotoViewer.root (消失) | M | 現有 `PhotoViewerScreen.rootElement` |
| OrderDetailTests:26 | Orders.SummaryTile 型別標註 | K | 現有 `summaryValue(_:)` 的參數型別 |
| OrderDetailTests:76 | More.row(.paymentMethods) (連同 L73 goToMore) | M | 現有 `LookupManagementScreen.open(.paymentMethods, in:)` |
| OrderDetailTests:81 | LookupManagement.root | M | 現有 `LookupManagementScreen.open(.paymentMethods, in:)` (open 已等前景) |
| OrderDetailTests:88 | LookupManagement.row(name) | M | 現有 `itemRow(named:)`；L132-137 的徽章比對改現有 `paymentMethodClassification(named:)` (5.5、3.1) |
| OrderDetailTests:94 | LookupManagement.editButton(name) | M | 現有 `beginEditPaymentMethod(named:)` (涵蓋 L90-96 的等待、左滑、點編輯，回傳 PaymentMethodEditorScreen) |
| OrderDetailTests:99 | paymentMethodCashOnDeliveryToggle | M | Q18 isCashOnDeliveryOn (L107)＋Q19 toggleCashOnDelivery (L101-105、113-118) |
| OrderDetailTests:103 | paymentMethodEditorRoot (捲動容器) | M | Q19 內部使用現有 `PaymentMethodEditorScreen.rootElement` |
| OrderDetailTests:121 | paymentMethodSaveButton | M | 現有 `PaymentMethodEditorScreen.tapSave()` |


##### Orders/Edit (8：N 0／M 8／K 0)
| 檔:行 | 查詢 | 類 | 目標 |
| --- | --- | --- | --- |
| KeyboardDismissTests:49 | OrderEdit.chargedAmountField 讀值 | M | 現有 `OrderEditScreen.chargedAmountValue` |
| OrderEditAddOptionTests:47 | OrderEdit.sourceRow label 等待 | M | P28 waitForSourceLabel(containing:) (label 比對本身屬 B4 Non-Goal，只換查詢入口) |
| OrderEditAddOptionTests:86 | OptionPicker.optionRow | M | Q15 hasOption |
| OrderEditAddOptionTests:95 | OrderEdit.paymentRow label 等待 | M | P29 waitForPaymentLabel(containing:) |
| OrderCreateTests:122 | OrderEdit.saveButton 等 isEnabled | M | P27 waitForSaveEnabled (現有 isSaveEnabled 是立即讀值，Then 需要等狀態轉換) |
| OrderCreateTests:186 | OrderEdit.currencyRow label 含日圓 | M | 現有 `currencyCode()` 比對 "JPY" (5.5 指定) |
| OrderCreateTests:202 | OptionPicker.optionRow | M | Q15 hasOption |
| OrderEditDirtyTests:92 | OrderEdit.root 消失 | M | 現有 `rootElement`＋waitForDisappearance |

##### Orders/Filters (1：N 0／M 1／K 0)
| 檔:行 | 查詢 | 類 | 目標 |
| --- | --- | --- | --- |
| OrderFilterSheetTests:133 | Orders.filterClearButton 存在＋isEnabled | M | P31 isFilterClearEnabled (形狀同 OrderEditScreen.isSaveEnabled) |

##### Orders/Regular (40：N 0／M 39／K 1)
OrderRegularAccessibilitySizeTests (10，全 M)
| 行 | 查詢 | 目標 |
| --- | --- | --- |
| 80、145 | Orders.listRoot 框線 | 現有 `OrdersScreen.rootElement` |
| 83 | Orders.clearFiltersButton 框線 | P11 regularClearFiltersButton |
| 148、149、150、151、152 | 狀態膠囊、全部時間膠囊、付款方式、類別、清除篩選 (identifier, 名稱) 陣列 | P7 statusChip、P8 dateChip、P9 paymentMethodTrigger、P10 categoryTrigger、P11；陣列改成 (XCUIElement, 名稱) |
| 185、188 | private tapHeaderGap 內的 listRoot、clearFiltersButton | P19 tapRegularHeaderGap (把 tapHeaderGap 搬進 Page Object；裁決 D3) |

OrderRegularColumnScopeTests (26：M 25／K 1)
| 行 | 查詢 | 目標 |
| --- | --- | --- |
| 155 | Orders.row(orderID:) isSelected | 現有 `orderRow(orderID:)` |
| 178、179、180 | selectAllButton、batchStatusMenuButton、selectionDoneButton 框線 | P17、P16、P18 |
| 272 | Orders.detailEmptyState 出現 | P5 hasDetailEmptyState |
| 275、628 | Orders.detailStatusMenuButton 消失／框線 | P24 OrderDetailScreen.statusMenuButton |
| 276、629 | Orders.detailMoreButton 消失／框線 | P23 OrderDetailScreen.moreButton |
| 310 | Orders.listRoot 消失 | 現有 `OrdersScreen.rootElement` |
| 311 | Orders.detailRoot 消失 | 現有 `OrderDetailScreen.rootElement` |
| 312 | Orders.detailEmptyState 消失 | P6 waitForDetailEmptyStateDismissal |
| 341 | Orders.detailRoot 出現 | 現有 `OrderDetailScreen.waitUntilReady()` |
| 458、459、460 | orderCountLabel、addButton、batchMenuButton 框線 (assertListControls) | P14、P12、P13 |
| 497、619 | Orders.listRoot 框線 | 現有 `rootElement` |
| 602、603、604、605、606 | requireDetailColumnLeadingEdge 的五個錨點 | 現有 Support `foregroundOrdersDetailFrame(in:)` (5.4 指定改用，整段刪除，不需新方法) |
| 670 | Orders.selectionSummary (label 等待並回傳元素) | P15 selectionSummary |
| 689 | Dashboard.root 框線 | 現有 `DashboardScreen(app:).rootElement` |
| 521 | Root.sidebar 是否存在 (K) | 系統側邊欄存在判斷，與 AdaptiveNavigationContinuityUITests:1119 同類 |

OrderRegularColumnWidthTests (3，全 M)：34 Orders.detailSummaryTile(.revenue) 框線 → P25 summaryTile；37 Orders.detailMoreButton 框線 → P23；73 Orders.statusChip("shipping") 框線 → P7。
OrderRegularSearchBarTests (1，M)：225 Orders.listRoot 框線 → 現有 `rootElement`。

##### Performance (0 筆)
LaunchPerformanceTests 沒有 identifier 查詢。

##### Smoke (10：N 1／M 8／K 1)
| 檔:行 | 查詢 | 類 | 目標 |
| --- | --- | --- | --- |
| AppLockTests:30 | AppLock.retryButton 出現 | M | Q20 AppLockScreen.waitForRetryButton |
| HarnessSelfCheckTests:44 | Dashboard.emptyState | K | assertEmptyState |
| HarnessSelfCheckTests:60、80 | Dashboard.emptyStateActionButton 出現並讀 label (語言) | M | Q11 emptyStateActionLabel |
| HarnessSelfCheckTests:121 | Dashboard.currentDateSubtitle 出現並讀 label | M | Q12 currentDateSubtitle |
| LaunchSmokeTests:53 | More.root | N | 更多入口清單 |
| OrientationLayoutTests:152 | Orders.filterButton (private filterButton(in:)；L136 等 2 秒判不存在、L141 等 10 秒判存在) | M | P21 hasFilterTrigger(timeout:)；filterButton(in:) 刪除 |
| OrientationLayoutTests:164 | Dashboard.kpiTile(.revenue) 交給捲動 | M | Q10 kpiTile |
| OrientationLayoutTests:211 | Orders.row 前綴 (private rows(withIdentifierPrefix:)) | M | P22 hasHittableOrderRow |
| OrientationLayoutTests:236 | Insights.categoryRankRow 前綴＋捲動露出 | M | Q14 revealFirstCategoryRank；rows(withIdentifierPrefix:) 兩處都改後刪除 |
備註：5.6 依裁決 4 為三個截圖測試補版面斷言時，若需要本表以外的元素或框線，依 tasks「表上沒有的情況停下回報」。

##### Tools (9：N 0／M 3／K 6)
| 檔:行 | 查詢 | 類 | 目標 |
| --- | --- | --- | --- |
| CurrencyPickerTests:416 | More.row(.settings) (連同 L415 goToMore、L418-419 等待) | M | 現有 `SettingsScreen.open(in:)` |
| CurrencyPickerTests:458 | OptionPicker.optionRow(KRW) 出現 | M | Q15 hasOption |
| CurrencyPickerTests:472 | OptionPicker.optionRow(KRW) 消失 | M | Q16 waitForOptionDismissal |
| ToolLoadTabSwitchTests:22、23、24、44、45、46 | Fx／Quote 的 loading、loadFailure、retryButton | K | 遷移後只剩 assertLoadStateStaysStable 的參數 (L182-184、202-204)。同一批 identifier 經 `ToolLoadElements` 的 loading／loadFailure／retryButton 三個查詢屬性 (L104-119，該處沒有 BLID 字面) 直接查元素，這三個屬性改呼叫 Q21-Q23 (FxScreen)／Q24-Q26 (QuoteScreen) 後刪除；struct 留 name 與三個 identifier 並改 private (重掃 H1)，或改成持有 Page Object |

##### 三類分佈摘要
- N 15 筆全部是「更多」入口清單與其分欄附屬元素 (More 4、Navigation 10、Smoke 1)。
- K 81 = assertLoadStateStaysStable 參數 40 (Campaigns 6、Customers 4、Reload 21、OrderListLoadFailure 3、ToolLoad 6)＋單一快照鍵 14 (Dashboard 8、Insights 6)＋純值檢查 11 (Counterexample)＋assertEmptyState 5 (CampaignListTests:22、CustomersTests:47、InsightsTests:126、OrdersListTests:157、HarnessSelfCheckTests:44)＋tapAlertButton／tapMenuItem 3 (LookupManagementTests:373、398、NavigationScenarioUITests:146)＋列舉型別標註 6 (AdaptiveNavigationContinuityUITests:1064、1405、1555、1556、1561、OrderDetailTests:26)＋系統側邊欄 2 (AdaptiveNavigationContinuityUITests:1119、OrderRegularColumnScopeTests:521)。
- M 134 = 改用現有 Page Object／Support 方法 45 筆＋用 5.2／5.3 新增方法 89 筆。各資料夾 (現有／新增)：Campaigns 2／5、Customers 0／5、Forms 0／2、More 4／2、Navigation 7／23、Orders 根層 6／10、Detail 7／2、Edit 3／5、Filters 0／1、Regular 15／24、Smoke 0／8、Tools 1／2。

#### 5.2 要新增的 Page Object 方法 (只改 `Screens/Orders/**`，5 檔 32 個)
形狀依 design：等待回傳 Bool 不可丟棄；會失敗的動作 `throws(UITestError)` 帶 `file: StaticString = #filePath, line: UInt = #line`；元素只給量框線或交給 Support 輸入／捲動 helper 的。
| # | Screen | 簽章 | 使用的 Tests 行 |
| --- | --- | --- | --- |
| P1 | OrdersScreen | `func waitForLoadFailure(timeout: TimeInterval = 10) -> Bool` | CustomersLoadStateTests:48、LoadFailureReloadLoopTests:65、101、OrderListLoadFailureTests:21 |
| P2 | OrdersScreen | `func waitForLoading(timeout: TimeInterval = 10) -> Bool` | LoadFailureReloadLoopTests:81、120、OrderListLoadFailureTests:23 |
| P3 | OrdersScreen | `func tapRetry(file:line:) throws(UITestError)` | OrderListLoadFailureTests:24 (L35) |
| P4 | OrdersScreen | `func hasEmptyState(timeout: TimeInterval = 10) -> Bool` (立即判斷傳 0) | OrderListLoadFailureTests:22 |
| P5 | OrdersScreen | `func hasDetailEmptyState(timeout: TimeInterval = 10) -> Bool` (詳情欄未選取提示存在且有快照框線) | OrdersNavigationSmokeTests:199、AdaptiveNavigationContinuityUITests:1515、OrderRegularColumnScopeTests:272 |
| P6 | OrdersScreen | `func waitForDetailEmptyStateDismissal(timeout: TimeInterval = 10) -> Bool` | OrderRegularColumnScopeTests:312 |
| P7 | OrdersScreen | `func statusChip(_ filterID: String) -> XCUIElement` | AdaptiveNavigationContinuityUITests:1129、1226、OrderRegularAccessibilitySizeTests:148、OrderRegularColumnWidthTests:73 |
| P8 | OrdersScreen | `func dateChip(_ periodID: String) -> XCUIElement` | OrderRegularAccessibilitySizeTests:149 |
| P9 | OrdersScreen | `var paymentMethodTrigger: XCUIElement` | OrderRegularAccessibilitySizeTests:150、AdaptiveNavigationContinuityUITests:282 |
| P10 | OrdersScreen | `var categoryTrigger: XCUIElement` | OrderRegularAccessibilitySizeTests:151、AdaptiveNavigationContinuityUITests:285 |
| P11 | OrdersScreen | `var regularClearFiltersButton: XCUIElement` | OrderRegularAccessibilitySizeTests:83、152 |
| P12 | OrdersScreen | `var addButton: XCUIElement` | AdaptiveNavigationContinuityUITests:1136、OrderRegularColumnScopeTests:459 |
| P13 | OrdersScreen | `var batchMenuButton: XCUIElement` | OrderRegularColumnScopeTests:460 |
| P14 | OrdersScreen | `var orderCountLabel: XCUIElement` | OrderRegularColumnScopeTests:458、AdaptiveNavigationContinuityUITests:822 (L888) |
| P15 | OrdersScreen | `var selectionSummary: XCUIElement` | NavigationScenarioUITests:32、OrderRegularColumnScopeTests:670 |
| P16 | OrdersScreen | `var batchStatusMenuButton: XCUIElement` | NavigationScenarioUITests:41、OrderRegularColumnScopeTests:179 |
| P17 | OrdersScreen | `var selectAllButton: XCUIElement` | OrderRegularColumnScopeTests:178 |
| P18 | OrdersScreen | `var selectionDoneButton: XCUIElement` | OrderRegularColumnScopeTests:180 |
| P19 | OrdersScreen | `func tapRegularHeaderGap(file:line:) throws(UITestError)` (點清單欄標頭清除鈕右側空白，搬入 OrderRegularAccessibilitySizeTests:184 tapHeaderGap 的邏輯；D3) | OrderRegularAccessibilitySizeTests:185、188 |
| P20 | OrdersScreen | `var listRootCount: Int`、`var detailRootCount: Int` (形狀比照 P26 與 `LookupManagementScreen.presentedSheetCount`，主對話代選) | AdaptiveNavigationContinuityUITests:801、804 |
| P21 | OrdersScreen | `func hasFilterTrigger(timeout: TimeInterval = 10) -> Bool` | OrientationLayoutTests:152 |
| P22 | OrdersScreen | `func hasHittableOrderRow(timeout: TimeInterval = 10) -> Bool` | OrientationLayoutTests:211 |
| P23 | OrderDetailScreen | `var moreButton: XCUIElement` | OrdersNavigationSmokeTests:42、159、393、OrderRegularColumnWidthTests:37、OrderRegularColumnScopeTests:276、629 |
| P24 | OrderDetailScreen | `var statusMenuButton: XCUIElement` | OrderRegularColumnScopeTests:275、628 |
| P25 | OrderDetailScreen | `func summaryTile(_ tile: BLAccessibilityID.Orders.SummaryTile) -> XCUIElement` | OrderRegularColumnWidthTests:34 |
| P26 | OrderEditScreen | `var presentedRootCount: Int` (比照 LookupManagementScreen.presentedSheetCount) | OrdersNavigationSmokeTests:364、428 |
| P27 | OrderEditScreen | `func waitForSaveEnabled(timeout: TimeInterval = 10) -> Bool` | OrderCreateTests:122 |
| P28 | OrderEditScreen | `func waitForSourceLabel(containing text: String, timeout: TimeInterval = 10) -> Bool` | OrderEditAddOptionTests:47 |
| P29 | OrderEditScreen | `func waitForPaymentLabel(containing text: String, timeout: TimeInterval = 10) -> Bool` | OrderEditAddOptionTests:95 |
| P30 | OrderFilterSheetScreen | `var filterSearchField: XCUIElement` | SearchInputFocusUITests:176 |
| P31 | OrderFilterSheetScreen | `func isFilterClearEnabled(file:line:) throws(UITestError) -> Bool` (等 5 秒存在，否則失敗) | OrderFilterSheetTests:133 |
| P32 | OrderCategoryPickerScreen | `var pickerSearchField: XCUIElement` | SearchInputFocusUITests:180 |
沒有重複的依據：`grep -rn 'BLAccessibilityID\.<id>' apps/ios/BuyLedgerUITests/Screens` 逐一查。listLoadFailure、listLoading、orderCountLabel、selectionSummary、batchStatusMenuButton、selectAllButton、detailStatusMenuButton 在 Screens 0 筆；detailEmptyState、listEmptyState、addButton、listLoadFailureRetryButton 只在 OrdersScreen private 的 isForegroundReady／currentPathProjection 與 RootNavigationScreen 的元素組；statusChip、dateChip、paymentMethodMenuButton、categoryFilterButton、clearFiltersButton、batchMenuButton、selectionDoneButton、filterButton、detailMoreButton、detailSummaryTile、saveButton、sourceRow、paymentRow、filterSearchField、categoryPickerSearchField、filterClearButton 只出現在點擊、讀 label／isSelected／isEnabled／value 的既有方法內部，沒有回傳元素、等待狀態或計數的現有方法。

#### 5.3 要新增的 Page Object 方法 (`Screens/**` 中 `Screens/Orders/` 以外，10 檔 26 個；與 5.2 檔案不重疊)
| # | Screen | 簽章 | 使用的 Tests 行 |
| --- | --- | --- | --- |
| Q1 | CampaignsScreen | `func waitForLoadFailure(timeout: TimeInterval = 10) -> Bool` (形狀同 DashboardScreen.waitForLoadFailure) | CampaignFlowTests:27、50 |
| Q2 | CampaignsScreen | `func waitForRetryButton(timeout: TimeInterval = 10) -> Bool` (重試鍵出現且可點) | CampaignFlowTests:28、51 |
| Q3 | CampaignsScreen | `func tapRetry(file:line:) throws(UITestError)` | CampaignFlowTests:28、51 |
| Q4 | CampaignsScreen | `var destinationContainer: XCUIElement` (Common.selectedItem(.campaigns) 根容器；測試以它限縮 progressIndicators 交給 absentElements) | CampaignListLoadFailureLoopTests:20 |
| Q5 | CustomersScreen | `func hasEmptyState(timeout: TimeInterval = 10) -> Bool` | CustomersLoadStateTests:28、63、AdaptiveNavigationContinuityUITests:774 |
| Q6 | CustomersScreen | `func waitForLoading(timeout: TimeInterval = 10) -> Bool` | CustomersLoadStateTests:70、LoadFailureReloadLoopTests:111 |
| Q7 | CustomersScreen | `func tapRetry(file:line:) throws(UITestError)` | CustomersLoadStateTests:86 |
| Q8 | CustomersScreen | `func customerRowLabel(customerName: String, timeout: TimeInterval = 10) -> String?` (列可點後回傳 label，否則 nil；private customerRow 不改公開) | AdaptiveNavigationContinuityUITests:779 |
| Q9 | DashboardScreen | `func waitForLoading(timeout: TimeInterval = 10) -> Bool` | LoadFailureReloadLoopTests:153、182 |
| Q10 | DashboardScreen | `func kpiTile(_ kpi: BLAccessibilityID.Dashboard.KPI) -> XCUIElement` | AdaptiveNavigationContinuityUITests:1408 (框線)、OrientationLayoutTests:164 (捲動) |
| Q11 | DashboardScreen | `func emptyStateActionLabel(timeout: TimeInterval = 10) -> String?` | HarnessSelfCheckTests:60、80 |
| Q12 | DashboardScreen | `func currentDateSubtitle(timeout: TimeInterval = 10) -> String?` | HarnessSelfCheckTests:121 |
| Q13 | InsightsScreen | `func waitForLoading(timeout: TimeInterval = 10) -> Bool` | LoadFailureReloadLoopTests:73 |
| Q14 | InsightsScreen | `func revealFirstCategoryRank() -> Bool` (形狀同現有 revealCostDonut()) | OrientationLayoutTests:236 |
| Q15 | OptionPickerScreen | `func hasOption(_ value: String, timeout: TimeInterval = 10) -> Bool` (比照 hasOrder／hasCampaign；立即判斷傳 0) | LookupManagementTests:87、93、OrderEditAddOptionTests:86、OrderCreateTests:202、CurrencyPickerTests:458 |
| Q16 | OptionPickerScreen | `func waitForOptionDismissal(_ value: String, timeout: TimeInterval = 10) -> Bool` (比照 waitForDeleteConfirmationDismissal 的成對形狀) | CurrencyPickerTests:472 |
| Q17 | SettingsScreen | `var defaultCurrencyRow: XCUIElement` (量框線；private element(_:) 已有同查詢) | ReadableWidthUITests:102 |
| Q18 | PaymentMethodEditorScreen | `func isCashOnDeliveryOn(file:line:) throws(UITestError) -> Bool` (必要時在編輯器根內捲到可點，再讀 value 是否為 "1"；捲不到時失敗) | OrderDetailTests:99 (L107) |
| Q19 | PaymentMethodEditorScreen | `func toggleCashOnDelivery(file:line:) throws(UITestError)` (Form 內點內層 switch，確認 value 翻轉，未翻轉時失敗) | OrderDetailTests:99、103 |
| Q20 | AppLockScreen | `func waitForRetryButton(timeout: TimeInterval = 10) -> Bool` | AppLockTests:30 |
| Q21 | FxScreen | `func waitForLoading(timeout: TimeInterval = 10) -> Bool` | ToolLoadTabSwitchTests L104-107 (識別值來自 :22) |
| Q22 | FxScreen | `func waitForLoadFailure(timeout: TimeInterval = 10) -> Bool` | ToolLoadTabSwitchTests L109-112 (:23) |
| Q23 | FxScreen | `func tapRetry(file:line:) throws(UITestError)` | ToolLoadTabSwitchTests L114-117 (:24) |
| Q24-Q26 | QuoteScreen | 同 Q21-Q23 | ToolLoadTabSwitchTests (:44、45、46) |
(Q23、Q26：4.6 以「無呼叫端」刪除了 QuoteScreen.tapRetry；ToolLoad 改呼叫後即有呼叫端)
沒有重複的依據：Campaigns.listLoadFailure、Dashboard.loading、Insights.loading、paymentMethodCashOnDeliveryToggle、Fx／Quote 的 loading／loadFailure／retryButton 在 Screens 0 筆；Customers 的 listEmptyState／listLoading／RetryButton 只在 open(in:) 的就緒元素組；Common.selectedItem(.campaigns) 只在 selectedCampaignID() 讀 value；Dashboard.kpiTile 只在 prepareLayoutSnapshot 清單與 kpiValue 內部；emptyStateActionButton 只在 tapCreateFirstOrder；currentDateSubtitle 只在快照清單；categoryRankRow 只在快照清單與 categoryProfit；optionRow 只在 selectOption、optionLabel (後者不存在即失敗，不能做不存在判斷)；defaultCurrencyRow 只在 openDefaultCurrency；AppLock.retryButton 只在兩個 enabled 狀態等待與 tapRetry。

#### 5.3 的既有方法回傳形狀補正 (S；4.6 漏改，併入 5.3，裁決 D4)
design：「由其他畫面呈現或推入的畫面，由呈現它的 Page Object 動作在新畫面就緒後回傳」。4.5 已把 OrderEditScreen.openCurrencyPicker 等改為回傳，下列四個仍是 Void：
| # | 現況 | 建議 | 受益的 Tests |
| --- | --- | --- | --- |
| S1 | `CampaignsScreen.tapAdd(file:line:) throws(UITestError)` | `@discardableResult … -> CampaignEditScreen` | CampaignCrudTests:31、CampaignEditDateRowTests:22、43、CampaignFlowTests:85、343 的「點新增後等 CampaignEditScreen 就緒」兩行 |
| S2 | `FxScreen.openCurrencyPicker(file:line:)` | `-> OptionPickerScreen` | CurrencyPicker openPicker |
| S3 | `QuoteScreen.openCurrencyPicker(file:line:)` | `-> OptionPickerScreen` | CurrencyPickerTests openPicker |
| S4 | `SettingsScreen.openDefaultCurrency(file:line:)` | `-> OptionPickerScreen` | CurrencyPickerTests openPicker |
不採 S 時第 5 組照現況寫「呼叫後建 Page Object 再等就緒」，不影響本報告其他項。


#### 本地導覽 helper 的去向 (`Tests/**` 內會切分頁、點入口、推入或呈現畫面的 private 成員；4.5／4.6 已刪掉 openOrders 等 25 檔的副本，現存 11 個)
| 檔:行 | helper | 去向 | 替代呼叫／理由 |
| --- | --- | --- | --- |
| Campaigns/CampaignProgressAccessibilityTests.swift:67 | readKoreaCampaignRowLabel(in:awaiting:file:line:) | 留作 private | 只串接 CampaignsScreen.open(in:)、hasCampaign、campaignRow，單一型別用；內部 failWithDiagnostics 改 requireCondition，koreaCampaignID 改 CampaignSeedFixture (G2) |
| Dashboard/DashboardLayoutSmokeTests.swift:127 | openDashboard(contentSizeCategory:) | 留作 private | 負責啟動字級參數＋DashboardScreen.open(in:)＋等內容，比照 4.6 保留的 openInsights(seed:) |
| Insights/InsightsLayoutSmokeTests.swift:101 | openInsights(seed:) | 留作 private | 4.6 已定 (負責啟動與種子) |
| Forms/SearchInputFocusUITests.swift:170 | openCategorySearch(typing:in:) | 留作 private (OrdersSearchInputFocusUITests) | compact：`let sheet = try orders.openFilterSheet()`、`try sheet.typeFilterSearch(text)`、回傳 `sheet.filterSearchField` (P30)；regular：`let picker = try orders.openCategoryPicker()`、用 `picker.pickerSearchField` (P32) |
| Forms/OrderEditInputFocusUITests.swift:475 | prepareSavedCardlessOrder(in:) | 留作 private | 4.5 已定；L483-488 改 `let picker = try edit.openPaymentPicker()` (已回傳就緒)；Given 用 helper 的 failWithDiagnostics＋return nil 改 requireCondition (design：helper 依呼叫步驟歸類) |
| Forms/OrderEditInputFocusUITests.swift:531 | saveAndReopenOrderEdit(_:expectedRevenue:in:) | 留作 private | openMoreMenu＋tapEdit＋重建等待改 `let reopened = try detail.openEdit()` (S:Orders/OrderDetailScreen.swift:44) |
| Navigation/AdaptiveNavigationContinuityUITests.swift:1553 | readDashboardKPIValues(in:required:) | 留作 DashboardAdaptiveLayoutUITests 的 private | `root.goToDashboard()`＋`DashboardScreen(app:)` 改 `let dashboard = try DashboardScreen.open(in: app)` |
| Orders/Detail/OrderDetailTests.swift:175 | profitValue(for:in:) | 留作 private | 一行串接 `OrdersScreen.open(in:).tapOrder(orderID:).summaryValue(.profit)`，L68、148 兩處呼叫 |
| Orders/Edit/OrderCreateTests.swift:216 | selectFromPicker(_:open:value:file:line:) | 刪除 | L110、136：`try edit.openSourcePicker().selectOption(Self.orderSource)`；L137：`try edit.openCategoryPicker().selectOption(Self.category)`。4.5 後 open…Picker 已等就緒，helper 的重建與等待重複 |
| Tools/CurrencyPickerTests.swift:407 | openPicker(_:language:) | 留作 private (依入口參數化的前置) | .settings：L414-419 改 `let settings = try SettingsScreen.open(in: app)`；.orderEdit：L433-439 改 `try OrdersScreen.open(in: app).tapAddOrder().openCurrencyPicker()` 取回傳；採 S2-S4 時四個分支都取回傳值，L442-447 的重建等待刪除 |
| Tools/ToolLoadTabSwitchTests.swift:130 | switchTabAndReturnDuringRead(_:) | 留作 private | RootNavigationToolLoadUITests 屬根導覽受測，保留 selectTab；標記移回本體 (C4)、改 throws (F)、元素改 Q21-Q26 |
相關但不是導覽：OrderCreateTests:198 assertCategoryPickerHasLookupOption 改收 openCategoryPicker() 的回傳值 (L199-200 重建與等待刪除)。其餘 private helper (expandUnpaidOrderRow、Orientation 的 capture*／attachScreenshot、launchRegularLandscapeApp、各 assert*／read*) 不切分頁、不點入口、不推入或呈現，不列。

#### goTo*／selectTab(／tapRootTab( 對照
指令：`grep -rnE '\.goTo[A-Z]|selectTab\(|tapRootTab\(' apps/ios/BuyLedgerUITests/Tests | wc -l` → 116。保留 61＋替代 55＝116。
保留 (9 個根導覽受測型別，61)：
- RootNavigationCampaignLoadFailureUITests：CampaignFlowTests:49、57、58；CampaignListLoadFailureLoopTests:26、43、44、57、58 (8)
- RootNavigationContinuityUITests：AdaptiveNavigationContinuityUITests:69、129、146、190、268、450、554、590、620、676、678、718、720、757、845、870、902、938、940、979、980、1109、1344、1368 (24)
- RootNavigationLoadFailureUITests：LoadFailureReloadLoopTests:21、22、23、35、47、64、72、78、100、117 (10)
- RootNavigationScenarioUITests：NavigationScenarioUITests:109、191 (2)；RootNavigationReadableWidthUITests：ReadableWidthUITests:36 (1)；RootNavigationMoreUITests：MoreNavigationSmokeTests:23、65 (2)
- RootNavigationRegularColumnsUITests：OrderRegularColumnScopeTests:89、299、306、330、334、337 (6)；RootNavigationLaunchUITests：LaunchSmokeTests:52、92、93、94、95、98 (6)；RootNavigationToolLoadUITests：ToolLoadTabSwitchTests:142、143 (2)
替代 (55)：
| 檔:行 | 新型別 | 替代呼叫 |
| --- | --- | --- |
| CampaignFlowTests:26、292 | CampaignsUITests | `CampaignsScreen.open(in:)` |
| CampaignFlowTests:79、340 | CampaignEditUITests | `CampaignsScreen.open(in:)` 後 tapAdd |
| CustomersLoadStateTests:47 | CustomersLoadStateUITests | `OrdersScreen.open(in:)`＋`requireCondition(orders.waitForLoadFailure(timeout:))` (P1) |
| InsightsTests:61 | InsightsUITests | `DashboardScreen.open(in:)` |
| InsightsTests:69 | InsightsUITests | `CampaignsScreen.open(in:)` |
| LookupManagementTests:75 | OrderEditRenamedCategoryUITests | `OrdersScreen.open(in:).tapAddOrder()` |
| AdaptiveNavigationContinuityUITests:357、415、492、1206、1271 | OrdersAdaptiveLayoutUITests | `OrdersScreen.open(in:)` |
| AdaptiveNavigationContinuityUITests:1001 | OrderEditDraftRotationUITests | `OrdersScreen.open(in:).tapAddOrder()` |
| AdaptiveNavigationContinuityUITests:1317 | CampaignsAdaptiveLayoutUITests | `CampaignsScreen.open(in:)` |
| AdaptiveNavigationContinuityUITests:1399、1558 | DashboardAdaptiveLayoutUITests | `DashboardScreen.open(in:)` |
| NavigationScenarioUITests:25、69 | OrdersSelectionUITests | `OrdersScreen.open(in:)`，XCTSkip 移到其後 |
| NavigationScenarioUITests:138 | SettingsLanguageUITests | `SettingsScreen.open(in:)` 後再 `XCTSkipUnless(moreLayout == .compact)` (需實測：設定頁推入後 moreLayout 是否仍判得出；不成立時維持 goToMore 並列為白名單例外，裁決 D5) |
| OrderDetailTests:73 | OrderDetailUITests | `LookupManagementScreen.open(.paymentMethods, in:)` |
| OrderPaymentMethodMenuTests:38、70 | OrdersPaymentMethodMenuUITests | `OrdersScreen.open(in:)` (G3 重複導覽合一) |
| OrderListLoadFailureTests:27 | OrdersLoadFailureUITests | `OrdersScreen.open(in:)` (前提型併入 Given) |
| OrdersNavigationSmokeTests:21、106、135、172、227、346、416 | OrdersNavigationUITests | `OrdersScreen.open(in:)` |
| OrdersNavigationSmokeTests:272 | OrderEditRotationUITests | `OrdersScreen.open(in:)` |
| OrderRegularAccessibilitySizeTests:34、55、73、106 | OrdersRegularAccessibilitySizeUITests | 刪除 (其後已有 `OrdersScreen.open(in:)`)，skip 移到 open 之後 |
| OrderRegularColumnScopeTests:33、51、70、127、146、167、200、230、261 | OrdersRegularColumnScopeUITests | 刪除 (其後已有 `OrdersScreen.open(in:)`)，skip 移到 open 之後 (H2) |
| OrderRegularSearchBarTests:36、72、109、146 | OrdersRegularSearchBarUITests | 刪除 (其後已有 `OrdersScreen.open(in:)`)，skip 移到 open 之後 |
| OrientationLayoutTests:23 | RootNavigationOrientationUITests | `OrdersScreen.open(in:)` (When 是轉向，不是根導覽受測) |
| OrientationLayoutTests:44 | DashboardOrientationUITests | `DashboardScreen.open(in:)` |
| OrientationLayoutTests:61 | OrdersOrientationUITests | `OrdersScreen.open(in:)` |
| OrientationLayoutTests:78 | InsightsOrientationUITests | `InsightsScreen.open(in:)` |
| CurrencyPickerTests:415 | OptionPickerCurrencyUITests (openPicker) | `SettingsScreen.open(in:)` |
| CurrencyPickerTests:434 | OptionPickerCurrencyUITests (openPicker) | `OrdersScreen.open(in:)` |

#### 各任務要處理的重掃項目

t17 唯讀產出、主對話驗證。對象是提案前 t17 重掃 `Tests/**` 的 A、C、D、F、G、H 類在 4.2 至 4.6 後仍存在的項目；B 類 (定位與斷言文字) 已分別寫在方法對照、identifier 引用盤點與 tasks 5.5、5.8、5.10，E 類 (型別後綴) 在類別對照。類別：A 為 Given／When 內以 `XCTAssert*` 或 `failWithDiagnostics` 驗前置 (A1 Given、A2 When、A3 基準值延到 Then 驗，只供參考)；C 為 Given／When／Then (C2 多組、C3 Then 內含動作、C4 標記寫在 helper 內)；D 為命名與摘要；F 為回傳 Bool 的 helper；G 為重複 helper 與常數；H 為其他 kit 與專案規則 (H1 `fileprivate`、H2 版面 skip 位置、H3 手動截圖、H4 效能測試啟動路徑、H5 接續輸入、H6 guard 換行、H8 斷言 helper 內含動作)。

- 「改 requireCondition」的寫法：`if !cond { failWithDiagnostics(in: app, msg) }`、`guard cond else { failWithDiagnostics(…); return }`、`XCTAssert*(cond, msg)` 改成 `try requireCondition(cond, in: app, msg)` 並刪掉 if、guard 與 return；`XCTAssertEqual(a, b, msg)` 改成 `try requireCondition(a == b, in: app, "msg (實際：\(a))")`；後面要用到的值改 `try requireValue(…)`。被 Given 或 When 呼叫的 private helper 依呼叫它的步驟歸類，改 `throws(UITestError)` 並在內部用 `requireCondition`。
- `assertAlertMessage` 在 4.4 已改成 `stopWithDiagnostics` 加 `throws(UITestError)`，在 Given 內呼叫已等同前置檢查，不改寫 (下表標「不改」的 4 處)。
- 主對話驗證：以腳本掃描 59 檔每個 test 方法中 `// Then` 之前的 `XCTAssert*` 與 `failWithDiagnostics(`，92 行全部列在下表；其餘列在 private helper 內。
- 合計 197 列：A 類 83 列 114 處 (4 處不改，實際改 110 處；各任務 5.4a 3、5.4b 5、5.5 24、5.6a 2、5.6b 12、5.7a 0、5.7b 8、5.8 12、5.9a 41、5.9b 5、5.10 2)、A3 參考 2、C2 41 (可拆 10、前提 7、旅程 22，另 `ToolLoadTabSwitchTests` 兩條依裁決 6 視為旅程)、C3 9、C4 1、F 2、G 20 (G2 6、G3 2、G4 4、G5 5、G15 2、G16 1)、H 16 (H1 1、H2 7、H3 4、H4 1、H5 1、H6 1、H8 1)、D 23 (D2 1、D3 2、D4 11 為確認 9 列加參考 2 列、alert 訊息寫進摘要 1 列、新型別摘要 8)。H7 (規則文件缺口) 屬 6.2。
- `InsightsLaunchLoadingTests.swift:17` 的開團 id 陣列含四月韓國團 id 字面值，不在提案前的 G2 清單；5.10 一併改用 `CampaignSeedFixture.koreaCampaignID` (主對話代選，t17 建議)。

##### 5.4a Orders/Filters
| 項目 | 現行檔:行 | 所在方法或 helper | 要做的事 | 備註 |
| --- | --- | --- | --- | --- |
| A1 | Orders/Filters/OrderPaymentMethodMenuTests.swift:45 | testPaymentMethodMenu_選信用卡_清單只列信用卡八筆 (Given) | 改 requireCondition | 清單就緒；改用 OrdersScreen.open(in:) 後可刪 |
| A1 | Orders/Filters/OrderPaymentMethodMenuTests.swift:77 | testPaymentMethodMenu_選信用卡_觸發鈕標記已選取 (Given) | 同上 | 同上 |
| A1 | Orders/Filters/OrderPaymentMethodMenuTests.swift:80 | 同上 (Given) | 改 requireCondition | 未選擇時觸發鈕不應已選取 |
| C3 | Orders/Filters/OrderFilterSheetTests.swift:242 | testFilterSheetDiscard_繼續編輯_留在篩選畫面 | 同方法對照 (tapFilterApply 移到 When 末尾) | |
| G3 | Orders/Filters/OrderPaymentMethodMenuTests.swift:38、70 | 兩條測試的 Given | goToOrders＋OrdersScreen(app:)＋等待改 `OrdersScreen.open(in:)` | 見「goTo*／selectTab(／tapRootTab( 對照」 |
| G4 | Orders/Filters/OrderCategoryPickerLargeTests.swift:45-50 | testCategoryPickerLargeApply_ (Then) | 內嵌清單比對改 `try assertListedOrderIDs(OrdersSeedFixture.largeFilteredOrderIDs, orders)` | Support/XCTestCase+OrdersAssertions.swift (4.5) |
| G4 | Orders/Filters/OrderFilterSheetLargeTests.swift:45-50 | testFilterSheetLargeApply_ (Then) | 同上 | |
| G4 | Orders/Filters/OrderPaymentMethodMenuTests.swift:55-61 | testPaymentMethodMenu_選信用卡_清單只列信用卡八筆 (Then) | 改 `try assertListedOrderIDs(Self.creditCardOrderIDs, orders)` | |
| G5 | Orders/Filters/OrderCategoryPickerTests.swift:172 | private assertTrigger(_:contains:) | 搬進 OrdersUITestSupport.assertTrigger (以參數指定觸發鈕，失敗走 stopWithDiagnostics 並 throws) 後刪除 | |
| G5 | Orders/Filters/OrderFilterSheetTests.swift:338 | private assertTrigger(_:contains:) | 同上 | |
| G5 | Orders/Filters/OrderCategoryPickerLargeTests.swift:42-44 | testCategoryPickerLargeApply_ (Then) | 內嵌觸發鈕比對改呼叫 OrdersUITestSupport.assertTrigger | |
| G5 | Orders/Filters/OrderFilterSheetLargeTests.swift:42-44 | testFilterSheetLargeApply_ (Then) | 同上 | |
| G5 | Orders/Filters/OrderPaymentMethodMenuTests.swift:52-54 | testPaymentMethodMenu_選信用卡_清單只列信用卡八筆 (Then) | 同上 (付款方式觸發鈕) | |
| D4 | Orders/Filters/OrderCategoryPickerTests.swift:52 | testCategoryPickerSwipeDown_ 的摘要 | 摘要只複述名稱，依新名 testCategoryPickerBlocksSwipeDismiss_ 改寫成具體行為 (選了哪格、下滑後仍在、選取保留) | |
| D4 | Orders/Filters/OrderFilterSheetTests.swift:169 | testFilterSheetSwipeDown_無變更_可關閉 的摘要 | 同上 | |
合計 15。已由 4.x 解掉：G3 (Filters 4 檔的本地 openOrders 副本，4.5)、G4 (兩份 private assertListedOrderIDs，4.5)、G6 (Filters 固定值，4.5)。

##### 5.4b Orders/Regular
| 項目 | 現行檔:行 | 所在方法或 helper | 要做的事 | 備註 |
| --- | --- | --- | --- | --- |
| A1 | Orders/Regular/OrderRegularClearFiltersTests.swift:41 | testRegularClearFilters_有篩選條件_三項回到預設且狀態維持 (Given) | 改 requireCondition | 清除篩選可點 |
| A1 | Orders/Regular/OrderRegularClearFiltersTests.swift:46 | 同上 (Given) | 同上 | 日期已選本月 |
| A1 | Orders/Regular/OrderRegularClearFiltersTests.swift:50 | 同上 (Given) | 同上 | 付款方式為信用卡 |
| A1 | Orders/Regular/OrderRegularClearFiltersTests.swift:53 | 同上 (Given) | 同上 | 類別兩項 |
| A1 | Orders/Regular/OrderRegularClearFiltersTests.swift:56 | 同上 (Given) | 同上 | 狀態為已確認 |
| C2 | Orders/Regular/OrderRegularAccessibilitySizeTests.swift:98 | testRegularFilters_最大輔助字級點標頭空白處_篩選不變且清除鈕仍可清除 | 同方法對照 (可拆 A／B) | |
| G3 | Orders/Regular/OrderRegularAccessibilitySizeTests.swift:34、55、73、106；OrderRegularColumnScopeTests.swift:33、51、70、127、146、167、200、230、261；OrderRegularSearchBarTests.swift:36、72、109、146 | 各測試 Given | goToOrders 後又 OrdersScreen.open(in:) 的重複導覽刪去前者，skip 移到 open 之後 | 見「goTo*／selectTab(／tapRootTab( 對照」 |
| G4 | Orders/Regular/OrderRegularClearFiltersTests.swift:80-83 | testRegularClearFilters_有篩選條件_ (Then) | 改 `try assertListedOrderIDs(OrdersSeedFixture.allOrderIDs, orders)` | |
| G16 | Orders/Regular/OrderRegularColumnScopeTests.swift:597 | private requireDetailColumnLeadingEdge | 改用 U:XCTestCase+PlatformScope.swift:116 `foregroundOrdersDetailFrame(in:)` 後刪除 | tasks 5.4 |
| H2 | Orders/Regular/OrderRegularColumnWidthTests.swift:28 | testRegularColumns_橫向訂單列與詳情摘要_ | 同方法對照 (skip 移到轉向後、tapOrder 前) | |
| H2 | Orders/Regular/OrderRegularColumnWidthTests.swift:71 | testRegularColumns_狀態膠囊可點_ | 同方法對照 | |
| H2 | Orders/Regular/OrderRegularColumnScopeTests.swift:96 | testRegularColumns_直向叫出收起的側邊欄_ | 同方法對照 (skip 由實作者提前，主對話在 iPad 確認，裁決 8) | |
| D | Orders/Regular/RootNavigationRegularColumnsUITests.swift、OrdersRegularColumnScopeUITestSupport.swift (新檔) | 型別摘要 | 新寫型別摘要 (寫「這是什麼」，不用「驗證」開頭) | |
合計 13。已由 4.x 解掉：G7 (openSelectedOrder 兩份與 UITEST-MRG 編號，4.5)、G3 (ClearFilters 的本地 openOrders，4.5)、G6 (allOrderIDs，4.5)、assertHorizontalBounds 移回本檔 (4.3)。

##### 5.5 Orders/Detail＋Orders/Edit
| 項目 | 現行檔:行 | 所在方法或 helper | 要做的事 | 備註 |
| --- | --- | --- | --- | --- |
| A1 | Orders/Detail/OrderDetailMenuTests.swift:20、44、71 | 三條測試的 Given 呼叫 private assertOriginalDetailIsDisplayed | helper (L99-104，以 failWithDiagnostics 判定) 改 `throws(UITestError)`、內部 requireCondition；Then 的呼叫端 L35、62、86 一併加 try | 同一 helper 在 Given 與 Then 都用 |
| A1 | Orders/Detail/OrderDetailMenuTests.swift:25 | testOrderDetailMoreMenu_點編輯後取消_ (Given) | 改 requireCondition | 編輯表單出現；tapEdit 回傳就緒畫面後可刪 |
| A1 | Orders/Detail/OrderDetailMenuTests.swift:49 | testOrderDetailMoreMenu_點合併後取消_ (Given) | 同上 | 候選畫面出現 |
| A1 | Orders/Detail/OrderDetailMenuTests.swift:52 | 同上 (Given) | 改 requireCondition | 候選畫面列出可合併訂單 |
| A1 | Orders/Detail/OrderDetailMenuTests.swift:75 | testOrderDetailMoreMenu_點刪除後取消_ (Given) | 改 `try requireCondition(detail.waitForDeleteConfirmation(), …)` | |
| A1 | Orders/Detail/OrderDetailMenuTests.swift:77 | 同上 (Given) assertAlertMessage | 不改 (4.4 後已是 stopWithDiagnostics＋throws) | 摘要未把訊息列為預期 |
| A1 | Orders/Detail/OrderDetailTests.swift:84 | testRelaunch_補勾貨到付款後重啟_ (Given) | 隨「identifier 引用盤點」改 LookupManagementScreen.open(.paymentMethods, in:) 後刪除 | |
| A1 | Orders/Detail/OrderDetailTests.swift:126 | 同上 (Given) assertAlertMessage | 不改 (同上) | |
| A1 | Orders/Detail/OrderDetailTests.swift:129 | 同上 (Given) | 改 `try requireCondition(app.alertDismissed(), …)` | |
| A1 | Orders/Detail/OrderDetailTests.swift:136 | 同上 (Given) | 改 requireCondition；比對改 `paymentMethodClassification(named:)` 讀值 | 徽章等待 |
| A1 | Orders/Detail/OrderMergeTests.swift:23 | testDismissSheetBySwipe_合併確認未修改_ (Given) | 改 requireCondition | 確認表單就緒；tapCandidate 回傳就緒畫面後可刪 |
| A1 | Orders/Edit/KeyboardDismissTests.swift:23 | testSubmitCustomerName_ (Given) | 改 requireCondition | 鍵盤呈現 |
| A1 | Orders/Edit/KeyboardDismissTests.swift:41 | testTapNumericKeyboardDone_ (Given) | 同上 | 數字鍵盤或 Popover 呈現 |
| A1 | Orders/Edit/OrderCreateTests.swift:107 | testSelectOption_客戶與來源已填後選商品類別_ (Given) | 改 requireCondition | 必填未齊時儲存停用 |
| A1 | Orders/Edit/OrderCreateTests.swift:114 | 同上 (Given) | 刪除 (openCategoryPicker 已回傳就緒的 OptionPickerScreen) | 隨 selectFromPicker 刪除一起處理 |
| A1 | Orders/Edit/OrderEditAddOptionTests.swift:32 | testAddOrderSource_ (Given) | 刪除或改 requireCondition (openSourcePicker 已等就緒) | |
| A1 | Orders/Edit/OrderEditAddOptionTests.swift:67 | testAddPaymentMethod_ (Given) | 同上 (openPaymentPicker) | |
| A1 | Orders/Edit/OrderEditAddOptionTests.swift:71 | 同上 (Given) | 改 requireCondition | 新增付款方式編輯器就緒 |
| A1 | Orders/Edit/OrderEditDirtyTests.swift:33 | testCancel_進過選擇器返回且未修改_ (Given) | 刪除或改 requireCondition (選擇器已由呈現動作等就緒) | |
| A1 | Orders/Edit/OrderEditDirtyTests.swift:37 | 同上 (Given) | 改 requireCondition | 返回後表單就緒 |
| A1 | Orders/Edit/OrderEditDirtyTests.swift:61 | testCancel_有變更後選繼續編輯_ (Given) | 改 `try requireCondition(app.alertPresented(), …)` | |
| A1 | Orders/Edit/OrderEditDirtyTests.swift:84 | testCancel_有變更後選捨棄變更_ (Given) | 同上 | |
| A3 | Orders/Detail/OrderDetailTests.swift:159 | testRelaunch_ (Then) `XCTAssertEqual(before, "+$970")` | 參考：基準值可改在 Given (L68-70) 以 requireCondition 驗，避免基準錯時跑完整段 | 提案前列為參考 |
| C3 | Orders/Detail/AISummaryTests.swift:35 | testTapAISummary_AI未開啟_ | 同方法對照 | |
| C3 | Orders/Detail/AISummaryTests.swift:62 | testTapAISummary_AI已開啟_ | 同方法對照 | |
| C3 | Orders/Detail/PhotoViewerPagingTests.swift:43 | testSwipeToNextPhoto_ | 同方法對照 | |
| C3 | Orders/Edit/OrderEditAddOptionTests.swift:91 | testAddPaymentMethod_ | 同方法對照 | |
| H8 | Orders/Edit/OrderCreateTests.swift:185 | private assertCurrencyIsJapaneseYen | 同方法對照 (submitCustomerName 移到 When 末尾) | 比對同時改 currencyCode() == "JPY" (5.5) |
合計 28。已由 4.x 解掉：G8 (開新增訂單表單的 6 份副本，4.5)、G9 (開既有詳情／合併／編輯的副本，4.5)、G7 的 UITEST-MRG 編號 (4.5)、A1 中 assertAlertMessage 內部用 XCTAssert 的問題 (4.4)。

##### 5.6a Orders 根層
| 項目 | 現行檔:行 | 所在方法或 helper | 要做的事 | 備註 |
| --- | --- | --- | --- | --- |
| A1 | Orders/OrdersListTests.swift:41 | testSelectStatusChip_選已確認_ (Given) | 改 requireCondition | 篩選前置 |
| A1 | Orders/OrdersListTests.swift:66 | testSearch_輸入客戶名稱_ (Given) | 同上 | 搜尋前置 |
| C2 | Orders/OrderListLoadFailureTests.swift:18 | testRetryTapped_訂單每次讀取皆失敗_ | 同方法對照 (前提併入 Given：L29-32 的失敗、無空狀態、重試鍵改 requireCondition) | |
| C2 | Orders/OrdersNavigationSmokeTests.swift:223 | testOrders_清除排除詳情的類別篩選_ | 同方法對照 (前提併入 Given) | |
| C2 | Orders/OrdersNavigationSmokeTests.swift:342 | testOrders_編輯訂單取消_ | 同方法對照 (前提併入 Given) | |
| C2 | Orders/OrdersNavigationSmokeTests.swift:412 | testOrders_新增訂單單一Sheet_ | 同方法對照 (可拆 A／B) | |
| C2 | Orders/OrdersNavigationSmokeTests.swift:17 | testOrders_選取訂單詳情與原生返回_ | 同方法對照 (旅程，每個 When 配自己的 Then) | |
| C2 | Orders/OrdersNavigationSmokeTests.swift:168 | testOrders_搜尋排除詳情後清除path_ | 同方法對照 (旅程) | |
| C2 | Orders/OrdersNavigationSmokeTests.swift:268 | testOrders_編輯草稿與焦點_ | 同方法對照 (旅程，移到 OrderEditRotationUITests) | |
| H2 | Orders/OrdersNavigationSmokeTests.swift:142 | testOrders_改選另一筆訂單_ | 同方法對照 (skip 移到 open 之後、tapOrder 之前) | |
| H2 | Orders/OrdersNavigationSmokeTests.swift:177 | testOrders_搜尋排除詳情後清除path_ | 同上 | |
| H2 | Orders/OrdersNavigationSmokeTests.swift:232 | testOrders_清除排除詳情的類別篩選_ | 同上 | |
| H5 | Orders/OrdersNavigationSmokeTests.swift:301 | testOrders_編輯草稿與焦點_ | 同方法對照 (`typeText("X")` 改 appendText) | |
| D4 | Orders/OrdersNavigationSmokeTests.swift:98 | testOrders_選取訂單後_path與詳情同步 的摘要 | 摘要只複述名稱，改寫成具體行為 (選哪筆、path 與詳情根的值) | |
| D | Orders/OrderEditRotationUITests.swift (新檔) | 型別摘要 | 新寫型別摘要 | |
合計 15。已由 4.x 解掉：G3 (openOrdersList 副本，4.5)、G10 的內嵌訂單編號列舉 (改讀 displayedOrderID，4.5)、G14 (搜尋收鍵盤、清除與系統結束鈕，4.5)。

##### 5.6b Smoke＋Performance
| 項目 | 現行檔:行 | 所在方法或 helper | 要做的事 | 備註 |
| --- | --- | --- | --- | --- |
| A1 | Smoke/AppLockTests.swift:26 | testTapRetry_驗證替身失敗_ (Given) | 改 requireCondition | 啟動後直接進鎖定畫面 |
| A1 | Smoke/AppLockTests.swift:32 | 同上 (Given) | 改 `try requireCondition(lockScreen.waitForRetryButton(), …)` (Q20) | |
| A1 | Smoke/HarnessSelfCheckTests.swift:25 | testRelaunch_有資料後改以空資料重啟_ (Given) | 改 requireCondition | 首次啟動總覽就緒 |
| A1 | Smoke/HarnessSelfCheckTests.swift:28 | 同上 (Given) | 同上 | 首次啟動不應是空狀態 |
| A1 | Smoke/HarnessSelfCheckTests.swift:32 | 同上 (Given) | 同上 | 首次啟動有 BL-2604-018 |
| A2 | Smoke/HarnessSelfCheckTests.swift:40 | 同上 (When) | 同上 | 重啟後總覽就緒 |
| A1 | Smoke/HarnessSelfCheckTests.swift:57 | testRelaunch_英文啟動後不指定語言重啟_ (Given) | 同上 | 英文啟動總覽就緒 |
| A1 | Smoke/HarnessSelfCheckTests.swift:63 | 同上 (Given) | 改 `try requireValue(dashboard.emptyStateActionLabel(), …)` (Q11) | 見「identifier 引用盤點」 |
| A2 | Smoke/HarnessSelfCheckTests.swift:77 | 同上 (When) | 改 requireCondition | 預設語言重啟總覽就緒 |
| A2 | Smoke/HarnessSelfCheckTests.swift:83 | 同上 (When) | 改 requireValue (Q11) | |
| A1 | Smoke/HarnessSelfCheckTests.swift:141 | testTapSave_行事曆替身授予權限_ (Given) | 改 requireCondition | CampaignsScreen.open(in:) 已等就緒，可刪 |
| A1 | Smoke/HarnessSelfCheckTests.swift:145 | 同上 (Given) | 改 `try requireCondition(campaigns.hasCampaign(campaignID:), …)` | |
| G2 | Smoke/HarnessSelfCheckTests.swift:143 | 同上 (Given) | 區域常數改 `CampaignSeedFixture.koreaCampaignID` | |
| G15 | Smoke/AppLockTests.swift:101 | private assertNoSystemBiometricPrompt | 搬進 BLUITestConfigurationUITestSupport.assertNoSystemPrompt(in:file:line:) (stopWithDiagnostics＋throws) 後刪除；L47、69 改呼叫 | |
| G15 | Smoke/HarnessSelfCheckTests.swift:159-161 | testTapSave_行事曆替身授予權限_ (Then) | 內嵌 springboard 檢查改呼叫同一 TestSupport | |
| H3 | Smoke/OrientationLayoutTests.swift:39 | testRotateToLandscape_含開團與訂單資料_首頁附上橫向截圖 | 補自動判定版面的斷言 (版面判定或框線，預期值字面值)，截圖保留 (design、裁決 4) | 移到 DashboardOrientationUITests |
| H3 | Smoke/OrientationLayoutTests.swift:56 | 訂單頁附上橫向截圖 | 同上 | OrdersOrientationUITests |
| H3 | Smoke/OrientationLayoutTests.swift:73 | 分析頁附上橫向截圖 | 同上 | InsightsOrientationUITests |
| H3 | Smoke/OrientationLayoutTests.swift:175 | private attachScreenshot(named:of:) | 手動 XCTAttachment 屬「需要對比視覺結果」例外，保留；搬進 RootNavigationOrientationUITestSupport 供四個型別共用 | |
| H4 | Performance/LaunchPerformanceTests.swift:20 | testLaunch_冷啟動_量測啟動時間 | Tests 端不改啟動路徑 (維持 `XCUIApplication().launch()`)，只做 kit 排版對齊；例外寫進規則檔由 6.2 處理 | |
| D | Smoke/DashboardOrientationUITests.swift、OrdersOrientationUITests.swift、InsightsOrientationUITests.swift、RootNavigationOrientationUITestSupport.swift、BLUITestConfigurationUITestSupport.swift (新檔) | 型別摘要 | 新寫型別摘要 | |
合計 21。已由 4.x 解掉：G18 (行事曆測試開開團編輯改走 Page Object 鏈，4.6)。

##### 5.7a Navigation/AdaptiveNavigationContinuityUITests
| 項目 | 現行檔:行 | 所在方法或 helper | 要做的事 | 備註 |
| --- | --- | --- | --- | --- |
| C2 | Navigation/AdaptiveNavigationContinuityUITests.swift:20 | testSidebarPreferenceSurvivesTabChange_ | 同方法對照 (旅程，每個 When 配自己的 Then) | |
| C2 | Navigation/AdaptiveNavigationContinuityUITests.swift:349 | testSelectionSurvivesLayoutChange_ | 同上 | |
| C2 | Navigation/AdaptiveNavigationContinuityUITests.swift:408 | testOrdersStartUnselected_ | 同上 | |
| C2 | Navigation/AdaptiveNavigationContinuityUITests.swift:488 | testSearchKeepsOrClearsSelection_ | 同上 | |
| C2 | Navigation/AdaptiveNavigationContinuityUITests.swift:545 | testMoreSettingsSurvivesRoundTrip_ | 同上 | |
| C2 | Navigation/AdaptiveNavigationContinuityUITests.swift:748 | testMoreCustomerSurvivesRoundTrip_ | 同上 | |
| C2 | Navigation/AdaptiveNavigationContinuityUITests.swift:997 | testDraftSurvivesRotation_ | 同上 | |
| C2 | Navigation/AdaptiveNavigationContinuityUITests.swift:1101 | testSidebarReservedRegion_ | 同上 | |
| C2 | Navigation/AdaptiveNavigationContinuityUITests.swift:1259 | testOrdersLayoutCombination_ | 同上 | |
| C2 | Navigation/AdaptiveNavigationContinuityUITests.swift:1340 | testCampaignAndMoreKeepTarget_ | 同上 | |
| H2 | Navigation/AdaptiveNavigationContinuityUITests.swift:373 | testSelectionSurvivesLayoutChange_ | 同方法對照 (skip 上移到轉直向後的下一行) | |
| D4 | Navigation/AdaptiveNavigationContinuityUITests.swift:402 | testOrdersStartUnselected_ 的摘要 | 摘要只複述名稱，依新名改寫 (首次進入、轉向、點選前的選取狀態) | |
| D4 | Navigation/AdaptiveNavigationContinuityUITests.swift:1310 | testCampaignRowSelected_ 的摘要 | 同上 | |
| D4 | Navigation/AdaptiveNavigationContinuityUITests.swift:1335 | testCampaignAndMoreKeepTarget_ 的摘要 | 同上 | |
| D | Navigation/RootNavigationContinuityUITests.swift (改名)、OrdersAdaptiveLayoutUITests.swift、OrderEditDraftRotationUITests.swift、CampaignsAdaptiveLayoutUITests.swift、DashboardAdaptiveLayoutUITests.swift (新檔) | 型別摘要 | 改名者改寫成新範圍，新檔新寫 | |
合計 15。已由 4.x 解掉：G10 (requireDetailShows 收進 Support/XCTestCase+OrdersAssertions.swift，4.5)、G1 (openCampaignDetail，4.6)。不需處理：F 的 waitForSidebarMarkerHidden (L1463) 依 design「wait… 回傳 Bool、不可丟棄」合規，呼叫端都有使用回傳值。本檔 A 類：掃描 Given／When 段沒有 XCTAssert* 或 failWithDiagnostics。

##### 5.7b Navigation 其餘 4 檔
| 項目 | 現行檔:行 | 所在方法或 helper | 要做的事 | 備註 |
| --- | --- | --- | --- | --- |
| A1 | Navigation/LoadFailureReloadLoopTests.swift:67 | testLeaveInsights_ (Given) | 改 `try requireCondition(OrdersScreen(app:).waitForLoadFailure(timeout:), …)` (P1)；逾時改 LaunchOptions 推導 | |
| A2 | Navigation/LoadFailureReloadLoopTests.swift:75 | 同上 (When) | 改 requireCondition (Q13 waitForLoading) | 時間窗前提 |
| A1 | Navigation/LoadFailureReloadLoopTests.swift:103 | testLeaveCustomers_ (Given) | 同 L67 | |
| A2 | Navigation/LoadFailureReloadLoopTests.swift:114 | 同上 (When) | 改 requireCondition (Q6) | |
| A1 | Navigation/LoadFailureReloadLoopTests.swift:148 | testColdStartUnlock_ (Given) | 改 requireCondition | 鎖定畫面時間窗 |
| A2 | Navigation/LoadFailureReloadLoopTests.swift:155 | 同上 (When) | 改 requireCondition (Q9) | |
| A1 | Navigation/LoadFailureReloadLoopTests.swift:184 | testBackgroundLock_ (Given) | 改 requireCondition (Q9) | |
| A2 | Navigation/LoadFailureReloadLoopTests.swift:192 | 同上 (When) | 改 `try requireCondition(waitUntilInBackground(app, timeout: 5), …)` | |
| C2 | Navigation/LoadFailureReloadLoopTests.swift:15 | testTabSwitch_訂單每次讀取皆失敗_ | 同方法對照 (旅程) | |
| C2 | Navigation/ReadableWidthUITests.swift:32 | testMoreReadableWidth_ | 同方法對照 (可拆 A／B) | |
| C3 | Navigation/ReadableWidthUITests.swift:108 | testMoreReadableWidth_ | 同方法對照 (收尾 rotateToPortrait 刪除，裁決 7) | |
| D2 | Navigation/ReadableWidthUITests.swift:11 | 型別摘要 | 「驗證 regular 根導覽下…」改成「…的 UI 測試」並配合新型別名 RootNavigationReadableWidthUITests | |
| D | Navigation/RootNavigationLoadFailureUITests.swift、RootNavigationScenarioUITests.swift (改名)、AppLockLoadFailureUITests.swift、OrdersSelectionUITests.swift、SettingsLanguageUITests.swift (新檔) | 型別摘要 | 改名者改寫成新範圍，新檔新寫 | |
合計 13。不需處理：F 的 waitUntilInBackground (L229) 依 design wait 規則合規。

##### 5.8 Campaigns＋Customers
| 項目 | 現行檔:行 | 所在方法或 helper | 要做的事 | 備註 |
| --- | --- | --- | --- | --- |
| A1 | Campaigns/CampaignCrudTests.swift:33 | testTapSave_新增開團並輸入名稱_ (Given) | 改 requireCondition | 編輯表單就緒；採 S1 後 tapAdd 回傳就緒畫面可刪 |
| A1 | Campaigns/CampaignCrudTests.swift:61 | testCancelDelete_刪除確認選取消_ (Given) | 改 `try requireCondition(detail.waitForDeleteConfirmation(), …)` | |
| A1 | Campaigns/CampaignCrudTests.swift:63 | 同上 (Given) assertAlertMessage | 不改 (4.4 後已 throws)；摘要見下方 D | |
| A1 | Campaigns/CampaignDetailTests.swift:30 | testCancelSettle_結團確認選取消_ (Given) | 改 `try requireCondition(detail.isSettleConfirmationPresented(), …)` | |
| A1 | Campaigns/CampaignDetailTests.swift:32 | 同上 (Given) assertAlertMessage | 不改；摘要見下方 D | |
| A1 | Campaigns/CampaignEditDateRowTests.swift:45 | testReminderDateRow_開啟訂購提醒_ (Given) | 改 requireCondition (採 S1 後可刪) | |
| A2 | Campaigns/CampaignProgressAccessibilityTests.swift:75 | private readKoreaCampaignRowLabel (When 的 L26、42 呼叫) | 改 `try requireCondition(campaigns.hasCampaign(…), …)` | helper 已 throws |
| A2 | Customers/CustomersLoadStateTests.swift:22、30 | testOpenCustomers_訂單每次讀取皆失敗_ (When) | L22 open(in:) 已等前景，guard 可刪或改 requireCondition；L30 改 `try requireCondition(!customers.hasEmptyState(timeout: 0), …)` (Q5) | |
| A1 | Customers/CustomersLoadStateTests.swift:50 | testOpenCustomers_訂單延遲讀取失敗_ (Given) | 改 `try requireCondition(OrdersScreen(app:).waitForLoadFailure(timeout:), …)` (P1)，逾時改 LaunchOptions 推導 | |
| A2 | Customers/CustomersLoadStateTests.swift:57、65 | 同上 (When) | 同 L22、30 | |
| C2 | Campaigns/CampaignFlowTests.swift:69 | testSaveButtonTapped_開團寫入失敗_ | 同方法對照 (可拆 A／B) | |
| C2 | Campaigns/CampaignFlowTests.swift:115 | testConfirmDelete_失敗提示關閉後再次刪除_ | 同方法對照 (前提併入 Given) | |
| C2 | Campaigns/CampaignFlowTests.swift:284 | testBackTapped_ | 同方法對照 (旅程) | |
| C2 | Campaigns/CampaignFlowTests.swift:336 | testRotated_ | 同方法對照 (旅程) | |
| C2 | Campaigns/CampaignListLoadFailureLoopTests.swift:15 | testTabSwitch_ | 同方法對照 (旅程) | |
| C2 | Customers/CustomersLoadStateTests.swift:43 | testOpenCustomers_訂單延遲讀取失敗_ | 同方法對照 (可拆 A／B) | |
| C3 | Campaigns/CampaignFlowTests.swift:146-147 | testConfirmDelete_失敗提示關閉後再次刪除_ | 同方法對照 (cancelDelete＋alertDismissed 刪除，裁決 7) | |
| G2 | Campaigns/CampaignCrudTests.swift:20 | private static let koreaCampaignID | 刪除，改用 CampaignSeedFixture.koreaCampaignID | |
| G2 | Campaigns/CampaignDetailTests.swift:17 | 同上 | 同上 | |
| G2 | Campaigns/CampaignProgressAccessibilityTests.swift:17 | 同上 | 同上 | |
| D4 | Campaigns/CampaignEditDateRowTests.swift:37 | testReminderDateRow_ 的摘要 | 摘要只複述名稱，依新名改寫 | |
| D4 | Campaigns/CampaignFlowTests.swift:41 | testRetryTapped_重試後_ 的摘要 | 同上 (移到 RootNavigationCampaignLoadFailureUITests) | |
| D4 | Campaigns/CampaignListTests.swift:14、Customers/CustomersTests.swift:38 | 空狀態測試的摘要 | 參考 (提案前列為參考)：只多「尚無…」，可不改 | |
| D | Campaigns/CampaignCrudTests.swift:50、CampaignDetailTests.swift:19 | testCancelDelete_、testCancelSettle_ 的摘要 | 摘要把 alert 訊息寫成預期結果；訊息比對留在 Given 作前提，摘要改成只寫取消後的結果 | |
| D | Customers/RootNavigationCustomerOrdersUITests.swift (新檔)、各改名型別 | 型別摘要 | 新檔新寫；CampaignEditUITests (原 CampaignCrudTests) 等改名者改寫成新範圍 | |
合計 25。已由 4.x 解掉：G1 (openCampaignDetail 兩份，4.6)、G17 (開客戶頁兩份，4.6)、F 的 openCustomersWithoutEmptyState (4.6 刪除) 與 assertLoadFailureStaysStable 回傳 Bool (4.4 改 throws Void)、A1 中 assertAlertMessage 內部 XCTAssert (4.4)。不需處理：H2 CampaignFlowTests:325 已在轉向後宣告。

##### 5.9b Tools
| 項目 | 現行檔:行 | 所在方法或 helper | 要做的事 | 備註 |
| --- | --- | --- | --- | --- |
| A1 | Tools/FxTests.swift:32 | testTypeAmount_選美元後輸入金額_ (Given) | 改 requireCondition (採 S2 後 openCurrencyPicker 回傳就緒 picker 可刪) | |
| A1 | Tools/FxTests.swift:37 | 同上 (Given) | 改 requireCondition | 選幣別後匯率頁就緒 |
| A2 | Tools/ToolLoadTabSwitchTests.swift:133、149、156 | private switchTabAndReturnDuringRead (When 的 L28、50 呼叫) | 三處改 requireCondition，helper 改 `throws(UITestError)` 不回傳 Bool；L28、50 的 guard 拿掉 | 與下列 F 一起改 |
| F | Tools/ToolLoadTabSwitchTests.swift:130 | switchTabAndReturnDuringRead(_:) | 回傳 Bool 改 throws Void | |
| C2 | Tools/FxTests.swift:70 | testContinueTyping_ | 同方法對照 (旅程) | |
| C2 | Tools/QuoteTests.swift:65 | testContinueTyping_ | 同上 | |
| C2 | Tools/SettingsGoalInputTests.swift:17 | testContinueTyping_ | 同上 | |
| C2 | Tools/ToolLoadTabSwitchTests.swift:15 | testTabSwitch_匯率延遲讀取中_ | 同方法對照 (旅程，裁決 6) | |
| C2 | Tools/ToolLoadTabSwitchTests.swift:37 | testTabSwitch_報價延遲讀取中_ | 同上 | |
| C3 | Tools/ToolLoadTabSwitchTests.swift:33 | testTabSwitch_匯率延遲讀取中_ (Then 呼叫含重試點擊的 helper) | 同方法對照 (標記移回本體後重試成為第二組 When) | |
| C3 | Tools/ToolLoadTabSwitchTests.swift:55 | testTabSwitch_報價延遲讀取中_ | 同上 | |
| C4 | Tools/ToolLoadTabSwitchTests.swift:170、188、191 | private assertReadFailureShownAndRetryable | helper 內的 // Then、// When、// Then 移回兩條測試本體同一縮排層級，helper 拆成或內聯為不含標記的斷言 | |
| H1 | Tools/ToolLoadTabSwitchTests.swift:87 | fileprivate struct ToolLoadElements | 改 private (被 private helper 簽章使用時改成 internal 巢狀型別)；查詢屬性改 Q21-Q26 | 見「identifier 引用盤點」 |
合計 13。已由 4.x 解掉：G13 (開匯率、報價並等就緒的副本，4.6)。

##### 5.9a Forms
| 項目 | 現行檔:行 | 所在方法或 helper | 要做的事 | 備註 |
| --- | --- | --- | --- | --- |
| A1 | Forms/EditorTextInputFocusUITests.swift:22、24、25 | testFocusCampaignNameFromLeft_ (Given) | 三處 XCTAssert 改 requireCondition | 前置名稱、失焦、失焦不改原文 |
| A1 | Forms/EditorTextInputFocusUITests.swift:46、52、55、59 | testFocusCampaignNotesFromFirstLine_ (Given) | 四處改 requireCondition | 前置名稱、備註原文、失焦、原文不變 |
| A1 | Forms/EditorTextInputFocusUITests.swift:78、80、81 | testFocusLookupNameFromLeft_ (Given) | 三處改 requireCondition | |
| A1 | Forms/EditorTextInputFocusUITests.swift:101、103、107 | testFocusPaymentMethodNameFromLeft_ (Given) | 三處改 requireCondition | |
| A1 | Forms/QuoteInputFocusUITests.swift:46、53、54 | testFocusFieldFromLeft_本金直接換到運費_ (Given) | 三處改 requireCondition | |
| A1 | Forms/QuoteInputFocusUITests.swift:76 | testFocusFieldFromLeft_本金未輸入即失焦_ (Given) | 改 requireCondition | 提示文字 (placeholder) |
| A1 | Forms/QuoteInputFocusUITests.swift:97 | testFocusFieldFromLeft_零值本金輸入中_ (Given) | 改 requireCondition | |
| A1 | Forms/QuoteInputFocusUITests.swift:117 | testFocusFieldFromLeft_零值刷卡費率輸入_ (Given) | 改 requireCondition | |
| A1 | Forms/QuoteInputFocusUITests.swift:181 | private preparePrincipal (Given 的 L19、73 呼叫) | 改 requireCondition | 與下列 F 一起改 |
| F | Forms/QuoteInputFocusUITests.swift:168 | preparePrincipal(in:file:line:) | 回傳 Bool 改 throws Void，L19、73 的 guard 拿掉 | |
| A1 | Forms/OrderEditInputFocusUITests.swift:274、279、286、290 | testFocusCardlessDeduction_ (Given) | 四處改 requireCondition | 該測試另依定稿表拆 A／B |
| A2 | Forms/OrderEditInputFocusUITests.swift:358 | testFocusChargedAmountFromLeft_已有折抵時提高實付_ (When) | XCTAssertEqual 改 requireCondition | |
| A2 | Forms/OrderEditInputFocusUITests.swift:393、400 | testFocusChargedAmountFromLeft_已有折抵時輸入再刪空_ (When) | 兩處改 requireCondition | |
| A1 | Forms/OrderEditInputFocusUITests.swift:480、486、492、499、512、517 | private prepareSavedCardlessOrder (Given 用) | 六處 `app.failWithDiagnostics`＋`return nil` 改 requireCondition，回傳改非 optional 的 OrderEditScreen；L486 隨「本地導覽 helper 的去向」改用 openPaymentPicker() 回傳值後刪除 | |
| A1 | Forms/OrderEditInputFocusUITests.swift:538、543、550、557 | private saveAndReopenOrderEdit (由 prepareSavedCardlessOrder 呼叫) | 同上；L557 隨改用 detail.openEdit() 刪除 | |
| A1 | Forms/SearchInputFocusUITests.swift:75 | testFocusOrderListSearchFromLeft_深連結取代既有文字_ (Given) | 改 requireCondition | |
| A1 | Forms/ToolsInputFocusUITests.swift:20、48、72 | testFocusAmountFromLeft_ 兩條與 testTapPresetAmount_ (Given) | 三處改 requireCondition (FxScreen.open(in:) 已等前景，可刪) | |
| A3 | Forms/OrderEditInputFocusUITests.swift:42 | testFocusChargedAmountFromLeft_零值輸入_ (Then) | 參考：聚焦前基準 0 可在 Given 以 requireCondition 驗 | 提案前列為參考 |
| C2 | Forms/OrderEditInputFocusUITests.swift:266 | testFocusCardlessDeduction_ | 同方法對照 (可拆 A／B) | |
| D3 | Forms/OrderEditInputFocusUITests.swift:262-263 | testFocusCardlessDeduction_ 的摘要 | 拆 A／B 後各寫一行摘要 | |
| G2 | Forms/EditorTextInputFocusUITests.swift:19 | testFocusCampaignNameFromLeft_ (Given) 字面值 | 改 CampaignSeedFixture.koreaCampaignID | |
| H6 | Forms/OrderEditInputFocusUITests.swift:490-491 | private prepareSavedCardlessOrder | 同方法對照 (guard 合成一行，裁決 8) | |
| D | Forms 的新檔 LookupManagementInputFocusUITests、MergeFlowInputFocusUITests、OptionPickerInputFocusUITests、SettingsInputFocusUITests 與改名的 CampaignEditInputFocusUITests、OrdersSearchInputFocusUITests、FxInputFocusUITests | 型別摘要 | 新檔新寫，改名者改寫成新範圍 | |
合計 23 列 (A1／A2 共 41 處)。已由 4.x 解掉：G8 (openNewOrderEdit，4.5)、G9 (開合併候選的副本，4.5)、G13 (openQuote，4.6)、G14 (dismissSearchKeyboard，4.5)、G18 (openCampaignEdit，4.6)。

##### 5.10 Dashboard＋Insights＋More
| 項目 | 現行檔:行 | 所在方法或 helper | 要做的事 | 備註 |
| --- | --- | --- | --- | --- |
| A1 | Dashboard/DashboardLaunchLoadingTests.swift:44 | testDashboardRetry_ (Given) | 改 `try requireCondition(dashboard.waitForLoadFailure(), …)` | |
| A2 | Insights/InsightsLaunchLoadingTests.swift:27 | testInsightsLaunch_ (When) | 改 requireCondition | |
| G2 | Dashboard/DashboardLaunchLoadingTests.swift:17 | private static let koreaCampaignID | 刪除，改 CampaignSeedFixture.koreaCampaignID | |
| D3 | Dashboard/DashboardLayoutSmokeTests.swift:14-15 | testDashboardLayout_標準字級_ 的摘要 | 摘要合成一行 | |
| C2 | More/LookupManagementTests.swift:58 | testRenameItem_新訂單選擇器只顯示新名稱 | 同方法對照 (前提併入 Given，移到 OrderEditRenamedCategoryUITests) | |
| C2 | More/LookupManagementTests.swift:199 | testRequestDeletion_寫入失敗提示關閉後再刪除_ | 同方法對照 (前提併入 Given；W4 刪除，裁決 7) | |
| C2 | More/LookupManagementTests.swift:254 | testRequestDeletion_滑動刪除後取消_ | 同方法對照 (前提併入 Given) | |
| C2 | More/LookupManagementTests.swift:123 | testRequestDeletion_刪除寫入失敗_ | 同方法對照 (可拆 A／B) | |
| C2 | More/LookupManagementTests.swift:162 | testRequestDeletion_長按選單刪除寫入失敗_ | 同上 | |
| C2 | More/LookupManagementTests.swift:286 | testAddItem_新增寫入失敗_ | 同上 | |
| C2 | More/LookupManagementTests.swift:359 | testAddForm_未儲存取消_ | 同上 | |
| C2 | More/LookupManagementTests.swift:334 | testRenameForm_旋轉後續輸入_ | 同方法對照 (旅程) | |
| C2 | More/MoreNavigationSmokeTests.swift:18 | testMoreNavigation_寬版同工具重開保留_ | 同方法對照 (旅程) | |
| D4 | More/LookupManagementTests.swift:317 | testOpenCategoryManagement_ 的摘要 | 摘要只複述名稱，依新名改寫 | |
| D4 | Insights/InsightsTests.swift:118 | testGoToInsights_空資料_ 的摘要 | 參考 (同 5.8 空狀態兩條) | |
| D | More/OrderEditRenamedCategoryUITests.swift (新檔) 與改名型別 | 型別摘要 | 新檔新寫，改名者改寫成新範圍 | |
合計 16。已由 4.x 解掉：G11 (isAbove 收成 CGRect.isAbove，4.6)、G12 (InsightsTests 的 openInsights 刪除、版面測試的版本留 private，4.6)。備註：Insights/InsightsLaunchLoadingTests.swift:17 的 campaignIDs 陣列含四月韓國團 id 字面值，不在提案前 G2 清單，可一併改用 CampaignSeedFixture.koreaCampaignID (t17 建議，可選)。

### 5.2 訂單畫面 Page Object 補方法

- t1n 實作，只改 `Screens/Orders/` 的 `OrdersScreen`、`OrderDetailScreen`、`OrderEditScreen`、`OrderFilterSheetScreen`、`OrderCategoryPickerScreen`，`Tests/**`、`Support/**` 未改。P1 至 P32 的名稱與簽章與 5.1 的「5.2 要新增的 Page Object 方法」表一致，沒有差異 (P20 為 `listRootCount`、`detailRootCount` 兩個屬性)。
- 同一查詢收成一處：`OrdersScreen` 的清單根、詳情根、空狀態、詳情未選取提示、重試鍵、新增鈕、篩選入口與訂單列改由 private 查詢屬性提供，`isForegroundReady`、`currentPathProjection` 與 19 個既有的點擊、讀值方法改用新成員；`OrderDetailScreen` 的摘要卡、更多鈕，`OrderEditScreen` 的儲存鈕與四個選擇列入口 (private `tapPickerRow` 改收元素)，`OrderFilterSheetScreen`、`OrderCategoryPickerScreen` 的搜尋欄與清除鈕同樣改用新成員。`isForegroundReady` 保留原本的判斷順序與「任一元素可互動」的語意 (`hasHittableOrderRow(timeout: 0)`，`Polling.wait` 在逾時為 0 時仍判斷一次)；P19 `tapRegularHeaderGap` 搬入 `OrderRegularAccessibilitySizeTests.tapHeaderGap` 的幾何條件 (清單右緣內縮 8、右側空白至少 20、點擊高度取清除鈕中線)，失敗出口改 `stopWithDiagnostics`、框線判斷改 `isUsableFrame`，測試檔那份留到 5.4b 刪除。
- 驗證：建置成功 (iPhone 17 跑 `LaunchSmokeTests` 2 通過、1 skip)，`Screens/Orders/` 沒有編譯警告；以腳本逐項比對 32 個方法 (33 個成員) 的簽章各在目標檔恰好出現一次；`@discardableResult` 的函式沒有回傳 `Bool` 的。

### 5.3 其餘畫面 Page Object 補方法與回傳形狀補正

- t9 實作，只改 `Screens/**` 中 `Screens/Orders/` 以外的 10 檔，`Tests/**`、`Support/**` 未改。Q1 至 Q26 的名稱與簽章與 5.1 的「5.3 要新增的 Page Object 方法」表一致，沒有差異；Q26 `QuoteScreen.tapRetry` 依表加回 (4.6 以無呼叫端刪除)。S1 至 S4 (`CampaignsScreen.tapAdd` → `CampaignEditScreen`，`FxScreen`／`QuoteScreen.openCurrencyPicker`、`SettingsScreen.openDefaultCurrency` → `OptionPickerScreen`) 改為點擊後 `requireReady` 再回傳並標 `@discardableResult`；全部呼叫端 (`CampaignCrudTests`、`CampaignEditDateRowTests`、`CampaignFlowTests`、`CurrencyPickerTests`、`FxTests`、`QuoteTests`、`SearchInputFocusUITests`) 都預期呈現該畫面，沒有 alert 或其他分支，呼叫端不用改。
- 同一查詢收成一處：開團根容器 (`destinationContainer`，`selectedCampaignID` 改用)、總覽空狀態行動鈕與 KPI 卡 (`kpiValue` 改用 `kpiTile`)、選項列 (private `optionRow`，`selectOption`、`optionLabel` 與兩個新等待共用)、設定頁預設幣別列、App 鎖重試鍵、付款方式編輯器的貨到付款開關。Q14 `revealFirstCategoryRank` 依表比照 `revealCostDonut` (等 5 秒後取穩定可見框線)，現行測試是等 10 秒後捲入；呼叫前已等分析頁就緒，保留表上的形狀 (主對話代選)。
- 主對話修正：`CampaignsScreen` 的 Computed Properties extension 補 `@MainActor`，消除新增 `destinationContainer` 的 3 則與 4.6 留下的 3 則 main actor 隔離警告；`DashboardScreen.currentDateSubtitle` 一行 103 字元改斷行；`kpiValue` 內說明「以 `any` 查詢」的註解隨查詢移到 `kpiTile`；`AppLockScreen` 兩處與 `CampaignsScreen` 一處 `let x = self.x` 的同名區域變數改為直接使用屬性或改名。
- 驗證：建置成功；以腳本逐項比對 Q1 至 Q26 與 S1 至 S4 共 30 項簽章各在目標檔恰好出現一次；`@discardableResult` 的函式沒有回傳 `Bool` 的；重試鍵在 App 端都是 `Button` (`BLLoadFailureView`、`FxStatusBanner`、`QuoteStatusBanner`)，以 `app.buttons` 查詢與現行測試的 `.any` 查詢指向同一元素。主對話修正後重新建置成功 (iPhone 17 `LaunchSmokeTests` 2 通過、1 skip)，UI target 沒有編譯警告。

### 5.4a Orders/Filters

- t9 實作。五檔依類別對照改名 (`OrderPaymentMethodMenuTests` → `OrdersPaymentMethodMenuUITests`，其餘加 `UI`)，20 條方法依方法對照改名；新增 `Orders/Filters/OrdersUITestSupport.swift`，只有 `assertTrigger`，兩檔各自的 private 版本刪除。`OrderFilterSheetTests` 的清除鈕查詢改用 P31；付款方式兩條改用 `OrdersScreen.open(in:)`，Given 的「未選付款方式」改 `requireCondition`；篩選捨棄確認的 C3 把繼續編輯、確認 sheet 仍開啟、套用都移到 When；大量類別兩條與付款方式的清單比對改用 `assertListedOrderIDs`；類別選擇器下滑那條依 D4 補上「仍在選擇器且『美妝』保留」的 Then。
- 主對話修正：t9 的 `assertTrigger` 收觸發鈕元素，但篩選入口在 `OrdersScreen` 是 private，建置失敗。改為收觸發鈕標題字串，呼叫端改用 Page Object 既有的 `filterTriggerLabel()`／`categoryTriggerLabel()`／`paymentMethodTriggerLabel()` (與改名前的寫法相同，不擴大 Page Object 的元素介面；主對話代選)。
- 驗證：建置成功。主對話以腳本比對型別與方法名，和 5.1 方法對照逐條一致；Given／When (含它們呼叫的 private helper) 內的 `XCTAssert`／`failWithDiagnostics` 為 0 (同一腳本在改前快照命中舊寫法，作陽性對照)，主對話逐條人工檢視；`find` 沒有 `*Tests.swift` 殘留。`BLAccessibilityID.` 引用 0、`goTo*`／`selectTab(` 0。iPhone 17：`OrderFilterSheetUITests` 11、`OrderFilterSheetLargeUITests` 1 通過，類別選擇器 6 條與付款方式 2 條為 regular 限定而 skip；這 8 條另在 iPad Air 11-inch (M4) 跑，全數通過。執行數 20 = 4.7 的 20。

### 5.5 Orders/Detail＋Orders/Edit

- t1n 實作。十檔依類別對照改名 (`OrderMergeTests` → `MergeFlowUITests`、`OrderDetailMenuTests` → `OrderDetailMoreMenuUITests`、`OrderCreateTests` → `OrderEditCreateUITests`、`KeyboardDismissTests` → `OrderEditKeyboardDismissUITests`、`PhotoViewerPagingTests` → `PhotoViewerUITests`，其餘加 `UI`)，23 條方法改名，沒有拆型別。日圓幣別兩條改讀 `OrderEditScreen.currencyCode()` 比對 `"JPY"`；貨到付款那條改用 `LookupManagementScreen.open(.paymentMethods, in:)`、`beginEditPaymentMethod`、Q18／Q19 與 `tapSave()`，更正後以 `Polling.wait` 等 `paymentMethodClassification(named:)` 的完整值等於 `"貨到付款"`，不再比對 label；回溯前的 `+$970` 依重掃 A3 移到 Given 驗。重掃 28 列：A1 22 處改 `requireCondition`／`requireValue` 或改用呈現動作回傳的就緒 Page Object (`openEdit`、`openMerge`、`openSourcePicker` 等)，`assertAlertMessage` 兩處保留 (已會丟錯停止)；C3 四處 (AI 總結兩條、照片換頁、新增付款方式後返回) 的動作移到 When；`assertCurrencyIsJapaneseYen` 只剩讀值與斷言，收鍵盤移到 When。`selectFromPicker` 依表刪除，`profitValue`、`assertOriginalDetailIsDisplayed`、`launchWithJapaneseYenDefault` 留作 private 並改 `throws(UITestError)`。
- M 17 筆全數遷移，保留 1 筆 K (`SummaryTile` 型別標註)。來源與付款標籤的 label CONTAINS 等待依盤點保留 (改經 P28、P29)。
- 驗證：建置成功。主對話以腳本比對型別與方法名，和 5.1 方法對照逐條一致；Given／When (含它們呼叫的 private helper) 內的 `XCTAssert`／`failWithDiagnostics` 為 0 (同一腳本在改前快照命中舊寫法，作陽性對照)，主對話逐條人工檢視；`find` 沒有 `*Tests.swift` 殘留。iPhone 17 跑十個類別 23 條 (4.7 的 9 + 14) 全數通過。變異檢查 (與 5.10 同一次執行，三處暫改互不影響)：拿掉幣別列的 `accessibilityValue` 時兩條日圓測試在 Then 失敗 (「預設日圓的新訂單幣別代碼應為 JPY」)；付款方式列的 value 改為不套用時貨到付款那條在 Given 失敗 (「付款方式更新成功後，完整分類值未顯示貨到付款」)；還原後雜湊一致。

### 5.6a Orders 根層

- t16 實作。`OrderListLoadFailureTests` → `OrdersLoadFailureUITests`、`OrdersListTests` → `OrdersUITests`、`OrdersNavigationSmokeTests` 拆成 `OrdersNavigationUITests` 與 `OrderEditRotationUITests` (轉向往返的旅程)，15 → 16 條。載入失敗那條的等待改用 `LaunchOptions.delayedReadFailureTimeout` (預設延遲 8 秒時同為 15 秒)，前提型兩組 When／Then 併入 Given；導覽類別的 `tapRootTab(.orders)` 加 `waitUntilReady` 改用 `OrdersScreen.open(in:)`；「新增訂單單一 Sheet 後取消」拆成點新增與取消兩條；「清除類別篩選」「編輯後取消」兩條前提併入 Given；詳情訂單改讀詳情根的 value，詳情導覽列標題改用共用 helper，接續輸入改 `appendText` (H5)；H2 三條的 regular skip 移到 `OrdersScreen.open(in:)` 之後、第一次 `tapOrder` 之前。
- 保留 (t16 選擇，主對話同意)：`OrdersUITests.assertSearchRestored` 在 `Polling.wait` 內每輪重查搜尋欄框線，共用的 `hittableSearchField()` 會丟錯、不能放進不丟錯的輪詢 closure。Then 內既有的 `failWithDiagnostics` 4 處保留 (只在 Then)。
- 跨資料夾的舊名引用由後續任務改：`Tests/Orders/Regular/` 兩處註解 (5.4b)、`AdaptiveNavigationContinuityUITests` 一處 Note (5.7a)、`.claude/rules/ios-navigation.md` 一處 (6.2)。
- 驗證：建置成功。主對話以腳本比對型別與方法名，和 5.1 方法對照逐條一致；Given／When (含它們呼叫的 private helper) 內的 `XCTAssert`／`failWithDiagnostics` 為 0 (同一腳本在改前快照命中舊寫法，作陽性對照)，主對話逐條人工檢視；`find` 沒有 `*Tests.swift` 殘留。`goTo*`／`selectTab(` 0。iPhone 17 跑 4 個類別 16 條 (4.7 的 15 + 拆分 1)：13 通過、3 skip (H2 三條 regular 限定)；iPad 跑 `OrdersNavigationUITests` 8 條：7 通過、1 skip (收合版那條，已在 iPhone 通過)，H2 三條在 iPad 於選取訂單前判得出版面並通過。

### 5.10 Dashboard＋Insights＋More

- t8 實作。七檔依類別對照改名 (`MoreNavigationSmokeTests` → `RootNavigationMoreUITests`，根導覽受測，保留 `goToMore` 兩處；`*SmokeTests` 改 `*UITests`)，`LookupManagementTests` 拆出 `OrderEditRenamedCategoryUITests` (裁決 2)，Dashboard 4、Insights 6、More 15 → 19 條：可拆型四條各拆 A／B，B 的 Given 重做 A 並以 `alertPresented()` 收尾；「刪除失敗提示關閉後再刪除」前兩組併入 Given、最後按取消的一組依裁決 7 刪除。韓國團 id 改用 `CampaignSeedFixture.koreaCampaignID` (`DashboardLaunchLoadingUITests` 與 `InsightsLaunchLoadingUITests`)；`InsightsUITests` 的 `goTo*` 改用 `DashboardScreen`／`CampaignsScreen.open(in:)`；系統返回鍵改 `tapUniqueNativeBackButton()`；自訂 alert 兩處維持 3.2 的 identifier。M 6 筆遷移，N 4 (「更多」入口列) 與 K 2 (自訂 alert 按鈕) 保留。
- 前提不成立 (t8 回報)：刪除寫入失敗的兩條 A，點刪除後確認框仍在收回，`alertPresented()` 會先命中確認框。主對話裁決保留以 alert 內「知道了」按鈕出現判斷失敗提示已呈現：AlertState 的按鈕掛不上 identifier，`tapAlertButton(label:)` 同樣以文字找 alert 按鈕，兩者定位方式一致 (主對話代選)。
- 驗證：建置成功。主對話以腳本比對型別與方法名，和 5.1 方法對照逐條一致；Given／When (含它們呼叫的 private helper) 內的 `XCTAssert`／`failWithDiagnostics` 為 0 (同一腳本在改前快照命中舊寫法，作陽性對照)，主對話逐條人工檢視；`find` 沒有 `*Tests.swift` 殘留。`goTo*` 只在 `RootNavigationMoreUITests` 兩處 (根導覽受測)。iPhone 17 跑八個類別 29 條 (4.7 的 4 + 6 + 15，加 More 拆分 4)：28 通過、1 skip (`RootNavigationMoreUITests` 寬版那條，已在 iPad 通過)。變異檢查：拿掉 `discardAlertKeepEditingButton` 的 identifier 時，`testTapAlertButton_捨棄確認選繼續編輯_保留草稿且單層sheet` 在點按鈕那行失敗 (「找不到 identifier 為 lookupManagement.discardAlert.keepEditingButton 的 alert 按鈕」)，還原後雜湊一致。
- 本輪共同：同一次執行另含 `LaunchSmokeTests` (iPhone 2 通過、1 skip；iPad 3 通過)。iPhone 共 91 條，78 通過、0 失敗、13 skip，約 36 分；iPad 共 21 條，19 通過、0 失敗、2 skip，約 14 分。編譯警告 10 則都是基準已記錄的 main actor 隔離警告 (`ScreenProtocol` 9、`XCTestCase+Diagnostics` 1，全量重編時出現)，測試檔沒有新警告。

### 5.4b Orders/Regular

- t9 實作。五檔依類別對照改名 (`OrderRegular*Tests` → `OrdersRegular*UITests`)，`OrderRegularColumnScopeTests` 依裁決 5 拆出 `RootNavigationRegularColumnsUITests` (側邊欄與切換總覽／訂單分頁三條，根導覽受測，保留 `goTo*`)，兩型別共用的 `assertListControls`、`listColumnBounds`、`assertHorizontalBounds`、`layoutScopeReason` 收進 `OrdersRegularColumnScopeUITestSupport`；標頭空白與清除篩選那條依 C2 拆成 A／B；依裁決 18 新增 `testDatePeriodSelected_最大輔助字級_選取欄外日期膠囊` (spec「date chip outside the visible width」：Given 以 `requireCondition` 確認「本月」膠囊起始不可點，When `selectRegularDateChip("thisMonth")`，Then 為選取狀態)，24 → 26 條。`RunLoop.run` 改 `Polling`；`requireDetailColumnLeadingEdge` 刪除，改用 `foregroundOrdersDetailFrame(in:)`；`tapHeaderGap` 刪除，改呼叫 P19；清除篩選的 5 處前置改 `requireCondition`、清單結果改 `assertListedOrderIDs`；M 39 筆遷移到 P5 至 P25 與各 Page Object 的 `rootElement`，K 1 筆 (`Root.sidebar`，系統側邊欄存在判斷) 保留；H2 三處 skip 提前 (側邊欄那條依裁決 8 移到選取訂單前)；`compact 清單由 OrdersListTests 覆蓋` 的舊名改為 `OrdersUITests`。
- 主對話修正：`testSearchTextChanged_搜尋無符合訂單_詳情只顯示空狀態` 在 Then 重複宣告 `detail`，編譯失敗，刪除重複宣告；新測試前提訊息的 `+` 串接合回一行。
- iPad 第一輪 26 條中 5 條失敗，退回 t9 修正：導覽列改用共用的 `navigationBar(containingTitle:)` 取得，這個 helper 回傳「identifier、label 或任一 staticText 相符」的第一個導覽列，詳情導覽列與清單欄導覽列都拿到清單欄或根側邊欄的導覽列 (`OrdersRegularColumnScopeUITests` 三條「位置越界：詳情導覽列狀態選單」、`OrdersRegularSearchBarUITests` 兩條橫向「『訂單』導覽列不在清單欄內」)；搜尋列測試的「清單欄標題保留」也被放寬成「畫面上有該標題」。主對話裁決：共用標題 helper 只回答畫面上有沒有某標題、不能指定欄位，要量某一欄導覽列框線或確認那一欄的標題時，導覽列依框線 (搜尋列測試，改名前的挑法) 或 identifier (`navigationBars.matching(identifier: 客戶名)`) 挑出，屬系統容器查詢、留在測試；`waitForNavigationBarTitle` 只留作等待 (主對話代選)。t9 依此改回，`SearchBarPositions` 加回 `listTitle` 並在搜尋前後比對。
- 驗證：建置成功。主對話以腳本比對型別與方法名，和 5.1 方法對照逐條一致 (另多新增的一條)；Given／When (含呼叫的 private helper) 內的 `XCTAssert`／`failWithDiagnostics` 為 0，主對話逐條人工檢視；`find` 沒有 `*Tests.swift` 殘留，`goTo*` 只在 `RootNavigationRegularColumnsUITests`。iPad Air 11-inch (M4) 跑本資料夾 7 個型別：第一輪 21 通過、5 失敗 (見上)，修正後重跑兩個類別 13 條全數通過，合計 26 條 (4.7 的 24 + 拆分 1 + 新增 1) 皆通過；側邊欄那條提前的 skip 在 iPad 判得出版面並執行。變異檢查：暫時讓 `selectRegularDateChip` 不經水平捲動時，新測試在點膠囊那行失敗 (「找不到或無法點擊 orders.list.dateChip.thisMonth」)，還原後雜湊一致。

### 5.6b Smoke＋Performance

- t16 實作。`AppLockTests` → `AppLockUITests`、`HarnessSelfCheckTests` → `BLUITestConfigurationUITests`、`LaunchSmokeTests` → `RootNavigationLaunchUITests` (冒煙類別，之後的驗證改用新名)，`OrientationLayoutTests` 依裁決 4 拆成 `RootNavigationOrientationUITests` 與 `DashboardOrientationUITests`、`OrdersOrientationUITests`、`InsightsOrientationUITests`，14 → 14 條；`LaunchPerformanceTests` 已符合 kit，檔案未改。新增 `BLUITestConfigurationUITestSupport.assertNoSystemPrompt` (兩處系統彈窗檢查合併，失敗經 `stopWithDiagnostics`) 與 `RootNavigationOrientationUITestSupport.attachScreenshot` (實際被三個型別使用，多收 `XCTestCase` 參數供附件)；韓國團 id 改用 `CampaignSeedFixture.koreaCampaignID`；Orientation 的 4 處 `goTo*` 改用各畫面的 `open(in:)`，`RootNavigationLaunchUITests` 的 6 處屬根導覽受測保留。
- 三個只附截圖的測試補版面斷言 (重掃 H3)：Given 在直向讀出版面 (`rootLayout()` 或 `ordersLayout(in:)`)，Then 比對轉為橫向後的版面相同，另驗內容可達 (總覽營收 KPI 卡的水平範圍在視窗內、訂單有可點的列、分析的類別排行與成本結構可露出)，截圖附件保留。預期值取自直向的版面判定，與既有的 `RootNavigationOrientationUITests` 同一形狀，不是字面值；兩台的直向與橫向版面相同 (iPhone 17 compact、iPad Air regular，見 4.7)，斷言的是轉向後版面不變 (主對話代選，7.1 審查時再看)。
- 表外 (t16 提出，主對話採用)：`RootNavigationLaunchUITests` 第三條在 4.x 後 Then 沒有斷言，補「切回總覽後總覽畫面就緒」；Then 內 `if … failWithDiagnostics` 改 `requireCondition`。`LaunchPerformanceTests` 不補 `continueAfterFailure` (本任務只做排版，主對話代選)。保留：`BLUITestConfigurationUITests` 固定參考時間那條的預期副標由測試內的 `Date.FormatStyle` 組出 (不是 App 的格式化程式，方法對照標為不變)。規則檔兩處舊名 (`AppLockTests`、`OrientationLayoutTests`) 由 6.2 改。
- 驗證：建置成功。主對話以腳本比對型別與方法名，和 5.1 方法對照逐條一致；Given／When (含呼叫的 private helper) 內的 `XCTAssert`／`failWithDiagnostics` 為 0，主對話逐條人工檢視；`find` 沒有 `*Tests.swift` 殘留 (Performance 只有表上的例外 `LaunchPerformanceTests`)。iPhone 17 跑 Smoke 7 個型別 14 條 (4.7 的 14)：13 通過、1 skip (`RootNavigationLaunchUITests` 寬版那條)；iPad 跑四個 Orientation 型別與 `RootNavigationLaunchUITests`，7 條全數通過。變異檢查：`OrdersOrientationUITests` 的預期版面暫改為 `.compact` 時，在 iPad 以「橫向訂單頁的前景欄位版面不符預期 (預期: compact, 實際: regular)」失敗，還原後雜湊一致。

### 5.9a Forms

- t1n 實作。`EditorTextInputFocusUITests` 拆成 `CampaignEditInputFocusUITests` 與 `LookupManagementInputFocusUITests`，`SearchInputFocusUITests` 拆成 `OrdersSearchInputFocusUITests`、`MergeFlowInputFocusUITests`、`OptionPickerInputFocusUITests`，`ToolsInputFocusUITests` 拆成 `FxInputFocusUITests` 與 `SettingsInputFocusUITests`，`OrderEditInputFocusUITests`、`QuoteInputFocusUITests` 保留原名；超額折抵那條依 C2 拆成 A／B，37 → 38 條。Given／When 的前置 (Editor、Quote 19 處與 OrderEdit、Search 的 A1／A2) 改 `requireCondition`，`preparePrincipal`、`prepareSavedCardlessOrder`、`saveAndReopenOrderEdit` 改 `throws(UITestError)` 並回傳非 optional；實付 0 的基準依 A3 移到 Given；裁決 8 的多條件 guard 合成一行。注音鍵與候選字改用 `waitForKeyboardKey`、`tapKeyboardKey`、`tapKeyboardCandidate`，系統缺注音鍵時的 skip 保留；篩選與類別選擇器的搜尋欄改用呈現動作回傳的 Page Object 的 P30、P32；韓國團 id 改用 `CampaignSeedFixture.koreaCampaignID`；`settings.openDefaultCurrency` 改用 S4 的回傳值。焦點測試的 `tapLeftToFocus` 後直接 `typeText` 保留，避免共用輸入 helper 重置游標而測不到游標位置缺陷 (t1n 選擇)。
- 驗證：建置成功。主對話以腳本比對型別與方法名，和 5.1 方法對照逐條一致；Given／When (含呼叫的 private helper) 內的 `XCTAssert`／`failWithDiagnostics` 為 0，主對話逐條人工檢視；`find` 沒有 `*Tests.swift` 殘留 (Performance 只有表上的例外 `LaunchPerformanceTests`)。iPhone 17 跑九個型別 38 條 (4.7 的 37 + 拆分 1) 全數通過。
- 本輪共同：iPhone 一次跑 Smoke 與 Forms 共 52 條，51 通過、0 失敗、1 skip，約 25 分；iPad 一次跑 Regular、四個 Orientation 型別與冒煙類別共 33 條 (見 5.4b)。編譯警告 10 則同基準 (`ScreenProtocol` 9、`XCTestCase+Diagnostics` 1)，測試檔沒有新警告。

### 5.7a Navigation/AdaptiveNavigationContinuityUITests

- t16 實作。依類別對照拆成 `RootNavigationContinuityUITests` 8、`OrdersAdaptiveLayoutUITests` 5、`OrderEditDraftRotationUITests` 1、`CampaignsAdaptiveLayoutUITests` 1、`DashboardAdaptiveLayoutUITests` 2 條 (17 → 17)，原檔刪除，沒有新增 TestSupport；17 個英文句子式名稱改為表上的名稱，旅程每個 When 配自己的 Then。空期望等待兩處改 `Polling.wait` (`waitForSidebarMarkerHidden` 與轉直向後的側邊欄標記穩定取樣；後者丟棄回傳值，3 秒內未穩定時沿用最後讀值，由後面的分頁數斷言判定)；M 18 筆遷移到 5.2、5.3 的方法，N 7、K 6 保留；`goTo*`／`tapRootTab` 只留在 `RootNavigationContinuityUITests` (根導覽受測)；改用 `OrdersScreen`／`CampaignsScreen.open(in:)`、`tapAddOrder()` 後刪掉緊接的 `waitUntilReady` (進入點與呈現動作已等就緒，比照 5.6a)；private helper 改 `throws(UITestError)`；H2 的 skip 移到轉直向後的下一行。跨資料夾舊名：兩則 Note 引用 5.6a 改名前的方法名，改為 `OrdersNavigationUITests` 的新名 (第二則為 t16 另外發現)。
- 驗證：建置成功。主對話以腳本比對型別與方法名，和 5.1 方法對照逐條一致；Given／When (含呼叫的 private helper) 內的 `XCTAssert`／`failWithDiagnostics` 為 0，主對話逐條人工檢視；`find` 沒有 `*Tests.swift` 殘留 (表上例外除外)。iPhone 17 跑五個型別 17 條：8 通過、9 skip (寬版限定)；iPad Air 11-inch (M4) 17 條：15 通過、2 skip (`OrdersAdaptiveLayoutUITests` 的 iPhone 收合版膠囊那條已在 iPhone 通過；並排選取後反覆轉向那條在兩台都 skip，基準的 4.6 iPhone 與 4.7 iPad 也都 skip：要「直向收合、橫向並排」的裝置才會執行，兩台都不是)。

### 5.8 Campaigns＋Customers

- t9 實作。`CampaignFlowTests` 整檔刪除，11 條依表分到 `CampaignsUITests`、`CampaignDetailUITests`、`CampaignEditUITests`、`RootNavigationCampaignLoadFailureUITests`；`CampaignCrudTests` → `CampaignEditUITests` (取消刪除那條移到 `CampaignDetailUITests`)，其餘依表改名；`CustomersTests` 拆出 `RootNavigationCustomerOrdersUITests`。Campaigns 20 → 21 (寫入失敗那條拆 A／B)、Customers 5 → 6 (延遲讀取的重試段拆成獨立測試，等待改用 `delayedReadFailureTimeout`)。韓國團 id 三份本地常數改用 `CampaignSeedFixture.koreaCampaignID`；新增開團改用 S1 `tapAdd()` 的回傳值；開詳情改 `openDetail(campaignID:)`；根導覽目的地改用 Q4 `destinationContainer`；客戶頁改 `CustomersScreen.open(in:)` 與 Q5 至 Q8；取消刪除與取消結團的確認框訊息比對留在 Given，改為 `requireCondition` 前置；裁決 7 的尾端取消刪除刪除。
- 主對話修正：`CampaignEditDateRowUITests` 的提醒列測試名與表不符 (`testToggleReminder_開啟_出現提醒時間列`)，改回表上的 `testToggleReminder_開啟訂購提醒_出現提醒時間列`。
- 驗證：建置成功。主對話以腳本比對型別與方法名，和 5.1 方法對照逐條一致；Given／When (含呼叫的 private helper) 內的 `XCTAssert`／`failWithDiagnostics` 為 0，主對話逐條人工檢視；`find` 沒有 `*Tests.swift` 殘留 (表上例外除外)。iPhone 17 跑兩個資料夾 9 個型別 27 條 (4.7 的 20、5 加拆分各 1)：26 通過、1 skip；iPad 跑 `CampaignsUITests` 3 條：2 通過、1 skip。收合版返回後轉橫向那條在兩台都 skip，基準的 4.6 iPhone 與 4.7 iPad 也都 skip (同 5.7a 的原因)。

### 5.9b Tools

- t1n 實作。五檔依表改名 (`CurrencyPickerTests` → `OptionPickerCurrencyUITests`、`ToolLoadTabSwitchTests` → `RootNavigationToolLoadUITests`，其餘加 `UI`)，36 → 36 條。幣別選擇器的四個入口改用進入點與 S2 至 S4 的回傳值，KRW 列出現與消失改用 Q15、Q16；`RootNavigationToolLoadUITests` 的兩條旅程保留 (裁決 6)，Given／When／Then 標記與重試動作移回測試本體，`fileprivate` 拿掉，`ToolLoadElements` 改為 private 的診斷參數並改呼叫 Q21 至 Q26，`Timing.readDelay` 與寫死的逾時刪除，改用 `options.delayedReadFailureTimeout`。每條旅程新增初次讀取與重試各一個 `XCTAssertGreaterThanOrEqual`：起點分別在呼叫工具頁進入點之前、點重試鍵之前，下限讀同一個 `options.readDelaySeconds`。
- 驗證：建置成功。主對話以腳本比對型別與方法名，和 5.1 方法對照逐條一致；Given／When (含呼叫的 private helper) 內的 `XCTAssert`／`failWithDiagnostics` 為 0，主對話逐條人工檢視；`find` 沒有 `*Tests.swift` 殘留 (表上例外除外)。iPhone 17 跑五個型別 36 條全數通過。變異檢查：`LaunchOptions.readDelaySeconds` 暫改 12 時兩條仍通過；同時讓 App 端忽略參數、固定延遲 2 秒時兩條都在初次讀取的下限斷言失敗 (實測間隔 9.96 秒、10.27 秒，小於 12)；還原後雜湊一致。初次讀取量到的間隔包含切分頁往返約 8 秒，所以 App 端固定 2 秒時，初次讀取的下限只有在延遲參數大於這段時間 (例如 12) 時才會失敗；重試段從點重試鍵前計時、沒有往返，預設 8 秒就分辨得出 (7.1 補測：預設 8 秒加 App 固定 2 秒，兩條都只在重試段的下限斷言失敗，間隔 3.69 秒、3.58 秒，各 1 筆失敗；還原後雜湊一致)。
- 本輪共同：iPhone 一次跑三個任務與冒煙類別共 83 條，72 通過、0 失敗、11 skip，約 33 分；iPad 23 條，20 通過、0 失敗、3 skip，約 16 分。

### 5.7b Navigation 其餘 4 檔

- t16 實作。`LoadFailureReloadLoopTests` 拆成 `RootNavigationLoadFailureUITests` 3 條與 `AppLockLoadFailureUITests` 2 條；`NavigationScenarioUITests` 拆成 `RootNavigationScenarioUITests` 2、`OrdersSelectionUITests` 2、`SettingsLanguageUITests` 1 條 (`XCTExpectFailure` 嚴格模式那條保留)；`ReadableWidthUITests` 改名 `RootNavigationReadableWidthUITests` 並依表拆成商品類別與設定兩條，尾端轉回直向依裁決 7 刪除，B 改為自行啟動後開設定；`AdaptiveLayoutCheckCounterexampleTests` 維持原名與方法名。16 → 17 條，連同 5.7a 的 17，Navigation 33 → 34。空期望等待改 `Polling.wait`，固定觀察窗改 `Polling.pause(for:)` 並在呼叫點寫理由；`goTo*`／`selectTab` 只留在根導覽受測的三個型別 (共 13 處，與表一致)。
- 延遲讀取的等待改用 `LaunchOptions` 推導的逾時：首次出現原本寫死的 10、7、5 秒改為 `options.delayedReadFailureTimeout` (預設 15 秒)，上限比原值寬；依 design「由它推導的逾時…共用，不各自加餘裕」採用 (t16 提出，主對話代選)。
- 驗證：建置成功。主對話以腳本比對型別與方法名，Navigation 34 條和 5.1 方法對照逐條一致；Given／When (含呼叫的 private helper) 內的 `XCTAssert`／`failWithDiagnostics` 為 0，主對話逐條人工檢視；`find` 整個 `Tests/` 只剩表上的兩個例外 (`AdaptiveLayoutCheckCounterexampleTests`、`LaunchPerformanceTests`)。iPad Air 11-inch (M4) 跑 7 個型別加冒煙類別 19 條：16 通過、0 失敗、1 預期失敗、2 skip (收合版限定)；iPhone 17 同一組 19 條：15 通過、0 失敗、1 預期失敗、3 skip (寬版限定)，每條至少在一台通過。裁決 D5：`SettingsLanguageUITests` 先 `SettingsScreen.open(in:)` 再判斷「更多」版面，iPad 判為並排並依預期 skip (與 4.7 的 iPad 相同)，iPhone 判為收合並通過，不需改回 `goToMore`。

### 6.1 UI 測試規範掃描守門

- t8 實作。新增 `BuyLedgerTests/Guards/UITestConvention/` 三檔 (`UITestConventionScanner`、`UITestConventionScanTests`、`UITestConventionScenarios`)，以 `SwiftSourceFiles` 列舉 `TestPaths.iosRoot` 下的 `BuyLedgerUITests`，逐行經 `SwiftSourceStripping` 去掉註解與字串後比對：
  - 檔名：`Tests/` 下的 `.swift` 只能以 `UITests.swift` 或 `TestSupport.swift` 結尾；例外 `LaunchPerformanceTests.swift` (kit 的效能測試命名) 與 `AdaptiveLayoutCheckCounterexampleTests.swift` (不啟動 App 的純值自我檢查)。
  - 可丟棄的 Bool：整個 UI target 以 `@discardableResult\b[^{]*->\s*Bool\s*\{` 比對到左大括號為止的整個宣告，回報 `@discardableResult` 所在行。
  - 不丟錯的失敗出口：`Support/`、`Screens/` 與 `Tests/**/*TestSupport.swift` 中，兩個 Diagnostics 檔以外以 `\bfailWithDiagnostics\s*\(|\bXCTFail\s*\(|\bXCTAssert\w*` 逐行比對。
  - 三條都回報「相對路徑:行號」，並斷言掃到的檔數大於 0；另有 18 條以字串樣本驗證掃描器本身的參數化案例 (spec 的 4 個情境與反例：回傳 Page Object 的 `@discardableResult`、註解與字串內的樣式、診斷檔、一般測試檔的 `XCTAssert`)。
- 主對話修正：第一次執行時自我測試「Page Object 呼叫非拋錯出口被拒」失敗，`app.failWithDiagnostics(` 沒有命中。Swift Regex 的 `\b` 預設是 Unicode 字詞邊界，「字母.字母」之間不斷開，帶接收者的呼叫 (Support 與 Page Object 的實際寫法) 全都會漏判；正式掃描當時通過只是因為現況本來就沒有違規。兩個樣式改加 `.wordBoundaryKind(.simple)`，並在樣式上方註明理由。
- 驗證：建置成功；iPhone 17 跑 `UITestConventionScanTests` 4 個測試 (3 條正式掃描 0 違規、18 條案例) 全數通過。變異檢查一次放入四個探針：`Tests/ProbeTests.swift` (空檔)、`Support/XCUIApplication+Scrolling.swift` 多行簽章的 `waitUntilHittableByScrolling` 前加回 `@discardableResult`、`OrdersScreen.tapRetry` 內加 `app.failWithDiagnostics("probe")`、`OrdersUITestSupport.assertTrigger` 內加 `XCTFail("probe")`；三條正式掃描各只列出自己的探針 (`Tests/ProbeTests.swift:1`、`Support/XCUIApplication+Scrolling.swift:42`、`Screens/Orders/OrdersScreen.swift:120` 與 `Tests/Orders/Filters/OrdersUITestSupport.swift:35`)，自我測試仍通過；刪除探針、還原後雜湊一致。本輪 5 則編譯警告都在本 change 未改的 `OrdersViewLayoutTests`、`ColorContrast`。

### 6.2 規則檔與文件

- t8 實作。`.claude/rules/ios-ui-tests.md` 依現行程式改寫：受控例外分「會操作」與「只讀量測」兩類並逐項列出 helper，查系統容器與量框線明列為可留在測試檔；版面判定改為 `rootLayout()`／`ordersLayout(in:)`／`moreLayout(in:)`；`AppNavigator` 退回條件與 `[BLUITest] root tab fallback used` 標記；sheet 層數改用 `presentedSheetCount`／`presentedRootCount`；新增「失敗與停止」(停止訊號、唯一丟錯出口、備援寫法、`BLUITestCase` 限定、預期失敗區塊、`Polling.wait` closure 不丟錯、`wait*` 回傳 `Bool` 不可丟棄、`LaunchPerformanceTests` 啟動例外)、「進入畫面與 helper 放置」、「命名與測試結構」、「預期值」與「常駐掃描守門」各節；改名類別的引用改為新名。`ios-unit-tests.md` 守門改為四條並寫明 `Store` 掃描樣式與人工複核的情況；`ios-navigation.md`、`ios-design-system.md`、三個 snapshot 測試的註解改用新類別名；`apps/ios/CLAUDE.md` 的 kit 差異補 `BLUITestCase.launch(_:)`、`wait*` 回傳 `Bool` 的解讀與旅程測試多組 When／Then；`apps/ios/README.md` 補 `-BLUITestReadDelaySeconds` 旗標與 `Guards/UITestConvention`。
- 主對話審閱修正：`ios-ui-tests.md` 的類別命名把遷移說法「`SmokeTests` 改為 `UITests`」改成現行規則「不用 `SmokeTests` 後綴」；方法名 `<Member>` 的取序補齊 5.1 的 K4、K5 (view Action、`AlertState` Action、binding 不算 Action、Page Object 方法、Support 方法、無 action 的 alert 按鈕取 `tapAlertButton`、旅程取重複的 Action 或 State 屬性)，原範例 `testOrderRowTapped_` 在程式中不存在，改用實際存在的名稱。
- 待 7.1 判定 (t8 回報)：design「規則與程式矛盾以 spec 為準修正」要求以位置或 label 定位的例外收在共用 helper，現況仍有兩處在 Page Object (`OrderFilterSheetScreen.sheetGrabber`、`InsightsScreen` 以 `segmentedControls.buttons.element(boundBy:)` 依序選取期間)，規則檔照現況寫明位置。
- 驗證：以 5.1 類別對照的 55 個舊類別名 `grep -rnw` 掃 `.claude/rules`、`apps/ios/CLAUDE.md`、`apps/ios/README.md` 與 `apps/ios/**/*.swift` (排除單元測試 `BuyLedgerTests/Core/Domain/OrderMergeTests.swift`)，只剩 `UITestConventionScenarios.swift` 三處：spec 指定的「舊後綴檔名被拒」樣本字串，不是類別引用 (主對話代選接受為例外)。design 所列已搬移或改名的 helper 舊名 (`rootLayout` 屬性、`goToOrders()`、`isRegularLayout` 等四個版面述詞、`OrdersScreen.revealElement`／`waitUntilFrameStable`／`typeSearchText`／`hittableSearchField`、`tapAlertButton(identifier:)`、`app.sheets.count`、`LaunchSmokeTests`) 在規則檔與兩份平台文件為 0；`ios-ui-tests.md` 反引號內的識別字以腳本對照程式碼全數存在 (工具名與系統符號除外)；新增文字沒有事件經過、日期或沿革。snapshot 三檔只改註解，`swiftc -parse` 通過。

### 7.1 審查

- 審查者：t17 (opus-xhigh-reviewer) 唯讀審查正確性並逐檔逐條做 style 閘門 (166 個 Swift 檔與 6 份文件，G1 至 G13 與 kit 鐵則 X1 至 X3，附逐檔清單)；t1p (fable-arch-reviewer) 唯讀審查架構。兩者審查前後 `git status` 與雜湊相同。主對話同時審查並合併取捨，以下取捨皆為主對話代選。
- 結果：t17 必修 9 (正確性與契約 4、style 5 群組 57 處)、建議 7、觀察 6，166 檔中 132 檔全條通過；t1p 必修 6、建議 8、觀察 7，架構不需重做。
- 採用並修正 (t9 改 Support 與 Screens、t8 改規則檔與 App 的 MARK、t1n 改 Tests；主對話審查各自的 diff)：
  - 契約：述詞內含捲動的 `PaymentMethodEditorScreen.isCashOnDeliveryOn`、`CampaignDetailScreen.isUnpaidOnlyEnabled` 拆成 `reveal…Toggle(file:line:) throws(UITestError)` 與只讀屬性，呼叫端在 Given／When 先露出；`InsightsScreen.revealCostDonut`、`revealFirstCategoryRank` 由回傳 `Bool` 改為會失敗的露出動作，轉向測試的露出移到 When；design 點名的 `isSettleConfirmationPresented`、`isConfirmationDismissed` 改為 `waitForSettleConfirmation`、`waitForConfirmationDismissal`，`AppNavigator.isSidebarLayout` 改為回傳列舉的 `rootPresentationMode(file:line:)`。
  - 等待型述詞與狀態讀取：5.1 定下的 `has…(timeout:)` 與 `is…(file:line:) throws` 保留，規則檔的契約改寫成五種形狀 (見 Decisions「wait helper 保留 Bool 並禁止丟棄結果」的補記)。
  - 各收成一處：`CampaignDetailScreen.tapBack` 改呼叫 `tapBackButton(inNavigationBarContaining:)`，`OptionPickerScreen.tapBack` 改用 `tapUniqueNativeBackButton`；`RootNavigationScreen` 的「更多」前景判斷改讀 `MoreDestinationIdentifiers` 的 `foreground` 與 `rowPrefixes`。
  - 以文字定位的地方收進共用 helper：`assertAlertMessage(contains:timeout:)` 改為在逾時內輪詢「目前 alert 含該文字的 staticText」，確認框收回期間不會比對到舊 alert；`CampaignDetailUITests` 三處內聯的 alert 訊息比對、`LookupManagementUITests` 以「知道了」按鈕判斷失敗提示的兩處 (5.10 的例外) 與以 `alertPresented()` 當「操作失敗提示已出現」的前置，都改用它；`OrdersSelectionUITests` 以文字查已選筆數改用新增的只讀 `staticTextCount`、`navigationBarTextCount`。
  - 失敗位置：`assertOrdersLayoutIsRecognized`、`assertSingleEditSheet` (改用 `presentedRootCount`)、`requireDistributionRowsBeforeFilter` 補 `file:line:` 與 `throws(UITestError)`；`requireDetailShows` 改為唯一使用者 `OrdersAdaptiveLayoutUITests` 的 private 成員。
  - 無呼叫端刪除：`scrollToHittableGently`、`scrollToFullyVisibleGently`、`OrdersScreen.displayedOrderID()`。
  - 其他：Dashboard 重試後 Then 的捲動改為 `XCTAssertTrue(waitUntilHittableByScrolling…)` 並恢復專屬訊息；搜尋列測試的輪詢 closure 改為 typed `do`／`catch`；private helper 改 typed throws；`paymentMethodClassification(named:)` 先查列是否存在；`DependencyValues+BLUITestOverrides` 的 MARK 改回功能名 (本 change 曾改成六區名，違反外部型別依功能分區)；三個 Orientation 測試與規則檔「轉向測試」寫明「轉向前後版面不變」只適用直向與橫向同版面的測試裝置。
  - 文件：規則檔總則與 design「規則與程式矛盾以 spec 為準修正」補「或單一 Page Object」(spec 原文)；導覽列一節補「量某一欄導覽列框線時以框線或 identifier 挑出屬系統容器查詢」(5.4b 的裁決)；只讀量測清單補新 helper；`scrollToHittableGently` 的引用改指 `waitUntilHittableByGentleDrag`。
  - style：行寬 20 處、MARK 區名與順序 19 處 (13 檔 `ScreenProtocol` 區名、自創區名、順序)、閉括號前空行 7 處、doc 缺 Parameter／Returns／Throws 10 處、Given／When／Then 空行 1 處，全數修正。
  - 主對話修正：拆出的只讀屬性 `isCashOnDeliveryOn`、`isUnpaidOnlyEnabled` 讀值前補查元素是否存在，不存在回傳 `false`，符合「純查詢不失敗」。
  - 延遲下限的偵測力 (t17 O1、t1p 建議 5)：主對話以預設 8 秒加 App 端固定延遲 2 秒實測 `RootNavigationToolLoadUITests`，兩條旅程都只在重試段的下限斷言失敗 (間隔 3.69 秒、3.58 秒，各 1 筆失敗)，初次讀取段通過；據此改寫 5.9b 那句紀錄，不另加 12 秒的斷言。還原後雜湊一致。
- 不採用 (理由)：前景就緒元素組與「更多」工具進入流程的收斂 (t1p 建議 1、2) 屬內部整理、對外形狀已一致，排在本 change 之後；`BLUITestCase` 繼承掃描 (t1p 建議 3) 目前 74 個類別都符合，先以規則檔約束；`LookupItemRow` 旗標對照兩份 (t1p 建議 4) 為相鄰兩處，改 App 需重驗 snapshot，記為觀察；`OrderPercentConversionTests` 的 `TestStore` (t1p 建議 7) 依 design 一律改 `TestStore` 而保留；分段控制項位置退回的自我確認 (t1p 建議 8、t17 O3) 屬 Non-Goals 的對照表範圍。
- 記錄的觀察：驗收 grep「`hasKeyboardFocus` 述詞字面值與 `isFinite` 只在定義檔」字面不成立，例外為 `XCUIElement+FocusTap.swift` 對 snapshot 求值的述詞 (HEAD 既有) 與 `XCUIApplication+Reveal.swift` 的純量參數檢查 (t17 O2)；`@discardableResult` 掃描樣式遇到沒有本體的宣告或參數預設值含 closure 時可能誤報或漏判，現況兩種寫法都沒有 (t17 O6)；TestSupport 同資料夾第二個的命名、`requireCondition` 的三種寫法、`OrdersScreen.navigationBarTitle` 實為存在判斷等 (t1p 觀察)。
- 驗證：iPhone 17 iOS 26.5 跑完整 UI 回歸 (`-only-testing:BuyLedgerUITests`、`-skip-testing:BuyLedgerUITests/LaunchPerformanceTests`)：75 類別 263 條，210 通過、0 失敗、52 skip (皆為寬版限定)、1 預期失敗 (`RootNavigationScenarioUITests` 的 `XCTExpectFailure` 嚴格模式)，約 100 分鐘 (6,024 秒)；263 條等於原始碼的 264 條扣掉效能測試 1 條。編譯沒有警告，執行期警告 45 則全是「Invalid frame dimension (negative or non-finite)」。iPad Air 11-inch (M4) iPadOS 27.0 跑 iPhone 上有 skip 的 19 個類別、四個 Orientation 類別、`SettingsLanguageUITests`，以及用到這輪改過的畫面或返回鍵的 8 個類別 (`CampaignDetailUITests`、`CampaignEditUITests`、`LookupManagementUITests`、`OptionPickerCurrencyUITests`、`OrderDetailMoreMenuUITests`、`OrderDetailUITests`、`OrderEditAddOptionUITests`、`OrderEditCreateUITests`)，共 32 類別 140 條：132 通過、0 失敗、8 skip，約 80 分鐘。兩台都 skip 的只有 `CampaignsUITests` 收合版返回後轉橫向與 `OrdersAdaptiveLayoutUITests` 並排選取後反覆轉向兩條 (同 5.7a、5.7b，基準也 skip)，其餘每條至少在一台通過。

### 8.1 搜尋檢查與變異

- 主對話執行。搜尋檢查 (範圍 `apps/ios/BuyLedgerUITests`)：
  - `grep -rn 'requireCondition('`：517 行，條件含 `try` 的只有版面判定 (`ordersLayout(in:)`、`moreLayout(in:)`) 與群組值讀取 (`pickerGroupValue`、`filterGroupValue`)，包住會自行失敗的動作或進入點 0 處；動作回傳 `Void` 或 Page Object，編譯器本來就不讓它們當 `Bool` 條件。
  - `find Tests -name '*Tests.swift' ! -name '*UITests.swift'`：只有 `AdaptiveLayoutCheckCounterexampleTests.swift`、`LaunchPerformanceTests.swift`。
  - `pollUntil`、`RunLoop.current.run` 0 處；`XCTestExpectation()` 只在 `Support/Polling.swift`；`ValueParsing.swift`、`XCUIElement+ValueParsing.swift` 不存在；`UIAssertionError`、`InteractionError`、`NativeBackButtonError` 0 處。
  - `static func open(` 九個畫面各一個 (Campaigns、Customers、Dashboard、Fx、Insights、LookupManagement、Orders、Quote、Settings)；`static func open(from:`、`static func navigate(in:` 0 處。
  - `\.goTo[A-Z]|selectTab\(` 在 `Tests/` 只出現在 9 個 `RootNavigation*` 類別 (5.1 標為根導覽受測)。
  - `\bcatch\b|try\?`：預期失敗那一處 (`RootNavigationScenarioUITests`)、三處 `snapshot()`，另有 `OrdersRegularSearchBarUITests` 輪詢 closure 的 typed `catch`：記下錯誤後在輪詢結束時原樣丟出，不吞掉失敗 (7.1 改的)。
  - `hasKeyboardFocus` 述詞字面值與 `isFinite`：除定義檔 (`XCUIElement+TextInput.swift`、`CGRect+Validity.swift`) 外，只有 7.1 記的兩個例外 (`XCUIElement+FocusTap.swift` 對 snapshot 求值的述詞、`XCUIApplication+Reveal.swift` 的純量參數檢查)。
  - `grep -rn 'BLAccessibilityID\.' Tests`：98 行，逐條對照 5.1 盤點：沒有 Page Object 的「更多」入口清單、更多詳情提示與選取標記 15 行；傳給 `assertEmptyState`、`assertLoadStateStaysStable`、`tapAlertButton(_:)`、`tapMenuItem(_:label:)` 的參數，`framesInSingleSnapshot` 結果的鍵，純值檢查型別的值，根側邊欄，KPI 與 SummaryTile 的型別標註共 83 行。= 5.1 的 N 15、K 81，加上遷移後改傳 `assertEmptyState` 的 2 行。
  - 無呼叫端重掃：先以名稱比對 `Support/`、`Screens/` 的宣告 (去掉註解後，整個 UI target 出現次數不多於宣告次數即列出)，只有 `LaunchOptions.CalendarAccess.denied` (design「刪除無呼叫端 helper」記為保留的例外)。陽性對照：同一比對在 7.1 修正前的程式上列出 7.1 處理的 `scrollToHittableGently`、`scrollToFullyVisibleGently`、`MoreDestinationIdentifiers.rowPrefixes`、`tapBackButton`，但漏掉 `OrdersScreen.displayedOrderID` (`OrderDetailScreen` 有同名成員)。因此對不同型別同名的 40 個名稱、97 個成員各加一個帶唯一訊息的 `@available(*, deprecated)` 後建置，依呼叫處的警告判斷：96 個有警告；`OrdersScreen.categoryGrid` 沒有，它只被同檔加了標記的 `filterCategoryCell`、`revealFilterCategory` 呼叫 (deprecated 成員內呼叫不出警告)，實有呼叫端。結果：無呼叫端 0 個 (保留的例外除外)。
- 變異 (iPhone 17)：`CustomersScreen.open(in:)` 等待的目的地 identifier `Customers.listEmptyState` 暫改為不存在的值，跑 `CustomersUITests`：`testTask_空資料_顯示空狀態` 在 `CustomersUITests.swift:22` (呼叫進入點那行) 以「客戶清單前景內容未就緒」失敗，xcresult 只有 1 筆失敗。與上一項的 deprecated 標記同一次建置。還原後 UI target 全部 143 檔雜湊與暫改前一致。
- 結論：spec「Failures are never masked」(失敗停在呼叫那行、只記一筆) 與「Page object contract」(進入點與動作的形狀、無呼叫端 helper) 成立。

### 8.2 完整單元回歸

- 主對話執行。iPhone 17 iOS 26.5 外觀鎖淺色後跑完整 `BuyLedgerTests`：2,085 條，2,082 通過、0 失敗、3 條預期失敗 (`ServiceTestValueStrictnessTests` 以 `withKnownIssue` 驗證未覆寫的服務會回報未實作，該檔與 `main` 相同)，約 4 分鐘。跑完後工作樹雜湊與跑前一致，snapshot 沒有重錄。編譯警告 5 則都在本 change 沒改的檔案 (`OrdersViewLayoutTests` 的 main actor 呼叫 3 則、`ColorContrast` 的 trait 設定 2 則)。

### 8.3 最終兩平台回歸

- 主對話執行，兩台跑前外觀鎖淺色。iPad 先單獨跑 `OrderEditKeyboardDismissUITests` (`KeyboardDismissTests` 改名後) 2 條通過，約 230 秒 (4.7 為 222 秒)。
- iPad Air 11-inch (M4) iPadOS 27.0 完整 UI 回歸 (`-only-testing:BuyLedgerUITests`、`-skip-testing:BuyLedgerUITests/LaunchPerformanceTests`)：75 類別 263 條，236 通過、2 失敗、24 skip、1 預期失敗，8,429 秒 (約 140 分鐘)。兩條在 4.7 的 iPad 都通過，單獨重跑仍失敗，不是執行順序造成：
  - `OrderEditInputFocusUITests.testFocusChargedAmountFromLeft_零值輸入_即時取代且失焦保留` 停在「找不到客戶名稱欄位，無法準備聚焦測試」。Given 已把表單捲到實付欄，When 呼叫的 `focusChargedAmountFromLeft` 會先收客戶鍵盤、等客戶欄 5 秒，客戶欄在 iPad 已不在可及性樹。原因是本 change 依命名表把這條的 When 由 `tapLeftToFocus` 改成 `focusChargedAmountFromLeft` (為了名實一致)；7.1 只在 iPhone 跑過這個類別。抹除模擬器後重跑仍失敗。主對話代選修正：When 改回 `try edit.chargedAmountField.tapLeftToFocus(in: app)`，與改動前及同前綴的「已有折抵時提高實付」、「已有折抵時輸入再刪空」兩條一致；`focusChargedAmountFromLeft` 仍由沒有先捲動的兩條測試呼叫。命名表該列的「改呼叫 focusChargedAmountFromLeft」以本條為準。8.3 規定先回報再處理，這次是回報時同步修正。
  - `CampaignDetailUITests.testUnpaidOnlyToggled_開啟_隱藏已收款客戶列` 停在「未收款開關值未變成開啟」：點下值為 0 的內層開關後 10 秒內值都沒變。原始碼與 7.1 在 iPad 通過時雜湊相同，日期是注入的固定值；`erase --shutdown-first`、boot、鎖淺色後單獨重跑通過，判定為模擬器環境，不改程式。
  - 抹除後先跑 `OrderEditKeyboardDismissUITests` 2 條通過，再跑修正後的 `OrderEditInputFocusUITests` 與 `CampaignDetailUITests`：24 條 (16＋8)，23 通過、0 失敗、1 skip (`testDetailSelectionChanged_返回後再進入_保留未收款篩選` 只在收合版執行，4.7 也 skip)，1,504 秒。
  - 使用者選擇接受上述類別重跑，不再重跑 iPad 完整回歸。
- 修正後 iPhone 17 iOS 26.5 先跑 `UITestConventionScanTests` 4 條通過，再跑完整 UI 回歸：75 類別 263 條，210 通過、0 失敗、52 skip (皆為寬版限定)、1 預期失敗 (`RootNavigationScenarioUITests` 的 `XCTExpectFailure` 嚴格模式)，6,288 秒 (約 105 分鐘)。
- 測試數：兩台的類別與每類條數相同，每類條數等於原始碼的 `func test` 數。各資料夾為 Campaigns 21、Customers 6、Dashboard 4、Forms 38、Insights 6、More 19、Navigation 34、Orders 16、Orders/Detail 9、Orders/Edit 14、Orders/Filters 20、Orders/Regular 26、Smoke 14、Tools 36。依舊類別對新類別逐一對照 4.7 (58 類別 252 條)：252 ＋ 拆分 10 ＋ 5.4b 新增 1 − 刪除 0 ＝ 263，條數有變的只有 Implementation Contract 列出的拆分與新增所在類別，以及 `CampaignFlowTests` 的 11 條移入 Campaigns 各類別 (含拆分共 12 條)。
- 兩台都 skip 的只有 `CampaignsUITests` 收合版返回後轉橫向與 `OrdersAdaptiveLayoutUITests` 並排選取後反覆轉向兩條 (同 7.1)，預期失敗那條兩台都是預期失敗，其餘每條至少在一台通過。
- `AppNavigator` 退回標記 (Build Logs)：iPad 完整回歸與之後的重跑都是 0 次；iPhone 14 次，分在 14 條測試、各 1 次，都是啟動後約 4 秒第一次點根分頁時，五個根分頁還查不到 identifier、分頁列恰有 5 個按鈕，依順序點到的按鈕標籤與目標分頁一致。7.1 的 iPhone 完整回歸同一標記 3 次，次數隨啟動時序變動。兩台不是都 0 次，不把「移除退回與 spec 情境」記到 roadmap。
- 執行期警告 iPad 44 則、iPhone 45 則，全是「Invalid frame dimension (negative or non-finite)」；編譯沒有警告。
- `snapshot-ui` (iPhone 17，iPhone 回歸建置的 App，`-BLUITest`、`-BLUITestSeed lookupsOnly`、`-BLUITestDefaultCurrency JPY`)：
  - 新增訂單的幣別列 `orderEdit.currencyRow`：label「幣別、日圓」，value「JPY」。
  - 付款方式管理列：信用卡、Apple Pay、LINE Pay 只有 label (名稱)、沒有 value；銀行轉帳 label「銀行轉帳」、value「銀行匯款」；貨到付款與無卡兩列 value 為分類名，label 為空字串。以 `axe describe-ui` 讀原始可及性樹，這兩列的 `AXLabel` 確實是空字串，不是 snapshot 工具省略；只出現在名稱與分類同字的列，原因未查。UI 測試以 identifier 定位列、讀 `value` 取分類，不受影響。記為觀察，不在本 change 處理。
- 每次跑完都比對工作樹雜湊：iPad 完整回歸前後一致；修正後到 iPhone 回歸與 `snapshot-ui` 結束只差 `OrderEditInputFocusUITests.swift` 這一個檔。期間另一個 change 的 session 暫用 iPhone 模擬器 (時段錯開，沒有同時跑測試)，並在主目錄暫放過其 change 目錄約 1 分鐘、已刪除，不屬於本 change。

### verify／review 後的修正

- `/spectra-verify` 0 嚴重、6 警告，`/spectra-review` 0 嚴重、2 警告、5 建議，主對話逐項讀程式確認。使用者選擇修正違反本 change 規則的 7 項，並補兩個單元層級的測試；UI 失敗路徑的自我測試 (verify 警告 5) 與重構類建議 (Page Object 自寫的捲動迴圈、等鍵盤穩定的迴圈、付款方式分類對照、訂單頁重試情境、未存變更 sheet helper) 不在本 change 處理。
- 實作：t16 (總覽、開團詳情、分析頁)、t9 (選擇器、AI 總結、導覽列與搜尋欄 helper、篩選 sheet、啟動參數)、t1n (App 延遲旗標警告、Store 掃描自我測試)、t8 (規則檔)。以下名稱與做法為主對話代選：
  - 開新畫面的動作回傳 Page Object：`DashboardScreen.tapCreateFirstOrder` 回傳 `OrderEditScreen`；新增 `OptionPickerScreen.tapAddPaymentMethod` (回傳 `PaymentMethodEditorScreen`) 與 `OrdersScreen.openAISummary` (回傳 `AISummaryScreen`)，`tapAdd`、`tapAISummary` 保留給以 alert 結束的情境。
  - 導覽列標題與搜尋欄：新增 `isNavigationBarTitleVisible(_:)` (以導覽列內 label 相符且可互動的 staticText 判定，不看導覽列 identifier)、`visibleNavigationBarTitle(of:)`、`firstHittableSearchField`；`OrdersUITests`、`OrdersRegularSearchBarUITests` 改用它們，`Tests/` 已無直接的導覽列標題與 `searchFields` 查詢。
  - 會捲動的述詞拆成露出動作與唯讀查詢：新增 `CampaignDetailScreen.revealDistributionRow`、`revealReceivedAmount`、`DashboardScreen.revealOngoingCampaign`、`revealRecentOrder`；`hasDistributionRow` 改純查詢，`hasOngoingCampaign`、`waitForUnpaidOnlyEnabled`、`waitForReceivedAmount` 改為不捲動的等待型述詞。捲動都移到 Given 或 When，包含 7.1 留在 Then 的總覽那處 (依規則檔「Then 不夾帶動作」)。`requireDistributionRowsBeforeFilter` 移成 `CampaignDetailScreen.revealDistributionRowsBeforeFilter`，`Support/XCTestCase+CampaignFlow.swift` 因此刪除。`InsightsUITests` 營收歸屬那條的 5 個讀值由 Then 移到 When。
  - `InsightsScreen.selectRange` 依位置點分段前比對分段數、點後等該分段變成選取態，不成立時 `stopWithDiagnostics`；`isRangeSelected` 分段數不符時回傳 `false`。
  - `-BLUITestReadDelaySeconds` 缺值或後接旗標時只印「後面沒有接秒數，不套用讀取延遲」，不再印共用解析的「改用預設值」。
  - `OrderFilterSheetUITests` 11 處與 `OrderFilterSheetLargeUITests` 1 處改用 `openFilterSheet()` 的回傳值，並移除它的 `@discardableResult`。
  - 8.1 紀錄的「8 個 `RootNavigation*` 類別」更正為 9 個。
  - `TestSuiteIntegrityTests` 抽出純函式 `storeConstructionFindings(in:relativePath:excludingPrefix:)` 與 `storeScanFailures(fileCount:findings:)`，新增 7 個樣本的參數化測試與「沒有可掃描的檔案時回報失敗」一條。樣本放 `Guards/StoreConstructionSamples.swift`，左括號以 `\u{28}` 表示，避免正式掃描命中樣本檔。
  - `BLUITestConfigurationUITests` 新增三條不啟動 App 的 `launchArguments` 純值測試 (訂單延遲預設 8 秒、匯率延遲 12 秒、沒有讀取失敗時不帶秒數旗標)；UI 測試總數由 263 條變為 266 條 (Smoke 由 14 條變為 17 條)。
  - `.claude/rules/ios-ui-tests.md` 補上述 helper、導覽列標題的判定方式，以及動作可能呈現 alert 或畫面時依結果拆成兩個動作。
- 審查：t17 唯讀審查並逐檔做 style 閘門 (23 檔)。正確性沒有必修；style 必修 8 項 19 處 (doc 段落順序、Private Method 區排序、自創 MARK、未達條件卻斷行 10 處、超過三個引數未斷行、GWT 空行)，建議 3、觀察 10。主對話採用全部必修、3 項建議與觀察 O1、O4、O5、O6、O8 (O8 與上面的述詞拆分是同一條規則)；O7 所在的檔本輪沒改，不順手重排。實作者修正後 t17 複審，15 項全部通過、沒有新違規。主對話另修一處 `swiftc -parse` 抓不到的編譯錯誤 (`contains(\.isHittableOnScreen)` 少 `where:`)。
- 驗證：
  - iPhone 17：`TestSuiteIntegrityTests`、`UITestConventionScanTests`、`BLUITestConfigurationTests`、`BLUITestConfigurationInvalidValuesTests` 38 條通過 (含新增的 7 個樣本與空掃描)。受影響的 14 個 UI 類別共 65 條，62 條通過或 skip；`RootNavigationContinuityUITests` 3 條轉向測試以「轉向後 App 視窗寬仍未大於高」失敗。這 3 條本輪沒改、8.3 通過，抹除模擬器後重跑該類別 0 失敗，每條結果與 8.3 相同，判定為模擬器轉向失效。
  - iPad Air 11-inch (M4)：先跑 `OrderEditKeyboardDismissUITests` 2 條通過，再跑同一組 14 個類別 65 條：48 通過、16 skip、1 失敗。失敗的是 `CampaignDetailUITests.testUnpaidOnlyToggled_開啟_隱藏已收款客戶列`，點下開關後值 10 秒內沒變，與 8.3 iPad 完整回歸那次相同。單獨重跑通過、整個類別重跑仍失敗；抹除模擬器後整個類別 7 通過、1 skip，鍵盤前提類別也通過 (抹除後第一次跑有 1 條 UI 查詢逾時，重跑通過)。點開關的程式本輪沒改，判定為 iPad 模擬器長時間執行後的環境狀態，記為觀察。
  - 編譯：完整重編時出現 10 則 main actor 隔離警告，位置在 `Screens/ScreenProtocol.swift` 的 Computed Properties extension 與 `Support/XCTestCase+Diagnostics.swift`。HEAD 的 `Screen.swift` 與同名檔是相同寫法 (extension 沒標 `@MainActor`)，屬既有問題；先前的增量建置沒有重編這兩個檔，所以 7.1 與 8.3 紀錄的「編譯沒有警告」不完整。本 change 不處理，記為後續。
  - 每輪派工前後比對檔案雜湊：第一輪改 23 檔、第二輪改 15 檔並刪 1 檔，都在各自的派工範圍內。
