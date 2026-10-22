//
//  ProjectionWriteBoundaryTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/2.
//

import Testing

/// 確認投影只有 `RootFeature` 可以寫入
struct ProjectionWriteBoundaryTests {

    // MARK: - Properties

    /// `RootFeature.swift` 的相對路徑；掃描時排除唯一合法寫入者
    static let rootFeatureRelativePath = "Features/App/RootFeature.swift"

    /// `Generated` 目錄不納入掃描
    static let excludedDirectoryName = "Generated"

    /// App target 檔案數量下限
    static let minimumProductionFileCount = 100

    /// 各 feature 持有的投影屬性
    static let projectionOwners: [ProjectionOwner] = [
        ProjectionOwner(
            name: "OrdersFeature",
            rootStateKey: "orders",
            homeFileRelativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
            properties: ["campaigns", "defaultCurrency", "aiSummarySettings"]
        ),
        ProjectionOwner(
            name: "MoreFeature",
            rootStateKey: "more",
            homeFileRelativePath: "Features/More/MoreFeature.swift",
            properties: ["preferences", "biometryType"]
        ),
        ProjectionOwner(
            name: "AppLockFeature",
            rootStateKey: "appLock",
            homeFileRelativePath: "Features/App/AppLockFeature.swift",
            properties: ["isBiometricUnlockEnabled"]
        ),
        ProjectionOwner(
            name: "CampaignFeature",
            rootStateKey: "campaigns",
            homeFileRelativePath: "Features/Campaigns/CampaignFeature.swift",
            properties: ["orders"]
        ),
        ProjectionOwner(
            name: "CustomersFeature",
            rootStateKey: "customers",
            homeFileRelativePath: "Features/Customers/CustomersFeature.swift",
            properties: ["orders"]
        ),
        ProjectionOwner(
            name: "DashboardFeature",
            rootStateKey: "dashboard",
            homeFileRelativePath: "Features/Dashboard/DashboardFeature.swift",
            properties: ["orders", "campaigns", "monthlyProfitGoalTWD", "loadState"]
        ),
        ProjectionOwner(
            name: "InsightsFeature",
            rootStateKey: "insights",
            homeFileRelativePath: "Features/Insights/InsightsFeature.swift",
            properties: ["orders", "campaigns", "loadState"]
        ),
    ]

    /// 可能改變陣列或字典內容的 `mutating` 方法
    static let mutatingMethodNames = [
        "append",
        "removeAll",
        "remove",
        "insert",
        "sort",
        "swapAt",
        "removeFirst",
        "removeLast",
        "removeSubrange",
        "replaceSubrange",
        "reserveCapacity",
        "shuffle",
        "reverse",
    ]

    /// 涵蓋完整路徑、值參數、唯讀轉換，以及註解與字串的守門案例
    static let sharedOrderScenarios: [SharedOrderScenario] = [
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/OrderWrites/OrdersCascadeOperations.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Other/Helper.swift",
            source: """
            /// 以值接收開團狀態的外部 helper
            ///
            /// - Parameter state: 不能寫入訂單投影的開團狀態
            func update(state: CampaignFeature.State) {
                state.$orders.withLock { $0 = [] }
            }
            """,
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Campaigns/CampaignFeature.swift",
            source: "state.campaigns.$orders.withLock { $0 = [] }",
            expectedCount: 2
        ),
        SharedOrderScenario(
            relativePath: "Features/Campaigns/CampaignFeature.swift",
            source: "CampaignListFeature.State(orders: state.$orders)",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Campaigns/CampaignFeature.swift",
            source: "SharedReader(state.$orders)",
            expectedCount: 0
        ),
        SharedOrderScenario(
            relativePath: "Features/App/RootFeature.swift",
            source: "state.campaigns.$orders.withLock { $0 = orders }",
            expectedCount: 0
        ),
        SharedOrderScenario(
            relativePath: "Features/Campaigns/CampaignFeature.swift",
            source: "let orders = state.$orders",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Campaigns/CampaignFeature.swift",
            source: "SharedReader(\n    state.campaigns.$orders\n)",
            expectedCount: 0
        ),
        SharedOrderScenario(
            relativePath: "Features/Campaigns/CampaignFeature.swift",
            source: "// state.$orders.withLock { $0 = [] }\n/* let orders = state.$orders */",
            expectedCount: 0
        ),
        SharedOrderScenario(
            relativePath: "Features/Campaigns/CampaignFeature.swift",
            source: "let example = \"state.$orders.withLock { $0 = [] }\"",
            expectedCount: 0
        ),
        SharedOrderScenario(
            relativePath: "Features/More/MoreFeature.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 2
        ),
        SharedOrderScenario(
            relativePath: "Features/More/MoreFeature.swift",
            source: "CustomersFeature.State(orders: state.$orders)",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/More/MoreFeature.swift",
            source: "let leakedOrders = state.$orders",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/More/MoreFeature.swift",
            source: "CustomersFeature.State(orders: SharedReader(\n    state.more.$orders\n))",
            expectedCount: 0
        ),
        SharedOrderScenario(
            relativePath: "Features/App/RootFeature.swift",
            source: "state.more.$orders.withLock { $0 = orders }",
            expectedCount: 0
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/OrderWrites/OrdersCascadeOperations.swift",
            source: "state.campaigns.$orders.withLock { $0 = orders }",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/OrderWrites/OrdersCascadeOperations.swift",
            source: "state.more.$orders.withLock { $0 = orders }",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/OrderWrites/OrdersCascadeOperations.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
    ]

    /// 訂單資料來源的合法寫入者與唯讀容器及 helper 的正反案例
    static let sharedOrderWriterScenarios: [SharedOrderScenario] = [
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Other/OrdersFeature.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/OrdersLoad/OrdersLoadFeature.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 0
        ),
        SharedOrderScenario(
            relativePath: "Features/Other/OrdersLoadFeature.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/OrderWrites/OrderWritesFeature.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 0
        ),
        SharedOrderScenario(
            relativePath: "Features/Other/OrderWritesFeature.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/OrderList/Operations/OrdersBatchOperations.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/OrderList/Operations/OrdersBatchOperations.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/Root/Plans/OrdersMergeFlowOperations.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/Root/Plans/OrdersMergeFlowOperations.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/OrderEdit/Models/OrderDraft+WriteResult.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/OrderEdit/Models/OrderDraft+WriteResult.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/Root/Views/OrdersView.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/Root/Views/OrdersView.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/Root/Views/OrdersCompactView.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/Root/Views/OrdersCompactView.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/Root/Views/OrdersRegularListColumn.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/Root/Views/OrdersRegularListColumn.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/Root/Views/OrdersRegularDetailColumn.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/Orders/Presentation/Root/Views/OrdersRegularDetailColumn.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
        SharedOrderScenario(
            relativePath: "Features/App/RootSidebarLayout.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        SharedOrderScenario(
            relativePath: "Features/App/RootSidebarLayout.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
    ]
}
