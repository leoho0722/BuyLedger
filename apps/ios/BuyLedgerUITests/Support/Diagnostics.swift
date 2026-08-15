//
//  Diagnostics.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 測試失敗時的診斷附件

// MARK: - Internal Method

extension XCTestCase {

    /// 把目前畫面截圖存成永久附件
    /// - Parameters:
    ///   - app: 受測 App
    ///   - name: 附件名稱
    func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 把目前的可及性樹存成永久附件，供比對元素查詢為何落空
    /// - Parameters:
    ///   - app: 受測 App
    ///   - name: 附件名稱
    func attachAccessibilityTree(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(string: app.debugDescription)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 附上截圖與可及性樹，讓找不到元素時直接失敗
    /// - Parameters:
    ///   - app: 受測 App
    ///   - message: 失敗訊息
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func failWithDiagnostics(
        in app: XCUIApplication,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        attachScreenshot(of: app, named: "失敗畫面")
        attachAccessibilityTree(of: app, named: "失敗時的可及性樹")
        XCTFail(message, file: file, line: line)
    }
}
