//
//  RootNavigationOrientationUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/4.
//

import XCTest

/// 裝置轉為橫向後的根導覽與訂單篩選版面 UI 測試
@MainActor
final class RootNavigationOrientationUITests: BLUITestCase {

    /// 驗證轉為橫向後，根導覽與訂單篩選各自符合裝置版面
    ///
    /// - Throws: 轉向未完成，或根導覽與訂單篩選的版面不符預期時丟出測試錯誤
    /// - Note: 根導覽依 `AppNavigator` 判定，訂單篩選依 `PlatformScope` 判定，兩者分開斷言
    func testRotateToLandscape_含開團與訂單資料_根導覽與訂單篩選符合裝置版面() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .campaignsWithOrders))
        let orders = try OrdersScreen.open(in: app)
        let navigator = AppNavigator(app: app)
        let rootLayout = try navigator.rootLayout()
        let isOrdersRegular = try ordersLayout(in: app) == .regular

        // When
        try rotateToLandscape(app)

        // Then
        try assertRootNavigation(navigator: navigator, in: app, expected: rootLayout)
        try assertOrdersFilter(orders, in: app, isRegular: isOrdersRegular)
    }
}

// MARK: - Private Method

private extension RootNavigationOrientationUITests {

    /// 斷言轉為橫向後的根導覽呈現：版面類別維持直向判定類別，compact 額外斷言有底部分頁列且無側邊欄
    ///
    /// - Parameters:
    ///   - navigator: 根導覽 helper
    ///   - app: 受測 App
    ///   - expected: 預期的根導覽版面類別
    /// - Throws: 根導覽呈現不符預期時丟出測試錯誤
    func assertRootNavigation(
        navigator: AppNavigator,
        in app: XCUIApplication,
        expected: AppNavigator.RootLayout
    ) throws(UITestError) {
        let actual = try navigator.rootLayout()
        let actualDescription = String(describing: actual)
        try requireCondition(
            actual == expected,
            in: app,
            "橫向根導覽版面不符預期 (預期: \(expected), 實際: \(actualDescription))"
        )
        switch expected {
        case .regular:
            // 側邊欄與頂部分頁列都屬 regular 版面，前述 `rootLayout` 已核驗，此處不另斷言
            break

        case .compact:
            try requireCondition(
                app.tabBars.firstMatch.waitForExistence(timeout: 10),
                in: app,
                "compact 版面橫向沒有底部分頁列"
            )
            let presentationMode = try navigator.rootPresentationMode()
            try requireCondition(presentationMode != .sidebar, in: app, "compact 版面橫向出現側邊欄")
        }
    }

    /// 斷言轉為橫向後的訂單篩選呈現：regular 不顯示整合篩選鈕，compact 顯示整合篩選鈕
    ///
    /// - Parameters:
    ///   - orders: 訂單畫面 Page Object
    ///   - app: 受測 App
    ///   - isRegular: 訂單前景是否為 regular 欄位呈現
    /// - Throws: 訂單清單未就緒或篩選鈕狀態不符預期時丟出測試錯誤
    func assertOrdersFilter(
        _ orders: OrdersScreen,
        in app: XCUIApplication,
        isRegular: Bool
    ) throws(UITestError) {
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單未就緒")
        if isRegular {
            try requireCondition(
                !orders.hasFilterTrigger(timeout: 2),
                in: app,
                "regular 版面橫向不應顯示整合篩選鈕"
            )
        } else {
            try requireCondition(orders.hasFilterTrigger(), in: app, "compact 版面橫向的訂單頁沒有整合篩選鈕")
        }
    }
}
