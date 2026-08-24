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
    /// - Returns: 總結 sheet 內容容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.AISummary.root
    }
}

// MARK: - Internal Method

@MainActor
extension AISummaryScreen {

    /// 點導覽列的關閉收起 sheet
    func tapClose() {
        let button = app.buttons[BLAccessibilityID.AISummary.closeButton]
        button.waitUntilHittable()
        button.tap()
    }

    /// 點錯誤態的重試
    func tapRetry() {
        let button = app.buttons[BLAccessibilityID.AISummary.retryButton]
        button.waitUntilHittable()
        button.tap()
    }
}
