//
//  ProjectionWriteBoundaryOrdersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Testing

/// 訂單與共享開團投影掃描的單元測試，以片段案例驗證違規筆數
struct ProjectionWriteBoundaryOrdersTests {

    /// 驗證 Orders 投影的各片段違規筆數符合預期，寫入只允許根功能，訂單狀態與處理訂單 `State` 的 helper 都不得寫入
    ///
    /// - Parameter scenario: 原始碼路徑、片段與固定預期筆數
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    @Test(arguments: Self.ordersProjectionScenarios)
    func projectionViolations_訂單投影正反片段_符合預期違規筆數(scenario: ProjectionWriteBoundaryScenario) throws {
        // Given
        let source = scenario.source

        // When
        let violations = try ProjectionWriteBoundaryScanner.projectionViolations(
            relativePath: scenario.relativePath,
            source: source
        )

        // Then
        #expect(violations.count == scenario.expectedCount)
    }

    /// 驗證共享開團投影的各片段違規筆數符合預期，只有根功能可寫入，訂單端只能傳遞唯讀引用
    ///
    /// - Parameter scenario: 原始碼路徑、共享開團的正反片段與固定預期筆數
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    @Test(
        arguments: ProjectionWriteBoundarySharedCampaignScenarios.sharedCampaignProjectionScenarios
    )
    func projectionViolations_共享開團正反片段_符合預期違規筆數(scenario: ProjectionWriteBoundaryScenario) throws {
        // Given

        // When
        let violations = try ProjectionWriteBoundaryScanner.projectionViolations(
            relativePath: scenario.relativePath,
            source: scenario.source
        )

        // Then
        #expect(violations.count == scenario.expectedCount)
    }
}

// MARK: - Private Method

private extension ProjectionWriteBoundaryOrdersTests {

    /// 根功能檔案、訂單狀態、`extension`、處理訂單 `State` 的 helper 與純讀取的固定案例
    static var ordersProjectionScenarios: [ProjectionWriteBoundaryScenario] {
        [
            ProjectionWriteBoundaryScenario(
                relativePath: "Features/App/Presentation/Root/RootFeature.swift",
                source: """
                    state.orders.$campaigns.withLock { $0 = [] }
                    state.orders.defaultCurrency = .jpy
                    state.orders.aiSummarySettings = settings
                    """,
                expectedCount: 0
            ),
            ProjectionWriteBoundaryScenario(
                relativePath: "Features/App/Presentation/Root/RootNavigationOperations.swift",
                source: """
                    root.orders.campaigns.removeAll()
                    root.orders.defaultCurrency = .jpy
                    root.orders.aiSummarySettings = settings
                    """,
                expectedCount: 3
            ),
            ProjectionWriteBoundaryScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: """
                    struct OrdersFeature {
                        func core(state: inout State) {
                            state.campaigns = []
                            state.defaultCurrency = .jpy
                            state.aiSummarySettings = settings
                        }
                    }
                    """,
                expectedCount: 3
            ),
            ProjectionWriteBoundaryScenario(
                relativePath: "Features/Orders/OrdersFeature+Projection.swift",
                source: """
                    extension OrdersFeature.State {
                        mutating func update() {
                            campaigns.removeAll()
                            self.defaultCurrency = .jpy
                            aiSummarySettings = settings
                        }
                    }
                    """,
                expectedCount: 3
            ),
            ProjectionWriteBoundaryScenario(
                relativePath: "Features/Orders/OrdersProjectionOperations.swift",
                source: """
                    func update(child: inout OrdersFeature.State) {
                        child.defaultCurrency = .jpy
                    }
                    """,
                expectedCount: 1
            ),
            ProjectionWriteBoundaryScenario(
                relativePath: "Features/Orders/Presentation/Root/Plans/OrdersContainerPlan.swift",
                source: """
                    func update(child: OrdersFeature.State) {
                        var child = child
                        child.defaultCurrency = .jpy
                    }
                    """,
                expectedCount: 1
            ),
            ProjectionWriteBoundaryScenario(
                relativePath: "Features/Orders/OrderListOperations.swift",
                source: """
                    func update(state: inout OrderListFeature.State, root: inout RootFeature.State) {
                        root.orders.defaultCurrency = .jpy
                    }
                    """,
                expectedCount: 1
            ),
            ProjectionWriteBoundaryScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: """
                    struct OrdersFeature {
                        struct State {
                            var defaultCurrency: CurrencyCode = .twd
                        }
                        func read(state: State) {
                            let currency = state.defaultCurrency
                            let currentCampaigns = state.campaigns
                            let settings = state.aiSummarySettings
                        }
                    }
                    """,
                expectedCount: 0
            ),
            ProjectionWriteBoundaryScenario(
                relativePath: "Features/Orders/OrdersRequestPlan.swift",
                source: """
                    func read(child: OrdersFeature.State) {
                        let currency = child.defaultCurrency
                    }
                    // child.orders.defaultCurrency = .jpy
                    let message = "root.orders.aiSummarySettings = settings"
                    """,
                expectedCount: 0
            ),
        ]
    }
}
