//
//  FxInputFocusUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/5.
//

import XCTest

/// 匯率金額欄位聚焦、還原與快捷金額的 UI 測試
@MainActor
final class FxInputFocusUITests: BLUITestCase {

    /// 驗證匯率金額從左側取得焦點後輸入 5，輸入立即取代預設金額且收鍵盤後保留
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusAmountFromLeft_輸入5_取代預設金額() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let fx = try FxScreen.open(in: app)
        try fx.focusAmountFromLeft()

        // When
        fx.amountField.typeText("5")
        _ = Polling.wait(timeout: 3) {
            fx.amountFieldValue() == "5"
        }
        let editingValue = fx.amountFieldValue()
        try fx.dismissAmountKeyboard()
        _ = Polling.wait(timeout: 3) {
            fx.amountFieldValue() == "5"
        }
        let finalValue = fx.amountFieldValue()

        // Then
        XCTAssertEqual(editingValue, "5", "輸入中應只顯示新輸入的 5")
        XCTAssertEqual(finalValue, "5", "收鍵盤後應保留新輸入的 5")
    }

    /// 驗證匯率金額只聚焦不輸入時，聚焦中顯示提示文字，收鍵盤後還原預設金額
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusAmountFromLeft_只聚焦不輸入_收鍵盤後還原預設金額() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let fx = try FxScreen.open(in: app)

        // When
        try fx.focusAmountFromLeft()
        let focusedValue = fx.amountFieldValue()
        try fx.dismissAmountKeyboard()
        _ = Polling.wait(timeout: 3) {
            fx.amountFieldValue() == "150000"
        }
        let finalValue = fx.amountFieldValue()

        // Then
        XCTAssertEqual(focusedValue, "輸入金額", "聚焦中的金額欄應顯示提示文字")
        XCTAssertEqual(finalValue, "150000", "未輸入就失焦應還原預設金額")
    }

    /// 驗證未聚焦時點 50000 快捷金額按鈕，金額欄直接顯示 50000，不經過聚焦清空流程
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testQuickAmountTapped_未聚焦時點按鈕_金額欄顯示該金額() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let fx = try FxScreen.open(in: app)

        // When
        try fx.tapPresetAmount("50000")

        // Then
        _ = Polling.wait(timeout: 3) {
            fx.amountFieldValue() == "50000"
        }
        XCTAssertEqual(fx.amountFieldValue(), "50000", "點快捷金額後金額欄應顯示該金額")
    }
}
