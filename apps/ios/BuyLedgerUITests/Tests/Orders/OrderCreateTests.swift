//
//  OrderCreateTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 新增訂單的表單就緒、必填驗證與完整建單流程測試
final class OrderCreateTests: BLUITestCase {

    // MARK: - Static Properties

    /// 建單填入的客戶名稱 (使用者資料，中英兩語言皆可輸入)
    private static let customerName = "測試客戶"

    /// 選取的訂單來源 (lookupsOnly 主檔既有項目)
    private static let orderSource = "蝦皮"

    /// 選取的商品類別 (lookupsOnly 主檔既有項目)
    private static let category = "美妝"

    /// 填入的客戶實付金額
    private static let chargedAmount = "4200"

    // MARK: - Tests

    /// 從訂單分頁點新增後，編輯表單就緒
    @MainActor
    func testTapAddOpensOrderEditForm() {
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = openOrderEdit(app)

        _ = edit
    }

    /// 填完必填欄位後，儲存按鈕應可用
    @MainActor
    func testSaveEnablesAfterRequiredFieldsFilled() {
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = openOrderEdit(app)

        // 剛開新表單：客戶名／來源／類別皆未填，儲存應停用
        if edit.isSaveEnabled {
            failWithDiagnostics(in: app, "新表單必填未齊時儲存不應可用")
        }

        edit.typeCustomerName(Self.customerName)
        selectFromPicker(app, open: { edit.openSourcePicker() }, value: Self.orderSource)
        selectFromPicker(app, open: { edit.openCategoryPicker() }, value: Self.category)

        // 三項必填齊備後儲存應轉為可用 (可用的按鈕才可點)
        let saveButton = app.buttons[BLAccessibilityID.OrderEdit.saveButton]
        if !saveButton.wait(for: NSPredicate(format: "isEnabled == true"), timeout: 10) {
            failWithDiagnostics(in: app, "填完客戶名、來源與類別後儲存仍不可用")
        }
    }

    /// 建立訂單後，確認新訂單出現在清單
    @MainActor
    func testCreateOrderAppearsInList() {
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = openOrderEdit(app)

        // 先填數字欄，避免鍵盤影響後續欄位。
        edit.typeChargedAmount(Self.chargedAmount, in: app)
        edit.typeCustomerName(Self.customerName)
        selectFromPicker(app, open: { edit.openSourcePicker() }, value: Self.orderSource)
        selectFromPicker(app, open: { edit.openCategoryPicker() }, value: Self.category)

        edit.tapSave()

        // 回到訂單清單：lookupsOnly 原本無訂單，建立後清單應至少出現一列
        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            failWithDiagnostics(in: app, "儲存後訂單清單根 identifier「\(orders.rootIdentifier)」逾時仍未出現")
        }

        let prefix = BLAccessibilityID.Orders.row(orderID: "")
        let anyOrderRow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
            .firstMatch
        if !anyOrderRow.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "建立訂單後清單仍無任何訂單列")
        }
    }
}

// MARK: - Private Method

private extension OrderCreateTests {

    /// 切到訂單分頁、點新增並等編輯表單就緒，回傳編輯表單 Page Object
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 已就緒的訂單編輯表單 Page Object
    @MainActor
    func openOrderEdit(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OrderEditScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders() {
            failWithDiagnostics(in: app, "切到訂單分頁後畫面未就緒", file: file, line: line)
        }

        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "訂單清單根 identifier「\(orders.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }

        orders.tapAddOrder()

        let edit = OrderEditScreen(app: app)
        if !edit.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "點新增後編輯表單根 identifier「\(edit.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
        return edit
    }

    /// 開啟某個選擇器、等就緒後點選指定值
    /// - Parameters:
    ///   - app: 受測 App
    ///   - open: 開啟選擇器的操作
    ///   - value: 要選取的值
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    @MainActor
    func selectFromPicker(
        _ app: XCUIApplication,
        open: () -> Void,
        value: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        open()

        let picker = OptionPickerScreen(app: app)
        if !picker.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "選擇器根 identifier「\(picker.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }

        picker.selectOption(value)
    }
}
