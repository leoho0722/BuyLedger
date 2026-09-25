//
//  AlertInteraction.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - Internal Method

/// Alert 的定位與斷言 helper
extension XCUIApplication {

    /// 指定 identifier 的 alert 是否呈現
    /// - Parameters:
    ///   - identifier: alert 的 accessibility identifier
    ///   - timeout: 等待 alert 出現的秒數
    /// - Returns: alert 是否在逾時前出現
    func alertExists(_ identifier: String, timeout: TimeInterval = 5) -> Bool {
        alerts[identifier].waitForExistence(timeout: timeout)
    }

    /// 點目前 alert 中指定 identifier 的按鈕
    /// - Parameters:
    ///   - identifier: 按鈕的 accessibility identifier
    ///   - timeout: 等待按鈕可互動的秒數
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    func tapAlertButton(
        _ identifier: String,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let button = alerts.buttons[identifier]
        guard button.waitUntilHittable(timeout: timeout) else {
            XCTFail("找不到 identifier 為 \(identifier) 的 alert 按鈕", file: file, line: line)
            return
        }
        button.tap()
    }

    /// 是否有任一 alert 正呈現
    /// - Parameter timeout: 等待 alert 出現的秒數
    /// - Returns: 是否有 alert 在逾時前出現
    func alertPresented(timeout: TimeInterval = 5) -> Bool {
        alerts.firstMatch.waitForExistence(timeout: timeout)
    }

    /// 目前 alert 是否已消失
    /// - Parameter timeout: 等待 alert 消失的秒數
    /// - Returns: alert 是否在逾時前消失
    func alertDismissed(timeout: TimeInterval = 5) -> Bool {
        alerts.firstMatch.waitForDisappearance(timeout: timeout)
    }

    /// 點目前 alert 中指定顯示文字的按鈕
    /// - Parameters:
    ///   - label: 按鈕顯示文字
    ///   - timeout: 等待按鈕可互動的秒數
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    func tapAlertButton(
        label: String,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let button = alerts.firstMatch.buttons[label]
        guard button.waitUntilHittable(timeout: timeout) else {
            XCTFail("找不到文字為 \(label) 的 alert 按鈕", file: file, line: line)
            return
        }
        button.tap()
    }

    /// 斷言目前 alert 的訊息含指定文字
    /// - Parameters:
    ///   - substring: 預期出現於 alert 訊息中的文字
    ///   - timeout: 等待 alert 出現的秒數
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    func assertAlertMessage(
        contains substring: String,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let alert = alerts.firstMatch
        guard alert.waitForExistence(timeout: timeout) else {
            XCTFail("畫面上沒有呈現任何 alert，無法比對訊息", file: file, line: line)
            return
        }
        let predicate = NSPredicate(format: "label CONTAINS %@", substring)
        let matched = alert.staticTexts.matching(predicate).firstMatch
        XCTAssertTrue(
            matched.exists,
            "alert 訊息不含預期文字：\(substring)",
            file: file,
            line: line
        )
    }
}
