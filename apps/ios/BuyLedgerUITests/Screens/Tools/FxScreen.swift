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
    /// - Returns: 換算結果的 accessibility value；元素不存在時為 `nil`
    var convertedValue: String? {
        // 合併朗讀的卡片在 XCUITest 歸為 `staticText`，故以 `.any` 查詢而非 `otherElements`
        let element = app.descendants(matching: .any)[BLAccessibilityID.Fx.convertedValue]
        guard element.waitForExistence(timeout: 10) else {
            return nil
        }
        return element.value as? String
    }

    /// 換算結果卡片合併朗讀後的完整 accessibility text
    ///
    /// - Returns: 包含來源幣別與匯率資訊的完整文字；元素不存在時為 `nil`
    var conversionSummary: String? {
        let element = app.descendants(matching: .any)[BLAccessibilityID.Fx.convertedValue]
        guard element.waitForExistence(timeout: 10) else {
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
    /// - Returns: 金額欄的文字值；元素不存在或值不是字串時為 `nil`
    var amountFieldValue: String? {
        let field = app.textFields[BLAccessibilityID.Fx.amountField]
        guard field.waitForExistence(timeout: 10) else {
            return nil
        }
        return field.value as? String
    }
}

// MARK: - Internal Method

@MainActor
extension FxScreen {

    /// 從更多分頁導到匯率頁
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 匯率頁的 Page Object
    static func open(
        from app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FxScreen {
        let root = RootNavigationScreen(app: app)
        root.goToMore(file: file, line: line)

        let entry = app.descendants(matching: .any)[BLAccessibilityID.More.row(.fx)]
        entry.tapAfterWaiting(in: app, file: file, line: line)

        return FxScreen(app: app)
    }

    /// 開啟來源幣別選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openCurrencyPicker(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.descendants(matching: .any)[BLAccessibilityID.Fx.currencyPickerButton]
        if !button.isHittableOnScreen, !app.scrollToHittable(button, within: rootElement) {
            app.failWithDiagnostics("捲動後來源幣別按鈕仍未穩定或不可點", file: file, line: line)
            return
        }
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 填入換算金額後收起數字鍵盤
    ///
    /// - Parameters:
    ///   - amount: 要輸入的金額字串
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func typeAmount(
        _ amount: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = app.textFields[BLAccessibilityID.Fx.amountField]
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

    /// 點金額欄取得鍵盤焦點
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapAmountField(file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[BLAccessibilityID.Fx.amountField]
        guard app.scrollToHittable(field, within: rootElement) else {
            app.failWithDiagnostics("捲動後金額欄位仍未穩定或不可點", file: file, line: line)
            return
        }
        field.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 清空金額欄後輸入文字並保留鍵盤焦點
    ///
    /// - Parameters:
    ///   - amount: 要輸入的金額字串
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func replaceAmountKeepingKeyboard(
        _ amount: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = app.textFields[BLAccessibilityID.Fx.amountField]
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
    }

    /// 收起金額欄的數字鍵盤
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func dismissAmountKeyboard(file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[BLAccessibilityID.Fx.amountField]
        field.dismissNumericKeyboard(in: app, file: file, line: line)
    }

    /// 捲動露出金額欄後點欄位左側取得焦點，等鍵盤就位
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 金額欄是否已從左側點擊取得焦點且鍵盤就緒
    @discardableResult
    func focusAmountFromLeft(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        let field = amountField
        if !field.isHittableOnScreen, !app.scrollToHittable(field, within: rootElement) {
            app.failWithDiagnostics("捲動後金額欄位仍未穩定或不可點", file: file, line: line)
            return false
        }
        return field.tapLeftToFocus(in: app, file: file, line: line)
    }

    /// 點指定的快捷金額按鈕
    ///
    /// - Parameters:
    ///   - amount: 按鈕對應的未格式化金額字串
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapPresetAmount(_ amount: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.descendants(matching: .any)[
            BLAccessibilityID.Fx.presetAmountButton(amount: amount)
        ]
        if !button.isHittableOnScreen, !app.scrollToHittable(button, within: rootElement) {
            app.failWithDiagnostics("捲動後快捷金額按鈕仍未穩定或不可點", file: file, line: line)
            return
        }
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 判定金額欄是否取得鍵盤焦點
    ///
    /// - Returns: 金額欄是否為鍵盤焦點
    func isAmountFieldFocused() -> Bool {
        let field = app.textFields[BLAccessibilityID.Fx.amountField]
        return field.exists && NSPredicate(format: "hasKeyboardFocus == true").evaluate(with: field)
    }

    /// 續打金額欄文字，呼叫端需先確認焦點，續打時不點擊
    ///
    /// - Parameter text: 要續打的文字
    func appendAmount(_ text: String) {
        let field = app.textFields[BLAccessibilityID.Fx.amountField]
        field.typeText(text)
    }
}

// MARK: - Screen

extension FxScreen: Screen {

    /// 判定匯率頁已就緒的根元素 identifier (捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Fx.root
    }
}
