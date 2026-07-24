//
//  Screen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 所有 Page Object 的共同契約
///
/// 每個畫面以自己的根 identifier 判定是否就緒，並統一提供就緒等待；
/// Page Object 對外暴露語意操作，元素查詢細節不外洩給測試檔
protocol Screen {

    // MARK: - Screen Requirements

    /// 受測 App
    var app: XCUIApplication { get }

    /// 判定畫面已就緒的根元素 identifier
    var rootIdentifier: String { get }
}

// MARK: - Internal Method

extension Screen {

    /// 等畫面就緒
    /// - Parameter timeout: 逾時秒數
    /// - Returns: 逾時前是否就緒
    @discardableResult
    func waitUntilReady(timeout: TimeInterval = 10) -> Bool {
        rootElement.waitForExistence(timeout: timeout)
    }

    /// 畫面是否已呈現
    var isDisplayed: Bool {
        rootElement.exists
    }

    /// 以根 identifier 命中的元素，先在標準容器類型找、找不到再退回全域查詢
    ///
    /// 根容器可能是捲動視圖、集合或一般容器，逐一嘗試避免因容器型別不同而查不到
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
