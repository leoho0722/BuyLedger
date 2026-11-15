//
//  SettingsScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 設定頁的 Page Object
struct SettingsScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Computed Properties

@MainActor
extension SettingsScreen {

    /// 設定頁的預設幣別列
    var defaultCurrencyRow: XCUIElement {
        element(BLAccessibilityID.Settings.defaultCurrencyRow)
    }

    /// 每月目標金額欄位
    var monthlyGoalField: XCUIElement {
        app.textFields[BLAccessibilityID.Settings.monthlyGoalField].firstMatch
    }

    /// 每月目標金額欄目前的文字值
    ///
    /// - Parameter timeout: 等待欄位出現的秒數
    /// - Returns: 目標金額欄的文字值；元素不存在或值不是字串時為 `nil`
    func monthlyGoalFieldValue(timeout: TimeInterval = 10) -> String? {
        let field = app.textFields[BLAccessibilityID.Settings.monthlyGoalField]
        guard field.waitForExistence(timeout: timeout) else {
            return nil
        }
        return field.value as? String
    }
}

// MARK: - Internal Method

@MainActor
extension SettingsScreen {

    /// 從「更多」分頁導到設定頁並等待設定根元素就緒
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的設定頁 Page Object
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    static func open(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> SettingsScreen {
        try RootNavigationScreen(app: app).goToMore(file: file, line: line)
        // iPhone 上更多根的 CollectionView 可能不可點，故只等存在後再點入口列
        let moreRoot = app.descendants(matching: .any)[BLAccessibilityID.More.root]
        guard moreRoot.waitForExistence(timeout: 10) else {
            try app.stopWithDiagnostics(
                "更多根 identifier「\(BLAccessibilityID.More.root)」逾時仍未出現",
                file: file,
                line: line
            )
        }

        let settingsRow = app.descendants(matching: .any)[BLAccessibilityID.More.row(.settings)]
        // 橫向 iPhone 的更多清單較短，先將下方的設定入口列捲入可點範圍
        if !settingsRow.isHittableOnScreen,
           !app.waitUntilHittableByGentleDrag(settingsRow, within: moreRoot),
           !app.waitUntilHittableByScrolling(settingsRow, within: moreRoot) {
            try app.stopWithDiagnostics(
                "更多清單捲動後仍找不到可點的設定入口列",
                file: file,
                line: line
            )
        }
        try settingsRow.tapAfterWaiting(in: app, file: file, line: line)

        let screen = SettingsScreen(app: app)
        guard screen.waitUntilReady() else {
            try app.stopWithDiagnostics(
                "設定頁根 identifier「\(screen.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
        return screen
    }

    /// 點語言選擇列開啟語言選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func openLanguagePicker(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let picker = element(BLAccessibilityID.Settings.languagePicker)
        try picker.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點預設幣別列並等待幣別選擇器就緒
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的幣別選擇器
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    func openDefaultCurrency(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OptionPickerScreen {
        try defaultCurrencyRow.tapAfterWaiting(in: app, file: file, line: line)
        let picker = OptionPickerScreen(app: app)
        try picker.requireReady(file: file, line: line)
        return picker
    }

    /// 清空每月目標金額欄後輸入新文字，之後鍵盤焦點保留在目標金額欄
    ///
    /// - Parameters:
    ///   - text: 要輸入的文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func replaceMonthlyGoal(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.Settings.monthlyGoalField]
        try field.clearAndType(
            text,
            in: app,
            file: file,
            line: line
        )
    }

    /// 續打每月目標金額欄文字，呼叫端需先確認焦點，續打時不點擊
    ///
    /// - Parameter text: 要續打的文字
    func appendMonthlyGoal(_ text: String) {
        let field = app.textFields[BLAccessibilityID.Settings.monthlyGoalField]
        field.typeText(text)
    }

    /// 捲動露出每月目標欄後點欄位左側取得焦點，等鍵盤就位
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func focusMonthlyGoalFromLeft(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = monthlyGoalField
        if !field.isHittableOnScreen {
            try app.scrollToHittable(field, within: rootElement, file: file, line: line)
        }
        try field.tapLeftToFocus(in: app, file: file, line: line)
    }

    /// 點返回鍵回到上一層畫面
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func goBack(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        try app.tapUniqueNativeBackButton(file: file, line: line)
    }

    /// 判定每月目標金額欄是否取得鍵盤焦點
    ///
    /// - Returns: 目標金額欄是否為鍵盤焦點
    func isMonthlyGoalFieldFocused() -> Bool {
        monthlyGoalField.hasKeyboardFocus
    }

    /// 收起每月目標金額欄的數字鍵盤
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func dismissMonthlyGoalKeyboard(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.Settings.monthlyGoalField]
        try field.dismissNumericKeyboard(in: app, file: file, line: line)
    }
}

// MARK: - ScreenProtocol

extension SettingsScreen: ScreenProtocol {

    /// 設定頁的畫面根 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Settings.root
    }
}

// MARK: - Private Method

@MainActor
private extension SettingsScreen {

    /// 以 identifier 命中畫面上的元素 (不限型別)
    ///
    /// - Parameter identifier: 目標元素的 accessibility identifier
    /// - Returns: 命中的畫面元素
    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
