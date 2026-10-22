//
//  ProjectionWriteBoundaryTests+Orders.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Testing

extension ProjectionWriteBoundaryTests {

    /// Orders 投影只允許根功能寫入，容器與取得子 `State` 的 helper 都受守門
    ///
    /// - Parameter scenario: 原始碼路徑、片段與固定預期筆數
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    @Test(arguments: Self.ordersProjectionScenarios)
    func projectionViolations_訂單投影正反片段_符合預期違規筆數(scenario: SharedOrderScenario) throws(any Error) {
        // Given
        let source = scenario.source

        // When
        let violations = try Self.projectionViolations(
            relativePath: scenario.relativePath,
            source: source
        )

        // Then
        #expect(violations.count == scenario.expectedCount)
    }

    /// 共享開團投影只允許根功能寫入，訂單端只傳遞唯讀引用
    ///
    /// - Parameter scenario: 原始碼路徑、共享開團的正反片段與固定預期筆數
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    @Test(arguments: Self.sharedCampaignProjectionScenarios)
    func projectionViolations_共享開團正反片段_符合預期違規筆數(scenario: SharedOrderScenario) throws {
        // Given

        // When
        let violations = try Self.projectionViolations(
            relativePath: scenario.relativePath,
            source: scenario.source
        )

        // Then
        #expect(violations.count == scenario.expectedCount)
    }
}

// MARK: - Private Method

private extension ProjectionWriteBoundaryTests {

    /// 根檔、容器、`extension`、子 `State` helper 與純讀取的固定案例
    static var ordersProjectionScenarios: [SharedOrderScenario] {
        [
            SharedOrderScenario(
                relativePath: "Features/App/Presentation/Root/RootFeature.swift",
                source: """
                state.orders.$campaigns.withLock { $0 = [] }
                state.orders.defaultCurrency = .jpy
                state.orders.aiSummarySettings = settings
                """,
                expectedCount: 0
            ),
            SharedOrderScenario(
                relativePath: "Features/App/Presentation/Root/RootNavigationOperations.swift",
                source: """
                root.orders.campaigns.removeAll()
                root.orders.defaultCurrency = .jpy
                root.orders.aiSummarySettings = settings
                """,
                expectedCount: 3
            ),
            SharedOrderScenario(
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
            SharedOrderScenario(
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
            SharedOrderScenario(
                relativePath: "Features/Orders/OrdersProjectionOperations.swift",
                source: """
                func update(child: inout OrdersFeature.State) {
                    child.defaultCurrency = .jpy
                }
                """,
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/Plans/OrdersContainerPlan.swift",
                source: """
                func update(child: OrdersFeature.State) {
                    var child = child
                    child.defaultCurrency = .jpy
                }
                """,
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/OrderListOperations.swift",
                source: """
                func update(state: inout OrderListFeature.State, root: inout RootFeature.State) {
                    root.orders.defaultCurrency = .jpy
                }
                """,
                expectedCount: 1
            ),
            SharedOrderScenario(
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
            SharedOrderScenario(
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
