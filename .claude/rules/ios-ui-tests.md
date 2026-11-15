---
paths:
  - "apps/ios/BuyLedgerUITests/**"
  - "apps/ios/BuyLedgerAccessibilityIDs/**"
  - "apps/ios/BuyLedger/App/Testing/**"
  - "apps/ios/BuyLedger/Features/**/*{View,Sheet,Layout,Row,Content,Column,Card,Section,Tile,Tiles,List,Banner,Menu,Field,Destination}.swift"
  - "apps/ios/BuyLedger/Shared/DesignSystem/Components/**"
---

# iOS UI 自動化測試 (XCUITest)

`BuyLedgerUITests` 共用 `Support/`、Page Object (`Screens/`) 與 `App/Testing/` 的啟動掛鉤；執行方式、測試計畫與雜訊判讀見 `apps/ios/CLAUDE.md` 的「建置與開發指令」。App 端加 identifier 時同樣適用下方「定位與 identifier」。

- **`BuyLedgerUITests` target 不能 `import Testing` (建置錯誤 `_Testing_Unavailable`)**：UI target 內不啟動 App 的純值自檢 (如 `AdaptiveLayoutCheckCounterexampleTests`) 也用 XCTest。
- **選擇性執行與變異驗證必須確認實際執行數大於 0**：`0 tests executed` 不是通過，不能用成功退出碼判定測試有效。
- **執行裝置與前置見 `apps/ios/CLAUDE.md` 的「UI 測試」**：本機 UI 測試預設跑 iPhone 17 (iOS 26.5) 與 iPad Air 11-inch (M4) (iPadOS 27.0) 模擬器，需要實機時改跑 iPhone 12 與 iPad Air 5。
- **只存在於單一版面的功能，測試以 compact／regular 版面明確宣告適用範圍，不判斷裝置是 iPhone 或 iPad**：測試方法 `throws`，到達判斷版面所需的畫面後立刻宣告 `XCTSkipUnless`，再接其他 Given 步驟；要轉向後才能判斷的，轉向後立刻宣告。skip 條件只能是版面，不得因元素找不到或其他狀態而 skip；skip 訊息寫明版面限制。
    - 根導覽專屬案例：`launch` 後即可用 `try AppNavigator(app: app).rootLayout()` 取得 `RootLayout` (`.regular` 或 `.compact`)；側邊欄或頂部分頁列為 `.regular`，底部分頁列為 `.compact`，判不出來時失敗。
    - 訂單功能專屬案例：先 `try OrdersScreen.open(in: app)` 切到訂單分頁，再以 `try ordersLayout(in: app)` (`XCTestCase+PlatformScope.swift`) 取得 `ListDetailLayout` (`.regular` 為並排、`.compact` 為收合)；在訂單前景之前判斷會因無法辨識 Orders 前景欄位而失敗。
    - 更多功能專屬案例：先 `try RootNavigationScreen(app: app).goToMore()` 切到更多分頁並等入口清單就緒，再以 `try moreLayout(in: app)` 判斷 (依入口清單與目前工具是否並排)，不以 `rootLayout()` 代替：根導覽與功能內的分欄各自決定。

## 定位與 identifier

- **一律以 `accessibilityIdentifier` 定位，不用顯示文字或 `accessibilityLabel`**：App 支援中英切換，文字定位在英文模式整批失效。
    - 常數集中在 `BuyLedgerAccessibilityIDs/` (同時編入 App 與 UITests)，`BLAccessibilityID` 依區域分檔為 `BLAccessibilityID+<區域>.swift`，兩端引用常數、不寫字面值。
    - 在 `BuyLedgerAccessibilityIDs/` 定義常數時，固定 identifier 寫完整字串字面值；需要組出的只能由 `option`、`row`、`indexed` 在字面值前綴之後接最後一段變動值，不在中段插入參數，也不在變動值之後再接固定片段，UI 測試失敗訊息印出的值才能以前綴搜到定義；UI 測試也以空字串呼叫這些函式取得 `BEGINSWITH` 前綴。
    - 固定值與前綴用 2 至 4 段 lowerCamelCase，第一段是所屬巢狀型別名稱 (如 `AISummary` → `aiSummary`)；定義形式、宣告位置、形狀、只含 ASCII、值不重複、不落在其他前綴之下都由 `AccessibilityIdentifierScanTests` 掃描守門，掃描不認得的新寫法先修改 spec `ui-test-element-identity` 的接受清單，並擴充掃描規則與案例再用。系統指定、App 無法改名的 identifier 不進 `BuyLedgerAccessibilityIDs/`，集中在 UI 測試 `Support/SystemAccessibilityID.swift`，其他檔不寫這些值的字面值 (同一組掃描守門)。
- **identifier 只掛在本身就是無障礙元素的東西上**：按鈕、輸入欄、捲動容器、`accessibilityElement(children: .combine/.contain)` 後的容器。
    - 掛在純 `VStack` 等版面容器會把子元素併吞成單一字串；容器需要 identifier 時先加 `.accessibilityElement(children: .contain)`。
- **合併朗讀的列以 `accessibilityValue` 承載主要數值**，不為了測試把 `.combine` 拆開。
    - 這類元素在 XCUITest 歸為 `staticText`，查詢用 `app.descendants(matching: .any)[id]`，不用 `otherElements`。
    - `LabeledContent` 的內建 value 讀不到，要顯式加 `.accessibilityElement(children: .combine)` + `.accessibilityValue(...)`。
