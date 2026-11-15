//
//  MergeFlowScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單合併流程的 Page Object
struct MergeFlowScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Internal Method

@MainActor
extension MergeFlowScreen {

    /// 等待指定訂單編號的候選列出現
    ///
    /// - Parameters:
    ///   - orderID: 訂單編號
    ///   - timeout: 等待候選列出現的秒數
    /// - Returns: 候選列是否在逾時前出現
    func hasCandidate(orderID: String, timeout: TimeInterval = 5) -> Bool {
        candidateRow(orderID: orderID).waitForExistence(timeout: timeout)
    }

    /// 點指定訂單編號的候選列推進合併
    ///
    /// - Parameters:
    ///   - orderID: 訂單編號
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的合併確認表單
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    func tapCandidate(
        orderID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OrderEditScreen {
        let row = candidateRow(orderID: orderID)
        try row.tapAfterWaiting(in: app, file: file, line: line)
        let screen = OrderEditScreen(app: app)
        try screen.requireReady(file: file, line: line)
        return screen
    }

    /// 點工具列的取消合併
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapCancel(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = app.buttons[BLAccessibilityID.OrderMerge.cancelButton]
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }
}

// MARK: - ScreenProtocol

extension MergeFlowScreen: ScreenProtocol {

    /// 合併候選 sheet 的根元素 identifier，即候選清單捲動容器
    var rootIdentifier: String {
        BLAccessibilityID.OrderMerge.candidateListRoot
    }
}

// MARK: - Private Method

@MainActor
private extension MergeFlowScreen {

    /// 取指定訂單編號的候選列
    ///
    /// - Parameter orderID: 訂單編號
    /// - Returns: 對應的候選列元素
    func candidateRow(orderID: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.OrderMerge.candidateRow(orderID: orderID)]
    }
}
