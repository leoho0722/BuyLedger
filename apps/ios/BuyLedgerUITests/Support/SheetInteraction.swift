//
//  SheetInteraction.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 關閉 sheet 的下滑互動 helper
///
/// 以 sheet 根元素的座標由上緣往下拖出關閉手勢：非 dirty 的 sheet 會被下滑關閉、
/// dirty 的 sheet 因 `interactiveDismissDisabled` 只回彈不關閉；兩個情境各自等「消失」或「仍在」供斷言

// MARK: - Internal Method

extension XCUIApplication {

    /// 下滑關閉非 dirty 的 sheet
    ///
    /// 沒有未儲存變更時 sheet 應被下滑手勢關閉；下滑後等根元素消失
    /// - Parameters:
    ///   - sheetRoot: sheet 的根元素
    ///   - timeout: 逾時秒數
    /// - Returns: 逾時前 sheet 是否關閉
    @discardableResult
    func dismissSheetBySwipe(_ sheetRoot: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        dragSheetDown(sheetRoot)
        return sheetRoot.waitForDisappearance(timeout: timeout)
    }

    /// 驗證 dirty 的 sheet 擋下下滑關閉
    ///
    /// 有未儲存變更時 `interactiveDismissDisabled` 會讓下滑只回彈、sheet 仍在；下滑後給一小段時間確認未消失
    /// - Parameters:
    ///   - sheetRoot: sheet 的根元素
    ///   - settleTimeout: 等待確認未消失的秒數，只需涵蓋回彈動畫
    /// - Returns: sheet 是否仍在畫面 (擋下即為 true)
    func expectSheetBlocksSwipeDismiss(_ sheetRoot: XCUIElement, settleTimeout: TimeInterval = 2) -> Bool {
        dragSheetDown(sheetRoot)
        return !sheetRoot.waitForDisappearance(timeout: settleTimeout)
    }
}

// MARK: - Private Method

private extension XCUIApplication {

    /// 從 sheet 上緣中央往下拖出下滑手勢
    ///
    /// 起點取根元素上緣避免拖到內部捲動內容，終點落在根元素下方一段距離讓拖曳越過關閉門檻
    /// - Parameter sheetRoot: sheet 的根元素
    func dragSheetDown(_ sheetRoot: XCUIElement) {
        let start = sheetRoot.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.02))
        let end = sheetRoot.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1.5))
        start.press(forDuration: 0.1, thenDragTo: end)
    }
}
