//
//  CampaignListTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團列表空狀態的 UI 測試
@MainActor
final class CampaignListTests: BLUITestCase {

    /// 驗證空資料時切到開團分頁，列表顯示尚無開團的空狀態
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
