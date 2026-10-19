//
//  PlatformScope.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

// MARK: - Internal Method

extension XCTestCase {

    /// 判斷 App 目前是否為 regular 版面，側邊欄出現時為 regular
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 目前是否為 regular 版面
    func isRegularLayout(_ app: XCUIApplication) -> Bool {
        AppNavigator(app: app).isSidebarLayout
    }

    /// 判斷 App 目前是否為 compact 版面，分頁列出現時為 compact
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 目前是否為 compact 版面
    func isCompactLayout(_ app: XCUIApplication) -> Bool {
        !AppNavigator(app: app).isSidebarLayout
    }
}
