//
//  OrderEditKeyboardDismissUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/20.
//

import XCTest

/// 訂單編輯表單收起文字與數字鍵盤的 UI 測試
@MainActor
final class OrderEditKeyboardDismissUITests: BLUITestCase {

    /// 驗證新增訂單輸入客戶名稱並顯示文字鍵盤後，按 return 可收起鍵盤
    ///
    /// - Throws: 必要的 UI 操作或文字鍵盤未呈現時丟出 UITestError.stopped
    func testSubmitCustomerName_文字鍵盤顯示中_按return收起鍵盤() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        try edit.typeCustomerName("測試客戶")
        let keyboard = app.keyboards.firstMatch
        try requireCondition(keyboard.waitForExistence(timeout: 5), in: app, "輸入後鍵盤未呈現")

        // When
        try edit.submitCustomerName()

        // Then
        XCTAssertTrue(keyboard.waitForDisappearance(timeout: 5), "一般鍵盤的 return 應收起鍵盤")
    }

    /// 驗證實付金額顯示數字鍵盤或 Popover 時，點完成可收起鍵盤並保留輸入值
    ///
    /// - Throws: 必要的 UI 操作或數字鍵盤未呈現時丟出 UITestError.stopped
    func testTapNumericKeyboardDone_數字鍵盤顯示中_收起鍵盤() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        try edit.typeChargedAmount("123", shouldDismissKeyboard: false)
        try requireCondition(
            app.waitForNumericKeyboardPresentation(timeout: 5),
            in: app,
            "聚焦實付金額後數字鍵盤或 Popover 未呈現"
        )

        // When
        try edit.tapNumericKeyboardDone()

        // Then
        XCTAssertTrue(app.waitForNumericKeyboardDismissal(timeout: 5), "數字鍵盤與 Popover 應收起")
        XCTAssertEqual(edit.chargedAmountValue, "123", "收起鍵盤後實付金額應保留輸入值")
    }
}