- **系統控制項掛不上 identifier 時，以位置或文字定位的例外收在 `Support/` 的共用 helper 或單一 Page Object 內，測試檔不直接查詢；其餘仍以 identifier 定位**，分類如下：
    - **會操作的例外** (點擊、輸入、捲動、收鍵盤)：定位與操作收在共用 helper 或單一 Page Object 內；依位置時的順序來自 App 端列舉、或以系統控制項消失與否確認結果，也屬此類。
        - 原生根分頁：`RootNavigationLayout` 在每個 `Tab` 上掛 `BLAccessibilityID.Root.tab(_:)`，`AppNavigator` 以此查找；分頁列與側邊欄共用同一組 identifier。依按鈕順序退回的條件見「資料與相依」的版面差異。
        - 根側邊欄切換鈕：`AppNavigator.revealSidebarIfCollapsed()`，以系統識別碼 (`SystemAccessibilityID`) 查找。
        - 導覽列返回鍵：`XCUIApplication.tapUniqueNativeBackButton(file:line:)` 點唯一可見且可互動的系統返回鍵；`tapBackButton(inNavigationBarContaining:file:line:)` 點含指定 identifier 元素的導覽列上的返回鍵。系統返回鍵帶語言無關的 identifier `BackButton` (`SystemAccessibilityID.backButton`)。
        - 搜尋欄：`XCUIApplication.hittableSearchField(file:line:)` 取目前前景可互動的系統搜尋欄，清除鈕取該搜尋欄的 `buttons.firstMatch` (標籤隨系統語言變動)；窄版的系統結束鈕由 `XCUIApplication.tapSearchEndButton(file:line:)` 點擊，標籤為 `關閉` (計畫已鎖語言)。
        - 系統鍵盤的注音鍵與候選字：`XCUIApplication.tapKeyboardKey(_:file:line:)` 與 `tapKeyboardCandidate(_:file:line:)`，以顯示文字定位 (計畫已鎖語言)，參考 `OrderEditInputFocusUITests` 的注音組字測試。
        - alert 按鈕：`XCUIApplication.tapAlertButton(_:)` 依 identifier 點擊，用於能自掛 identifier 的自訂 `.alert`；TCA `AlertState` 與無法掛 identifier 的系統 alert 用 `tapAlertButton(label:)` 依按鈕文字點擊 (計畫已鎖語言)。
        - `Menu` 項目：`XCUIApplication.tapMenuItem(_:label:)` 先展開再點 identifier；iPadOS 27 的 `Menu` 內 `Picker(.inline)` 選項帶不出 identifier，呼叫端一律傳可見標籤作回退 (計畫已鎖語言)。
        - 系統表單把手：`OrderFilterSheetScreen.sheetGrabber` (Page Object 內的元素查詢)。
        - 分段控制項：identifier 掛在 `Picker`，選項以 `segmentedControls.buttons.element(boundBy:)` 依宣告順序取，目前只在 `InsightsScreen` 內。
    - **只讀量測或比對的例外**：共用 helper 內讀取，不操作。
        - 導覽列標題：`XCUIApplication.waitForNavigationBarTitle(_:timeout:)` 與 `navigationBar(containingTitle:)` (計畫已鎖語言)；測試檔不直接查導覽列標題。判斷標題是否可見用 `XCUIApplication.isNavigationBarTitleVisible(_:)`：導覽列內 label 等於標題且可互動的 staticText 才算可見，不以導覽列的 identifier 判定 (搜尋結束後大標題可能變空白，但導覽列的 identifier 仍是標題，無法分辨)；讀某一導覽列可見的標題用 `XCUIApplication.visibleNavigationBarTitle(of:)`。要量某一欄導覽列的框線時，以框線或 `app.navigationBars.matching(identifier:)` 挑出該導覽列，屬系統容器查詢，可留在測試檔。
        - 文字數量：`XCUIApplication.staticTextCount(_:)` 計全畫面 label 等於該文字的 staticText 數，`navigationBarTextCount(_:)` 計所有導覽列內的同類數量，兩者都是只讀。
        - 可互動搜尋欄：`XCUIApplication.firstHittableSearchField` 取第一個可互動的搜尋欄，沒有時為 `nil`；`XCUIApplication.hasHittableSearchField` 判斷是否有可互動的搜尋欄，兩者都取代依位置取搜尋欄。
        - 鍵盤按鍵是否存在：`XCUIApplication.waitForKeyboardKey(_:timeout:)`。
        - TCA `AlertState` 的訊息：`XCUIApplication.assertAlertMessage(contains:timeout:file:line:)` 在逾時內輪詢目前 alert 中含該文字的 staticText，逾時才停止；確認框收回期間不會比對到舊 alert。
        - 量框線的錨點：`XCTestCase+PlatformScope.swift` 的 `foregroundOrdersDetailFrame(in:)` 與清單、詳情欄的錨點取樣。
    - **以執行期 ID 為鍵的列**：列的 identifier 由前綴加使用者輸入的名稱組成 (`BLAccessibilityID` 的 `row` 系列)，以 identifier 前綴加名稱定位 (`BEGINSWITH` 查詢)，不以顯示文字比對。
