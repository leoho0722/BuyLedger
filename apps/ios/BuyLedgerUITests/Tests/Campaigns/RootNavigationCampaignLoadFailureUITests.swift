//
//  RootNavigationCampaignLoadFailureUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/9.
//

import XCTest

/// 開團載入失敗時切換分頁與重試的根導覽 UI 測試
@MainActor
final class RootNavigationCampaignLoadFailureUITests: BLUITestCase {

    /// 驗證開團載入失敗時，往返總覽與訂單後仍顯示失敗訊息與重試鍵
    ///
    /// - Throws: 分頁或穩定載入失敗狀態未就緒時丟出測試錯誤
    func testTabSelected_開團每次載入皆失敗_返回清單仍穩定顯示失敗畫面()
        throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders, loadFailure: .campaigns))
        let navigator = AppNavigator(app: app)
        let campaignsRoot = CampaignsScreen(app: app).destinationContainer
        let loading = campaignsRoot.progressIndicators.firstMatch

        // When
        try navigator.selectTab(.campaigns)

        // Then
        try requireCondition(
            campaignsRoot.waitForExistence(timeout: 10),
            in: app,
            "開團分頁根容器未出現，無法縮限載入指示器查詢範圍"
        )
        try assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Campaigns.listLoadFailure,
            present: [BLAccessibilityID.Campaigns.listLoadFailureRetryButton],
            absent: [],
            absentElements: [loading],
            context: "首次進入開團清單"
        )

        // When
        try navigator.selectTab(.dashboard)
        try navigator.selectTab(.campaigns)

        // Then
        try assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Campaigns.listLoadFailure,
            present: [BLAccessibilityID.Campaigns.listLoadFailureRetryButton],
            absent: [],
            absentElements: [loading],
            context: "切換總覽再返回開團清單"
        )

        // When
        try navigator.selectTab(.orders)
        try navigator.selectTab(.campaigns)

        // Then
        try assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Campaigns.listLoadFailure,
            present: [BLAccessibilityID.Campaigns.listLoadFailureRetryButton],
            absent: [],
            absentElements: [loading],
            context: "切換訂單再返回開團清單"
        )
    }

    /// 驗證開團載入失敗並重試後，分頁導覽仍可運作
    ///
    /// - Throws: 開團分頁、失敗畫面或重試入口未就緒時丟出測試錯誤
    /// - Note: 重試後切出再返回，確認導覽仍可運作且失敗畫面保留
    func testTabSelected_開團重試後_分頁仍可切換() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders, loadFailure: .campaigns))
        let root = RootNavigationScreen(app: app)
        try root.goToCampaigns()
        let campaigns = CampaignsScreen(app: app)
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
        try requireCondition(
            campaigns.waitForRetryButton(),
            in: app,
            "重試後載入失敗畫面沒有可點的重試鍵"
        )

        // When
        try root.goToDashboard()
        try root.goToCampaigns()

        // Then
        XCTAssertTrue(
            campaigns.waitForLoadFailure(timeout: 10),
            "切回後載入失敗畫面未顯示"
        )
        XCTAssertEqual(app.state, .runningForeground)
    }
}

