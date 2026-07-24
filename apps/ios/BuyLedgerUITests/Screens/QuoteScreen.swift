//
//  QuoteScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 報價試算頁的 Page Object
///
/// 以 accessibility identifier 對外暴露幣別選擇器入口、商品本金輸入與建議售價的語意操作，元素查詢細節不外洩給測試檔；
/// 報價頁是「更多」分頁下的 push 目的地，導航封裝在 ``open(from:)``
struct QuoteScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定報價頁已就緒的根 identifier (捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Quote.root
    }

    /// 建議售價 hero 卡的 accessibility value
    ///
    /// hero 卡是合併朗讀的單一元素，主要數值放在該元素的 value；元素不存在時回傳空字串
    var suggestedPriceValue: String {
        // 合併朗讀的卡片在 XCUITest 歸為 staticText，故以 any 查詢而非 otherElements
        let element = app.descendants(matching: .any)[BLAccessibilityID.Quote.suggestedPriceValue]
        guard element.waitForExistence(timeout: 10) else {
            return ""
        }
        return (element.value as? String) ?? ""
    }
}

// MARK: - Internal Method

@MainActor
extension QuoteScreen {

    /// 從更多分頁導到報價頁
    ///
    /// 報價試算是「更多」分頁下的 push 目的地：先切到更多分頁再點報價列；
    /// 是否成功抵達交由呼叫端以 ``Screen/waitUntilReady(timeout:)`` 判定並附診斷
    /// - Parameter app: 受測 App
    /// - Returns: 報價頁 Page Object
    static func open(from app: XCUIApplication) -> QuoteScreen {
        let root = RootNavigationScreen(app: app)
        root.goToMore()

        let entry = app.descendants(matching: .any)[BLAccessibilityID.More.row(.quote)]
        entry.waitUntilHittable()
        entry.tap()

        return QuoteScreen(app: app)
    }

    /// 開啟來源幣別選擇器
    ///
    /// 幣別入口是自繪 `Button`，XCUITest 可能歸為 button 或 staticText，故以 any 查詢；離屏時先捲入可點位置
    func openCurrencyPicker() {
        let button = app.descendants(matching: .any)[BLAccessibilityID.Quote.currencyPickerButton]
        if !button.isHittable {
            app.scrollToHittable(button, within: rootElement)
        }
        button.waitUntilHittable()
        button.tap()
    }

    /// 填入商品本金後收起數字鍵盤
    ///
    /// 本金欄為 `decimalPad`，無 return 鍵，輸入後以鍵盤工具列完成鍵收起；離屏時先在捲動容器內捲到可點
    /// - Parameters:
    ///   - amount: 要輸入的本金字串
    ///   - app: 受測 App，供收數字鍵盤時定位鍵盤工具列
    func typePrincipal(_ amount: String, in app: XCUIApplication) {
        let field = app.textFields[BLAccessibilityID.Quote.principalField]
        app.scrollToHittable(field, within: rootElement)
        field.waitUntilHittable()
        // decimalPad 出現後 SwiftUI 會把此欄捲到鍵盤上方，聚焦與輸入才成立
        field.tap()
        if let existing = field.value as? String, existing != amount {
            let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count)
            field.typeText(deletes)
        }
        field.typeText(amount)
        field.dismissNumericKeyboard(in: app)
    }
}
