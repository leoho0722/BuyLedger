//
//  MenuInteraction.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開選單與點選單項目的互動 helper
///
/// SwiftUI 的 `Menu` (點觸發) 與 contextMenu (長按觸發) 其項目在無障礙樹上都以按鈕呈現，
/// 一律以掛在項目上的 accessibilityIdentifier 定位；contextMenu 需先長按目標元素叫出選單，
/// 再由 ``tapMenuItem(_:timeout:)`` 等目標項目可點才點下

// MARK: - Internal Method

extension XCUIApplication {

    /// 長按目標元素叫出 contextMenu
    ///
    /// 長按前先確認目標可點，避免對還沒上畫面的元素發手勢；叫出後由 ``tapMenuItem(_:timeout:)``
    /// 等目標項目出現再點，故此處不另等選單容器
    /// - Parameters:
    ///   - element: 承載 contextMenu 的目標元素
    ///   - duration: 長按秒數，預設 1 秒足以觸發 contextMenu
    ///   - timeout: 等目標可點的逾時秒數
    /// - Returns: 逾時前目標是否可長按
    @discardableResult
    func openContextMenu(on element: XCUIElement, duration: TimeInterval = 1, timeout: TimeInterval = 10) -> Bool {
        guard element.waitUntilHittable(timeout: timeout) else {
            return false
        }
        element.press(forDuration: duration)
        return true
    }

    /// 點選單項目
    ///
    /// 適用 `Menu` 與 contextMenu 兩種來源的項目 (兩者在無障礙樹上都是按鈕)；等項目可點才點，
    /// 逾時回傳 false 交由呼叫端以 ``failWithDiagnostics(in:_:file:line:)`` 失敗
    /// - Parameters:
    ///   - identifier: 項目的 accessibilityIdentifier
    ///   - timeout: 逾時秒數
    /// - Returns: 逾時前是否點到項目
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

    /// 以 identifier 命中選單項目，先在選單項與按鈕類型找、找不到再退回全域查詢
    ///
    /// 項目依觸發來源與版面可能落在 `menuItem` 或 `button` 類型，逐一嘗試避免因型別不同而查不到
    /// - Parameter identifier: 項目的 accessibilityIdentifier
    /// - Returns: 對應的查詢元素 (未必當下已存在，等待交由呼叫端)
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
