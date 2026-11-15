//
//  XCUIApplication+SheetInteraction.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - 工作表互動

/// 關閉 sheet 的下滑互動 helper
extension XCUIApplication {

    /// 下滑關閉沒有變更的 sheet
    ///
    /// - Parameters:
    ///   - sheetRoot: sheet 的根元素
    ///   - timeout: 等待 sheet 消失的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: sheet 未在逾時前關閉時丟出測試錯誤
    func dismissSheetBySwipe(
        _ sheetRoot: XCUIElement,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        dragSheetDown(sheetRoot)
        guard sheetRoot.waitForDisappearance(timeout: timeout) else {
            try stopWithDiagnostics("下滑後 sheet 仍未關閉", file: file, line: line)
        }
    }

    /// 下滑有變更的 sheet，確認在觀察期間未關閉
    ///
    /// - Parameters:
    ///   - sheetRoot: sheet 的根元素
    ///   - settleTimeout: 觀察 sheet 是否消失的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: sheet 在觀察期間消失時丟出測試錯誤
    func expectSheetBlocksSwipeDismiss(
        _ sheetRoot: XCUIElement,
        settleTimeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        dragSheetDown(sheetRoot)
        guard !sheetRoot.waitForDisappearance(timeout: settleTimeout) else {
            try stopWithDiagnostics("有未儲存變更的 sheet 意外因下滑而關閉", file: file, line: line)
        }
    }
}

// MARK: - 工作表狀態判定

private extension XCUIApplication {

    /// 從 sheet 上緣中央往下拖出下滑手勢
    ///
    /// - Parameter sheetRoot: sheet 的根元素
    func dragSheetDown(_ sheetRoot: XCUIElement) {
        let start = sheetRoot.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.02))
        let end = sheetRoot.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1.5))
        start.press(forDuration: 0.1, thenDragTo: end)
    }
}
