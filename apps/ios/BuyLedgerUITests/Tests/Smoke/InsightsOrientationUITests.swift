//
//  InsightsOrientationUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 裝置轉為橫向後的分析頁版面 UI 測試，並附上橫向的分析頁截圖
@MainActor
final class InsightsOrientationUITests: BLUITestCase {

    /// 驗證分析頁轉為橫向後，根導覽維持直向判定的版面類別，類別排行列與成本結構圖都能捲入可見範圍
    ///
    /// - Throws: 轉向未完成、根導覽版面改變或類別排行與成本結構圖無法露出時丟出測試錯誤
    /// - Note: 預期版面取自直向判定，斷言轉向前後版面不變
    ///   只適用直向與橫向同一版面的測試裝置 (iPhone 17、iPad Air)
    /// - Note: 截圖附件保留在 result bundle，供人工確認排列
    func testRotateToLandscape_含開團與訂單資料_分析頁符合裝置版面() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let insights = try InsightsScreen.open(in: app)
        try requireCondition(insights.waitUntilReady(), in: app, "直向啟動後分析頁未就緒")
        let navigator = AppNavigator(app: app)
        let expectedLayout = try navigator.rootLayout()

        // When
        try rotateToLandscape(app)
        try insights.revealFirstCategoryRank()

        // Then
        let actualLayout = try navigator.rootLayout()
        try requireCondition(
            actualLayout == expectedLayout,
            in: app,
            "橫向分析頁的根導覽版面不符預期 (預期: \(expectedLayout), 實際: \(actualLayout))"
        )
        try RootNavigationOrientationUITestSupport.attachScreenshot(
            named: "橫向分析頁 類別排行",
            of: app,
            to: self
        )

        // When
        try insights.revealCostDonut()

        // Then
        try RootNavigationOrientationUITestSupport.attachScreenshot(
            named: "橫向分析頁 成本結構",
            of: app,
            to: self
        )
    }
}
