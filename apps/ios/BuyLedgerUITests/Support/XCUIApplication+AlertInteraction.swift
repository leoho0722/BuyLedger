//
//  XCUIApplication+AlertInteraction.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - 警告框互動

/// Alert 的定位與斷言 helper
extension XCUIApplication {

    /// 等待任一 alert 呈現
    ///
    /// - Parameter timeout: 等待 alert 出現的秒數
    /// - Returns: 是否有 alert 在逾時前出現
    func alertPresented(timeout: TimeInterval = 5) -> Bool {
        alerts.firstMatch.waitForExistence(timeout: timeout)
    }

    /// 斷言目前 alert 的訊息含指定文字
    ///
    /// - Parameters:
    ///   - substring: 預期出現於 alert 訊息中的文字
    ///   - timeout: 等待 alert 出現的秒數
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出測試錯誤
    func assertAlertMessage(
        contains substring: String,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let predicate = NSPredicate(format: "label CONTAINS %@", substring)
        let didMatch = Polling.wait(timeout: timeout) {
            let alert = alerts.firstMatch
            return alert.exists && alert.staticTexts.matching(predicate).firstMatch.exists
        }
        if didMatch {
            return
        }
        guard alerts.firstMatch.exists else {
            try stopWithDiagnostics("畫面上沒有呈現任何 alert，無法比對訊息", file: file, line: line)
        }
        try stopWithDiagnostics(
            "alert 訊息不含預期文字：\(substring)",
            file: file,
            line: line
        )
    }

    /// 點目前 alert 中指定 identifier 的按鈕
    ///
    /// - Parameters:
    ///   - identifier: 按鈕的 accessibility identifier
    ///   - timeout: 等待按鈕可互動的秒數
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Note: 框線不穩時照樣點擊
    /// - Note: 首次點擊後 alert 仍在且位置改變時重試一次
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出測試錯誤
    func tapAlertButton(
        _ identifier: String,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        // SwiftUI alert 的按鈕以兩層同 identifier 的 Button 出現，取第一個避免多重比對
        let button = alerts.buttons[identifier].firstMatch
        try tapAlertButton(
            button: button,
            failureMessage: "找不到 identifier 為 \(identifier) 的 alert 按鈕",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 點目前 alert 中指定顯示文字的按鈕
    ///
    /// - Parameters:
    ///   - label: 按鈕顯示文字
    ///   - timeout: 等待按鈕可互動的秒數
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Note: 框線不穩時照樣點擊
    /// - Note: 首次點擊後 alert 仍在且位置改變時重試一次
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出測試錯誤
    func tapAlertButton(
        label: String,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let button = alerts.firstMatch.buttons[label]
        try tapAlertButton(
            button: button,
            failureMessage: "找不到文字為 \(label) 的 alert 按鈕",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 等待目前 alert 消失
    ///
    /// - Parameter timeout: 等待 alert 消失的秒數
    /// - Returns: alert 是否在逾時前消失
    func alertDismissed(timeout: TimeInterval = 5) -> Bool {
        alerts.firstMatch.waitForDisappearance(timeout: timeout)
    }
}

// MARK: - 警告框按鈕處理

private extension XCUIApplication {

    /// 等待並點擊 alert 按鈕，若 alert 移動導致首次點擊未關閉則重試一次
    ///
    /// - Parameters:
    ///   - button: alert 內要點擊的按鈕
    ///   - failureMessage: 按鈕不可點時的診斷訊息
    ///   - timeout: 等待按鈕可互動的秒數
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出測試錯誤
    func tapAlertButton(
        button: XCUIElement,
        failureMessage: String,
        timeout: TimeInterval,
        file: StaticString,
        line: UInt
    ) throws(UITestError) {
        guard button.waitUntilHittable(timeout: timeout) else {
            try stopWithDiagnostics(failureMessage, file: file, line: line)
        }
        // 鍵盤升起會讓 alert 上移，點擊前等框線穩定；逾時仍不穩時照樣點擊
        // 表單位置已變動時仍需嘗試點擊，避免等待結果中止重試流程
        // 框線逾時仍照常點擊
        _ = button.waitUntilStableAndHittable(
            timeout: 2,
            sampleInterval: 0.2,
            requiredSamples: 3
        )
        guard let frameBeforeTap = button.snapshotFrame else {
            try stopWithDiagnostics("Alert 按鈕框線不可用，無法安全點擊", file: file, line: line)
        }

        button.tap()
        guard !button.waitForDisappearance(timeout: 2),
              let frameAfterTap = button.snapshotFrame,
              frameAfterTap != frameBeforeTap else {
            return
        }

        // 重試前框線不穩時仍需點擊，沿用首次點擊的容錯規則
        // 框線逾時仍照常重試
        _ = button.waitUntilStableAndHittable(
            timeout: 2,
            sampleInterval: 0.2,
            requiredSamples: 3
        )
        guard let retryFrameBeforeTap = button.snapshotFrame else {
            try stopWithDiagnostics("Alert 按鈕移動後框線不可用，無法安全重試", file: file, line: line)
        }
        button.tap()
        let retryFrameAfterTap = button.snapshotFrame
        XCTContext.runActivity(named: "Alert 按鈕移動後重試") { activity in
            let movementAttachment = XCTAttachment(string: """
            首次點擊前框線：\(frameBeforeTap)
            首次點擊後框線：\(frameAfterTap)
            """)
            movementAttachment.name = "警告框按鈕移動框線"
            movementAttachment.lifetime = .keepAlways
            activity.add(movementAttachment)
            let retryAttachment = XCTAttachment(string: """
            重試點擊前框線：\(retryFrameBeforeTap)
            重試點擊後框線：\(String(describing: retryFrameAfterTap))
            """)
            retryAttachment.name = "警告框按鈕重試框線"
            retryAttachment.lifetime = .keepAlways
            activity.add(retryAttachment)
        }
    }
}
