//
//  OptionPickerScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 選項選擇器 (`OptionPickerSheet`) 的 Page Object
struct OptionPickerScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Internal Method

@MainActor
extension OptionPickerScreen {

    /// 點選指定原始值的選項列
    ///
    /// - Parameters:
    ///   - value: 選項的原始值
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func selectOption(
        _ value: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let row = optionRow(value)
        if !row.isHittableOnScreen {
            try app.scrollToHittable(
                row,
                within: rootElement,
                file: file,
                line: line
            )
        }
        try row.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 以搜尋欄輸入關鍵字
    ///
    /// - Parameters:
    ///   - text: 要搜尋的關鍵字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 找不到可互動的搜尋欄時丟出測試錯誤
    func search(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = try app.hittableSearchField(file: file, line: line)
        try field.clearAndType(
            text,
            in: app,
            file: file,
            line: line
        )
    }

    /// 讀取指定選項列的 accessibility label
    ///
    /// - Parameters:
    ///   - value: 選項的原始值
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 選項列的 accessibility label
    /// - Throws: 選項列逾時仍未出現時丟出 `UITestError.stopped`
    func optionLabel(
        for value: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> String {
        let row = optionRow(value)
        if !row.waitForExistence(timeout: 10) {
            try app.stopWithDiagnostics("選項列「\(value)」逾時仍未出現", file: file, line: line)
        }
        return row.label
    }

    /// 等待指定原始值的選項列出現
    ///
    /// - Parameters:
    ///   - value: 選項的原始值
    ///   - timeout: 等待選項列出現的秒數
    /// - Returns: 選項列是否在逾時前出現
    func hasOption(_ value: String, timeout: TimeInterval = 10) -> Bool {
        optionRow(value).waitForExistence(timeout: timeout)
    }

    /// 等待指定原始值的選項列從選擇器消失
    ///
    /// - Parameters:
    ///   - value: 選項的原始值
    ///   - timeout: 等待選項列消失的秒數
    /// - Returns: 選項列是否在逾時前消失
    func waitForOptionDismissal(_ value: String, timeout: TimeInterval = 10) -> Bool {
        optionRow(value).waitForDisappearance(timeout: timeout)
    }

    /// 點「新增」開啟新增流程
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    /// - Note: 付款方式選擇器改用 `tapAddPaymentMethod`
    func tapAdd(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = app.buttons[BLAccessibilityID.OptionPicker.addButton]
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點付款方式選擇器的「新增」並開啟付款方式編輯器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的付款方式編輯器
    /// - Throws: 新增按鈕無法互動或編輯器未就緒時丟出測試錯誤
    func tapAddPaymentMethod(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> PaymentMethodEditorScreen {
        try tapAdd(file: file, line: line)
        let screen = PaymentMethodEditorScreen(app: app)
        try screen.requireReady(file: file, line: line)
        return screen
    }

    /// 清空新增 alert 的名稱欄並填入名稱
    ///
    /// - Parameters:
    ///   - name: 要新增的選項名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func typeNewOptionName(
        _ name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        // SwiftUI alert 內的 `TextField` 不帶 identifier，改取唯一的文字欄
        let field = app.alerts.firstMatch.textFields.firstMatch
        try field.clearAndType(
            name,
            in: app,
            file: file,
            line: line
        )
    }

    /// 點新增 alert 的確認鍵送出名稱
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func confirmAdd(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        try app.tapAlertButton(
            BLAccessibilityID.OptionPicker.addAlertConfirmButton,
            file: file,
            line: line
        )
    }

    /// 點可互動的 Back 鍵，返回推入選擇器的表單，不選取任何選項
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 找不到可互動的選擇器返回鍵時丟出測試錯誤
    func tapBack(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        try app.tapUniqueNativeBackButton(file: file, line: line)
    }
}

// MARK: - ScreenProtocol

extension OptionPickerScreen: ScreenProtocol {

    /// 判定選擇器已就緒的根 identifier (選項清單容器)
    var rootIdentifier: String {
        BLAccessibilityID.OptionPicker.root
    }
}

// MARK: - Private Method

@MainActor
private extension OptionPickerScreen {

    /// 取指定原始值的選項列
    ///
    /// - Parameter value: 選項的原始值
    /// - Returns: 對應的選項列元素
    func optionRow(_ value: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.OptionPicker.optionRow(value)]
    }
}
