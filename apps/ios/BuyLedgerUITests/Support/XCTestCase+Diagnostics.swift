//
//  XCTestCase+Diagnostics.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - Internal Method

extension XCTestCase {

    /// 附上受測 App 的截圖與可及性樹，再記錄測試失敗
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
