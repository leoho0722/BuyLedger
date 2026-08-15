//
//  KeyboardDismissTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/20.
//

import XCTest

/// 訂單編輯表單收鍵盤路徑的回歸測試
final class KeyboardDismissTests: BLUITestCase {

    // MARK: - Tests

    /// 一般文字鍵盤的 return 應收起鍵盤
    @MainActor
    func testReturnKeyDismissesTextKeyboard() {
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = openNewOrderForm(in: app)
        edit.typeCustomerName("測試客戶")

        let keyboard = app.keyboards.firstMatch
        if !keyboard.waitForExistence(timeout: 5) {
            failWithDiagnostics(in: app, "輸入後鍵盤未呈現")
        }

        edit.submitCustomerName()

        XCTAssertTrue(
            keyboard.waitForDisappearance(timeout: 5),
            "一般鍵盤的 return 應收起鍵盤"
        )
    }

    /// 數字鍵盤的工具列完成鍵應收起鍵盤
    @MainActor
    func testNumericKeyboardToolbarDismissesKeyboard() {
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = openNewOrderForm(in: app)
        edit.typeChargedAmount("123", in: app, dismissKeyboard: false)

        let keyboard = app.keyboards.firstMatch
        if !keyboard.waitForExistence(timeout: 5) {
            failWithDiagnostics(in: app, "聚焦實付金額後數字鍵盤未呈現")
        }

        if !app.buttons[BLAccessibilityID.Common.keyboardDoneButton].waitUntilHittable(timeout: 5) {
            failWithDiagnostics(in: app, "數字鍵盤工具列的完成鍵未呈現")
        }
        edit.tapNumericKeyboardDone()

        XCTAssertTrue(
            keyboard.waitForDisappearance(timeout: 5),
            "數字鍵盤的工具列完成鍵應收起鍵盤"
        )
    }
}

// MARK: - Private Method

private extension KeyboardDismissTests {

    /// 切到訂單分頁並開啟新訂單表單
    /// - Parameter app: 受測 App
    /// - Returns: 已就緒的訂單編輯表單 Page Object
    @MainActor
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
