//
//  Diagnostics.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - Application Diagnostics

extension XCUIApplication {

    /// 附上截圖與可及性樹，讓找不到元素時直接失敗
    ///
    /// - Parameters:
    ///   - message: 失敗訊息
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func failWithDiagnostics(
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTContext.runActivity(named: "UI 互動失敗診斷") { activity in
            let screenshotAttachment = XCTAttachment(screenshot: screenshot())
            screenshotAttachment.name = "失敗畫面"
            screenshotAttachment.lifetime = .keepAlways
            activity.add(screenshotAttachment)

            let treeAttachment = XCTAttachment(string: debugDescription)
            treeAttachment.name = "失敗時的可及性樹"
            treeAttachment.lifetime = .keepAlways
            activity.add(treeAttachment)
        }
        XCTFail(message, file: file, line: line)
    }
}

// MARK: - Test Case Diagnostics

extension XCTestCase {

    /// 附上截圖與可及性樹，讓找不到元素時直接失敗
    ///
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
        app.failWithDiagnostics(message, file: file, line: line)
    }
}
