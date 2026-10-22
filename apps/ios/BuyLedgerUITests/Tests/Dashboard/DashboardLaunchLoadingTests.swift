//
//  DashboardLaunchLoadingTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/7.
//

import XCTest

/// 首頁冷啟動的開團載入與首次訂單讀取失敗後重試測試
final class DashboardLaunchLoadingTests: BLUITestCase {

    // MARK: - Properties

    /// `campaignsWithOrders` 中進行中的四月韓國團編號
    private static let koreaCampaignID = "CMP-SAMPLE-KR-APR"

    /// 冷啟動停在首頁時，開團卡應列出四月韓國團
    @MainActor
    func testDashboardLaunch_停在首頁_開團卡列出進行中開團() {
        // Given
        let options = LaunchOptions(seed: .campaignsWithOrders)

        // When
        let app = launch(options)
        let dashboard = DashboardScreen(app: app)

        // Then
        if !dashboard.waitUntilReady() {
            failWithDiagnostics(in: app, "冷啟動停在首頁時訂單資料未載入")
        }
        let hasOngoingCampaign = dashboard.hasOngoingCampaign(campaignID: Self.koreaCampaignID)
        if !hasOngoingCampaign {
            failWithDiagnostics(in: app, "首頁開團卡沒有內容，未列出進行中的四月韓國團")
        }
    }

    /// 首次讀取訂單失敗時顯示失敗與重試按鈕，重試成功後顯示近期訂單
    @MainActor
    func testDashboardRetry_首次訂單讀取失敗_重試後顯示訂單資料() {
        // Given
        let app = launch(LaunchOptions(seed: .minimalOrders, loadFailure: .ordersFirstReadOnly))
        let dashboard = DashboardScreen(app: app)
        if !dashboard.waitForLoadFailure() {
            failWithDiagnostics(in: app, "首次訂單讀取失敗後首頁未顯示載入失敗")
        }

        // When
        dashboard.tapRetry()

        // Then
        if !dashboard.waitUntilReady() {
            failWithDiagnostics(in: app, "點重試後首頁未顯示已載入內容")
        }
        if !dashboard.waitForLoadFailureDismissal() {
            failWithDiagnostics(in: app, "重試成功後首頁仍顯示載入失敗")
        }
        let recentOrder = dashboard.recentOrderRow(orderID: "UITEST-MIN-001")
        if !recentOrder.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "重試成功後近期訂單未出現種子訂單")
        }
        if !app.scrollToHittable(recentOrder, within: dashboard.rootElement) {
            failWithDiagnostics(in: app, "重試成功後近期訂單未能捲入可見範圍")
        }
    }
}
