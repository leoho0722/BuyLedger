//
//  QuoteScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 報價試算頁的 Page Object
struct QuoteScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Computed Properties

@MainActor
extension QuoteScreen {

    /// 商品本金輸入欄位
    var principalField: XCUIElement {
        app.textFields[BLAccessibilityID.Quote.principalField].firstMatch
    }

    /// 當地運費輸入欄位
    var localShippingField: XCUIElement {
        app.textFields[BLAccessibilityID.Quote.localShippingField].firstMatch
    }

    /// 當地運費欄目前的文字值，元素不存在或值不是字串時為缺值
    var localShippingFieldValue: String? {
        let field = localShippingField
        guard field.waitForExistence(timeout: 10) else {
            return nil
        }
        return field.value as? String
    }

    /// 刷卡費率輸入欄位
    var cardFeeField: XCUIElement {
        app.textFields[BLAccessibilityID.Quote.cardFeeField].firstMatch
    }

    /// 刷卡費率欄目前的文字值，元素不存在或值不是字串時為缺值
    var cardFeeFieldValue: String? {
        let field = cardFeeField
        guard field.waitForExistence(timeout: 10) else {
            return nil
        }
        return field.value as? String
    }

    /// 建議售價 hero 卡的 accessibility value
    ///
    /// - Returns: 建議售價的 accessibility value；元素不存在時為 `nil`
    var suggestedPriceValue: String? {
        // 合併朗讀的卡片在 XCUITest 歸為 `staticText`，故以 `any` 查詢而非 `otherElements`
        let element = app.descendants(matching: .any)[BLAccessibilityID.Quote.suggestedPriceValue]
        guard element.waitForExistence(timeout: 10) else {
            return nil
        }
        return element.value as? String
    }

    /// 來源幣別按鈕的 ISO 代碼
    ///
    /// - Returns: 來源幣別代碼；元素不存在時為 `nil`
    var sourceCurrencyCode: String? {
        let element = app.descendants(matching: .any)[BLAccessibilityID.Quote.currencyPickerButton]
        guard element.waitForExistence(timeout: 10) else {
            return nil
        }
        return element.value as? String
    }

    /// 本金欄目前的文字值
    ///
    /// - Returns: 本金欄的文字值；元素不存在或值不是字串時為 `nil`
    var principalFieldValue: String? {
        let field = app.textFields[BLAccessibilityID.Quote.principalField]
        guard field.waitForExistence(timeout: 10) else {
            return nil
        }
        return field.value as? String
    }
}

// MARK: - Internal Method

@MainActor
extension QuoteScreen {

    /// 從更多分頁導到報價頁
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 報價頁的 Page Object
    static func open(
        from app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> QuoteScreen {
        let root = RootNavigationScreen(app: app)
        root.goToMore(file: file, line: line)

        let entry = app.descendants(matching: .any)[BLAccessibilityID.More.row(.quote)]
        entry.tapAfterWaiting(in: app, file: file, line: line)

        return QuoteScreen(app: app)
    }

    /// 露出指定欄位後點左側取得焦點，保留當前鍵盤供直接換欄測試
    ///
    /// - Parameters:
    ///   - field: 要取得焦點的報價輸入欄位
    ///   - dx: 欄位內點擊位置的水平比例
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 欄位是否取得焦點且鍵盤就緒
    @discardableResult
    func focusFieldFromLeft(
        _ field: XCUIElement,
        dx: CGFloat = 0.04,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        if !field.isHittableOnScreen, !app.scrollToHittable(field, within: rootElement) {
            app.failWithDiagnostics("捲動後報價欄位仍未穩定或不可點", file: file, line: line)
            return false
        }
        return field.tapLeftToFocus(
            in: app,
            dx: dx,
            file: file,
            line: line
        )
    }

    /// 透過共用數字鍵盤流程，收起指定欄位的鍵盤或 Popover
    ///
    /// - Parameters:
    ///   - field: 目前持有數字鍵盤焦點的報價欄位
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func dismissKeyboard(
        for field: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        field.dismissNumericKeyboard(in: app, file: file, line: line)
    }

    /// 開啟來源幣別選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openCurrencyPicker(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.descendants(matching: .any)[BLAccessibilityID.Quote.currencyPickerButton]
        if !button.isHittableOnScreen, !app.scrollToHittable(button, within: rootElement) {
            app.failWithDiagnostics("捲動後來源幣別按鈕仍未穩定或不可點", file: file, line: line)
            return
        }
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 填入商品本金後收起數字鍵盤
    ///
    /// - Parameters:
    ///   - amount: 要輸入的本金字串
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func typePrincipal(
        _ amount: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = app.textFields[BLAccessibilityID.Quote.principalField]
        guard app.scrollToHittable(field, within: rootElement) else {
            app.failWithDiagnostics("捲動後金額欄位仍未穩定或不可點", file: file, line: line)
            return
        }
        field.clearAndType(
            amount,
            in: app,
            file: file,
            line: line
        )
        field.dismissNumericKeyboard(in: app, file: file, line: line)
    }

    /// 點匯率不可用橫幅的重試
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapRetry(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Quote.retryButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 捲動露出本金欄後點擊，取得鍵盤焦點
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapPrincipalField(file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[BLAccessibilityID.Quote.principalField]
        guard app.scrollToHittable(field, within: rootElement) else {
            app.failWithDiagnostics("捲動後本金欄位仍未穩定或不可點", file: file, line: line)
            return
        }
        field.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 清空本金欄後輸入文字並保留鍵盤焦點
    ///
    /// - Parameters:
    ///   - amount: 要輸入的本金字串
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func replacePrincipalKeepingKeyboard(
        _ amount: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = app.textFields[BLAccessibilityID.Quote.principalField]
        guard app.scrollToHittable(field, within: rootElement) else {
            app.failWithDiagnostics("捲動後本金欄位仍未穩定或不可點", file: file, line: line)
            return
        }
        field.clearAndType(
            amount,
            in: app,
            file: file,
            line: line
        )
    }

    /// 判定本金欄是否取得鍵盤焦點
    ///
    /// - Returns: 本金欄是否為鍵盤焦點
    func isPrincipalFieldFocused() -> Bool {
        let field = app.textFields[BLAccessibilityID.Quote.principalField]
        return field.exists && NSPredicate(format: "hasKeyboardFocus == true").evaluate(with: field)
    }

    /// 續打本金欄文字，呼叫端需先確認焦點，續打時不點擊
    ///
    /// - Parameter text: 要續打的文字
    func appendPrincipal(_ text: String) {
        let field = app.textFields[BLAccessibilityID.Quote.principalField]
        field.typeText(text)
    }

    /// 收起本金欄的數字鍵盤
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func dismissPrincipalKeyboard(file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[BLAccessibilityID.Quote.principalField]
        field.dismissNumericKeyboard(in: app, file: file, line: line)
    }
}

// MARK: - Screen

extension QuoteScreen: Screen {

    /// 判定報價頁已就緒的根 identifier (捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Quote.root
    }
}
