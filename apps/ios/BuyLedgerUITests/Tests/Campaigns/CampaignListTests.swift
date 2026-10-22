//
//  CampaignListTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團列表的空狀態測試
final class CampaignListTests: BLUITestCase {

    /// 空資料庫時，開團列表顯示尚無開團的空狀態
    @MainActor
    func testGoToCampaigns_空資料_顯示空狀態() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        let root = RootNavigationScreen(app: app)

        // When
        let isCampaignsReady = root.goToCampaigns()

        // Then
        if !isCampaignsReady {
            failWithDiagnostics(in: app, "切到開團分頁後畫面未就緒")
        }
        assertEmptyState(BLAccessibilityID.Campaigns.listEmptyState, in: app)
    }
}
