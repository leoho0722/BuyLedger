//
//  MenuInteraction.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開選單與點選單項目的互動 helper

// MARK: - Internal Method

extension XCUIApplication {

    /// 長按目標元素叫出 contextMenu
    /// - Parameters:
    ///   - element: 要長按的目標元素
    ///   - duration: 長按持續時間
    ///   - timeout: 等待元素可互動的秒數
    /// - Returns: 是否成功完成長按
    @discardableResult
    func openContextMenu(
        on element: XCUIElement,
        duration: TimeInterval = 1,
        timeout: TimeInterval = 10
    ) -> Bool {
        guard element.waitUntilHittable(timeout: timeout) else {
            return false
        }
        element.press(forDuration: duration)
        return true
    }

    /// 點選單項目
    /// - Parameters:
    ///   - identifier: 選單項目的 accessibility identifier
    ///   - timeout: 等待選單項目可互動的秒數
    /// - Returns: 是否成功點選選單項目
    @discardableResult
    func tapMenuItem(_ identifier: String, timeout: TimeInterval = 10) -> Bool {
        let item = menuItem(identifier)
        guard item.waitUntilHittable(timeout: timeout) else {
            return false
        }
        item.tap()
        return true
    }
}

// MARK: - Private Method

private extension XCUIApplication {

    /// 以 identifier 找選單項目，找不到時回退全域查詢
    /// - Parameter identifier: 選單項目的 accessibility identifier
    /// - Returns: 命中的選單項目
    func menuItem(_ identifier: String) -> XCUIElement {
        let byMenuItem = menuItems[identifier]
        if byMenuItem.exists {
            return byMenuItem
        }
        let byButton = buttons[identifier]
        if byButton.exists {
            return byButton
        }
        return descendants(matching: .any)[identifier]
    }
}
