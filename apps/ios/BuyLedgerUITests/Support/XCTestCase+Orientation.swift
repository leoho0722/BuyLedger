//
//  XCTestCase+Orientation.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import XCTest

// MARK: - 畫面方向控制

@MainActor
extension XCTestCase {

    /// 轉為橫向並等到 App 視窗寬大於高，完成後附上橫向視窗的點數尺寸
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 逾時仍未轉為橫向時丟出測試錯誤
    func rotateToLandscape(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        // 先註冊還原再轉向，測試失敗時方向也會轉回直向
        addTeardownBlock { XCUIDevice.shared.orientation = .portrait }
        XCUIDevice.shared.orientation = .landscapeLeft
        try requireCondition(
            waitForLandscapeWindow(of: app),
            in: app,
            "轉向後 App 視窗寬仍未大於高",
            file: file,
            line: line
        )

        let size = app.windows.firstMatch.frame.size
        let sizeText = "landscape window size: \(size.width) x \(size.height)"
        let attachment = XCTAttachment(string: sizeText)
        attachment.name = "橫向視窗點數尺寸"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 轉回直向並等到 App 視窗高大於寬
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 逾時仍未轉為直向時丟出測試錯誤
    func rotateToPortrait(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        XCUIDevice.shared.orientation = .portrait
        try requireCondition(
            waitForPortraitWindow(of: app),
            in: app,
            "轉向後 App 視窗高仍未大於寬",
            file: file,
            line: line
        )
    }

    /// 在逾時內輪詢 App 視窗，直到寬大於高
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - timeout: 等待視窗轉為橫向的秒數
    /// - Returns: 視窗是否在逾時前轉為橫向
    func waitForLandscapeWindow(of app: XCUIApplication, timeout: TimeInterval = 15) -> Bool {
        waitForWindow(of: app, timeout: timeout) { $0.width > $0.height }
    }

    /// 在逾時內輪詢 App 視窗，直到高大於寬
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - timeout: 等待視窗轉為直向的秒數
    /// - Returns: 視窗是否在逾時前轉為直向
    func waitForPortraitWindow(of app: XCUIApplication, timeout: TimeInterval = 15) -> Bool {
        waitForWindow(of: app, timeout: timeout) { $0.height > $0.width }
    }
}

// MARK: - 視窗尺寸等待

@MainActor
extension XCTestCase {

    /// 在逾時內輪詢 App 視窗尺寸，直到符合指定方向
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - timeout: 等待視窗轉向的秒數
    ///   - isOriented: 判斷視窗尺寸是否已是目標方向
    /// - Returns: 視窗是否在逾時前轉為目標方向
    func waitForWindow(
        of app: XCUIApplication,
        timeout: TimeInterval,
        isOriented: (CGSize) -> Bool
    ) -> Bool {
        let window = app.windows.firstMatch
        guard window.waitForExistence(timeout: timeout) else {
            return false
        }
        return Polling.wait(timeout: timeout, interval: 0.25) {
            isOriented(window.frame.size)
        }
    }
}
