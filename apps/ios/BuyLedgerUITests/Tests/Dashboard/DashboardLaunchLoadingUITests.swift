//
//  DashboardLaunchLoadingUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/7.
//

import XCTest

/// 首頁冷啟動的開團載入與首次訂單讀取失敗後重試的 UI 測試
@MainActor
final class DashboardLaunchLoadingUITests: BLUITestCase {

    /// 驗證冷啟動停在首頁時，首頁的開團卡列出進行中的四月韓國團
    ///
    /// - Throws: App 啟動失敗、首頁未就緒或開團列無法捲入可見範圍時丟出測試錯誤
    func testTask_冷啟動停在首頁_開團卡列出進行中開團() throws {
        // Given
        let options = LaunchOptions(seed: .campaignsWithOrders)
        let campaignID = CampaignSeedFixture.koreaCampaignID

        // When
        let app = try launch(options)
        let dashboard = DashboardScreen(app: app)
        try requireCondition(dashboard.waitUntilReady(), in: app, "冷啟動停在首頁時訂單資料未載入")
        try dashboard.revealOngoingCampaign(campaignID: campaignID)

        // Then
        XCTAssertTrue(
            dashboard.hasOngoingCampaign(campaignID: campaignID, timeout: 0),
            "首頁開團卡沒有內容，未列出進行中的四月韓國團"
        )
        XCTAssertTrue(
            dashboard.ongoingCampaignRow(campaignID: campaignID).isHittableOnScreen,
            "首頁開團卡的四月韓國團未捲入可見範圍"
        )
    }

    /// 驗證首次讀取訂單失敗時，首頁顯示載入失敗，按下重試成功後失敗畫面消失，並出現種子中的近期訂單
    ///
    /// - Throws: App 啟動、載入失敗前置、重試操作或近期訂單捲入可見範圍未完成時丟出測試錯誤
    func testRetryTapped_首次訂單讀取失敗_重試後顯示訂單資料() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .minimalOrders, loadFailure: .ordersFirstReadOnly))
        let dashboard = DashboardScreen(app: app)
        try requireCondition(dashboard.waitForLoadFailure(), in: app, "首次訂單讀取失敗後首頁未顯示載入失敗")

        // When
        try dashboard.tapRetry()
        try requireCondition(dashboard.waitUntilReady(), in: app, "點重試後首頁未顯示已載入內容")
        try requireCondition(dashboard.waitForLoadFailureDismissal(), in: app, "重試成功後首頁仍顯示載入失敗")
        try dashboard.revealRecentOrder(orderID: "UITEST-MIN-001")

        // Then
        XCTAssertTrue(
            dashboard.recentOrderRow(orderID: "UITEST-MIN-001").isHittableOnScreen,
            "重試成功後近期訂單未能捲入可見範圍"
        )
    }
}
