//
//  Assertions.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest
import CoreGraphics

// MARK: - Internal Method

/// 跨畫面共用的語意斷言
extension XCTestCase {

    /// 確認已停在指定畫面
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
        guard element.exists else {
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

    /// 確認進度列的標題與尾值成對出現
    /// - Parameters:
    ///   - titleIdentifier: 進度列標題的 identifier
    ///   - valueIdentifier: 進度列尾值的 identifier
    ///   - app: 受測 App
    ///   - timeout: 等待元素出現的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func assertProgressPairing(
        titleIdentifier: String,
        valueIdentifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let title = app.descendants(matching: .any)[titleIdentifier]
        let value = app.descendants(matching: .any)[valueIdentifier]
        if !title.waitForExistence(timeout: timeout) {
            failWithDiagnostics(
                in: app,
                "進度列標題「\(titleIdentifier)」未出現，與尾值未成對",
                file: file,
                line: line
            )
        }
        if !value.waitForExistence(timeout: timeout) {
            failWithDiagnostics(
                in: app,
                "進度列尾值「\(valueIdentifier)」未出現，與標題未成對",
                file: file,
                line: line
            )
        }
    }
}
