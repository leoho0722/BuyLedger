//
//  AppLockScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/31.
//

import XCTest

/// 帳本保護鎖定畫面的 Page Object
struct AppLockScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定畫面已就緒的根元素 identifier
    /// - Returns: 鎖定畫面根元素的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.AppLock.root
    }
}

// MARK: - Internal Method

@MainActor
extension AppLockScreen {

    /// 點擊「重新驗證」
    func tapRetry() {
        let button = app.buttons[BLAccessibilityID.AppLock.retryButton]
        button.waitUntilHittable()
        button.tap()
    }
}
