//
//  SettingsGoalInputTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

import XCTest

/// 設定頁每月目標金額欄的續輸入與收鍵盤後旋轉 UI 測試
@MainActor
final class SettingsGoalInputTests: BLUITestCase {

    /// 驗證目標金額欄輸入後旋轉，再續輸入的數字仍寫回同一欄並保持鍵盤焦點
    ///
    /// - Throws: 目標金額欄未就緒、旋轉失敗或欄位失去焦點時丟出測試錯誤
    func testContinueTyping_旋轉後續輸入_目標金額寫回同一欄() throws {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        let settings = SettingsScreen.navigate(in: app)
        settings.replaceMonthlyGoal("9")

        // When
        try rotateToLandscape(app)

        // Then
        try requireCondition(settings.isMonthlyGoalFieldFocused(), in: app, "旋轉後目標金額欄失去鍵盤焦點")

        // When
        settings.appendMonthlyGoal("0")

        // Then
        let value = try requireValue(settings.monthlyGoalFieldValue, in: app, "旋轉後目標金額欄元素不存在")
        XCTAssertEqual(value, "90", "旋轉後續輸入的數字應寫回目標金額欄")
    }

    /// 驗證使用者收起數字鍵盤後旋轉，目標金額輸入值保留，鍵盤與目標金額欄焦點維持收起，不因重排重新彈出
    ///
    /// - Throws: 目標金額欄未就緒或旋轉失敗時丟出測試錯誤
    func testKeyboardDismissal_收鍵盤後旋轉_鍵盤保持收起() throws {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        let settings = SettingsScreen.navigate(in: app)
        settings.replaceMonthlyGoal("9")
        settings.dismissMonthlyGoalKeyboard()

        // When
        try rotateToLandscape(app)

        // Then
        let value = try requireValue(settings.monthlyGoalFieldValue, in: app, "收鍵盤後旋轉目標金額欄元素不存在")
        XCTAssertEqual(value, "9", "收鍵盤後旋轉，目標金額欄應保留使用者輸入的值")
        XCTAssertFalse(settings.isMonthlyGoalFieldFocused(), "使用者收起鍵盤後，旋轉不應把目標金額欄重新設為焦點")
        if !app.keyboards.firstMatch.waitForNonExistence(timeout: 3) {
            failWithDiagnostics(in: app, "使用者收起鍵盤後旋轉，鍵盤被重新彈出")
        }
    }
}
