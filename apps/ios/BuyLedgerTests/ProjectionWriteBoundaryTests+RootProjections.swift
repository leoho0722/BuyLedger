//
//  ProjectionWriteBoundaryTests+RootProjections.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Testing

extension ProjectionWriteBoundaryTests {

    /// 根功能以外只能讀取子層投影，直接賦值、索引賦值與變異方法都要被攔下
    ///
    /// - Parameter scenario: 原始碼路徑、片段與獨立的預期違規筆數
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    @Test(arguments: RootProjectionScenario.allCases)
    func rootProjectionViolations_套用根子層投影片段_符合預期違規筆數(
        scenario: RootProjectionScenario
    ) throws(any Error) {
        // Given
        let relativePath = scenario.relativePath
        let source = scenario.source

        // When
        let violations = try Self.rootProjectionViolations(
            relativePath: relativePath,
            source: source
        )

        // Then
        #expect(violations.count == scenario.expectedCount)
    }
}

// MARK: - Nested Types

extension ProjectionWriteBoundaryTests {

    /// 根狀態子層投影的寫入、讀取與註解字串案例
    struct RootProjectionScenario: Sendable {

        /// 相對於 App 原始碼根目錄的路徑
        let relativePath: String

        /// 待掃描的原始碼片段
        let source: String

        /// 此片段應命中的投影寫入筆數
        let expectedCount: Int

        /// 涵蓋根檔豁免、投影與來源區分、別名、多行寫入及註解字串的固定案例
        static var allCases: [Self] {
            [
                Self(
                    relativePath: "Features/App/RootNavigationOperations.swift",
                    source: "state.more.preferences = .default",
                    expectedCount: 1
                ),
                Self(
                    relativePath: "Features/App/RootNavigationOperations.swift",
                    source: "state.more.biometryType = .faceID",
                    expectedCount: 1
                ),
                Self(
                    relativePath: "Features/App/RootFeature.swift",
                    source: "state.more.preferences = .default; state.more.biometryType = .faceID",
                    expectedCount: 0
                ),
                Self(
                    relativePath: "Features/App/RootNavigationOperations.swift",
                    source: "state.appLock.isBiometricUnlockEnabled = true",
                    expectedCount: 1
                ),
                Self(
                    relativePath: "Features/App/RootFeature.swift",
                    source: "state.appLock.isBiometricUnlockEnabled = true",
                    expectedCount: 0
                ),
                Self(
                    relativePath: "Features/App/RootNavigationOperations.swift",
                    source: "state.dashboard.orders = []",
                    expectedCount: 1
                ),
                Self(
                    relativePath: "Features/App/RootNavigationOperations.swift",
                    source: "state.campaigns.campaigns = []",
                    expectedCount: 0
                ),
                Self(
                    relativePath: "Features/App/RootFeature.swift",
                    source: "state.dashboard.orders = []",
                    expectedCount: 0
                ),
                Self(
                    relativePath: "Features/App/RootNavigationOperations.swift",
                    source: "state.insights.campaigns.removeAll()",
                    expectedCount: 1
                ),
                Self(
                    relativePath: "Features/App/RootNavigationOperations.swift",
                    source: "state.customers.orders[0] = order",
                    expectedCount: 1
                ),
                Self(
                    relativePath: "Features/App/RootNavigationOperations.swift",
                    source: "state.orders.orders.append(order)",
                    expectedCount: 0
                ),
                Self(
                    relativePath: "Features/App/RootNavigationOperations.swift",
                    source: "let text = \"state.dashboard.orders = []\"",
                    expectedCount: 0
                ),
                Self(
                    relativePath: "Features/App/RootNavigationOperations.swift",
                    source: "func update(root: inout RootFeature.State) { root.dashboard.orders = [] }",
                    expectedCount: 1
                ),
                Self(
                    relativePath: "Features/App/RootNavigationOperations.swift",
                    source: "// state.dashboard.orders = []\n/* state.insights.orders.removeAll() */",
                    expectedCount: 0
                ),
                Self(
                    relativePath: "Features/App/RootNavigationOperations.swift",
                    source: "state.campaigns.orders = []",
                    expectedCount: 1
                ),
                Self(
                    relativePath: "Features/App/RootNavigationOperations.swift",
                    source: "let unchanged = state.dashboard.orders == []",
                    expectedCount: 0
                ),
                Self(
                    relativePath: "Features/App/RootNavigationOperations.swift",
                    source: "state.dashboard.monthlyProfitGoalTwd += 1",
                    expectedCount: 1
                ),
                Self(
                    relativePath: "Features/App/RootNavigationOperations.swift",
                    source: "state\n    .dashboard\n    .orders = []",
                    expectedCount: 1
                ),
            ]
        }
    }
}
