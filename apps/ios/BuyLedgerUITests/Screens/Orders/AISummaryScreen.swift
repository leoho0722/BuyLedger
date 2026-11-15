//
//  AISummaryScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// AI 商品明細總結 sheet 的 Page Object
struct AISummaryScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Internal Method

@MainActor
extension AISummaryScreen {

    /// 點導覽列的關閉按鈕，收起 sheet
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapClose(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = app.buttons[BLAccessibilityID.AISummary.closeButton]
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }
}

// MARK: - ScreenProtocol

extension AISummaryScreen: ScreenProtocol {

    /// 判定總結 sheet 已就緒的根 identifier (內容容器)
    var rootIdentifier: String {
        BLAccessibilityID.AISummary.root
    }
}
