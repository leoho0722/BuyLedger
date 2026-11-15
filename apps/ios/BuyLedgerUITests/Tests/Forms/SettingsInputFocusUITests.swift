//
//  SettingsInputFocusUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 設定頁每月目標欄位聚焦與還原的 UI 測試
@MainActor
final class SettingsInputFocusUITests: BLUITestCase {

    /// 驗證每月目標從左側取得焦點後輸入 1，輸入立即取代原值且收鍵盤後保留
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusMonthlyGoalFromLeft_輸入1_取代原值() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let settings = try SettingsScreen.open(in: app)
        try settings.focusMonthlyGoalFromLeft()

        // When
        settings.monthlyGoalField.typeText("1")
        _ = Polling.wait(timeout: 3) {
            settings.monthlyGoalFieldValue() == "1"
        }
        let editingValue = settings.monthlyGoalFieldValue()
        try settings.dismissMonthlyGoalKeyboard()
        _ = Polling.wait(timeout: 3) {
            settings.monthlyGoalFieldValue() == "1"
        }
        let finalValue = settings.monthlyGoalFieldValue()

        // Then
        XCTAssertEqual(editingValue, "1", "輸入中應只顯示新輸入的 1")
        XCTAssertEqual(finalValue, "1", "收鍵盤後應保留新輸入的 1")
    }

    /// 驗證每月目標只聚焦不輸入時，聚焦中顯示提示文字，收鍵盤後還原 80000
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusMonthlyGoalFromLeft_只聚焦不輸入_收鍵盤後還原80000() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let settings = try SettingsScreen.open(in: app)

        // When
        try settings.focusMonthlyGoalFromLeft()
        let focusedValue = settings.monthlyGoalFieldValue()
        try settings.dismissMonthlyGoalKeyboard()
        _ = Polling.wait(timeout: 3) {
            settings.monthlyGoalFieldValue() == "80000"
        }
        let finalValue = settings.monthlyGoalFieldValue()

        // Then
        XCTAssertEqual(focusedValue, "目標金額", "聚焦中的目標金額欄應顯示提示文字")
        XCTAssertEqual(finalValue, "80000", "未輸入就失焦應還原 80000")
    }

    /// 驗證每月目標輸入後全部刪除會還原 80000，返回再進設定頁仍為 80000
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusMonthlyGoalFromLeft_輸入後全部刪除_返回再進仍為80000() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let settings = try SettingsScreen.open(in: app)
        try settings.focusMonthlyGoalFromLeft()
        settings.monthlyGoalField.typeText("1")
        _ = Polling.wait(timeout: 3) {
            settings.monthlyGoalFieldValue() == "1"
        }

        // When
        settings.monthlyGoalField.typeText(XCUIKeyboardKey.delete.rawValue)
        _ = Polling.wait(timeout: 3) {
            settings.monthlyGoalFieldValue() == "目標金額"
        }
        let emptiedValue = settings.monthlyGoalFieldValue()
        try settings.dismissMonthlyGoalKeyboard()
        _ = Polling.wait(timeout: 3) {
            settings.monthlyGoalFieldValue() == "80000"
        }
        let finalValue = settings.monthlyGoalFieldValue()
        // 並排版面的設定頁是詳情欄根畫面，沒有返回鍵
        if try moreLayout(in: app) == .compact {
            try settings.goBack()
        }
        let reopened = try SettingsScreen.open(in: app)
        _ = Polling.wait(timeout: 3) {
            reopened.monthlyGoalFieldValue() == "80000"
        }
        let reopenedValue = reopened.monthlyGoalFieldValue()

        // Then
        XCTAssertEqual(emptiedValue, "目標金額", "刪除唯一輸入的字元後欄位應為空，空欄的 value 會讀到提示文字")
        XCTAssertEqual(finalValue, "80000", "輸入後全部刪除應還原聚焦當下的 80000")
        XCTAssertEqual(reopenedValue, "80000", "返回再進設定頁，目標金額應仍為 80000")
    }
}
