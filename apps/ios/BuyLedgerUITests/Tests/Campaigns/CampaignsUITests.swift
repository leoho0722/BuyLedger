//
//  CampaignsUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團列表的 UI 測試，涵蓋空狀態、載入失敗與詳情選取
@MainActor
final class CampaignsUITests: BLUITestCase {

    /// 驗證空資料時開團列表顯示尚無開團的空狀態
    ///
    /// - Throws: 開團畫面或空狀態未就緒時丟出測試錯誤
    func testTask_空資料_顯示空狀態() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))

        // When
        _ = try CampaignsScreen.open(in: app)

        // Then
        try assertEmptyState(BLAccessibilityID.Campaigns.listEmptyState, in: app)
    }

    /// 驗證開團每次載入都失敗時，重試後仍顯示失敗畫面與重試鍵
    ///
    /// - Throws: 開團畫面、失敗訊息或重試入口未就緒時丟出測試錯誤
    func testRetryTapped_每次載入皆失敗_仍顯示失敗畫面與重試鍵() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders, loadFailure: .campaigns))
        let campaigns = try CampaignsScreen.open(in: app)
        try requireCondition(
            campaigns.waitForLoadFailure(),
            in: app,
            "未出現開團載入失敗畫面"
        )
        try requireCondition(
            campaigns.waitForRetryButton(),
            in: app,
            "載入失敗畫面沒有可點的重試鍵"
        )

        // When
        try campaigns.tapRetry()

        // Then
        XCTAssertTrue(
            campaigns.waitForLoadFailure(timeout: 10),
            "重試後載入失敗畫面未持續顯示"
        )
        XCTAssertTrue(
            campaigns.waitForRetryButton(),
            "重試後載入失敗畫面沒有可點的重試鍵"
        )
        XCTAssertEqual(app.state, .runningForeground)
    }

    /// 驗證收合版面返回清空選取，轉成並排版面後詳情欄顯示未選取提示
    ///
    /// - Throws: 開團畫面或詳情未就緒時丟出測試錯誤；不支援的版面會略過
    /// - Note: 對應驗收矩陣 N3
    func testDetailSelectionChanged_收合版返回後轉橫向_清空選取並顯示空詳情提示() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        defer {
            XCUIDevice.shared.orientation = .portrait
            _ = waitForPortraitWindow(of: app)
        }
        let campaigns = try CampaignsScreen.open(in: app)
        if try campaignLayout(in: app) != .compact {
            try rotateToPortrait(app)
        }
        try XCTSkipUnless(
            try campaignLayout(in: app) == .compact,
            "原生返回鍵只存在於收合版面，此裝置無法建立收合版面"
        )
        let initialSelection = try requireValue(
            campaigns.selectedCampaignID(),
            in: app,
            "初次載入未出現開團選取標記"
        )
        try requireCondition(initialSelection == "", in: app, "初次載入不應已選取開團")

        // When
        let detail = try campaigns.openDetail(campaignID: CampaignSeedFixture.koreaCampaignID)

        // Then
        try requireCondition(
            campaigns.selectedCampaignID() == CampaignSeedFixture.koreaCampaignID,
            in: app,
            "收合版面的選取標記未指向四月韓國團"
        )

        // When
        try detail.tapBack()

        // Then
        XCTAssertTrue(campaigns.waitUntilReady(), "返回後開團列表未就緒")
        XCTAssertEqual(campaigns.selectedCampaignID(), "", "原生返回後選取標記應清空")

        // When
        try rotateToLandscape(app)
        try XCTSkipUnless(
            try campaignLayout(in: app) == .regular,
            "此裝置無法展開為並排版面，略過展開後的未選取提示驗證"
        )

        // Then
        XCTAssertTrue(
            campaigns.isDetailEmptyStateShown,
            "展開後詳情欄未顯示未選取提示"
        )
        XCTAssertEqual(campaigns.selectedCampaignID(), "", "展開後選取標記應維持為空")
    }
}