- **查系統容器是否存在與量框線不算受控例外，允許留在測試檔**：alert 是否呈現、鍵盤、視窗、分頁列、狀態列與導覽列的框線。量測容器與保留區時以 `app.windows.firstMatch`、`app.tabBars.firstMatch`、`app.statusBars.firstMatch` 取框線，不用它們切換分頁；狀態列可能被系統隱藏 (如 iPhone 橫向)，不存在時不納入保留區，存在卻取不到框線就失敗。
- **sheet 層數以 Page Object 計數自己的根 identifier**：SwiftUI sheet 不在 `app.sheets` 內。`LookupManagementScreen.presentedSheetCount` 計名稱表單根，`OrderEditScreen.presentedRootCount` 計訂單編輯根；sheet 內的元素仍以 identifier 定位。
- **`Menu` 的 identifier 掛在 `Menu` 本身，不是 label 內的 `Label`**：選單項目掛在各 `Button`，測試以 `tapMenuItem` 先展開再點。
- **push 目的地的返回鍵在 iPad 要 scope 到目的地那條導覽列**：`app.navigationBars.buttons.firstMatch` 可能點到側邊欄的鈕而關掉整個 sheet，改用 `tapBackButton(inNavigationBarContaining:)`。
- **sheet 疊在有搜尋欄的畫面上時，`app.searchFields.firstMatch` 會取到底層那一個**：iPad 的側邊欄版面讓底層 Orders 搜尋欄排在前面，iPhone 恰好順序相反所以不會中；改用 `app.hittableSearchField()` 取第一個可互動的，取不到就 `stopWithDiagnostics`。同型陷阱也適用於其他在 sheet 內重複出現的系統元件。

## 失敗與停止

- **會讓測試失敗的函式只有一種契約**：`UITestError.stopped(message:)` 是停止訊號，丟出前失敗已記錄，接住後繼續不會撤銷失敗，因此測試與 helper 都不接住它來繼續 (預期失敗的區塊除外)。
    - Support 與 Page Object 中會讓測試失敗的函式標 `throws(UITestError)`，帶 `file: StaticString = #filePath, line: UInt = #line` 並往下傳，失敗位置指向測試裡的呼叫行；呼叫端寫 `try screen.tapEdit()`，不再包一層 `requireCondition`。
    - 唯一的丟錯出口是 `XCUIApplication.stopWithDiagnostics(_:file:line:)`，附截圖與可及性樹後丟出；`requireCondition(_:in:_:)` 與 `requireValue(_:in:_:)` 以它實作。Support 與 Page Object 只經它記錄失敗，不直接呼叫 `failWithDiagnostics` (兩個 Diagnostics 檔除外，由 `UITestConventionScanTests` 的失敗出口規則守住)。
    - 有備援路徑的 helper (`tapMenuItem` 先 identifier 後標籤、`tapRootTab` 先分頁列後側邊欄、`dismissNumericKeyboard` 分段) 先以不會失敗的 `wait*`、`has…(timeout:)` 或純查詢述詞試各個備援，最後一個也不成立才 `stopWithDiagnostics`。可忽略的收尾動作改用不會失敗的等待，不以 `try?` 或 `do`／`catch` 吞掉停止訊號。
    - 版面判定回傳列舉，判不出來時失敗，不回傳 `nil` (`rootLayout()`、`ordersLayout(in:)`、`moreLayout(in:)`)；測試自己比對值後宣告 skip。
    - 函式依形狀分五種，規則依形狀：
        - **會失敗的動作**：`throws(UITestError)`，帶 `file`、`line`。點擊、輸入、捲動、`reveal…` 露出動作，以及回傳列舉的版面判定 (如 `rootLayout()`) 都屬此類。
        - **`wait*`**：回傳 `Bool`，不加 `@discardableResult`，逾時回傳 `false` 且不失敗，呼叫端必須處理結果。
        - **純查詢**：`is`／`has`／`contains` 開頭的述詞與屬性，不等待、不失敗、不做動作。
        - **等待型述詞**：`has…(timeout:)`，逾時內成立回傳 `true`，立即判斷傳 `timeout: 0`，語意同 `waitForExistence`。省略 `timeout` 時會以預設逾時等待，寫立即判斷時必須明確傳 `0`。
        - **狀態讀取**：`is…(file:line:) throws(UITestError)`，必要元素不存在即失敗，存在時回傳狀態。
    - 述詞 (純查詢、等待型述詞、狀態讀取) 都不做捲動或點擊；需要先露出的，由呼叫端在 Given 或 When 呼叫 `reveal…`。
    - 讀值與框線查詢回傳 Optional，區分「不存在」與「空值」。
- **單次記錄依賴 `BLUITestCase` 的 `continueAfterFailure = false`**：會失敗的 helper 只在 `BLUITestCase` 子類別使用；`LaunchPerformanceTests` 與 `AdaptiveLayoutCheckCounterexampleTests` 不繼承它，也不呼叫這些 helper。
    - `LaunchPerformanceTests` 不經 `BLUITestCase.launch(_:)` 啟動：它量測正式冷啟動路徑，帶 `-BLUITest` 會改量 harness 路徑，這是唯一的啟動例外。
