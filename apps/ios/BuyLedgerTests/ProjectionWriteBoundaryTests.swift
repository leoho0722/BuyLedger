//
//  ProjectionWriteBoundaryTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/2.
//

import Foundation
import Testing

/// 確認投影只有 `RootFeature` 可以寫入
struct ProjectionWriteBoundaryTests {

    // MARK: - Properties

    /// 涵蓋完整路徑、值參數、唯讀轉換，以及註解與字串的守門案例
    private static let sharedOrderScenarios: [SharedOrderScenario] = [
        SharedOrderScenario(
            relativePath: "Features/App/RootCascadeOperations.swift",
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
    ]

    /// RootFeature.swift 的相對路徑；掃描時排除唯一合法寫入者
    static let rootFeatureRelativePath = "Features/App/RootFeature.swift"

    /// Generated 目錄不納入掃描
    static let excludedDirectoryName = "Generated"

    /// App target 檔案數量下限
    private static let minimumProductionFileCount = 100

    /// 各 feature 持有的投影屬性
    static let projectionOwners: [ProjectionOwner] = [
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
            properties: ["orders", "campaigns", "monthlyProfitGoalTwd", "loadState"]
        ),
        ProjectionOwner(
            name: "InsightsFeature",
            rootStateKey: "insights",
            homeFileRelativePath: "Features/Insights/InsightsFeature.swift",
            properties: ["orders", "campaigns", "loadState"]
        ),
    ]

    /// 可能改變陣列或字典內容的 mutating 方法
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

    /// 確認投影持有者檔案都存在
    @Test
    func projectionOwners_檢查主檔路徑_全部存在() {
        // Given
        let owners = Self.projectionOwners

        // When
        let missingOwners = owners.filter {
            !FileManager.default.fileExists(
                atPath: Self.productionRoot.appending(path: $0.homeFileRelativePath).path
            )
        }

        // Then
        #expect(missingOwners.isEmpty, "找不到主檔，投影清單已過時：\(missingOwners.map(\.homeFileRelativePath))")
    }

    /// 驗證掃描涵蓋足夠的 App 檔案並找到投影擁有者宣告
    ///
    /// - Throws: 原始檔讀取或規則建立失敗時拋出錯誤
    @Test
    func hasStructDeclaration_正式原始碼_找到所有擁有者() throws(any Error) {
        // Given
        let files = try Self.swiftFiles(under: Self.productionRoot)
        let owners = Self.projectionOwners

        // When
        let declarations = try owners.map {
            try Self.hasStructDeclaration(owner: $0, in: files)
        }

        // Then
        #expect(
            files.count >= Self.minimumProductionFileCount,
            "App target Swift 檔案數量不足，productionRoot：\(Self.productionRoot.path)"
        )
        for (owner, isFound) in zip(owners, declarations) {
            #expect(isFound, "掃描不到 `struct \(owner.name)` 的宣告，掃描機制或 projectionOwners.name 疑似與現況脫節")
        }
    }

    /// 驗證投影屬性只能由 RootFeature.swift 寫入
    ///
    /// - Throws: 原始檔讀取或規則建立失敗時拋出錯誤
    @Test
    func findViolations_掃描正式原始碼_只有根功能寫入投影() throws(any Error) {
        // Given
        let expectedViolationCount = 0

        // When
        let violations = try Self.findViolations()

        // Then
        #expect(
            violations.count == expectedViolationCount,
            "以下位置寫入了唯讀投影，投影一律只能由 RootFeature 寫入：\(Self.describe(violations))"
        )
    }

    /// 共享訂單投影只允許根功能寫入，開團與更多功能只能轉成唯讀參考
    ///
    /// - Throws: 原始檔讀取或規則建立失敗時拋出錯誤
    @Test
    func sharedOrderViolations_掃描正式原始碼_沒有投影寫入或可寫參考外傳() throws(any Error) {
        // Given
        let files = try Self.swiftFiles(under: Self.productionRoot)
        var violations: [Violation] = []

        // When
        for file in files {
            let relativePath = Self.relativePath(of: file, under: Self.productionRoot)
            let source = try String(contentsOf: file, encoding: .utf8)
            violations += try Self.sharedOrderViolations(relativePath: relativePath, source: source)
        }

        // Then
        #expect(files.count >= Self.minimumProductionFileCount)
        #expect(violations.isEmpty, "共享訂單投影違規：\(Self.describe(violations))")
    }

    /// 以原始碼片段驗證共享訂單的寫入邊界與唯讀轉換規則
    ///
    /// - Parameter scenario: 檔案路徑、原始碼與預期違規筆數
    /// - Throws: 規則建立失敗時拋出錯誤
    @Test(arguments: Self.sharedOrderScenarios)
    func sharedOrderViolations_套用路徑與原始碼_符合預期違規筆數(scenario: SharedOrderScenario) throws(any Error) {
        // Given
        let relativePath = scenario.relativePath
        let source = scenario.source

        // When
        let violations = try Self.sharedOrderViolations(relativePath: relativePath, source: source)

        // Then
        #expect(violations.count == scenario.expectedCount)
    }
}

// MARK: - Computed Properties

extension ProjectionWriteBoundaryTests {

    /// App target 的掃描根目錄
    static var productionRoot: URL {
        iosRoot.appending(path: "BuyLedger")
    }
}

// MARK: - Private Method

private extension ProjectionWriteBoundaryTests {

    /// 測試 target 所在的 iOS 平台目錄
    static var iosRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
