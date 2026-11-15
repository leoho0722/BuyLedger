//
//  RootNavigationOrientationUITestSupport.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 裝置轉向 UI 測試共用的橫向截圖附件
@MainActor
enum RootNavigationOrientationUITestSupport {}

// MARK: - Internal Method

@MainActor
extension RootNavigationOrientationUITestSupport {

    /// 確認視窗仍是橫向後附上 App 的截圖 (橫向時只擷取到部分畫面)，附件保留在 result bundle
    ///
    /// - Parameters:
    ///   - name: 附件名稱
    ///   - app: 受測 App
    ///   - testCase: 接收附件的測試
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 視窗已不是橫向時丟出測試錯誤
    static func attachScreenshot(
        named name: String,
        of app: XCUIApplication,
        to testCase: XCTestCase,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let isLandscape = testCase.waitForLandscapeWindow(of: app, timeout: 5)
        try testCase.requireCondition(
            isLandscape,
            in: app,
            "截圖「\(name)」前視窗不是橫向",
            file: file,
            line: line
        )

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        testCase.add(attachment)
    }
}