- **預期失敗的區塊**：區塊前設 `continueAfterFailure = true`，在 `XCTExpectFailure(strict: true)` 內以 `do`／`catch` 接住停止訊號，`issueMatcher` 比對診斷訊息，區塊後設回 `false`。`catch` 只接住這個區塊的停止訊號，接住後接著執行 Then。
- **測試的 Given 與 When 以 `try requireCondition`／`try requireValue` 建立前置，不用 `XCTAssert*`**：Then 只放斷言，`XCTAssert*` 與需要截圖及可及性樹時的 `failWithDiagnostics(in:_:)` 都放在 Then。Then 內不夾帶動作，動作移到 When 或 Given 的收尾。
- **`Polling.wait` 的條件 closure 不丟錯**：要丟錯的量測在 closure 外側記下錯誤，輪詢結束後再丟出。

## 進入畫面與 helper 放置

- **根導覽可抵達的畫面提供 `static func open(in:file:line:)`**：`static func open(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) throws(UITestError) -> Self`，切到目的地並等前景就緒 (內容、空狀態、載入失敗或已推入的詳情) 才回傳，例：`OrdersScreen.open(in:)`、`CampaignsScreen.open(in:)`、`SettingsScreen.open(in:)`。需要內容的測試再 `try requireCondition(screen.waitUntilReady(), in: app, "...")`；`waitUntilReady` 只等根 identifier，不等內容。
    - 需要對象參數的畫面在 `in:` 前多一個參數，如 `LookupManagementScreen.open(_:in:file:line:)`。
    - 由其他畫面呈現或推入的畫面，由呈現它的 Page Object 動作在新畫面就緒後回傳，如 `OrdersScreen.tapAddOrder(file:line:)` 回傳 `OrderEditScreen`、`CampaignsScreen.openDetail(campaignID:file:line:)`、`OptionPickerScreen.tapAddPaymentMethod(file:line:)` 回傳 `PaymentMethodEditorScreen`、`OrdersScreen.openAISummary(file:line:)` 回傳 `AISummaryScreen`。
    - 動作可能呈現 alert 或畫面時，依結果拆成兩個動作：以 alert 結束的保留原名 (`OptionPickerScreen.tapAdd` 以名稱 alert 新增，`OrdersScreen.tapAISummary` 在 AI 未開啟時呈現提示 alert)，回傳畫面的另取 `open…`／`tapAdd…` 名稱，讓每個函式的結果只有一種。
    - `RootNavigationScreen.goTo*` 只給 `open(in:)` 內部，以及受測對象就是根導覽的測試使用 (切換根分頁本身、「更多」入口清單)；其他測試進畫面一律用 `<Screen>.open(in:)`。
    - 測試只有在畫面沒有 Page Object 時才直接以 identifier 查詢 App 元素；有 Page Object 的畫面一律經它。測試裡重寫導覽的本地 helper 改呼叫進入點後刪除；只串接 Page Object 呼叫的多步前置可留作該測試型別的 private 成員。
- **導覽只放 Page Object**；`XCTestCase` extension 放需要 `XCTestCase` 的 `require*`、共用斷言、版面判定與轉向，`<TypeUnderTest>TestSupport.swift` 只放該資料夾專用的斷言與固定值。
- **共用 helper 依呼叫範圍放置** (依 kit `file-templates.md` tests 一節)：
    - 只有一個測試型別使用的寫成該型別的 private 成員。
    - 同資料夾多個測試型別共用的放 `<TypeUnderTest>TestSupport.swift`，無 case 的 `enum`、成員 `static`，一個受測型別只有一個 (如 `Tests/Orders/Filters/OrdersUITestSupport.swift`)；它的斷言與 Support 相同，失敗時經 `stopWithDiagnostics` 丟錯。
    - 跨資料夾共用的移到 `Support/` 或 Page Object。
    - 放置規則只寫在這裡，不寫進 spec。

## 命名與測試結構

- **類別與檔名依 kit 命名**：`<Screen>UITests`；同一畫面有多個測試型別時用 `<Screen><行為>UITests`；流程跨越根目的地的歸 `RootNavigation<行為>UITests`；不用 `SmokeTests` 後綴，冒煙類別同樣以受測對象命名 (如 `RootNavigationLaunchUITests`)。一個型別涵蓋多個畫面時依畫面拆型別，拆出的檔留在原資料夾。
    - 沒有 Page Object 的受測對象 (「更多」入口清單、App 啟動、UI 測試 harness) 以受測對象命名：「更多」入口清單屬根導覽，歸 `RootNavigation<行為>UITests`。
    - 保留原名：`LaunchPerformanceTests` (kit 的 `<TypeUnderTest>PerformanceTests`)、`AdaptiveLayoutCheckCounterexampleTests` (不啟動 App 的純值檢查)。
- **方法依 kit 命名為 `test<Member>_<情境>_<預期>`**，後兩段用正體中文；`<Member>` 首字大寫，縮寫照原拼法只改首字 (如 `testAiSummaryTapped_`)。`<Member>` 依序取：
    - App 的 view Action 名稱 (如 `testSearchTextChanged_`)，其次 `AlertState` 的 Action；輸入、焦點、`Picker` 選取這類 binding 不算 view Action。
    - App 端沒有對應 Action 的 (binding、版面量測、轉向、系統手勢) 取 Page Object 方法名，再沒有才取 Support 方法名；alert 上沒有 action 的按鈕 (取消、知道了、繼續編輯) 取 `tapAlertButton`。
    - 旅程測試取旅程中重複的 App Action (如 `testTabSelected_`)，沒有時取連續性主體的 State 屬性 (如 `testDraft_`)。
