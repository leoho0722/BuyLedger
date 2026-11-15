//
//  XCTestCase+Assertions.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - 語意斷言

/// 跨畫面共用的語意斷言
@MainActor
extension XCTestCase {

    /// 取出測試前置值；缺少時附上 UI 診斷並讓測試失敗
    ///
    /// - Parameters:
    ///   - value: 待驗證的 optional 值
    ///   - app: 受測 App
    ///   - message: 值不存在時的失敗訊息
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已解包的前置值
    /// - Throws: 前置值不存在時丟出測試錯誤
    func requireValue<Value>(
        _ value: @autoclosure () throws(UITestError) -> Value?,
        in app: XCUIApplication,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> Value {
        if let value = try value() {
            return value
        }
        try app.stopWithDiagnostics(message, file: file, line: line)
    }

    /// 將純值檢查結果套用到活體測試；失敗時附上 UI 診斷並讓測試失敗
    ///
    /// - Parameters:
    ///   - outcome: 純值檢查的結果
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 檢查失敗時丟出測試錯誤
    func requireCheckPassed(
        _ outcome: CheckOutcome,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        guard case .failed(let reason) = outcome else {
            return
        }
        try requireCondition(
            false,
            in: app,
            reason,
            file: file,
            line: line
        )
    }

    /// 確認測試前置條件成立；失敗時附上 UI 診斷並停止目前測試
    ///
    /// - Parameters:
    ///   - condition: 待驗證的條件
    ///   - app: 受測 App
    ///   - message: 條件不成立時的失敗訊息
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 前置條件不成立時丟出測試錯誤
    func requireCondition(
        _ condition: @autoclosure () throws(UITestError) -> Bool,
        in app: XCUIApplication,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        if try condition() {
            return
        }
        try app.stopWithDiagnostics(message, file: file, line: line)
    }

    /// 確認空狀態容器存在
    ///
    /// - Parameters:
    ///   - identifier: 空狀態容器的 identifier
    ///   - app: 受測 App
    ///   - timeout: 等待容器出現的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出測試錯誤
    func assertEmptyState(
        _ identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let container = app.descendants(matching: .any)[identifier]
        if !container.waitForExistence(timeout: timeout) {
            try app.stopWithDiagnostics(
                "空狀態容器「\(identifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
    }
}
