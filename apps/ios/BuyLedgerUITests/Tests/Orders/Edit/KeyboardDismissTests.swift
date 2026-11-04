//
//  KeyboardDismissTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/20.
//

import XCTest

/// 訂單編輯表單收鍵盤路徑的回歸 UI 測試
@MainActor
final class KeyboardDismissTests: BLUITestCase {

    /// 驗證新增訂單表單的客戶名稱欄聚焦並顯示文字鍵盤時，按下 return 後鍵盤收起
    func testSubmitCustomerName_文字鍵盤顯示中_按return收起鍵盤() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = openNewOrderForm(in: app)
        edit.typeCustomerName("測試客戶")

        let keyboard = app.keyboards.firstMatch
        if !keyboard.waitForExistence(timeout: 5) {
            failWithDiagnostics(in: app, "輸入後鍵盤未呈現")
        }

        // When
        edit.submitCustomerName()

        // Then
        XCTAssertTrue(keyboard.waitForDisappearance(timeout: 5), "一般鍵盤的 return 應收起鍵盤")
    }

    /// 驗證新增訂單輸入金額並顯示數字鍵盤或數字 Popover 時，點完成鍵後鍵盤收起
    func testTapNumericKeyboardDone_數字鍵盤顯示中_收起鍵盤() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = openNewOrderForm(in: app)
        edit.typeChargedAmount("123", in: app, shouldDismissKeyboard: false)

        if !app.waitForNumericKeyboardPresentation(timeout: 5) {
            failWithDiagnostics(in: app, "聚焦實付金額後數字鍵盤或 Popover 未呈現")
        }

        // When
        edit.tapNumericKeyboardDone()

        // Then
        XCTAssertTrue(app.waitForNumericKeyboardDismissal(timeout: 5), "數字鍵盤與 Popover 應收起")
        let chargedAmountField = app.textFields[BLAccessibilityID.OrderEdit.chargedAmountField]
        XCTAssertEqual(chargedAmountField.value as? String, "123", "收起鍵盤後實付金額應保留輸入值")
    }
}

// MARK: - Private Method

private extension KeyboardDismissTests {

    /// 切到訂單分頁並開啟新訂單表單
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 已就緒的 `OrderEditScreen`
    func openNewOrderForm(in app: XCUIApplication) -> OrderEditScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders() {
            failWithDiagnostics(in: app, "無法切換到訂單分頁")
            return OrderEditScreen(app: app)
        }

        let orders = OrdersScreen(app: app)
        orders.tapAddOrder()

        let edit = OrderEditScreen(app: app)
        if !edit.waitUntilReady(timeout: 5) {
            failWithDiagnostics(in: app, "訂單編輯表單未出現")
        }
        return edit
    }
}
