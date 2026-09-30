//
//  SheetInteraction.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 關閉 sheet 的下滑互動 helper

// MARK: - Internal Method

extension XCUIApplication {

    /// 下滑關閉非 dirty 的 sheet
    /// - Parameters:
    ///   - sheetRoot: sheet 的根元素
    ///   - timeout: 等待 sheet 消失的秒數
    /// - Returns: sheet 是否在逾時前關閉
    @discardableResult
    func dismissSheetBySwipe(_ sheetRoot: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        dragSheetDown(sheetRoot)
        return sheetRoot.waitForDisappearance(timeout: timeout)
    }

    /// 驗證 dirty 的 sheet 擋下下滑關閉
    /// - Parameters:
    ///   - sheetRoot: sheet 的根元素
    ///   - settleTimeout: 等待回彈完成的秒數
    /// - Returns: sheet 是否仍留在畫面上
    func expectSheetBlocksSwipeDismiss(_ sheetRoot: XCUIElement, settleTimeout: TimeInterval = 2) -> Bool {
        dragSheetDown(sheetRoot)
        return !sheetRoot.waitForDisappearance(timeout: settleTimeout)
    }
}

// MARK: - Private Method

private extension XCUIApplication {

    /// 從 sheet 上緣中央往下拖出下滑手勢
    /// - Parameter sheetRoot: sheet 的根元素
    func dragSheetDown(_ sheetRoot: XCUIElement) {
        let start = sheetRoot.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.02))
        let end = sheetRoot.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1.5))
        start.press(forDuration: 0.1, thenDragTo: end)
    }
}