- **Given／When／Then**：
    - 前提型多組 When／Then 把前面幾組改寫成 Given；可拆型拆成各自的測試，名稱各自描述行為。
    - **旅程測試允許多組 When／Then**：後一組 When 承接前一組留下的狀態，拆開會失去連續性；每組 When 配自己的 Then，預期值仍寫字面值。kit 原文「一個測試只允許一組 When／Then」在此例外。

## 預期值

- **預期值以鎖定語言 (zh-Hant／TW) 的字面值比對**：定位到之後的內容比對，預期值寫字面值，不從 production 格式化程式推導。
    - 例外：App 端已把測試要驗的狀態放進合併列的 `accessibilityValue` (幣別列、付款方式列、訂單詳情根)，測試讀整個值比對，不在 label 裡找子字串。

## 資料與相依

- **測試前以 `LaunchOptions` 指定 seed profile 與語言**：模擬器首次啟動是空狀態。
    - 驗證輔助字級用 `LaunchOptions.contentSizeCategory`：序列化為 UIKit 系統參數 `-UIPreferredContentSizeCategoryName`，不經 `BLUITestConfiguration` (參考 `OrdersRegularAccessibilitySizeUITests`)。
    - `BLUITestHarness` 依 `BLUITestConfiguration` 建立測試 container (in-memory 或 persistent)，`DependencyValues+BLUITestOverrides.swift` 注入固定時間、`buyLedgerDatabase` 與外部相依替身；整套 harness 以 `#if DEBUG` 圈住，啟動掛鉤集中在 `AppLaunchConfigurator`。
- **外部相依一律走 test double**：`PhotoService`／`CalendarReminderService`／`ExchangeRateService` 在 UI 測試模式換成不開系統彈窗、不打網路的替身。
- **`DependencyValues+BLUITestOverrides.swift` 以注入的 `BuyLedgerDatabase` 組出 Service，不得在 `prepareDependencies` 的 closure 內讀 `$0.xxxService` 當底座**：`@Dependency` 在 `liveValue` 建立時擷取當下的 `_current`，不是正在準備的 `$0`，會拿到正式 store。
    - 需要包上失敗 closure 的 Service，以 `withDependencies { $0.buyLedgerDatabase = database } operation: { XxxService.liveValue }` 建立，改寫 closure 後再指派給 `$0.xxxService`。
    - `BuyLedgerDatabase` 的 `storeLocation` 如實傳入：in-memory 用 `.inMemory`，persistent 用 `.directory(<store 所在目錄>)`，不一律標成 in-memory。
- **延遲讀取秒數由 `LaunchOptions.readDelaySeconds` 傳給 App**：預設 8 秒，只在 `ordersDelayed`、`exchangeRatesDelayed` 載入失敗時以 `-BLUITestReadDelaySeconds` 帶入；失敗等待的逾時由 `LaunchOptions` 的計算屬性推導，不在各測試自行加餘裕。
- **UI 測試模式關閉 UIView 動畫，App 與 harness 都不重新開啟；驗證呈現競態的測試以 `LaunchOptions.shouldKeepViewAnimations` 保留動畫**：iPad 模擬器上轉向、鍵盤輸入或搜尋欄切換之後，同一個 App 程序可能每次等閒置都等滿 60 秒 (log 出現 `App animations complete notification not received`)，直到 App 被終止；關閉動畫後不再出現，機制推測是 XCTest 對動畫的追蹤失步。
    - 驗證「sheet、確認框或提示關閉之後接著呈現提示或確認框」的測試要帶 `shouldKeepViewAnimations`：這類競態只發生在關閉動畫期間，沒有動畫時測試偵測不到 (參考 `LookupManagementUITests` 的刪除寫入失敗案例)。
    - 等框線穩定、鍵盤就位、等視窗轉向等 helper 照常保留：保留動畫的測試仍需要它們，也是日後移除這個設定的前提。
    - UI 測試不驗證動畫本身 (時長、減少動態效果的替代動畫)，這類行為改由單元測試或正式模式、實機確認。
    - 判讀：未保留動畫的測試再出現這段訊息時，先確認 harness 的設定仍在；設定仍在，或訊息出現在保留動畫的測試，就記錄觸發前的步驟並回報，不自行改 helper 或 App。
    - 升級 Xcode 或 iPad 模擬器執行環境時，重新確認是否仍需要關閉動畫：暫時拿掉 harness 的呼叫，跑一次 iPad 完整 UI 回歸，訊息 0 次且全部通過才可移除。
- **找不到 App 元素一律失敗並附截圖與可及性樹，不用 `XCTSkip` 掩蓋**：`XCTSkip` 只留給真正的外部環境差異 (如系統文字選單)，並寫明原因。
    - iPadOS 數字 Popover 的關閉區域會攔截再次點同一欄位的點擊：驗證再次點擊的測試在 Popover 呈現時可明確 skip，並寫明原因。
