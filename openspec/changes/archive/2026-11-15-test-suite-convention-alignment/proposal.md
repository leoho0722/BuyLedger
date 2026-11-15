## Summary

把 UI 測試 (`apps/ios/BuyLedgerUITests`) 對齊 ios-dev-kit 4.2.4 與專案規則，同時把 Feature 單元測試裡剩下的 `Store` 改成 `TestStore`。UI 測試部分包括：helper 的失敗契約、類別與方法命名、Given／When／Then、重複 helper 收斂、規則與程式的矛盾，以及兩處以顯示文字斷言的狀態改走 `accessibilityValue`。

## Motivation

- 2026-11-14 兩位審查者 (t17：`Tests/**` 59 檔；t1p：`Screens/**` 與 `Support/**` 54 檔) 逐檔重掃的結果，取代 9/14 審查留下的 77 筆舊數字：
  - 回傳 `Bool` 的 helper 有 98 個不合 kit 的 `Bool` 命名 (Screens／Support 92、Tests 6)，而且失敗處理有四種寫法並存。有些 helper 自己 `failWithDiagnostics` 又回傳 `Bool`，呼叫端再 `requireCondition` 一次 (同一次失敗是否記成兩筆未實測，由任務 4.1 量測)；40 個帶 `@discardableResult`，違反 spec「Helpers cannot silently absorb a missing element」要求的「編譯器強制呼叫端處理」。
  - 49 個 UI 測試類別與檔名後綴是 `Tests`／`SmokeTests`，不是 kit 的 `<Screen>UITests`；另有 6 個 `*UITests` 以行為而非畫面命名。約 65 個測試名稱第一段是畫面名詞或英文句子，kit 要求照抄程式碼裡的方法或 Action 名稱。
  - 同一段導覽或斷言 helper 在測試型別各寫一份：Tests 內 18 組、Screens／Support 內 9 組，例如 `openOrders` 有 8 份、3 種簽章。
  - Given／When 內有 25 處以 `XCTAssert*` 驗前置；Then 內有 8 處夾帶動作；17 個測試的多組 When／Then 不屬於旅程測試。
  - 40 個 helper 沒有呼叫端；規則檔與程式互相矛盾，例如 `AppNavigator` 依按鈕順序退回；導覽列標題、搜尋欄結束鈕、注音鍵等受控例外直接寫在測試檔。
- UI 測試規範只靠審查時的一次性搜尋，漂移後沒有測試會失敗。
- 訂單編輯的「日圓」幣別與付款方式管理列的「貨到付款」徽章以 `label CONTAINS` 比對本地化文字 (使用者 10/22 指定改為 identifier 或 `accessibilityValue` 斷言)。
- 延遲讀取的秒數沒有單一來源：App 端 `DependencyValues+BLUITestOverrides` 兩處寫死 8 秒，UI 測試端各自的 `Timing` 只在註解寫「對齊」；調短時測試會改驗別的情境，卻不會失敗。
- 「更多」的工具清單在 `RootNavigationScreen` 與 `XCTestCase+PlatformScope` 列了三份，新增工具時漏改一份會以與新功能無關的「前景未就緒」失敗。
- `.claude/rules/ios-unit-tests.md` 已規定 Feature 測試一律用 `TestStore`，但 15 個單元測試檔仍有 26 處 `Store(`；`Store` 不比對狀態變化，漏掉的變更不會讓測試失敗，也沒有守門擋住新增。

## Proposed Solution

依使用者 2026-11-14 的四項裁決、兩輪提案審查後的十項推薦與 design 的主對話決策：

1. **失敗契約**：會讓測試失敗的函式 (動作、進入點、`assert*`、版面判定) 改成失敗時附診斷並 `throws(UITestError)`，不再回傳 `Bool`；版面判定回傳列舉；純查詢改 `is`／`has`；`wait*` 保留回傳 `Bool` 但不再標 `@discardableResult`。含等待或失敗副作用的 computed property 改成方法。先量測 XCTest 對「記錄失敗再丟錯」的記錄筆數，再定實作。
2. **命名**：49 個類別與檔名改為 `<Screen>UITests`／`<Screen><行為>UITests` (6 個行為命名的 `*UITests` 一併改，必要時依畫面拆型別，不搬資料夾)；測試名稱第一段改為 App 的 view Action 名稱，沒有對應 Action 時取 Page Object 方法名。新舊對照由主對話先定稿再分派。效能測試與不啟動 App 的純值自檢保留。
3. **Given／When／Then**：前置 `XCTAssert*` 改 `requireCondition`；Then 內的動作移到 When；前提型多組 When／Then 併入 Given，可拆型拆成獨立測試，旅程型保留並把允許條件寫進規則檔。
4. **收斂重複與死碼**：根導覽可抵達的畫面提供同形狀的 `open(in:)`，被呈現的畫面由呈現動作回傳；測試不重寫 Page Object 已提供的導覽，`goTo*` 只留給根導覽本身的測試；有 Page Object 的畫面上的直接查詢 (約 140 處，grep 估計) 先補 Page Object 方法再全部遷移；跨資料夾共用的斷言與固定值移到 `Support/`，同資料夾共用的放 `<TypeUnderTest>TestSupport.swift`；返回鍵、輪詢、框線有效性、「更多」工具清單各收成一處；刪除無呼叫端的 helper (保留兩個有用途的例外)。
5. **規則與程式一致**：受控例外分「會操作」與「只讀量測」兩類寫進 spec 與規則檔，以文字、label 或位置定位的例外一律收進共用 helper，查系統容器是否存在與量框線可留在測試檔；補記 `AppNavigator` 退回、系統把手、alert 訊息、導覽列標題與量框線取樣；詳情顯示的訂單改讀詳情根現成的 value；以鎖定語言比對預期文字維持現狀，並寫進規則檔。
6. **App 端補值**：付款方式管理列以 `accessibilityValue` 帶出分類，訂單編輯幣別列帶出幣別代碼；`LookupNameEditorSheet` 的自訂 alert 按鈕補 identifier；延遲讀取秒數改由 `LaunchOptions` 以啟動參數傳給 App。
7. **單元測試與常駐守門**：26 處 `Store(` 改成 `TestStore`，binding 測試送畫面實際送出的 action；新增掃描守門，讓 `Store(` 只能出現在 `SnapshotTests/`；另以掃描守門檢查 UI 測試檔名、可丟棄的 `Bool` helper，以及 Support／Page Object 直接呼叫不丟錯的 `failWithDiagnostics`；測試的 Given、When 一律以會丟錯的 `requireCondition` 建立前置。

