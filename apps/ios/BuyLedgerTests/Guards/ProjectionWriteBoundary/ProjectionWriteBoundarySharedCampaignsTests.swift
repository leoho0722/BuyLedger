//
//  ProjectionWriteBoundarySharedCampaignsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Testing

/// 唯讀開團引用的單元測試，以掃描片段案例檢查讀取、傳遞與寫入邊界
struct ProjectionWriteBoundarySharedCampaignsTests {

    /// 驗證唯讀開團宣告後只允許讀取與傳遞，寫入與重綁仍由正式入口回報，違規筆數符合案例的預期值
    ///
    /// - Parameter scenario: 唯讀宣告後的操作與固定預期違規筆數
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    @Test(arguments: Self.readerCampaignProjectionScenarios)
    func projectionViolations_唯讀開團宣告檔_禁止寫入並允許讀取與傳遞(scenario: ReaderCampaignScenario) throws {
        // Given
        let source = "@SharedReader var campaigns: [Campaign]\n" + scenario.operation

        // When
        let violations = try ProjectionWriteBoundaryScanner.projectionViolations(
            relativePath: "Features/Orders/Presentation/OrderList/OrderListFeature.swift",
            source: source
        )

        // Then
        #expect(violations.count == scenario.expectedCount)
    }
}

// MARK: - Nested Types

extension ProjectionWriteBoundarySharedCampaignsTests {

    /// 唯讀開團引用的操作片段與預期違規筆數
    struct ReaderCampaignScenario: Sendable {

        /// 唯讀宣告後的讀取、傳遞或寫入片段
        let operation: String

        /// 固定預期違規筆數
        let expectedCount: Int
    }
}

// MARK: - Private Method

private extension ProjectionWriteBoundarySharedCampaignsTests {

    /// 唯讀投影的直接寫入、根路徑寫入、合法讀取與傳遞案例
    static var readerCampaignProjectionScenarios: [ReaderCampaignScenario] {
        [
            ReaderCampaignScenario(
                operation: "state.$campaigns.withLock { $0 = [] }",
                expectedCount: 1
            ),
            ReaderCampaignScenario(
                operation: "root.orders.$campaigns = replacement",
                expectedCount: 1
            ),
            ReaderCampaignScenario(operation: "state.$campaigns = replacement", expectedCount: 1),
            ReaderCampaignScenario(
                operation: "state.$campaigns.wrappedValue = []",
                expectedCount: 1
            ),
            ReaderCampaignScenario(
                operation: "root.orders.$campaigns.withLock { $0 = [] }",
                expectedCount: 1
            ),
            ReaderCampaignScenario(
                operation: "root.orders.$campaigns.wrappedValue = []",
                expectedCount: 1
            ),
            ReaderCampaignScenario(
                operation: "state.$campaigns\n    .wrappedValue\n    = []",
                expectedCount: 1
            ),
            ReaderCampaignScenario(
                operation: "let snapshot = state.$campaigns.wrappedValue",
                expectedCount: 0
            ),
            ReaderCampaignScenario(
                operation: "let isEmpty = state.$campaigns.wrappedValue == []",
                expectedCount: 0
            ),
            ReaderCampaignScenario(
                operation: "OrderFilterFeature.State(campaigns: state.$campaigns)",
                expectedCount: 0
            ),
            ReaderCampaignScenario(
                operation: "// state.$campaigns.withLock { $0 = [] }",
                expectedCount: 0
            ),
            ReaderCampaignScenario(
                operation: "let example = \"state.$campaigns.wrappedValue = []\"",
                expectedCount: 0
            ),
        ]
    }
}
