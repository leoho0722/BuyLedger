//
//  BLUITestCase.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 所有 UI 測試的共用基底
///
/// - Note: 子類別可在 `// MARK: - XCTestCase` extension 覆寫 `setUpWithError`，並呼叫父類別以保留共用設定
@MainActor
class BLUITestCase: XCTestCase {}

// MARK: - Internal Method

extension BLUITestCase {

    /// 將裝置轉回直向後依啟動選項啟動 App
    ///
    /// - Parameter options: App 啟動選項
    /// - Returns: 已啟動的受測 App
    @discardableResult
    func launch(_ options: LaunchOptions = .default) -> XCUIApplication {
        // 座標型互動與版面斷言都以直向為準，避免前序測試把模擬器留在橫向
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = options.launchArguments
        app.launch()

        if !app.wait(for: .runningForeground, timeout: 15) {
            failWithDiagnostics(in: app, "App 未能於逾時前進入前景")
        }

        return app
    }
}

// MARK: - XCTestCase

extension BLUITestCase {

    /// 設定每個測試遇錯即停止
    ///
    /// - Throws: 父類別的設定失敗時丟出的錯誤
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }
}
