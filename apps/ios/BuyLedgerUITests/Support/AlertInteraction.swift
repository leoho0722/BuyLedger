//
//  AlertInteraction.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - Internal Method

/// Alert 的定位與斷言 helper
///
/// 專案硬規則是一律以 accessibilityIdentifier 定位，alert 按鈕比照辦理；
/// 訊息比對交由呼叫端先以 ``ValueParsing`` 產生當次 locale 的預期字串再傳入，不在測試裡寫死本地化字面值
extension XCUIApplication {

    /// 指定 identifier 的 alert 是否呈現
    ///
    /// identifier 指 alert 本身的 accessibilityIdentifier，不是其中的按鈕
    /// - Parameters:
    ///   - identifier: alert 的 accessibilityIdentifier
    ///   - timeout: 逾時秒數
    /// - Returns: 逾時前是否出現
    func alertExists(_ identifier: String, timeout: TimeInterval = 5) -> Bool {
        alerts[identifier].waitForExistence(timeout: timeout)
    }

    /// 點目前 alert 中指定 identifier 的按鈕
    ///
    /// 等按鈕可點再點；逾時前找不到就 `XCTFail`，不靜默略過
    /// - Parameters:
    ///   - identifier: 按鈕的 accessibilityIdentifier
    ///   - timeout: 等按鈕可點的逾時秒數
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
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
    ///
    /// TCA `AlertState` 渲染成系統 alert、掛不上自訂 identifier (平台限制)，同一時刻只會有一個，故以 `firstMatch` 判定
    /// - Parameter timeout: 逾時秒數
    /// - Returns: 逾時前是否出現
    func alertPresented(timeout: TimeInterval = 5) -> Bool {
        alerts.firstMatch.waitForExistence(timeout: timeout)
    }

    /// 目前 alert 是否已消失
    /// - Parameter timeout: 逾時秒數
    /// - Returns: 逾時前是否消失
    func alertDismissed(timeout: TimeInterval = 5) -> Bool {
        alerts.firstMatch.waitForDisappearance(timeout: timeout)
    }

    /// 點目前 alert 中指定顯示文字的按鈕
    ///
    /// 專供 `AlertState` 這類掛不上 identifier 的系統 alert；主回歸測試計畫已鎖定語言，按鈕文字為決定值。
    /// 一般能掛 identifier 的 alert 請改用 ``tapAlertButton(_:timeout:file:line:)``
    /// - Parameters:
    ///   - label: 按鈕的顯示文字
    ///   - timeout: 等按鈕可點的逾時秒數
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
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
    ///
    /// 逐一比對 alert 內每個靜態文字的 label；預期字串請以 ``ValueParsing`` 產生，勿寫死本地化字面值
    /// - Parameters:
    ///   - substring: 預期包含的文字
    ///   - timeout: 等 alert 出現的逾時秒數
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
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
