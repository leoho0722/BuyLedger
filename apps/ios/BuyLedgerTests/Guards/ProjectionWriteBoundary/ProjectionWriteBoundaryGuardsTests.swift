//
//  ProjectionWriteBoundaryGuardsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Foundation
import Testing

/// 共享訂單投影寫入邊界的單元測試，涵蓋正式原始碼掃描與片段違規案例
struct ProjectionWriteBoundaryGuardsTests {

    // MARK: - Properties

    /// App target 檔案數量下限
    private static let minimumProductionFileCount = 100

    /// 涵蓋完整路徑、值參數、唯讀轉換，以及註解與字串的守門案例
    private static let sharedOrderScenarios: [ProjectionWriteBoundaryScenario] = [
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/OrderWrites/OrdersCascadeOperations.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
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
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Campaigns/Presentation/Root/CampaignFeature.swift",
            source: "state.campaigns.$orders.withLock { $0 = [] }",
            expectedCount: 2
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Campaigns/Presentation/Root/CampaignFeature.swift",
            source: "CampaignListFeature.State(orders: state.$orders)",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Campaigns/Presentation/Root/CampaignFeature.swift",
            source: "SharedReader(state.$orders)",
            expectedCount: 0
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/App/Presentation/Root/RootFeature.swift",
            source: "state.campaigns.$orders.withLock { $0 = orders }",
            expectedCount: 0
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Campaigns/Presentation/Root/CampaignFeature.swift",
            source: "let orders = state.$orders",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Campaigns/Presentation/Root/CampaignFeature.swift",
            source: "SharedReader(\n    state.campaigns.$orders\n)",
            expectedCount: 0
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Campaigns/Presentation/Root/CampaignFeature.swift",
            source: "// state.$orders.withLock { $0 = [] }\n/* let orders = state.$orders */",
            expectedCount: 0
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Campaigns/Presentation/Root/CampaignFeature.swift",
            source: "let example = \"state.$orders.withLock { $0 = [] }\"",
            expectedCount: 0
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/More/Presentation/Root/MoreFeature.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 2
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/More/Presentation/Root/MoreFeature.swift",
            source: "CustomersFeature.State(orders: state.$orders)",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/More/Presentation/Root/MoreFeature.swift",
            source: "let leakedOrders = state.$orders",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/More/Presentation/Root/MoreFeature.swift",
            source: "CustomersFeature.State(orders: SharedReader(\n    state.more.$orders\n))",
            expectedCount: 0
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/App/Presentation/Root/RootFeature.swift",
            source: "state.more.$orders.withLock { $0 = orders }",
            expectedCount: 0
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/OrderWrites/OrdersCascadeOperations.swift",
            source: "state.campaigns.$orders.withLock { $0 = orders }",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/OrderWrites/OrdersCascadeOperations.swift",
            source: "state.more.$orders.withLock { $0 = orders }",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/OrderWrites/OrdersCascadeOperations.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
    ]

