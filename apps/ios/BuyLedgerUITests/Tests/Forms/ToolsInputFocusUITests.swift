//
//  ToolsInputFocusUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/5.
//

import XCTest

/// 匯率金額與設定頁每月目標欄位的聚焦清空、快捷金額與還原 UI 測試
@MainActor
final class ToolsInputFocusUITests: BLUITestCase {

    /// 驗證匯率金額從左側取得焦點後輸入 5，輸入立即取代預設金額且收鍵盤後保留
    func testFocusAmountFromLeft_輸入5_取代預設金額() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        let fx = FxScreen.open(from: app)
        guard fx.waitUntilReady() else {
            app.failWithDiagnostics("匯率頁尚未就緒")
            return
        }
        guard fx.focusAmountFromLeft() else {
            return
        }

        // When
        fx.amountField.typeText("5")
        _ = pollUntil(timeout: 3) {
            fx.amountFieldValue == "5"
        }
        let editingValue = fx.amountFieldValue
        fx.dismissAmountKeyboard()
        _ = pollUntil(timeout: 3) {
            fx.amountFieldValue == "5"
        }
        let finalValue = fx.amountFieldValue

        // Then
        XCTAssertEqual(editingValue, "5", "輸入中應只顯示新輸入的 5")
        XCTAssertEqual(finalValue, "5", "收鍵盤後應保留新輸入的 5")
    }

    /// 驗證匯率金額只聚焦不輸入時，聚焦中顯示提示文字，收鍵盤後還原預設金額
    func testFocusAmountFromLeft_只聚焦不輸入_收鍵盤後還原預設金額() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        let fx = FxScreen.open(from: app)
        guard fx.waitUntilReady() else {
            app.failWithDiagnostics("匯率頁尚未就緒")
            return
        }

        // When
        guard fx.focusAmountFromLeft() else {
            return
        }
        let focusedValue = fx.amountFieldValue
        fx.dismissAmountKeyboard()
        _ = pollUntil(timeout: 3) {
            fx.amountFieldValue == "150000"
        }
        let finalValue = fx.amountFieldValue

        // Then
        XCTAssertEqual(focusedValue, "輸入金額", "聚焦中的金額欄應顯示提示文字")
        XCTAssertEqual(finalValue, "150000", "未輸入就失焦應還原預設金額")
    }

    /// 驗證未聚焦時點 50000 快捷金額按鈕，金額欄直接顯示 50000，不經過聚焦清空流程
    func testTapPresetAmount_未聚焦時點按鈕_金額欄顯示該金額() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        let fx = FxScreen.open(from: app)
        guard fx.waitUntilReady() else {
            app.failWithDiagnostics("匯率頁尚未就緒")
            return
        }

        // When
        fx.tapPresetAmount("50000")

        // Then
        _ = pollUntil(timeout: 3) {
            fx.amountFieldValue == "50000"
        }
        XCTAssertEqual(fx.amountFieldValue, "50000", "點快捷金額後金額欄應顯示該金額")
    }

    /// 驗證每月目標從左側取得焦點後輸入 1，輸入立即取代原值且收鍵盤後保留
    func testFocusMonthlyGoalFromLeft_輸入1_取代原值() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        let settings = SettingsScreen.navigate(in: app)
        guard settings.focusMonthlyGoalFromLeft() else {
            return
        }

        // When
        settings.monthlyGoalField.typeText("1")
        _ = pollUntil(timeout: 3) {
            settings.monthlyGoalFieldValue == "1"
        }
        let editingValue = settings.monthlyGoalFieldValue
        settings.dismissMonthlyGoalKeyboard()
        _ = pollUntil(timeout: 3) {
            settings.monthlyGoalFieldValue == "1"
        }
        let finalValue = settings.monthlyGoalFieldValue

        // Then
        XCTAssertEqual(editingValue, "1", "輸入中應只顯示新輸入的 1")
        XCTAssertEqual(finalValue, "1", "收鍵盤後應保留新輸入的 1")
    }

    /// 驗證每月目標只聚焦不輸入時，聚焦中顯示提示文字，收鍵盤後還原 80000
    func testFocusMonthlyGoalFromLeft_只聚焦不輸入_收鍵盤後還原80000() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        let settings = SettingsScreen.navigate(in: app)

        // When
        guard settings.focusMonthlyGoalFromLeft() else {
            return
        }
        let focusedValue = settings.monthlyGoalFieldValue
        settings.dismissMonthlyGoalKeyboard()
        _ = pollUntil(timeout: 3) {
            settings.monthlyGoalFieldValue == "80000"
        }
        let finalValue = settings.monthlyGoalFieldValue

        // Then
        XCTAssertEqual(focusedValue, "目標金額", "聚焦中的目標金額欄應顯示提示文字")
        XCTAssertEqual(finalValue, "80000", "未輸入就失焦應還原 80000")
    }

    /// 驗證每月目標輸入後全部刪除會還原 80000，返回再進設定頁仍為 80000
    func testFocusMonthlyGoalFromLeft_輸入後全部刪除_返回再進仍為80000() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        let settings = SettingsScreen.navigate(in: app)
        guard settings.focusMonthlyGoalFromLeft() else {
            return
        }
        settings.monthlyGoalField.typeText("1")
        _ = pollUntil(timeout: 3) {
            settings.monthlyGoalFieldValue == "1"
        }

        // When
        settings.monthlyGoalField.typeText(XCUIKeyboardKey.delete.rawValue)
        _ = pollUntil(timeout: 3) {
            settings.monthlyGoalFieldValue == "目標金額"
        }
        let emptiedValue = settings.monthlyGoalFieldValue
        settings.dismissMonthlyGoalKeyboard()
        _ = pollUntil(timeout: 3) {
            settings.monthlyGoalFieldValue == "80000"
        }
        let finalValue = settings.monthlyGoalFieldValue
        // 並排版面的設定頁是詳情欄根畫面，沒有返回鍵
        if isMoreCompactLayout(app) {
            settings.goBack()
        }
        let reopened = SettingsScreen.navigate(in: app)
        _ = pollUntil(timeout: 3) {
            reopened.monthlyGoalFieldValue == "80000"
        }
        let reopenedValue = reopened.monthlyGoalFieldValue

        // Then
        XCTAssertEqual(emptiedValue, "目標金額", "刪除唯一輸入的字元後欄位應為空，空欄的 value 會讀到提示文字")
        XCTAssertEqual(finalValue, "80000", "輸入後全部刪除應還原聚焦當下的 80000")
        XCTAssertEqual(reopenedValue, "80000", "返回再進設定頁，目標金額應仍為 80000")
    }
}
