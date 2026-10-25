//
//  LaunchSmokeTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 啟動與分頁切換的冒煙 UI 測試
@MainActor
final class LaunchSmokeTests: BLUITestCase {

    /// 驗證從總覽依序切過其他四個分頁時，每次切換後目的地畫面都就緒，切回總覽後總覽畫面也就緒
    ///
    /// - Throws: 根導覽或前四次分頁切換的前置條件不成立時丟出測試錯誤
    /// - Note: 情境流程：煙霧測試依序切過四個分頁，前四次切換放 Given，切回總覽為受測動作
    func testGoToDashboard_依序切過其他四個分頁後_總覽畫面就緒() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒，總覽頁根 identifier 逾時仍未出現")
        // 前四次切換當下就確認就緒，失敗時的診斷截圖停在出錯的分頁
        try requireCondition(root.goToOrders(), in: app, "切換到「訂單」分頁後畫面未就緒")
        try requireCondition(root.goToCampaigns(), in: app, "切換到「開團」分頁後畫面未就緒")
        try requireCondition(root.goToInsights(), in: app, "切換到「分析」分頁後畫面未就緒")
        try requireCondition(root.goToMore(), in: app, "切換到「更多」分頁後畫面未就緒")

        // When
        let isDashboardReady = root.goToDashboard()

        // Then
        if !isDashboardReady {
            failWithDiagnostics(in: app, "從更多切回「總覽」分頁後畫面未就緒")
        }
    }
}
