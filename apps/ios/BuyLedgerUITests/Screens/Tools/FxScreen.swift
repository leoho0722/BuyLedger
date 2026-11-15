//
//  FxScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 匯率工具頁的 Page Object
struct FxScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Computed Properties

@MainActor
extension FxScreen {

    /// 換算後 TWD 結果的 accessibility value
    ///
    /// - Parameter timeout: 等待結果出現的秒數
    /// - Returns: 換算結果的 accessibility value；元素不存在時為 `nil`
    func convertedValue(timeout: TimeInterval = 10) -> String? {
        // 合併朗讀卡片在 XCUITest 歸為 `staticText`，故以 `.any` 查詢
        let element = app.descendants(matching: .any)[BLAccessibilityID.Fx.convertedValue]
        guard element.waitForExistence(timeout: timeout) else {
            return nil
        }
        return element.value as? String
    }

    /// 換算結果卡片合併朗讀後的完整 accessibility text
    ///
    /// - Parameter timeout: 等待結果出現的秒數
    /// - Returns: 包含來源幣別與匯率資訊的完整文字；元素不存在時為 `nil`
    func conversionSummary(timeout: TimeInterval = 10) -> String? {
        let element = app.descendants(matching: .any)[BLAccessibilityID.Fx.convertedValue]
        guard element.waitForExistence(timeout: timeout) else {
            return nil
        }
        return element.combinedText
    }

    /// 金額輸入欄位
    var amountField: XCUIElement {
        app.textFields[BLAccessibilityID.Fx.amountField].firstMatch
    }

    /// 來源金額欄目前的文字值
    ///
    /// - Parameter timeout: 等待欄位出現的秒數
    /// - Returns: 金額欄的文字值；元素不存在或值不是字串時為 `nil`
    func amountFieldValue(timeout: TimeInterval = 10) -> String? {
        let field = app.textFields[BLAccessibilityID.Fx.amountField]
        guard field.waitForExistence(timeout: timeout) else {
            return nil
        }
        return field.value as? String
    }
}

// MARK: - Internal Method

@MainActor
extension FxScreen {

    /// 從更多分頁導到匯率頁，等待結果卡片或載入失敗就緒
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 匯率頁的 Page Object
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    static func open(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> FxScreen {
        let root = RootNavigationScreen(app: app)
        try root.goToMore(file: file, line: line)

        let entry = app.descendants(matching: .any)[BLAccessibilityID.More.row(.fx)]
        try entry.tapAfterWaiting(in: app, file: file, line: line)

        try root.requireForeground(
            identifiers: [
                BLAccessibilityID.Fx.convertedValue,
                BLAccessibilityID.Fx.statusBanner,
            ],
            message: "匯率工具前景內容未就緒",
            file: file,
            line: line
        )
        return FxScreen(app: app)
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
        let button = app.descendants(matching: .any)[BLAccessibilityID.Fx.currencyPickerButton]
        if !button.isHittableOnScreen {
            try app.scrollToHittable(button, within: rootElement, file: file, line: line)
        }
        try button.tapAfterWaiting(in: app, file: file, line: line)
        let picker = OptionPickerScreen(app: app)
        try picker.requireReady(file: file, line: line)
        return picker
    }

    /// 等待匯率頁顯示載入中
    ///
    /// - Parameter timeout: 等待載入指示器出現的秒數
    /// - Returns: 載入指示器是否在逾時前出現
    func waitForLoading(timeout: TimeInterval = 10) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Fx.loading]
            .waitForExistence(timeout: timeout)
    }

    /// 等待匯率頁顯示載入失敗
    ///
    /// - Parameter timeout: 等待失敗訊息出現的秒數
    /// - Returns: 載入失敗訊息是否在逾時前出現
    func waitForLoadFailure(timeout: TimeInterval = 10) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Fx.loadFailure]
            .waitForExistence(timeout: timeout)
    }

    /// 點匯率頁載入失敗分支的重試按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 重試按鈕無法點擊時丟出測試錯誤
    func tapRetry(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = app.buttons[BLAccessibilityID.Fx.retryButton]
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 填入換算金額後收起數字鍵盤
    ///
    /// - Parameters:
    ///   - amount: 要輸入的金額字串
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func typeAmount(
        _ amount: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.Fx.amountField]
        try app.scrollToHittable(field, within: rootElement, file: file, line: line)
        try field.clearAndType(
            amount,
            in: app,
            file: file,
            line: line
        )
        try field.dismissNumericKeyboard(in: app, file: file, line: line)
    }

    /// 清空金額欄後輸入文字並保留鍵盤焦點
    ///
    /// - Parameters:
    ///   - amount: 要輸入的金額字串
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func replaceAmountKeepingKeyboard(
        _ amount: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.Fx.amountField]
        try app.scrollToHittable(field, within: rootElement, file: file, line: line)
        try field.clearAndType(
            amount,
            in: app,
            file: file,
            line: line
        )
    }

    /// 收起金額欄的數字鍵盤
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func dismissAmountKeyboard(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.Fx.amountField]
        try field.dismissNumericKeyboard(in: app, file: file, line: line)
    }

    /// 捲動露出金額欄後點欄位左側取得焦點，等鍵盤就位
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func focusAmountFromLeft(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = amountField
        if !field.isHittableOnScreen {
            try app.scrollToHittable(field, within: rootElement, file: file, line: line)
        }
        try field.tapLeftToFocus(in: app, file: file, line: line)
    }

    /// 點指定的快捷金額按鈕
    ///
    /// - Parameters:
    ///   - amount: 按鈕對應的未格式化金額字串
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapPresetAmount(
        _ amount: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let button = app.descendants(matching: .any)[
            BLAccessibilityID.Fx.presetAmountButton(amount: amount)
        ]
        if !button.isHittableOnScreen {
            try app.scrollToHittable(button, within: rootElement, file: file, line: line)
        }
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 判定金額欄是否取得鍵盤焦點
    ///
    /// - Returns: 金額欄是否為鍵盤焦點
    func isAmountFieldFocused() -> Bool {
        amountField.hasKeyboardFocus
    }

    /// 續打金額欄文字，呼叫端需先確認焦點，續打時不點擊
    ///
    /// - Parameter text: 要續打的文字
    func appendAmount(_ text: String) {
        let field = app.textFields[BLAccessibilityID.Fx.amountField]
        field.typeText(text)
    }
}

// MARK: - ScreenProtocol

extension FxScreen: ScreenProtocol {

    /// 判定匯率頁已就緒的根元素 identifier (捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Fx.root
    }
}
