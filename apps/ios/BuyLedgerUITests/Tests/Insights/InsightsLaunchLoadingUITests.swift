//
//  InsightsLaunchLoadingUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/8.
//

import XCTest

/// 冷啟動直接開分析頁時，開團毛利排行載入的 UI 測試
@MainActor
final class InsightsLaunchLoadingUITests: BLUITestCase {

    // MARK: - Properties

    /// 有歸屬訂單的兩個開團唯一識別碼，位於 `campaignsWithOrders` 種子中
    private static let campaignIDs = [CampaignSeedFixture.koreaCampaignID, "CMP-SAMPLE-JP-MAR"]

    /// 驗證冷啟動先開分析頁時，每團毛利排行列出兩個開團，不需先進入開團分頁
    ///
    /// - Throws: 分析頁未就緒或內容未載入時丟出測試錯誤
    func testTask_冷啟動先開分析頁_每團毛利排行列出開團() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let insights = try InsightsScreen.open(in: app)

        // When
        try requireCondition(insights.waitUntilReady(), in: app, "冷啟動先開分析頁時內容未載入")

        // Then
        for campaignID in Self.campaignIDs {
            if !insights.hasCampaignRank(campaignID: campaignID) {
                failWithDiagnostics(in: app, "分析頁每團毛利排行未列出開團 \(campaignID)")
                return
            }
        }
    }
}
