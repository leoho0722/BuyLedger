//
//  UITestConventionScenarios.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/15.
//

/// UI 測試規範守門掃描器的自我測試案例，以合成樣本驗證掃描器的判斷
enum UITestConventionScenarios {

    // MARK: - Properties

    /// 全部自我測試案例
    static let all: [Scenario] = namingCases + discardableBoolCases + failureExitCases

    /// 檔名規則的案例：舊後綴被拒、列名的例外不回報、合法後綴通過、非 Tests 目錄不在範圍
    static let namingCases: [Scenario] = [
        Scenario(
            name: "舊後綴檔名被拒並列出檔名",
            rule: .naming,
            relativePath: "Tests/Orders/Filters/OrderFilterSheetTests.swift",
            source: "",
            expectedLocations: ["Tests/Orders/Filters/OrderFilterSheetTests.swift:1"]
        ),
        Scenario(
            name: "效能測試例外檔名不回報",
            rule: .naming,
            relativePath: "Tests/Performance/LaunchPerformanceTests.swift",
            source: "",
            expectedLocations: []
        ),
        Scenario(
            name: "純值自我檢查例外檔名不回報",
            rule: .naming,
            relativePath: "Tests/Navigation/AdaptiveLayoutCheckCounterexampleTests.swift",
            source: "",
            expectedLocations: []
        ),
        Scenario(
            name: "UITests 後綴通過",
            rule: .naming,
            relativePath: "Tests/Orders/Filters/OrderFilterSheetUITests.swift",
            source: "",
            expectedLocations: []
        ),
        Scenario(
            name: "TestSupport 後綴通過",
            rule: .naming,
            relativePath: "Tests/Orders/Filters/OrdersUITestSupport.swift",
            source: "",
            expectedLocations: []
        ),
        Scenario(
            name: "非 Tests 目錄的檔名不在範圍",
            rule: .naming,
            relativePath: "Support/OrderFilterSheetTests.swift",
            source: "",
            expectedLocations: []
        ),
    ]

    /// `@discardableResult` 規則的案例：多行與單行的 Bool 函式被拒，Page Object 回傳與註解內的文字不回報
    static let discardableBoolCases: [Scenario] = [
        Scenario(
            name: "多行簽章的 @discardableResult Bool 函式被拒並列出宣告行",
            rule: .discardableBool,
            relativePath: "Support/Example.swift",
            source: #"""
            extension XCUIApplication {
                @discardableResult
                func waitUntilReady(
                    timeout: TimeInterval,
                    file: StaticString = #filePath,
                    line: UInt = #line
                ) throws(UITestError) -> Bool {
                    true
                }
            }
            """#,
            expectedLocations: ["Support/Example.swift:2"]
        ),
        Scenario(
            name: "單行簽章的 @discardableResult Bool 函式被拒",
            rule: .discardableBool,
            relativePath: "Support/Example.swift",
            source: #"""
            @discardableResult
            func isReady() -> Bool {
                true
            }
            """#,
            expectedLocations: ["Support/Example.swift:1"]
        ),
        Scenario(
            name: "回傳 Page Object 的 @discardableResult 不回報",
            rule: .discardableBool,
            relativePath: "Screens/Orders/OrdersScreen.swift",
            source: #"""
            @discardableResult
            func tapAddOrder(
                file: StaticString = #filePath,
                line: UInt = #line
            ) throws(UITestError) -> OrderEditScreen {
                OrderEditScreen()
            }
            """#,
            expectedLocations: []
        ),
        Scenario(
            name: "註解中的 @discardableResult 不回報",
            rule: .discardableBool,
            relativePath: "Support/Example.swift",
            source: #"""
            // @discardableResult
            func isReady() -> Bool {
                true
            }
            """#,
            expectedLocations: []
        ),
        Scenario(
            name: "沒有 @discardableResult 的 Bool 函式不回報",
            rule: .discardableBool,
            relativePath: "Support/Example.swift",
            source: #"""
            func isReady() -> Bool {
                true
            }
            """#,
            expectedLocations: []
        ),
    ]

    /// 失敗出口規則的案例：Page Object、Support 與 TestSupport 的非拋錯呼叫被拒，拋錯路徑、註解、字串與診斷檔不回報
    static let failureExitCases: [Scenario] = [
        Scenario(
            name: "Page Object 呼叫非拋錯出口被拒並列出行號",
            rule: .failureExit,
            relativePath: "Screens/Orders/OrdersScreen.swift",
            source: #"""
            final class Example {
                func waitForRow(in app: XCUIApplication) {
                    app.failWithDiagnostics("probe")
                }
            }
            """#,
            expectedLocations: ["Screens/Orders/OrdersScreen.swift:3"]
        ),
        Scenario(
            name: "Support 呼叫 XCTFail 被拒",
            rule: .failureExit,
            relativePath: "Support/Polling.swift",
            source: #"XCTFail("probe")"#,
            expectedLocations: ["Support/Polling.swift:1"]
        ),
        Scenario(
            name: "TestSupport 呼叫 XCTAssert 被拒",
            rule: .failureExit,
            relativePath: "Tests/Orders/Filters/OrdersUITestSupport.swift",
            source: #"XCTAssertTrue(flag, "probe")"#,
            expectedLocations: ["Tests/Orders/Filters/OrdersUITestSupport.swift:1"]
        ),
        Scenario(
            name: "拋錯的 stopWithDiagnostics 不回報",
            rule: .failureExit,
            relativePath: "Screens/Orders/OrdersScreen.swift",
            source: #"try app.stopWithDiagnostics("probe")"#,
            expectedLocations: []
        ),
        Scenario(
            name: "註解與字串中的失敗出口不回報",
            rule: .failureExit,
            relativePath: "Screens/Orders/OrdersScreen.swift",
            source: #"""
            // XCTAssertTrue(flag)
            let message = "failWithDiagnostics(in: app, probe)"
            """#,
            expectedLocations: []
        ),
        Scenario(
            name: "診斷檔自身的 XCTFail 不回報",
            rule: .failureExit,
            relativePath: "Support/XCUIApplication+Diagnostics.swift",
            source: #"XCTFail(message, file: file, line: line)"#,
            expectedLocations: []
        ),
        Scenario(
            name: "一般測試檔的 XCTAssert 不在失敗出口範圍",
            rule: .failureExit,
            relativePath: "Tests/Insights/InsightsUITests.swift",
            source: #"XCTAssertEqual(value, 1)"#,
            expectedLocations: []
        ),
    ]
}

// MARK: - Nested Types

extension UITestConventionScenarios {

    /// 一筆掃描器自我測試案例
    struct Scenario: Sendable {

        /// 案例名稱，出現在失敗訊息中
        let name: String

        /// 套用的守門規則
        let rule: UITestConventionScanner.Rule

        /// 合成檔案相對於 UI target 根目錄的路徑
        let relativePath: String

        /// 合成的原始碼
        let source: String

        /// 預期的違規位置，格式為 `相對路徑:行號`；空陣列表示不應回報任何違規
        let expectedLocations: [String]
    }
}
