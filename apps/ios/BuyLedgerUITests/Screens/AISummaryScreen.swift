//
//  AISummaryScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// AI 商品明細總結 sheet 的 Page Object
struct AISummaryScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定總結 sheet 已就緒的根 identifier (內容容器)
    ///
    /// - Returns: 總結 sheet 內容容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.AISummary.root
    }
}

// MARK: - Internal Method

@MainActor
extension AISummaryScreen {

    /// 點導覽列的關閉收起 sheet
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapClose(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.AISummary.closeButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點錯誤態的重試
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapRetry(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.AISummary.retryButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }
}
