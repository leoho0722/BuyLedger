//
//  XCUIApplication+Diagnostics.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - 應用程式診斷

/// 記錄 UI 互動失敗並附上受測 App 的診斷資料
extension XCUIApplication {

    /// 附上截圖與可及性樹，再記錄測試失敗
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

    /// 記錄失敗並附截圖與可及性樹，再丟出停止訊號
    ///
    /// - Parameters:
    ///   - message: 失敗訊息
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 診斷資料記錄後丟出 `UITestError.stopped`
    @MainActor
    func stopWithDiagnostics(
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> Never {
        failWithDiagnostics(message, file: file, line: line)
        throw UITestError.stopped(message: message)
    }
}
