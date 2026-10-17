//
//  MergeFlowScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單合併流程的 Page Object
struct MergeFlowScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定合併候選 sheet 已就緒的根 identifier (候選清單捲動容器)
    ///
    /// - Returns: 候選清單根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.OrderMerge.candidateListRoot
    }

    /// 是否正顯示沒有可合併訂單的空狀態
    ///
    /// - Returns: 是否顯示空狀態
    var isEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.OrderMerge.candidateListEmptyState].exists
    }
}

// MARK: - Internal Method

@MainActor
extension MergeFlowScreen {

    /// 取指定訂單編號的候選列
    ///
    /// - Parameter orderID: 訂單編號
    /// - Returns: 對應的候選列元素
    func candidateRow(orderID: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.OrderMerge.candidateRow(orderID: orderID)]
    }

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
    func tapCandidate(
        orderID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
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

    /// 點照片挑選步驟的繼續 (合計照片超上限時才出現的步驟)
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapPhotoContinue(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.OrderMerge.photoContinueButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點照片挑選步驟指定序位的照片格 (合計照片超上限時才出現的步驟)
    ///
    /// - Parameters:
    ///   - index: 照片格序位 (0 起算)
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapPhotoCell(
        index: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let cell = app.descendants(matching: .any)[
            BLAccessibilityID.OrderMerge.photoCell(index: index)
        ]
        if !cell.isHittable {
            app.scrollToHittable(cell, within: rootElement)
        }
        cell.tapAfterWaiting(in: app, file: file, line: line)
    }
}
