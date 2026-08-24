//
//  BLUITestCase.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 所有 UI 測試的共用基底
class BLUITestCase: XCTestCase {

    // MARK: - Data Properties

    /// 受測 App，於 ``launch(_:)`` 建立
    private(set) var app: XCUIApplication!

    // MARK: - Setup

    override func setUpWithError() throws {
        continueAfterFailure = false
        // 座標型互動與版面斷言都以直向為準，避免前序測試把模擬器留在橫向
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDownWithError() throws {
        app = nil
    }
}

// MARK: - Internal Method

extension BLUITestCase {

    /// 依啟動選項啟動 App
    /// - Parameter options: App 啟動選項
    /// - Returns: 已啟動的受測 App
    @discardableResult
    func launch(_ options: LaunchOptions = .default) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = options.launchArguments
        app.launch()

        if !app.wait(for: .runningForeground, timeout: 15) {
            failWithDiagnostics(in: app, "App 未能於逾時前進入前景")
        }

        self.app = app
        return app
    }
}
