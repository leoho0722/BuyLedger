//
//  SettingsScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 設定頁的 Page Object
struct SettingsScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 設定頁的畫面根 identifier
    ///
    /// - Returns: 設定頁的根 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Settings.root
    }

    /// 版本資訊列承載的文字 (label 串接 value)，列不存在時回 nil
    ///
    /// - Returns: 版本資訊列的合併文字；列不存在時為 `nil`
    var versionText: String? {
        let row = element(BLAccessibilityID.Settings.versionRow)
        guard row.exists else {
            return nil
        }
        return row.combinedText
    }
}

// MARK: - Internal Method

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
        let moreRoot = app.descendants(matching: .any)[BLAccessibilityID.More.root]
        guard moreRoot.waitUntilHittableOrFail(
            in: app,
            timeout: 10,
            file: file,
            line: line
        ) else {
            return SettingsScreen(app: app)
        }

        let settingsRow = app.descendants(matching: .any)[BLAccessibilityID.More.row(.settings)]
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
    func setMonthlyGoal(
        _ value: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
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
    func toggleAiSummary(file: StaticString = #filePath, line: UInt = #line) {
        let toggle = app.switches[BLAccessibilityID.Settings.aiSummaryToggle]
        toggle.tapAfterWaiting(in: app, file: file, line: line)
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
}

// MARK: - Private Method

private extension SettingsScreen {

    /// 以 identifier 命中畫面上的元素 (不限型別)
    ///
    /// - Parameter identifier: 目標元素的 accessibility identifier
    /// - Returns: 命中的畫面元素
    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