## Non-Goals

範圍外的項目與理由見 design 的 Goals／Non-Goals。

## Alternatives Considered

- 只改名、保留 `Bool` 回傳：四種失敗寫法會繼續並存，下一次改契約時同一批函式要再改一次 (使用者未採用)。
- 以顯示文字斷言的約 40 處全部改成語言無關的值：要動大量產品畫面，換來的保障在已鎖語言的測試計畫下有限 (使用者未採用)。
- 拆成多個 change (主對話未採用)：每個 change 都要兩平台完整 UI 回歸 (一輪約 50 分鐘，估計值)，而且同一批 Support 檔會在不同 change 重複改動。

## Impact

- Affected specs: `ui-test-support-layer`、`ui-test-element-identity`、`ui-test-launch-harness`、`test-guard-effectiveness`
- Affected code:
  - Modified:
    - apps/ios/BuyLedgerUITests/Support/ (helper 契約、MARK 分區、共用 helper、`LaunchOptions` 延遲參數)
    - apps/ios/BuyLedgerUITests/Screens/ (契約、進入點、死碼、文件註解)
    - apps/ios/BuyLedgerUITests/Tests/ (改名、Given／When／Then、改用 Page Object 與共用 helper)
    - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupItemRow.swift
    - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupNameEditorSheet.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditStatusSection.swift
    - apps/ios/BuyLedger/App/Testing/Configuration/BLUITestConfiguration.swift
    - apps/ios/BuyLedger/App/Testing/Overrides/DependencyValues+BLUITestOverrides.swift
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+More.swift (新增 alert 按鈕 identifier)
    - apps/ios/BuyLedgerTests/Features/ (15 個用 `Store(` 的測試檔)
    - apps/ios/BuyLedgerTests/Guards/TestSuiteIntegrityTests.swift
    - apps/ios/BuyLedgerTests/App/Testing/BLUITestConfigurationTests.swift、apps/ios/BuyLedgerTests/App/Testing/BLUITestConfigurationInvalidValuesTests.swift
    - apps/ios/BuyLedgerTests/SnapshotTests/ (只改引用 UI 測試類別名的註解，基準圖不動)
    - .claude/rules/ios-ui-tests.md、.claude/rules/ios-unit-tests.md、.claude/rules/ios-navigation.md、.claude/rules/ios-design-system.md、apps/ios/CLAUDE.md、apps/ios/README.md
  - New:
    - apps/ios/BuyLedgerTests/Guards/ 下的 UI 規範掃描子資料夾 (掃描器、掃描測試、案例三檔)
    - apps/ios/BuyLedgerUITests/Support/ 下的共用 helper 檔 (`CGRect+Validity.swift`、`XCUIApplication+SearchInteraction.swift` 等，實際檔名依 design 並在 apply 時記錄) 與各測試資料夾的 `<TypeUnderTest>TestSupport.swift` (型別名由任務 5.1 定稿)
  - Removed: apps/ios/BuyLedgerUITests/Support/ValueParsing.swift (整檔無呼叫端)
  - Renamed: apps/ios/BuyLedgerUITests/Support/XCUIElement+ValueParsing.swift → XCUIElement+CombinedText.swift；apps/ios/BuyLedgerUITests/Screens/Screen.swift → ScreenProtocol.swift；`Tests/` 下 55 個類別 (49 個 `*Tests`／`*SmokeTests` 與 6 個行為命名的 `*UITests`) 依對照表改名或拆檔
  - 不需修改：兩份 UI 測試計畫與 `.github/workflows/ci.yml` 只引用不改名的 `LaunchPerformanceTests`