- **版面差異由 `AppNavigator` 吸收**：`rootLayout()` 只依側邊欄標記與五個根分頁的位置判定 (側邊欄或頂部分頁列為 `.regular`，底部分頁列為 `.compact`)，不以裝置類型或系統版本推測；compact 含 iPhone 任何方向與 iPad 窄視窗。
    - `selectTab` 只做點擊：已選取即返回，否則經 `tapRootTab` 點擊。目標不在頂部分頁列上時由側邊欄點選，點選後側邊欄仍開著就收回。需要單獨叫出側邊欄時用 `revealSidebarIfCollapsed()` 點系統切換鈕；分頁列溢出時它不可用，因為它要求五個根分頁同時可見。
    - 依按鈕順序退回的條件：五個根分頁都查無 identifier，且分頁列恰有五個按鈕時，依 `Tab` 的宣告順序對應分頁列按鈕；只要有任一分頁帶 identifier 就不退回，找不到就失敗。真的點下退回元素時輸出 `[BLUITest] root tab fallback used`，回歸後在測試紀錄中搜尋此標記計次。
    - 根分頁列在直向且英文語系可能溢出，More 被收進系統「下一頁」箭頭 (該按鈕無 identifier、標籤隨語言變)。切根分頁只走 `AppNavigator` 或 `RootNavigationScreen`，不直接點分頁列或「下一頁」。
- **欄位歸屬以 `Support/XCTestCase+HorizontalBounds.swift` 取得的 frame 比對**：iPadOS 26 的內容會延伸到浮動側邊欄底下，捲動容器 (如 `Orders.listRoot`) 的左緣是 0，不能當欄位的左界；改用側邊欄右緣或畫面內可見的列當左界。
    - iPadOS 27 的詳情欄 (根容器、空狀態容器與導覽列) 會延伸到清單欄底下，框線從清單欄左緣起：詳情欄位置改用內容錨點 (`XCTestCase+PlatformScope.swift` 的 `foregroundOrdersDetailFrame(in:)`)，導覽列以右緣超出清單欄判定為詳情欄。
    - 量欄寬時以左右內距相同的列推算 (`2 × (捲動容器右緣 − 列中心)`，參考 `OrdersRegularColumnWidthUITests`)；欄寬隨量到的視窗座標更新，斷言前在逾時內重量。

## 輸入、捲動與鍵盤

- **表單下半的數字欄在其他文字欄輸入前先填**：別欄鍵盤升起後會蓋住它而聚焦失敗；被捲走時 `swipeDown` 回頂端再輸入。
    - 數字鍵盤完成鍵一律掛 `Common.keyboardDoneButton`；收數字鍵盤一律走共用 helper `XCUIElement.dismissNumericKeyboard`，`OrderEditScreen.tapNumericKeyboardDone` 亦經它，測試碼不自行點完成鍵。
    - 共用 helper 不得改按系統收鍵盤鍵、送 return、依裝置或系統版本分支，或以 `XCTSkip` 掩蓋；只有專門測試外部限制時才可明確 skip。
- **只差幾點露出底緣的欄位用 `XCUIApplication.waitUntilHittableByGentleDrag(_:within:)`，不用整頁 `swipeUp`**：整頁 swipe 帶慣性，會把目標衝出螢幕；這個 helper 以小幅、無慣性的拖曳捲進可點位置，回傳目標是否可點。
    - 此 helper 要求目標已在可及性樹上；離屏未渲染的惰性列走下一條。
- **惰性容器與 Form 的離屏 cell 可能存在但 frame 無效，直接查 `isHittable` 會讓 XCTest 記錄失敗**：透過 `Support/XCUIElement+Waiting.swift` 的 `isHittableOnScreen` 先排除不存在、座標非有限值或空 frame 的元素，再查可點性；等待用 `waitUntilHittable`，不能只以 `exists` 判斷已完成排版。
    - 查詢對到多個元素時 (如 identifier 擴散到圖表內的文字) 讀 `frame` 也會記錄失敗，`isHittableOnScreen` 以 `firstMatch` 判斷；新增讀 `frame` 的 helper 比照處理。
    - 目標不可點時由 `XCUIApplication+Scrolling.swift` 的 helper 捲動後再等，不用 `isHittable` 述詞輪詢，避免 XCTest 先記錄失敗而走不到捲動備援。
    - 水平 `ScrollView` 內的照片縮圖列相同。
- **`Form` 內的 `Toggle` 要點內層 `switches.firstMatch`，不點外層開關元素**：外層元素涵蓋整列，點它的中心會落在標題文字上而不切換 (參考 `CampaignEditScreen.toggleReminder`、`CampaignDetailScreen.toggleUnpaidOnly`)。
    - 切換後以開關的 `value` 或切換造成的畫面變化斷言，否則沒切到也會假通過。
- **List 惰性建立：sheet 停在 medium 高度或清單較長時，可視區外的列與組標題不在可及性樹上**：讀值或點擊前先捲動露出，以格子位置簽章不再變化判斷到底再換方向，不用固定次數盲滑 (參考 `XCUIApplication.reveal`)。
    - 位置簽章用格子相對於 sheet 的位置，每次手勢後等簽章連續兩次相同才判斷：拖動 sheet 本身會改變格子的螢幕座標，減速中讀值也會誤判到底。
    - sheet 內往上找不用 `swipeDown()`：清單到頂端時帶慣性的下滑會把沒有未套用變更的 sheet 拉掉，改用 `press(forDuration:thenDragTo:withVelocity:thenHoldForDuration:)` 慢速輕拖並停住再放開。
