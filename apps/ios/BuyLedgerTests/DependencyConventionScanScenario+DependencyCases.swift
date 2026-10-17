//
//  DependencyConventionScanScenario+DependencyCases.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/29.
//

// MARK: - Computed Properties

extension DependencyConventionScanScenario {

    /// 型別下標規則拒絕型別注入，以及 `+Dependency.swift` 中 `DependencyValues` accessor 以外的下標，
    /// 供 `violationCases` 跨檔組合使用
    static var dependencyViolationCases: [ViolationCase] {
        [
            ViolationCase(
                name: "Reducer 以型別取得依賴",
                source: "@Dependency(OrderService.self) private var orderService",
                relativePath: "Features/Orders/OrdersFeature.swift",
                sourceTree: .production,
                rules: [.dependencyTypeSubscript],
                expectedLine: 1,
                expectedReference: "@Dependency(OrderService.self)",
                expectedReason: "不得以型別下標注入依賴"
            ),
            ViolationCase(
                name: "測試以型別下標覆寫依賴",
                source: "$0[OrderService.self].fetchOrders = { [] }",
                relativePath: "OrdersFeatureTests.swift",
                sourceTree: .unitTests,
                rules: [.dependencyTypeSubscript],
                expectedLine: 1,
                expectedReference: "$0[OrderService.self]",
                expectedReason: "不得以型別下標讀取依賴"
            ),
            ViolationCase(
                name: "依賴值集合以型別下標讀取",
                source: "values[OrderService.self]",
                relativePath: "OrdersFeatureTests.swift",
                sourceTree: .unitTests,
                rules: [.dependencyTypeSubscript],
                expectedLine: 1,
                expectedReference: "values[OrderService.self]",
                expectedReason: "不得以型別下標讀取依賴"
            ),
            ViolationCase(
                name: "DependencyValues 以外使用 accessor 下標",
                source: "extension OtherValues { var service: OrderService { get { self[OrderService.self] } } }",
                relativePath: "Core/Dependencies/OrderService+Dependency.swift",
                sourceTree: .production,
                rules: [.dependencyTypeSubscript],
                expectedLine: 1,
                expectedReference: "self[OrderService.self]",
                expectedReason: "不得以型別下標讀取依賴"
            ),
            ViolationCase(
                name: "非 Dependency 檔使用 accessor 下標",
                source: "extension DependencyValues { var service: OrderService { get { self[OrderService.self] } } }",
                relativePath: "Core/Dependencies/OrderService.swift",
                sourceTree: .production,
                rules: [.dependencyTypeSubscript],
                expectedLine: 1,
                expectedReference: "self[OrderService.self]",
                expectedReason: "不得以型別下標讀取依賴"
            ),
            ViolationCase(
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

    /// 型別下標規則應接受的案例，供 `passingCases` 跨檔組合使用
    static var dependencyPassingCases: [PassingCase] {
        [
            PassingCase(
                name: "DependencyValues accessor 使用型別下標",
                source: "extension DependencyValues { var orderService: OrderService { get { self[OrderService.self] } } }",
                relativePath: "Core/Dependencies/OrderService+Dependency.swift",
                sourceTree: .production,
                rules: [.dependencyTypeSubscript]
            ),
            PassingCase(
                name: "Schema 型別陣列不是依賴下標",
                source: "Schema([OrderRecord.self, CampaignRecord.self])",
                relativePath: "Core/Persistence/BuyLedgerSchema.swift",
                sourceTree: .production,
                rules: [.dependencyTypeSubscript]
            ),
        ]
    }
}
