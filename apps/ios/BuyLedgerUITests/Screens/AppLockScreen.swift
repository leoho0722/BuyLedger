//
//  AppLockScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/31.
//

import XCTest

/// App 鎖定畫面的 Page Object
struct AppLockScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定畫面已就緒的根元素 identifier
    ///
    /// - Returns: 鎖定畫面根元素的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.AppLock.root
    }
}

// MARK: - Internal Method

@MainActor
extension AppLockScreen {

    /// 等待冷啟動的第一次驗證失敗結果
    ///
    /// - Parameter timeout: 等待失敗訊息出現的秒數
    /// - Returns: 失敗訊息是否在逾時前出現
    func waitForInitialFailure(timeout: TimeInterval = 10) -> Bool {
        let failedMessage = app.descendants(matching: .any)[BLAccessibilityID.AppLock.failedMessage]
        return failedMessage.waitForExistence(timeout: timeout)
    }

    /// 等待重新驗證進入執行中
    ///
    /// - Parameter timeout: 等待按鈕停用的秒數
    /// - Returns: 按鈕是否在逾時前停用
    func waitForRetryToBegin(timeout: TimeInterval = 10) -> Bool {
        let retryButton = app.buttons[BLAccessibilityID.AppLock.retryButton]
        return retryButton.wait(
            for: NSPredicate(format: "isEnabled == false"),
            timeout: timeout
        )
    }

    /// 等待重新驗證完成並再次顯示失敗訊息
    ///
    /// - Parameter timeout: 等待按鈕恢復可用的秒數
    /// - Returns: 按鈕恢復可用且失敗訊息存在
    func waitForFailedRetryResult(timeout: TimeInterval = 10) -> Bool {
        let retryButton = app.buttons[BLAccessibilityID.AppLock.retryButton]
        guard retryButton.wait(
            for: NSPredicate(format: "isEnabled == true"),
            timeout: timeout
        ) else {
            return false
        }
        let failedMessage = app.descendants(matching: .any)[BLAccessibilityID.AppLock.failedMessage]
        return failedMessage.waitForExistence(timeout: timeout)
    }

    /// 點擊「重新驗證」
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapRetry(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.AppLock.retryButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }
}
