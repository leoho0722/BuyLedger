//
//  DependencyConventionDependencyCases.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/29.
//

/// 型別下標規則的違規與合規案例
enum DependencyConventionDependencyCases {}

// MARK: - Computed Properties

extension DependencyConventionDependencyCases {

    /// 型別下標規則應拒絕的違規案例，包含型別注入與依賴註冊檔內不允許的下標
    ///
    /// - Note: 由 `DependencyConventionScanScenario` 彙總
    static var dependencyViolationCases: [DependencyScanViolationCase] {
        [
            DependencyScanViolationCase(
                name: "Reducer 以型別取得依賴",
                source: "@Dependency(OrderService.self) private var orderService",
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                sourceTree: .production,
                rules: [.dependencyTypeSubscript],
                expectedLine: 1,
                expectedReference: "@Dependency(OrderService.self)",
                expectedReason: "不得以型別下標注入依賴"
            ),
            DependencyScanViolationCase(
                name: "測試以型別下標覆寫依賴",
                source: "$0[OrderService.self].fetchOrders = { [] }",
                relativePath: "OrdersFeatureTests.swift",
                sourceTree: .unitTests,
                rules: [.dependencyTypeSubscript],
                expectedLine: 1,
                expectedReference: "$0[OrderService.self]",
                expectedReason: "不得以型別下標讀取依賴"
            ),
            DependencyScanViolationCase(
                name: "依賴值集合以型別下標讀取",
                source: "values[OrderService.self]",
                relativePath: "OrdersFeatureTests.swift",
                sourceTree: .unitTests,
                rules: [.dependencyTypeSubscript],
                expectedLine: 1,
                expectedReference: "values[OrderService.self]",
                expectedReason: "不得以型別下標讀取依賴"
            ),
            DependencyScanViolationCase(
                name: "DependencyValues 以外使用 accessor 下標",
                source: """
                extension OrderService: DependencyKey {}
                extension OtherValues {
                    var service: OrderService { get { self[OrderService.self] } }
                }
                """,
                relativePath: "Features/Orders/Data/Order/OrderService.swift",
                sourceTree: .production,
                rules: [.dependencyTypeSubscript],
                expectedLine: 3,
                expectedReference: "self[OrderService.self]",
                expectedReason: "不得以型別下標讀取依賴"
            ),
            DependencyScanViolationCase(
                name: "未宣告 DependencyKey 的檔案使用 accessor 下標",
                source: "extension DependencyValues { var service: OrderService { get { self[OrderService.self] } } }",
                relativePath: "Features/Orders/Data/Order/OrderService+Reads.swift",
                sourceTree: .production,
                rules: [.dependencyTypeSubscript],
                expectedLine: 1,
                expectedReference: "self[OrderService.self]",
                expectedReason: "不得以型別下標讀取依賴"
            ),
            DependencyScanViolationCase(
                name: "含引號的 regex literal 後仍掃描型別下標",
                source: #"let pattern = #/"""[\s\S]*?"""|"([^"\\]|\\.)*"/#; $0[OrderService.self]"#,
                relativePath: "OrdersFeatureTests.swift",
                sourceTree: .unitTests,
                rules: [.dependencyTypeSubscript],
                expectedLine: 1,
                expectedReference: "$0[OrderService.self]",
                expectedReason: "不得以型別下標讀取依賴"
            ),
        ]
    }

    /// 型別下標規則應接受的案例，由 `DependencyConventionScanScenario` 彙總
    static var dependencyPassingCases: [DependencyScanPassingCase] {
        [
            DependencyScanPassingCase(
                name: "Service 的 DependencyValues accessor 使用型別下標",
                source: """
                extension OrderService: DependencyKey {}
                extension DependencyValues {
                    var orderService: OrderService { get { self[OrderService.self] } }
                }
                """,
                relativePath: "Features/Orders/Data/Order/OrderService.swift",
                sourceTree: .production,
                rules: [.dependencyTypeSubscript]
            ),
            DependencyScanPassingCase(
                name: "Client 的 DependencyValues accessor 使用 Key 型別下標",
                source: """
                enum HTTPClientKey: DependencyKey {}
                extension DependencyValues {
                    var httpClient: any HTTPClientProtocol { get { self[HTTPClientKey.self] } }
                }
                """,
                relativePath: "Core/Networking/Client/HTTPClient.swift",
                sourceTree: .production,
                rules: [.dependencyTypeSubscript]
            ),
            DependencyScanPassingCase(
                name: "Schema 型別陣列不是依賴下標",
                source: "Schema([OrderRecord.self, CampaignRecord.self])",
                relativePath: "Core/Persistence/Database/BuyLedgerSchema.swift",
                sourceTree: .production,
                rules: [.dependencyTypeSubscript]
            ),
        ]
    }
}
