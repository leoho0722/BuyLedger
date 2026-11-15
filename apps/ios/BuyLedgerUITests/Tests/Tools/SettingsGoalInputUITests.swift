//
//  SettingsGoalInputUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

import XCTest

/// 設定頁每月目標金額轉向續輸入與鍵盤狀態的 UI 測試
@MainActor
final class SettingsGoalInputUITests: BLUITestCase {

    /// 驗證目標金額欄輸入後旋轉，再續輸入的數字仍寫回同一欄並保持鍵盤焦點
    ///
    /// - Throws: 目標金額欄未就緒、旋轉失敗或欄位失去焦點時丟出 UITestError.stopped
    func testMonthlyProfitGoalTWD_轉向後續輸入_目標金額寫回同一欄() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let settings = try SettingsScreen.open(in: app)
        try settings.replaceMonthlyGoal("9")

        // When
        try rotateToLandscape(app)

        // Then
        try requireCondition(settings.isMonthlyGoalFieldFocused(), in: app, "旋轉後目標金額欄失去鍵盤焦點")

        // When
        settings.appendMonthlyGoal("0")

        // Then
        let value = try requireValue(settings.monthlyGoalFieldValue(), in: app, "旋轉後目標金額欄元素不存在")
        XCTAssertEqual(value, "90", "旋轉後續輸入的數字應寫回目標金額欄")
    }

    /// 驗證使用者收起數字鍵盤後旋轉，目標金額輸入值保留，鍵盤與目標金額欄焦點維持收起，不因重排重新彈出
    ///
    /// - Throws: 目標金額欄未就緒或旋轉失敗時丟出 UITestError.stopped
    func testRotateToLandscape_收鍵盤後轉向_鍵盤保持收起() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let settings = try SettingsScreen.open(in: app)
        try settings.replaceMonthlyGoal("9")
        try settings.dismissMonthlyGoalKeyboard()

        // When
        try rotateToLandscape(app)

        // Then
        let value = try requireValue(settings.monthlyGoalFieldValue(), in: app, "收鍵盤後旋轉目標金額欄元素不存在")
        XCTAssertEqual(value, "9", "收鍵盤後旋轉，目標金額欄應保留使用者輸入的值")
        XCTAssertFalse(settings.isMonthlyGoalFieldFocused(), "使用者收起鍵盤後，旋轉不應把目標金額欄重新設為焦點")
        if !app.keyboards.firstMatch.waitForNonExistence(timeout: 3) {
            failWithDiagnostics(in: app, "使用者收起鍵盤後旋轉，鍵盤被重新彈出")
        }
    }
}
