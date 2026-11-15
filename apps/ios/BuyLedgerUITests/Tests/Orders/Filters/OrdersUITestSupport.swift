//
//  OrdersUITestSupport.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// Orders UI 測試共用的斷言
@MainActor
enum OrdersUITestSupport {}

// MARK: - Internal Method

@MainActor
extension OrdersUITestSupport {

    /// 確認觸發鈕標題包含指定文字
    ///
    /// - Parameters:
    ///   - label: 由 Page Object 讀到的觸發鈕標題
    ///   - fragment: 預期包含的標題文字
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 標題不含預期文字時丟出測試錯誤
    static func assertTrigger(
        label: String,
        contains fragment: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        guard label.contains(fragment) else {
            try app.stopWithDiagnostics(
                "觸發鈕標題應包含「\(fragment)」，實際為「\(label)」",
                file: file,
                line: line
            )
        }
    }
}
