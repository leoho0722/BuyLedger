//
//  DependencyConventionBoundaryCases.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/29.
//

/// Feature 與 Service 邊界規則的違規與合規案例
enum DependencyConventionBoundaryCases {}

// MARK: - Computed Properties

extension DependencyConventionBoundaryCases {

    /// Feature 與 Service 邊界規則應拒絕的案例，由 `DependencyConventionScanScenario` 彙總
    static var boundaryViolationCases: [DependencyScanViolationCase] {
        [
            DependencyScanViolationCase(
                name: "Feature 直接讀取 Database",
                source: #"@Dependency(\.buyLedgerDatabase) private var database"#,
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                sourceTree: .production,
                rules: [.featureBoundary],
                expectedLine: 1,
                expectedReference: #"\.buyLedgerDatabase"#,
                expectedReason: "Feature 不得直接取得 Database、Client 或 Store"
            ),
            DependencyScanViolationCase(
                name: "Feature 在 DataSomething 目錄讀取 Store",
                source: #"@Dependency(\.userDefaultsStore) private var store"#,
                relativePath: "Features/Orders/DataSomething/OrderFeature.swift",
                sourceTree: .production,
                rules: [.featureBoundary],
                expectedLine: 1,
                expectedReference: #"\.userDefaultsStore"#,
                expectedReason: "Feature 不得直接取得 Database、Client 或 Store"
            ),
            DependencyScanViolationCase(
                name: "Feature Views 目錄中的 Data.swift 讀取 App configuration",
                source: "$0.appConfigurationStore",
                relativePath: "Features/Orders/Views/Data.swift",
                sourceTree: .production,
                rules: [.featureBoundary],
                expectedLine: 1,
                expectedReference: "$0.appConfigurationStore",
                expectedReason: "Feature 不得直接取得 Database、Client 或 Store"
            ),
            DependencyScanViolationCase(
                name: "Feature 直接使用 SwiftData context",
                source: "let context: ModelContext",
                relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
                sourceTree: .production,
                rules: [.featureBoundary],
                expectedLine: 1,
                expectedReference: "ModelContext",
                expectedReason: "Feature 不得直接使用 SwiftData context 或 container"
            ),
            DependencyScanViolationCase(
                name: "Service 透過 key path 取得另一個 Service",
                source: #"@Dependency(\.settingsService) private var settingsService"#,
                relativePath: "Features/Orders/Data/Order/OrderService.swift",
                sourceTree: .production,
                rules: [.featureBoundary],
                expectedLine: 1,
                expectedReference: #"@Dependency(\.settingsService"#,
                expectedReason: "Service 不得取得另一個 Service"
            ),
            DependencyScanViolationCase(
                name: "Service 直接讀取另一個 live value",
                source: "SettingsService.liveValue",
                relativePath: "Features/Orders/Data/Order/OrderService.swift",
                sourceTree: .production,
                rules: [.featureBoundary],
                expectedLine: 1,
                expectedReference: "SettingsService.liveValue",
                expectedReason: "Service 不得取得另一個 Service"
            ),
        ]
    }

    /// Feature 與 Service 邊界規則應接受的案例，由 `DependencyConventionScanScenario` 彙總
    static var boundaryPassingCases: [DependencyScanPassingCase] {
        [
            DependencyScanPassingCase(
                name: "Feature Data 可存取 Database 與 context",
                source: #"""
                @Dependency(\.buyLedgerDatabase) private var database
                let context: ModelContext
                """#,
                relativePath: "Features/Orders/Data/Order/OrderService.swift",
                sourceTree: .production,
                rules: [.featureBoundary]
            ),
            DependencyScanPassingCase(
                name: "沒有加號的 Service 檔可引用自身",
                source: #"@Dependency(\.settingsService) private var settingsService"#,
                relativePath: "Features/Settings/Data/SettingsService.swift",
                sourceTree: .production,
                rules: [.featureBoundary]
            ),
            DependencyScanPassingCase(
                name: "縮寫開頭的 Service 檔可引用自身",
                source: #"@Dependency(\.aiSummaryService) private var service"#,
                relativePath: "Features/AISummary/Data/AISummaryService.swift",
                sourceTree: .production,
                rules: [.featureBoundary]
            ),
        ]
    }
}
