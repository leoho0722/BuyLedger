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

    /// 候選清單是否含指定訂單編號的列
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
    func tapCandidate(orderID: String, file: StaticString = #filePath, line: UInt = #line) {
        let row = candidateRow(orderID: orderID)
        row.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點工具列的取消合併
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapCancel(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.OrderMerge.cancelButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }
}

// MARK: - Screen

extension MergeFlowScreen: Screen {

    /// 以 `BLAccessibilityID.OrderMerge.candidateListRoot` 指定合併候選 sheet 的根元素
    ///
    /// - Returns: 候選清單捲動容器的 `identifier`
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
