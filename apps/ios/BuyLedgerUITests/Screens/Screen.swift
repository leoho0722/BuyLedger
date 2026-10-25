//
//  Screen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 所有 Page Object 的共同契約
protocol Screen {

    /// 受測 App
    var app: XCUIApplication { get }

    /// 判定畫面已就緒的根元素 identifier
    var rootIdentifier: String { get }
}

// MARK: - Computed Properties

extension Screen {

    /// 畫面是否已呈現，以根元素是否存在判定
    var isDisplayed: Bool {
        rootElement.exists
    }

    /// 以根 identifier 命中的元素，先在標準容器類型找、找不到再退回全域查詢
    var rootElement: XCUIElement {
        let byScrollView = app.scrollViews[rootIdentifier]
        if byScrollView.exists {
            return byScrollView
        }
        let byOther = app.otherElements[rootIdentifier]
        if byOther.exists {
            return byOther
        }
        return app.descendants(matching: .any)[rootIdentifier]
    }
}

// MARK: - Internal Method

extension Screen {

    /// 等待根元素出現，視為畫面就緒
    ///
    /// - Parameter timeout: 等待根元素出現的秒數
    /// - Returns: 根元素是否在逾時前出現
    @discardableResult
    func waitUntilReady(timeout: TimeInterval = 10) -> Bool {
        rootElement.waitForExistence(timeout: timeout)
    }
}