    /// 訂單資料來源的合法寫入者、唯讀訂單狀態與 helper 的正反案例
    private static let sharedOrderWriterScenarios: [ProjectionWriteBoundaryScenario] = [
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Other/OrdersFeature.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/OrdersLoad/OrdersLoadFeature.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 0
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Other/OrdersLoadFeature.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/OrderWrites/OrderWritesFeature.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 0
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Other/OrderWritesFeature.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/OrderList/Operations/OrdersBatchOperations.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/OrderList/Operations/OrdersBatchOperations.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/Root/Plans/OrdersMergeFlowOperations.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/Root/Plans/OrdersMergeFlowOperations.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/OrderEdit/Models/OrderDraft+WriteResult.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/OrderEdit/Models/OrderDraft+WriteResult.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/Root/Views/OrdersView.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/Root/Views/OrdersView.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/Root/Views/OrdersCompactView.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/Root/Views/OrdersCompactView.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/Root/Views/OrdersRegularListColumn.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/Root/Views/OrdersRegularListColumn.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/Root/Views/OrdersRegularDetailColumn.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/Orders/Presentation/Root/Views/OrdersRegularDetailColumn.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/App/Presentation/Root/RootSidebarLayout.swift",
            source: "state.$orders.withLock { $0 = [] }",
            expectedCount: 1
        ),
        ProjectionWriteBoundaryScenario(
            relativePath: "Features/App/Presentation/Root/RootSidebarLayout.swift",
            source: "OrdersFeature.State(orders: orders)",
            expectedCount: 0
        ),
    ]

    /// 驗證投影擁有者宣告的主檔路徑都存在於 App 原始碼，清單過時時會列出缺漏的主檔
    @Test
    func projectionOwners_檢查主檔路徑_全部存在() {
        // Given
        let owners = ProjectionWriteBoundaryScanner.projectionOwners

        // When
        let missingOwners = owners.filter {
            !FileManager.default.fileExists(
                atPath: ProjectionWriteBoundaryScanner.productionRoot.appending(
                    path: $0.homeFileRelativePath
                ).path
            )
        }

        // Then
        #expect(missingOwners.isEmpty, "找不到主檔，投影清單已過時：\(missingOwners.map(\.homeFileRelativePath))")
    }

    /// 驗證 App 原始碼的檔案數達下限，且每個投影擁有者都掃得到 `struct` 宣告
    ///
    /// - Throws: 原始檔讀取或規則建立失敗時丟出錯誤
    @Test
    func hasStructDeclaration_正式原始碼_找到所有擁有者() throws {
        // Given
        let files = try SwiftSourceFiles.swiftFiles(
            under: ProjectionWriteBoundaryScanner.productionRoot
        )
        let owners = ProjectionWriteBoundaryScanner.projectionOwners

        // When
        let declarations = try owners.map {
            try ProjectionWriteBoundaryPatterns.hasStructDeclaration(owner: $0, in: files)
        }

        // Then
        #expect(
            files.count >= Self.minimumProductionFileCount,
            "App target Swift 檔案數量不足，productionRoot：\(ProjectionWriteBoundaryScanner.productionRoot.path)"
        )
        for (owner, isFound) in zip(owners, declarations) {
            #expect(isFound, "掃描不到 `struct \(owner.name)` 的宣告，掃描機制或 projectionOwners.name 疑似與現況脫節")
        }
    }

    /// 驗證正式原始碼中沒有寫入唯讀投影的位置，投影一律只能由 `RootFeature.swift` 寫入
    ///
    /// - Throws: 原始檔讀取或規則建立失敗時丟出錯誤
    @Test
    func findViolations_掃描正式原始碼_只有根功能寫入投影() throws {
        // Given
        let expectedViolationCount = 0

        // When
        let violations = try ProjectionWriteBoundaryScanner.findViolations()

        // Then
        #expect(
            violations.count == expectedViolationCount,
            "以下位置寫入了唯讀投影，投影一律只能由 RootFeature 寫入：\(ProjectionWriteBoundaryPatterns.describe(violations))"
        )
    }

    /// 驗證共享訂單只由擁有者寫入，開團與更多功能只取得唯讀參考，沒有投影寫入或可寫參考外傳
    ///
    /// - Throws: 原始檔讀取或規則建立失敗時丟出錯誤
    @Test
    func sharedOrderViolations_掃描正式原始碼_沒有投影寫入或可寫參考外傳() throws {
        // Given
        let files = try SwiftSourceFiles.swiftFiles(
            under: ProjectionWriteBoundaryScanner.productionRoot
        )
        var violations: [ProjectionWriteBoundaryScanner.Violation] = []

        // When
        for file in files {
            let relativePath = SwiftSourceFiles.relativePath(
                of: file,
                under: ProjectionWriteBoundaryScanner.productionRoot
            )
            let source = try String(contentsOf: file, encoding: .utf8)
            violations += try ProjectionWriteBoundaryScanner.sharedOrderViolations(
                relativePath: relativePath,
                source: source
            )
        }

        // Then
        #expect(files.count >= Self.minimumProductionFileCount)
        #expect(
            violations.isEmpty,
            "共享訂單投影違規：\(ProjectionWriteBoundaryPatterns.describe(violations))"
        )
    }

    /// 驗證每個原始碼片段的共享訂單違規筆數都符合案例的預期值，涵蓋寫入邊界與唯讀轉換
    ///
    /// - Parameter scenario: 檔案路徑、原始碼與預期違規筆數
    /// - Throws: 規則建立失敗時丟出錯誤
    @Test(arguments: Self.sharedOrderScenarios + Self.sharedOrderWriterScenarios)
    func sharedOrderViolations_套用路徑與原始碼_符合預期違規筆數(scenario: ProjectionWriteBoundaryScenario) throws {
        // Given
        let relativePath = scenario.relativePath
        let source = scenario.source

        // When
        let violations = try ProjectionWriteBoundaryScanner.sharedOrderViolations(
            relativePath: relativePath,
            source: source
        )

        // Then
        #expect(violations.count == scenario.expectedCount)
    }
}
