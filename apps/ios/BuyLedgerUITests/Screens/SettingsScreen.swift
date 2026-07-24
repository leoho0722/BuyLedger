//
//  SettingsScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 設定頁的 Page Object
///
/// 對外只暴露語意操作 (開語言選擇器、填每月目標、切 AI 總結開關等)，元素查詢細節不外洩給測試檔；
/// 進到本頁的路徑是「更多」分頁的設定列，由 ``navigate(in:)`` 以 ``AppNavigator`` 直接驅動
struct SettingsScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 設定頁的畫面根 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Settings.root
    }

    /// 版本資訊列承載的文字 (label 串接 value)，列不存在時回 nil
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
    /// 呼叫端若已自行導航到位，可略過本方法、直接建 ``SettingsScreen`` 後 `waitUntilReady()`
    /// - Parameter app: 受測 App
    /// - Returns: 已等待就緒的設定頁 Page Object
    static func navigate(in app: XCUIApplication) -> SettingsScreen {
        AppNavigator(app: app).selectTab(.more)
        _ = app.descendants(matching: .any)[BLAccessibilityID.More.root].waitForExistence(timeout: 10)

        let settingsRow = app.descendants(matching: .any)[BLAccessibilityID.More.row(.settings)]
        settingsRow.waitUntilHittable()
        settingsRow.tap()

        let screen = SettingsScreen(app: app)
        screen.waitUntilReady()
        return screen
    }

    /// 點語言選擇列開啟語言選擇器
    func openLanguagePicker() {
        let picker = element(BLAccessibilityID.Settings.languagePicker)
        picker.waitUntilHittable()
        picker.tap()
    }

    /// 填入每月目標金額 (清空舊值後輸入再收數字鍵盤)
    /// - Parameter value: 目標金額 (TWD)
    func setMonthlyGoal(_ value: Int) {
        let field = app.textFields[BLAccessibilityID.Settings.monthlyGoalField]
        field.waitUntilHittable()
        field.clearAndType(String(value), in: app)
        field.dismissNumericKeyboard(in: app)
    }

    /// 切換 AI 總結開關
    func toggleAiSummary() {
        let toggle = app.switches[BLAccessibilityID.Settings.aiSummaryToggle]
        toggle.waitUntilHittable()
        toggle.tap()
    }

    /// 點預設幣別列推進到幣別選擇器
    func openDefaultCurrency() {
        let row = element(BLAccessibilityID.Settings.defaultCurrencyRow)
        row.waitUntilHittable()
        row.tap()
    }
}

// MARK: - Private Method

private extension SettingsScreen {

    /// 以 identifier 命中畫面上的元素 (不限型別)
    /// - Parameter identifier: 目標元素的 accessibility identifier
    /// - Returns: 對應的元素查詢
    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
