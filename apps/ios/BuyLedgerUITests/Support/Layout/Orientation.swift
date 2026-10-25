//
//  Orientation.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import XCTest

// MARK: - Internal Method

@MainActor
extension XCTestCase {

    /// 轉為橫向並等到 App 視窗寬大於高，完成後附上橫向視窗的點數尺寸
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 逾時仍未轉為橫向時丟出測試錯誤
    func rotateToLandscape(_ app: XCUIApplication) throws {
        // 先註冊還原再轉向，測試失敗時方向也會轉回直向
        addTeardownBlock { XCUIDevice.shared.orientation = .portrait }
        XCUIDevice.shared.orientation = .landscapeLeft
        try requireCondition(waitForLandscapeWindow(of: app), in: app, "轉向後 App 視窗寬仍未大於高")

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
    func rotateToPortrait(_ app: XCUIApplication) throws {
        XCUIDevice.shared.orientation = .portrait
        try requireCondition(
            waitForWindow(of: app, timeout: 15) { $0.height > $0.width },
            in: app,
            "轉向後 App 視窗高仍未大於寬"
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
}

// MARK: - Private Method

@MainActor
private extension XCTestCase {

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

        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if isOriented(window.frame.size) {
                return true
            }
            // 轉向動畫期間視窗尺寸尚未定案，讓出 run loop 後重查
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        } while Date() < deadline
        return false
    }
}