- **`swipeUp`／`swipeDown` 帶慣性，捲動後要點擊的元素先等 `frame` 連續兩次相同**：清單減速中點下去只會停住捲動、不會觸發按鈕 (參考 `XCUIElement.waitUntilStableAndHittable`)。
- **iPhone 模擬器第一鍵盤是注音，整段 `typeText` 含連續數字時第二個數字起會打成注音符號**：打完一個數字鍵盤就切回注音面板；含數字的文字逐字呼叫 `typeText` (參考 `XCUIApplication.typeSearchText`)。iPad 注音鍵盤有數字列，不會重現。
    - 逐字輸入也才抓得到「輸入一個字後失焦」這類缺陷：整段 `typeText` 會在畫面重繪前打完。
- **`scrollDismissesKeyboard(.interactively)` 無法以 XCUITest 合成手勢觸發，不寫 UI 測試守它 (產品端仍保留)**：`OrderEditKeyboardDismissUITests` 只覆蓋 return 鍵與數字鍵盤完成鍵兩條路徑。
- **iPadOS 27 的數字鍵盤可能是浮動面板，或貼在欄位旁的 Popover，兩者都沒有工具列完成鍵**：收數字鍵盤一律走 `dismissNumericKeyboard`，依畫面元素分流，不依裝置或系統版本。
    - 浮動面板以鍵盤高度低於完整鍵盤 (`floatingPadMaximumHeight`) 判定；Popover 以 `Popover` 與 `PopoverDismissRegion` (`SystemAccessibilityID.popoverDismissRegion`) 判定，沒有 `Keyboard` 元素。
    - 模擬器處於硬體鍵盤狀態時軟體鍵盤不出現：數字欄的 `Keyboard` 只剩全寬、高約 64 的工具列，同樣會判成浮動面板；文字欄與搜尋欄的 `Keyboard` 高度為 0。失敗訊息為「數字鍵盤未呈現，無法收起」、「數字鍵盤或 Popover 未能收起 (呈現方式：浮動數字面板)」或「點欄位左側後，未取得鍵盤焦點或鍵盤與數字 Popover 框線未穩定」。
        - 先在該台 Safari 聚焦網址列：同樣沒有軟體鍵盤就屬環境狀態，不改 helper 也不改 App。
        - 到 Device Hub 的 Device 選單處理：Simulate Hardware Keyboard 有勾就取消，沒勾也先勾上再取消 (顯示未勾不代表已生效)，仍沒有鍵盤再切換軟體鍵盤。
        - 重開模擬器不會清除；`toggle-connect-hardware-keyboard`、`toggle-software-keyboard` 需要輔助使用權限，回報成功也不一定生效。以 Safari 出現軟體鍵盤且重跑 `OrderEditKeyboardDismissUITests` 通過判定。
    - 只在呈現方式連續取樣都是完整鍵盤時點完成鍵：呈現方式會在輸入前後轉換，浮動面板上 XCUI 仍回報完成鍵可點，但點擊到不了按鈕，只會把鍵盤換成完整鍵盤。完成鍵存在但不可點時點其 frame 中心。
    - 浮動面板或 Popover 先在本欄位點兩下換成完整鍵盤再點完成鍵；完整鍵盤點過完成鍵仍收不掉才失敗。收起的判斷涵蓋鍵盤與 Popover 消失，並確認欄位已失去鍵盤焦點。
- **輸入 helper 依賴 App 的聚焦行為**：App 保證數字欄焦點由無到有時清空草稿、文字欄聚焦時游標在尾端。`clearAndType`／`appendText` 只在欄位未取得鍵盤焦點時點擊，已聚焦時沿用目前游標。
    - `clearAndType` 在確認焦點後讀取既有文字，非搜尋欄依字元數從尾端送刪除鍵再輸入；數字欄聚焦後已清空，多送刪除鍵仍是空操作。
    - `appendText` 不主動刪除原文，文字欄由 App 在聚焦時把游標放在尾端；數字欄只有已聚焦時才接續輸入，未聚焦時 App 會先清空草稿。
    - 接續輸入用 `appendText`，不用「點欄位再 `typeText`」：已聚焦時再次點擊會把游標移到點擊位置，可能把文字插進中間。
    - 驗證聚焦落點的測試例外：用 `tapLeftToFocus` 點欄位左側再 `typeText`，不經這兩個 helper，游標沒放到尾端時字才會插在前面，測試才守得住。
    - 搜尋欄清空用內建清除鈕，不送刪除鍵；聚焦中再次點擊會移動游標，清空後需確認焦點仍在該欄。
- **表單 sheet 在鍵盤升起時會整個上移，點擊要等框線穩定**：`tapAfterWaiting` 的點擊與輸入 helper 的初次聚焦點擊，都會在可點後等框線連續取樣相同，逾時仍不穩時照樣點擊。
    - 只用座標或快取 frame 的點擊不經此等待，要自行處理。
    - 自訂 `.alert` 在輸入後鍵盤升起時同樣會上移：`tapAlertButton` 點擊前等框線穩定，點擊後按鈕仍在且位置改變時重試一次。
