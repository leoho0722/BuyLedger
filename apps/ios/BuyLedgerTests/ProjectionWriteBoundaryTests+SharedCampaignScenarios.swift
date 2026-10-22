//
//  ProjectionWriteBoundaryTests+SharedCampaignScenarios.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

// MARK: - Computed Properties

extension ProjectionWriteBoundaryTests {

    /// 共享開團的合法同步、唯讀轉換、寫入與可寫引用外傳案例
    static var sharedCampaignProjectionScenarios: [SharedOrderScenario] {
        [
            SharedOrderScenario(
                relativePath: "Features/App/Presentation/Root/RootFeature.swift",
                source: "state.orders.$campaigns.withLock { $0 = loaded }",
                expectedCount: 0
            ),
            SharedOrderScenario(
                relativePath: "Features/Campaigns/Presentation/Root/CampaignFeature.swift",
                source: "state.$campaigns.withLock { $0 = loaded }",
                expectedCount: 0
            ),
            SharedOrderScenario(
                relativePath: "Features/Campaigns/Presentation/CampaignWrites/CampaignWritesFeature.swift",
                source: "state.$campaigns.withLock { $0 = loaded }",
                expectedCount: 0
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: """
                struct OrdersFeature {
                    struct State {
                        @Shared(value: []) var campaigns: [Campaign]
                        init() {
                            let prepare = { }
                            list = OrderListFeature.State(campaigns: SharedReader(_campaigns))
                        }
                    }
                }
                """,
                expectedCount: 0
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: "SharedReader(state.$campaigns)",
                expectedCount: 0
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/OrdersProjectionOperations.swift",
                source: "SharedReader(\n    state.orders.$campaigns\n)",
                expectedCount: 0
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: "// state.$campaigns.withLock { $0 = [] }\n/* let copy = state.$campaigns */",
                expectedCount: 0
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/OrdersProjectionOperations.swift",
                source: "let example = \"state.$campaigns.withLock { $0 = [] }\"",
                expectedCount: 0
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: "state.$campaigns.withLock { $0 = [] }",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/OrdersProjectionOperations.swift",
                source: "child.$campaigns.withLock { $0 = [] }",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: """
                struct OrdersFeature {
                    func core(state: inout State) {
                        state.campaigns = []
                    }
                }
                """,
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/OrdersProjectionOperations.swift",
                source: """
                func update(child: OrdersFeature.State) {
                    child.campaigns = []
                }
                """,
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: "OrderListFeature.State(campaigns: state.$campaigns)",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/OrdersProjectionOperations.swift",
                source: "updateCampaigns(state.$campaigns)",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: "let leaked = state.$campaigns",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/OrdersProjectionOperations.swift",
                source: "let leaked = child.$campaigns",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: """
                extension OrdersFeature.State {
                    mutating func rebind() {
                        self.$campaigns = replacement
                    }
                }
                """,
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/OrdersProjectionOperations.swift",
                source: "state.$campaigns = replacement",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: "$campaigns = replacement",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/App/Presentation/Root/RootNavigationOperations.swift",
                source: "root.orders.$campaigns.withLock { $0 = [] }",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/App/Presentation/Root/RootNavigationOperations.swift",
                source: "root.orders.$campaigns = replacement",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: "_campaigns.withLock { $0 = [] }",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: "state._campaigns = replacement",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: "helper(_campaigns)",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: "init() {\n    _campaigns.withLock { $0 = [] }\n}",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: "init() {\n    helper(_campaigns)\n}",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: "init() {\n    self._campaigns = Shared(value: [])\n}",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/OrderList/OrderListFeature.swift",
                source: "self._campaigns = campaigns",
                expectedCount: 0
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: "init() { }\nfunc read() {\n    SharedReader(_campaigns)\n}",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/OrderList/OrderListFeature.swift",
                source: "@SharedReader var campaigns: [Campaign]\nOrderFilterFeature.State(campaigns: state.$campaigns)",
                expectedCount: 0
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/OrdersProjectionOperations.swift",
                source: "// @SharedReader var campaigns: [Campaign]\nOrderFilterFeature.State(campaigns: state.$campaigns)",
                expectedCount: 1
            ),
            SharedOrderScenario(
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                source: "@SharedReader var campaigns: [Campaign]\nOrderFilterFeature.State(campaigns: state.$campaigns)",
                expectedCount: 1
            ),
        ]
    }
}
