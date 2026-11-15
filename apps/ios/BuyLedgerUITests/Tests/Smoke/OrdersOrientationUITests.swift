//
//  OrdersOrientationUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 裝置轉為橫向後的訂單頁版面 UI 測試，並附上橫向的訂單頁截圖
@MainActor
final class OrdersOrientationUITests: BLUITestCase {

    /// 驗證訂單頁轉為橫向後，前景欄位維持直向判定的版面類別，清單仍有可點的訂單列
    ///
    /// - Throws: 轉向未完成、訂單前景版面改變或清單沒有可點的訂單列時丟出測試錯誤
    /// - Note: 預期版面取自直向判定，斷言轉向前後版面不變
    ///   只適用直向與橫向同一版面的測試裝置 (iPhone 17、iPad Air)
    /// - Note: 截圖附件保留在 result bundle，供人工確認排列
    func testRotateToLandscape_含開團與訂單資料_訂單頁符合裝置版面() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let orders = try OrdersScreen.open(in: app)
        let expectedLayout = try ordersLayout(in: app)

        // When
        try rotateToLandscape(app)

        // Then
        let actualLayout = try ordersLayout(in: app)
        try requireCondition(
            actualLayout == expectedLayout,
            in: app,
            "橫向訂單頁的前景欄位版面不符預期 (預期: \(expectedLayout), 實際: \(actualLayout))"
        )
        try requireCondition(orders.hasHittableOrderRow(), in: app, "橫向訂單清單沒有可點的訂單列")
        try RootNavigationOrientationUITestSupport.attachScreenshot(
            named: "橫向訂單頁",
            of: app,
            to: self
        )
    }
}
