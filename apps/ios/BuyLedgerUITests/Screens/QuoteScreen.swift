//
//  QuoteScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 報價試算頁的 Page Object
struct QuoteScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定報價頁已就緒的根 identifier (捲動容器)
    /// - Returns: 報價頁根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Quote.root
    }

    /// 建議售價 hero 卡的 accessibility value
    /// - Returns: 建議售價的 accessibility value；元素不存在時為空字串
    var suggestedPriceValue: String {
        // 合併朗讀的卡片在 XCUITest 歸為 staticText，故以 any 查詢而非 otherElements
        let element = app.descendants(matching: .any)[BLAccessibilityID.Quote.suggestedPriceValue]
        guard element.waitForExistence(timeout: 10) else {
            return ""
        }
        return (element.value as? String) ?? ""
    }

    /// 匯率不可用橫幅是否存在
    /// - Returns: 匯率不可用橫幅是否存在
    var statusBannerExists: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Quote.statusBanner].exists
    }
}

// MARK: - Internal Method

@MainActor
extension QuoteScreen {

    /// 從更多分頁導到報價頁
    /// - Parameter app: 受測 App
    /// - Returns: 報價頁的 Page Object
    static func open(from app: XCUIApplication) -> QuoteScreen {
        let root = RootNavigationScreen(app: app)
        root.goToMore()

        let entry = app.descendants(matching: .any)[BLAccessibilityID.More.row(.quote)]
        entry.waitUntilHittable()
        entry.tap()

        return QuoteScreen(app: app)
    }

    /// 開啟來源幣別選擇器
    func openCurrencyPicker() {
        let button = app.descendants(matching: .any)[BLAccessibilityID.Quote.currencyPickerButton]
        if !button.isHittable {
            app.scrollToHittable(button, within: rootElement)
        }
        button.waitUntilHittable()
        button.tap()
    }

    /// 填入商品本金後收起數字鍵盤
    /// - Parameters:
    ///   - amount: 要輸入的本金字串
    ///   - app: 受測 App
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

    /// 點匯率不可用橫幅的重試
    func tapRetry() {
        let button = app.buttons[BLAccessibilityID.Quote.retryButton]
        button.waitUntilHittable()
        button.tap()
    }
}
