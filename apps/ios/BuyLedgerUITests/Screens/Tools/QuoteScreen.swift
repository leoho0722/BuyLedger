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
    ///
    /// - Parameter timeout: 等待欄位出現的秒數
    /// - Returns: 當地運費欄的文字值；元素不存在或值不是字串時為 `nil`
    func localShippingFieldValue(timeout: TimeInterval = 10) -> String? {
        let field = localShippingField
        guard field.waitForExistence(timeout: timeout) else {
            return nil
        }
        return field.value as? String
    }

    /// 刷卡費率輸入欄位
    var cardFeeField: XCUIElement {
        app.textFields[BLAccessibilityID.Quote.cardFeeField].firstMatch
    }

    /// 刷卡費率欄目前的文字值，元素不存在或值不是字串時為缺值
    ///
    /// - Parameter timeout: 等待欄位出現的秒數
    /// - Returns: 刷卡費率欄的文字值；元素不存在或值不是字串時為 `nil`
    func cardFeeFieldValue(timeout: TimeInterval = 10) -> String? {
        let field = cardFeeField
        guard field.waitForExistence(timeout: timeout) else {
            return nil
        }
        return field.value as? String
    }

    /// 建議售價 hero 卡的 accessibility value
    ///
    /// - Parameter timeout: 等待結果出現的秒數
    /// - Returns: 建議售價的 accessibility value；元素不存在時為 `nil`
    func suggestedPriceValue(timeout: TimeInterval = 10) -> String? {
        // 合併朗讀卡片在 XCUITest 歸為 `staticText`，故以 `any` 查詢
        let element = app.descendants(matching: .any)[BLAccessibilityID.Quote.suggestedPriceValue]
        guard element.waitForExistence(timeout: timeout) else {
            return nil
        }
        return element.value as? String
    }

    /// 來源幣別按鈕的 ISO 代碼
    ///
    /// - Parameter timeout: 等待幣別按鈕出現的秒數
    /// - Returns: 來源幣別代碼；元素不存在時為 `nil`
    func sourceCurrencyCode(timeout: TimeInterval = 10) -> String? {
        let element = app.descendants(matching: .any)[BLAccessibilityID.Quote.currencyPickerButton]
        guard element.waitForExistence(timeout: timeout) else {
            return nil
        }
        return element.value as? String
    }

    /// 本金欄目前的文字值
    ///
    /// - Parameter timeout: 等待欄位出現的秒數
    /// - Returns: 本金欄的文字值；元素不存在或值不是字串時為 `nil`
    func principalFieldValue(timeout: TimeInterval = 10) -> String? {
        let field = app.textFields[BLAccessibilityID.Quote.principalField]
        guard field.waitForExistence(timeout: timeout) else {
            return nil
        }
        return field.value as? String
    }
}

// MARK: - Internal Method

@MainActor
extension QuoteScreen {

    /// 從更多分頁導到報價頁，等待試算內容或載入失敗就緒
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 報價頁的 Page Object
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    static func open(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> QuoteScreen {
        let root = RootNavigationScreen(app: app)
        try root.goToMore(file: file, line: line)

        let entry = app.descendants(matching: .any)[BLAccessibilityID.More.row(.quote)]
        try entry.tapAfterWaiting(in: app, file: file, line: line)

        try root.requireForeground(
            identifiers: [
                BLAccessibilityID.Quote.suggestedPriceValue,
                BLAccessibilityID.Quote.statusBanner,
            ],
            message: "報價工具前景內容未就緒",
            file: file,
            line: line
        )
        return QuoteScreen(app: app)
    }

    /// 露出指定欄位後點左側取得焦點，保留當前鍵盤供直接換欄測試
    ///
    /// - Parameters:
    ///   - field: 要取得焦點的報價輸入欄位
    ///   - dx: 欄位內點擊位置的水平比例
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func focusFieldFromLeft(
        _ field: XCUIElement,
        dx: CGFloat = 0.04,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        if !field.isHittableOnScreen {
            try app.scrollToHittable(field, within: rootElement, file: file, line: line)
        }
        try field.tapLeftToFocus(
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
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func dismissKeyboard(
        for field: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try field.dismissNumericKeyboard(in: app, file: file, line: line)
    }

    /// 開啟來源幣別選擇器並等待選擇器就緒
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的幣別選擇器
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    func openCurrencyPicker(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OptionPickerScreen {
        let button = app.descendants(matching: .any)[BLAccessibilityID.Quote.currencyPickerButton]
        if !button.isHittableOnScreen {
            try app.scrollToHittable(button, within: rootElement, file: file, line: line)
        }
        try button.tapAfterWaiting(in: app, file: file, line: line)
        let picker = OptionPickerScreen(app: app)
        try picker.requireReady(file: file, line: line)
        return picker
    }

    /// 等待報價頁顯示載入中
    ///
    /// - Parameter timeout: 等待載入指示器出現的秒數
    /// - Returns: 載入指示器是否在逾時前出現
    func waitForLoading(timeout: TimeInterval = 10) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Quote.loading]
            .waitForExistence(timeout: timeout)
    }

    /// 等待報價頁顯示載入失敗
    ///
    /// - Parameter timeout: 等待失敗訊息出現的秒數
    /// - Returns: 載入失敗訊息是否在逾時前出現
    func waitForLoadFailure(timeout: TimeInterval = 10) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Quote.loadFailure]
            .waitForExistence(timeout: timeout)
    }

    /// 點報價頁載入失敗分支的重試按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 重試按鈕無法點擊時丟出測試錯誤
    func tapRetry(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = app.buttons[BLAccessibilityID.Quote.retryButton]
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 填入商品本金後收起數字鍵盤
    ///
    /// - Parameters:
    ///   - amount: 要輸入的本金字串
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func typePrincipal(
        _ amount: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.Quote.principalField]
        try app.scrollToHittable(field, within: rootElement, file: file, line: line)
        try field.clearAndType(
            amount,
            in: app,
            file: file,
            line: line
        )
        try field.dismissNumericKeyboard(in: app, file: file, line: line)
    }

    /// 清空本金欄後輸入文字並保留鍵盤焦點
    ///
    /// - Parameters:
    ///   - amount: 要輸入的本金字串
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func replacePrincipalKeepingKeyboard(
        _ amount: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.Quote.principalField]
        try app.scrollToHittable(field, within: rootElement, file: file, line: line)
        try field.clearAndType(
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
        principalField.hasKeyboardFocus
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
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func dismissPrincipalKeyboard(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.Quote.principalField]
        try field.dismissNumericKeyboard(in: app, file: file, line: line)
    }
}

// MARK: - ScreenProtocol

extension QuoteScreen: ScreenProtocol {

    /// 判定報價頁已就緒的根 identifier (捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Quote.root
    }
}
