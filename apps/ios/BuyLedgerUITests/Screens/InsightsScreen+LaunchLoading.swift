//
//  InsightsScreen+LaunchLoading.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/8.
//

import XCTest

// MARK: - Internal Method

@MainActor
extension InsightsScreen {

    /// 等指定開團的毛利排行列出現在可及性樹上
    ///
    /// - Parameter campaignID: 開團識別值
    /// - Returns: 是否找到該排行列
    /// - Note: 排行在惰性容器內，畫面外的列查 `isHittable` 會因 `frame` 無效而報錯，只確認列已出現
    func hasCampaignRank(campaignID: String) -> Bool {
        let row = app.descendants(matching: .any)[
            BLAccessibilityID.Insights.campaignRankRow(campaignID: campaignID)
        ]
        return row.waitForExistence(timeout: 10)
    }
}