- **鍵盤常在打字後才升起，表單隨之上移，輸入前後都要等**：`clearAndType` 在輸入前後各等一次，且每段等待都有上限。
    - 輸入前等鍵盤就位：完整鍵盤框線落在視窗內且連續不變，或浮動面板、數字 Popover 連續不變。逾時照樣輸入，並附上鍵盤狀態供失敗時判讀。
    - 輸入後等欄位框線連續相同才返回。

## 轉向測試

- **轉向類測試的預期值取自直向的版面判定，斷言的是「轉向前後版面不變」**：這只適用直向與橫向同一版面的測試裝置 (iPhone 17、iPad Air)；換到直向收合、橫向並排的裝置時，要改成依版面寫字面值並宣告 skip。
- **轉向測試 (`XCUIDevice.shared.orientation`) 一律經轉向 helper**：setter 只設定裝置方向，不等介面轉完就斷言，會在直向取得 compact 版面而誤判通過；改用 `Support/XCTestCase+Orientation.swift` 的 `rotateToLandscape`，轉回直向用 `rotateToPortrait`，兩者都會等視窗方向確定才返回。
    - Device Hub 的旋轉鈕只轉外框，Orientation 選單也不一定讓介面轉向 (iPad 會轉、iPhone 17 Pro Max 不會)，兩者都不能用來驗證橫向版面。
- **需要實測橫向畫面時，以 Xcode 27.1 MCP 的 `orientation` 指令轉向**：介面會跟著轉，回傳完整的橫向截圖；Device Hub 的旋轉鈕與 Orientation 選單不能驗證橫向版面 (見上一條)。
    - 只支援 iOS 27 以上的模擬器，與實機 XCUITest 無關。
    - 互動交給載入 `device-interaction` skill 的子代理：以 `DeviceInteractionStartSession` (不綁 workspace) 開連線，`DeviceInteractionSynthesize` 帶 `activationBundleId` 操作；以結構檔的 `Application UI orientation` 與 Window frame 確認方向。
    - 建置走 `mobilebuildmcp` (`build-and-run` 裝好再連線)，不讓 Xcode 建置。
    - 首次使用要在 Xcode 授權 MCP：授權時開另一個空白專案，不開 BuyLedger 專案，因為 Xcode 開啟 BuyLedger 時可能刪除 `Package.resolved`。
    - 連線回報 cannot be connected 時關掉 session，以新名稱重開：同名 session 短時間內不能重用。
    - 用完一定要 `DeviceInteractionEndSession`。
    - Device Hub 開著不影響 Xcode MCP 轉向。
- **模擬器上轉向測試失敗且 App 視窗維持直向時，先重開模擬器再重跑，重開後仍失敗才是真問題**：模擬器長時間連續跑後，`XCUIDevice.shared.orientation` 可能只改變裝置方向、介面不轉，屬環境狀態，不是產品或測試缺陷。
    - 判別：轉向類別 (`RootNavigationOrientationUITests`、`DashboardOrientationUITests`、`OrdersOrientationUITests`、`InsightsOrientationUITests`) 在「轉向後 App 視窗寬仍未大於高」失敗，且單獨重跑同樣失敗；沒有特定測試類別會穩定觸發，不必逐類排查，也不改測試碼或放寬等待。
    - 重開機：`mobilebuildmcp` 沒有關機指令，先開啟 Device Hub 再結束它 (結束時會把模擬器全部關機)，再以 `mobilebuildmcp simulator-management boot` 開機。開啟用 `mobilebuildmcp simulator-management open`，結束用 `osascript -e 'tell application "DeviceHub" to quit'` (App 名稱是 `DeviceHub`)。
- **橫向時 `XCTAttachment(screenshot:)` 的截圖只擷取到部分畫面**：判讀版面以可見部分為準，不因看不到右側元素就判定版面錯誤；需要完整畫面時另以 `mobilebuildmcp ui-automation screenshot` 取得。

## 常駐掃描守門

`BuyLedgerTests/Guards/UITestConvention/` 以原始碼掃描守門三條規範，由 `UITestConventionScanTests` 執行，失敗時回報「相對路徑:行號」：

- **測試檔檔名**：`BuyLedgerUITests/Tests/**` 的 `.swift` 只能是 `*UITests.swift` 或 `*TestSupport.swift`。列名的例外：`LaunchPerformanceTests.swift`、`AdaptiveLayoutCheckCounterexampleTests.swift`，理由寫在掃描器的例外清單內。
- **`@discardableResult` 回傳 `Bool`**：`BuyLedgerUITests/**` 中為 0 個；比對範圍是整個宣告直到左大括號，因為簽章常跨多行。
- **非拋錯失敗出口**：`Support/`、`Screens/` 與 `Tests/**/*TestSupport.swift` 中不呼叫 `failWithDiagnostics(`、`XCTFail(` 與 `XCTAssert*`；`Support/XCTestCase+Diagnostics.swift` 與 `Support/XCUIApplication+Diagnostics.swift` 除外。
- 比對前會去掉註解與字串，掃到的檔數為 0 時失敗，樣式不會命中掃描器自己的形式。
