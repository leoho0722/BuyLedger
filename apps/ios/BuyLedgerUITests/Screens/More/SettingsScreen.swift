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

    /// 版本資訊列的合併文字 (`label` 串接 `value`)，列不存在時為 `nil`
    var versionText: String? {
        let row = element(BLAccessibilityID.Settings.versionRow)
        guard row.exists else {
            return nil
        }
        return row.combinedText
    }

    /// 每月目標金額欄位
    var monthlyGoalField: XCUIElement {
        app.textFields[BLAccessibilityID.Settings.monthlyGoalField].firstMatch
    }

    /// 每月目標金額欄目前的文字值
    ///
    /// - Returns: 目標金額欄的文字值；元素不存在或值不是字串時為 `nil`
    var monthlyGoalFieldValue: String? {
        let field = app.textFields[BLAccessibilityID.Settings.monthlyGoalField]
        guard field.waitForExistence(timeout: 10) else {
            return nil
        }
        return field.value as? String
    }
}

// MARK: - Internal Method

@MainActor
extension SettingsScreen {

    /// 從「更多」分頁導航到設定頁並回傳就緒的 Page Object
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的設定頁 Page Object
    static func navigate(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> SettingsScreen {
        AppNavigator(app: app).selectTab(.more, file: file, line: line)
        // 更多根是全頁 CollectionView，iPhone 上可能長期不可點，只等存在後再點入口列
        let moreRoot = app.descendants(matching: .any)[BLAccessibilityID.More.root]
        guard moreRoot.waitForExistence(timeout: 10) else {
            app.failWithDiagnostics(
                "更多根 identifier「\(BLAccessibilityID.More.root)」逾時仍未出現",
                file: file,
                line: line
            )
            return SettingsScreen(app: app)
        }

        let settingsRow = app.descendants(matching: .any)[BLAccessibilityID.More.row(.settings)]
        // 橫向 iPhone 的更多清單較短，設定入口列可能在下方未建立或露在視窗外，先捲入可點範圍
        if !settingsRow.isHittableOnScreen,
           !app.scrollToHittableGently(settingsRow, within: moreRoot),
           !app.scrollToHittable(settingsRow, within: moreRoot) {
            app.failWithDiagnostics("更多清單捲動後仍找不到可點的設定入口列", file: file, line: line)
            return SettingsScreen(app: app)
        }
        settingsRow.tapAfterWaiting(in: app, file: file, line: line)

        let screen = SettingsScreen(app: app)
        if !screen.waitUntilReady() {
            app.failWithDiagnostics(
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
    func openLanguagePicker(file: StaticString = #filePath, line: UInt = #line) {
        let picker = element(BLAccessibilityID.Settings.languagePicker)
        picker.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 填入每月目標金額 (清空舊值後輸入再收數字鍵盤)
    ///
    /// - Parameters:
    ///   - value: 每月目標金額
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func setMonthlyGoal(_ value: Int, file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[BLAccessibilityID.Settings.monthlyGoalField]
        field.clearAndType(
            String(value),
            in: app,
            file: file,
            line: line
        )
        field.dismissNumericKeyboard(in: app, file: file, line: line)
    }

    /// 切換 AI 總結開關
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func toggleAISummary(file: StaticString = #filePath, line: UInt = #line) {
        let toggle = app.switches[BLAccessibilityID.Settings.aiSummaryToggle]
        if !toggle.waitForExistence(timeout: 10) {
            app.failWithDiagnostics("找不到 AI 總結開關", file: file, line: line)
            return
        }
        let previousValue = toggle.value as? String ?? ""
        toggle.switches.firstMatch.tapAfterWaiting(in: app, file: file, line: line)
        let changed = NSPredicate(format: "value != %@", previousValue)
        if !toggle.wait(for: changed, timeout: 5) {
            app.failWithDiagnostics("點擊後 AI 總結開關的值沒有改變", file: file, line: line)
        }
    }

    /// 點預設幣別列推進到幣別選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openDefaultCurrency(file: StaticString = #filePath, line: UInt = #line) {
        let row = element(BLAccessibilityID.Settings.defaultCurrencyRow)
        row.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 清空每月目標金額欄後輸入新文字，之後鍵盤焦點保留在目標金額欄
    ///
    /// - Parameters:
    ///   - text: 要輸入的文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func replaceMonthlyGoal(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[BLAccessibilityID.Settings.monthlyGoalField]
        field.clearAndType(
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
    /// - Returns: 目標金額欄是否已從左側點擊取得焦點且鍵盤就緒
    @discardableResult
    func focusMonthlyGoalFromLeft(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        let field = monthlyGoalField
        if !field.isHittableOnScreen, !app.scrollToHittable(field, within: rootElement) {
            app.failWithDiagnostics("捲動後目標金額欄位仍未穩定或不可點", file: file, line: line)
            return false
        }
        return field.tapLeftToFocus(in: app, file: file, line: line)
    }

    /// 點返回鍵回到上一層畫面
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func goBack(file: StaticString = #filePath, line: UInt = #line) {
        let back = app.buttons[BLAccessibilityID.Common.backButton].firstMatch
        back.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 判定每月目標金額欄是否取得鍵盤焦點
    ///
    /// - Returns: 目標金額欄是否為鍵盤焦點
    func isMonthlyGoalFieldFocused() -> Bool {
        let field = app.textFields[BLAccessibilityID.Settings.monthlyGoalField]
        return field.exists && NSPredicate(format: "hasKeyboardFocus == true").evaluate(with: field)
    }

    /// 收起每月目標金額欄的數字鍵盤
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func dismissMonthlyGoalKeyboard(file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[BLAccessibilityID.Settings.monthlyGoalField]
        field.dismissNumericKeyboard(in: app, file: file, line: line)
    }
}

// MARK: - Screen

extension SettingsScreen: Screen {

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
