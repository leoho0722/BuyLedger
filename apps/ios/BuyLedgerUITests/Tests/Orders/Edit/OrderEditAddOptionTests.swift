//
//  OrderEditAddOptionTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/17.
//

import XCTest

/// 在訂單編輯表單內新增主檔選項的 UI 流程測試
@MainActor
final class OrderEditAddOptionTests: BLUITestCase {

    // MARK: - Properties

    /// 新增的訂單來源名稱，以英文避免輸入法影響輸入
    private static let newOrderSource = "Pinkoi"

    /// 新增的付款方式名稱，以英文避免輸入法影響輸入
    private static let newPaymentMethod = "JKO Pay"

    /// 驗證在訂單來源選擇器新增「Pinkoi」後，選擇器關閉，表單的訂單來源改為選取該項目
    func testAddOrderSource_從訂單來源選擇器輸入名稱新增_關閉選擇器並選取新來源() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = openOrderEdit(app)
        let picker = OptionPickerScreen(app: app)
        // 新訂單會自動聚焦客戶名稱，先收起鍵盤才不會擋住選擇器入口
        edit.submitCustomerName()
        edit.openSourcePicker()
        if !picker.waitUntilReady() {
            failWithDiagnostics(in: app, "訂單來源選擇器未就緒")
        }
        picker.tapAdd()
        picker.typeNewOptionName(Self.newOrderSource)

        // When
        picker.confirmAdd()

        // Then
        if !picker.rootElement.waitForDisappearance() {
            failWithDiagnostics(in: app, "送出後訂單來源選擇器未關閉")
        }
        if !edit.waitUntilReady() {
            failWithDiagnostics(in: app, "送出後訂單表單未就緒，表單可能被關閉")
        }
        let sourceRow = app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.sourceRow]
        let selectsNewSource = NSPredicate(format: "label CONTAINS %@", Self.newOrderSource)
        if !sourceRow.wait(for: selectsNewSource, timeout: 10) {
            failWithDiagnostics(in: app, "訂單表單的訂單來源未選取新增的項目")
        }
    }

    /// 驗證在付款方式選擇器新增「JKO Pay」後，選擇器出現該項目，返回的訂單表單付款方式改選該項目
    ///
    /// - Note: 同次新增付款方式後返回原表單，後續觀察用來確認表單未關閉且已選取新增項目
    func testAddPaymentMethod_從付款方式選擇器新增_回到選擇器且表單保留() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = openOrderEdit(app)
        let picker = OptionPickerScreen(app: app)
        let editor = PaymentMethodEditorScreen(app: app)
        // 新訂單會自動聚焦客戶名稱，先收起鍵盤才點得到下方的付款方式列
        edit.submitCustomerName()
        edit.openPaymentPicker()
        if !picker.waitUntilReady() {
            failWithDiagnostics(in: app, "付款方式選擇器未就緒")
        }
        picker.tapAdd()
        if !editor.waitUntilReady() {
            failWithDiagnostics(in: app, "點新增付款方式後編輯器未就緒")
        }
        editor.typeName(Self.newPaymentMethod)

        // When
        editor.tapSave()

        // Then
        if !editor.rootElement.waitForDisappearance() {
            failWithDiagnostics(in: app, "送出後付款方式編輯器未收起")
        }
        if !picker.waitUntilReady() {
            failWithDiagnostics(in: app, "送出後沒有回到付款方式選擇器，訂單表單可能被關閉")
        }
        let newRow = app.descendants(matching: .any)[
            BLAccessibilityID.OptionPicker.optionRow(Self.newPaymentMethod)
        ]
        if !newRow.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "新增的付款方式未出現在選擇器")
        }
        picker.tapBack()
        if !edit.waitUntilReady() {
            failWithDiagnostics(in: app, "從選擇器返回後訂單表單未就緒")
        }
        let paymentRow = app.buttons[BLAccessibilityID.OrderEdit.paymentRow]
        let selectsNewMethod = NSPredicate(format: "label CONTAINS %@", Self.newPaymentMethod)
        if !paymentRow.wait(for: selectsNewMethod, timeout: 10) {
            failWithDiagnostics(in: app, "訂單表單的付款方式未選取新增的項目")
        }
    }
}

// MARK: - Private Method

private extension OrderEditAddOptionTests {

    /// 切到訂單分頁、點新增並等編輯表單就緒
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 已就緒的訂單編輯表單 Page Object
    func openOrderEdit(_ app: XCUIApplication) -> OrderEditScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders() {
            failWithDiagnostics(in: app, "切到訂單分頁後畫面未就緒")
        }
        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            failWithDiagnostics(in: app, "訂單清單未就緒")
        }
        orders.tapAddOrder()
        let edit = OrderEditScreen(app: app)
        if !edit.waitUntilReady() {
            failWithDiagnostics(in: app, "點新增後訂單編輯表單未就緒")
        }
        return edit
    }
}
