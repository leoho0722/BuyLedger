//
//  DashboardOrientationUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 裝置轉為橫向後的總覽版面 UI 測試，並附上橫向的首頁截圖
@MainActor
final class DashboardOrientationUITests: BLUITestCase {

    /// 驗證首頁轉為橫向後，根導覽維持直向判定的版面類別，營收 KPI 卡捲入可見範圍後水平落在視窗內
    ///
    /// - Throws: 轉向未完成、根導覽版面改變或營收 KPI 卡不在視窗內時丟出測試錯誤
    /// - Note: 預期版面取自直向判定，斷言轉向前後版面不變
    ///   只適用直向與橫向同一版面的測試裝置 (iPhone 17、iPad Air)
    /// - Note: 截圖附件保留在 result bundle，供人工確認排列
    func testRotateToLandscape_含開團與訂單資料_首頁符合裝置版面() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let dashboard = try DashboardScreen.open(in: app)
        try requireCondition(dashboard.waitUntilReady(), in: app, "直向啟動後總覽內容未就緒")
        let navigator = AppNavigator(app: app)
        let expectedLayout = try navigator.rootLayout()

        // When
        try rotateToLandscape(app)
        let revenueTile = dashboard.kpiTile(.revenue)
        try requireCondition(
            app.stableVisibleFrame(of: revenueTile, within: dashboard.rootElement) != nil,
            in: app,
            "橫向首頁的營收 KPI 卡無法捲入可見範圍"
        )

        // Then
        let actualLayout = try navigator.rootLayout()
        try requireCondition(
            actualLayout == expectedLayout,
            in: app,
            "橫向首頁的根導覽版面不符預期 (預期: \(expectedLayout), 實際: \(actualLayout))"
        )
        try RootNavigationOrientationUITestSupport.attachScreenshot(
            named: "橫向首頁",
            of: app,
            to: self
        )
        let revenueValue = revenueTile.value as? String
        try requireCondition(revenueValue != nil, in: app, "橫向首頁沒有營收 KPI 卡")
        let tileFrame = try requireValidFrame(of: revenueTile, in: app, context: "橫向營收 KPI 卡")
        let windowFrame = try requireValidFrame(
            of: app.windows.firstMatch,
            in: app,
            context: "App 視窗"
        )
        try requireCondition(
            tileFrame.minX >= windowFrame.minX - 1 && tileFrame.maxX <= windowFrame.maxX + 1,
            in: app,
            "橫向首頁的營收 KPI 卡越出視窗水平範圍 (KPI 卡: \(tileFrame), 視窗: \(windowFrame))"
        )
        try RootNavigationOrientationUITestSupport.attachScreenshot(
            named: "橫向首頁 KPI 卡",
            of: app,
            to: self
        )
    }
}
