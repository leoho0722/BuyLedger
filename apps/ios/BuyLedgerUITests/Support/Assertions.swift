//
//  Assertions.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest
import CoreGraphics

// MARK: - Nested Types

private extension XCTestCase {

    /// 需要前置值時的測試失敗種類
    enum UIAssertionError: Error {

        /// 前置值不存在
        case missingValue

        /// 前置條件不成立
        case conditionFailed
    }
}

// MARK: - Internal Method

/// 跨畫面共用的語意斷言
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
    /// - Throws: 前置值不存在時拋出測試錯誤
    func requireValue<Value>(
        _ value: Value?,
        in app: XCUIApplication,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Value {
        if let value {
            return value
        }
        app.failWithDiagnostics(message, file: file, line: line)
        throw UIAssertionError.missingValue
    }

    /// 驗證測試前置條件；失敗時附上 UI 診斷並停止目前測試
    ///
    /// - Parameters:
    ///   - condition: 待驗證的條件
    ///   - app: 受測 App
    ///   - message: 條件不成立時的失敗訊息
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 前置條件不成立時拋出測試錯誤
    func requireCondition(
        _ condition: @autoclosure () -> Bool,
        in app: XCUIApplication,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        if condition() {
            return
        }
        app.failWithDiagnostics(message, file: file, line: line)
        throw UIAssertionError.conditionFailed
    }

    /// 確認已停在指定畫面
    ///
    /// - Parameters:
    ///   - screen: 要確認的 Page Object
    ///   - timeout: 等待畫面就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func assertNavigationTitle(
        for screen: Screen,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if !screen.waitUntilReady(timeout: timeout) {
            failWithDiagnostics(
                in: screen.app,
                "畫面未就緒，根 identifier「\(screen.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
    }

    /// 確認空狀態容器存在
    ///
    /// - Parameters:
    ///   - identifier: 空狀態容器的 identifier
    ///   - app: 受測 App
    ///   - timeout: 等待容器出現的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func assertEmptyState(
        _ identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let container = app.descendants(matching: .any)[identifier]
        if !container.waitForExistence(timeout: timeout) {
            failWithDiagnostics(
                in: app,
                "空狀態容器「\(identifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
    }

    /// 確認元素命中區至少 44x44 point
    ///
    /// - Parameters:
    ///   - element: 要檢查命中區的元素
    ///   - minimum: 命中區的最小寬高
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func assertMinimumHitTarget(
        _ element: XCUIElement,
        minimum: CGFloat = 44,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if !element.exists {
            failWithDiagnostics(in: app, "待驗命中區的元素不存在", file: file, line: line)
            return
        }
        let frame = element.frame
        if frame.width < minimum || frame.height < minimum {
            failWithDiagnostics(
                in: app,
                "命中區 \(frame.width)x\(frame.height) 小於最小值 \(minimum)x\(minimum) point",
                file: file,
                line: line
            )
        }
    }
}
