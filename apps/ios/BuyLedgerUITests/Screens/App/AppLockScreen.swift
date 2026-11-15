//
//  AppLockScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/31.
//

import XCTest

/// App 鎖定畫面的 Page Object，供 UI 測試等待驗證結果並重新驗證
struct AppLockScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Internal Method

@MainActor
extension AppLockScreen {

    /// 等待冷啟動後第一次驗證失敗的訊息出現
    ///
    /// - Parameter timeout: 等待失敗訊息出現的秒數
    /// - Returns: 失敗訊息是否在逾時前出現
    func waitForInitialFailure(timeout: TimeInterval = 10) -> Bool {
        let failedMessage = app.descendants(matching: .any)[BLAccessibilityID.AppLock.failedMessage]
        return failedMessage.waitForExistence(timeout: timeout)
    }

    /// 等待重新驗證開始，即重試按鈕停用
    ///
    /// - Parameter timeout: 等待按鈕停用的秒數
    /// - Returns: 按鈕是否在逾時前停用
    func waitForRetryToBegin(timeout: TimeInterval = 10) -> Bool {
        retryButton.wait(for: NSPredicate(format: "isEnabled == false"), timeout: timeout)
    }

    /// 等待重新驗證完成並再次顯示失敗訊息
    ///
    /// - Parameter timeout: 等待按鈕恢復可用的秒數
    /// - Returns: 按鈕恢復可用且失敗訊息存在
    func waitForFailedRetryResult(timeout: TimeInterval = 10) -> Bool {
        guard retryButton.wait(
            for: NSPredicate(format: "isEnabled == true"),
            timeout: timeout
        ) else {
            return false
        }
        let failedMessage = app.descendants(matching: .any)[BLAccessibilityID.AppLock.failedMessage]
        return failedMessage.waitForExistence(timeout: timeout)
    }

    /// 等待重新驗證按鈕可點
    ///
    /// - Parameter timeout: 等待按鈕可點的秒數
    /// - Returns: 按鈕是否在逾時前可點
    func waitForRetryButton(timeout: TimeInterval = 10) -> Bool {
        retryButton.waitUntilHittable(timeout: timeout)
    }

    /// 點擊「重新驗證」
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapRetry(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        try retryButton.tapAfterWaiting(in: app, file: file, line: line)
    }
}

// MARK: - ScreenProtocol

extension AppLockScreen: ScreenProtocol {

    /// 判定畫面已就緒的根元素 identifier
    var rootIdentifier: String {
        BLAccessibilityID.AppLock.root
    }
}

// MARK: - Private Method

@MainActor
private extension AppLockScreen {

    /// 鎖定畫面的重新驗證按鈕
    var retryButton: XCUIElement {
        app.buttons[BLAccessibilityID.AppLock.retryButton]
    }
}
