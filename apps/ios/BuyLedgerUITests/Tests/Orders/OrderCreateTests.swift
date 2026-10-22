//
//  OrderCreateTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 新增訂單的預設幣別、必填驗證與完整建單流程測試
final class OrderCreateTests: BLUITestCase {

    // MARK: - Properties

    /// 建單填入的客戶名稱 (使用者資料，中英兩語言皆可輸入)
    private static let customerName = "測試客戶"

    /// 選取的訂單來源 (`lookupsOnly` 主檔既有項目)
    private static let orderSource = "蝦皮"

    /// 選取的商品類別 (`lookupsOnly` 主檔既有項目)
    private static let category = "美妝"

    /// 填入的客戶實付金額
    private static let chargedAmount = "4200"

    /// 從訂單分頁點新增時，預設日圓的新訂單顯示日圓且保留類別主檔選項
    ///
    /// - Throws: 訂單清單未就緒，或新訂單表單、幣別、類別選項不符預期時拋出測試錯誤
    @MainActor
    func testTapAddOrder_預設幣別日圓從訂單分頁開啟_幣別為日圓且有類別選項() throws(any Error) {
        // Given
        let app = launch(
            LaunchOptions(
                seed: .lookupsOnly,
                language: .traditionalChinese,
                defaultCurrencyCode: "JPY"
            )
        )
        let root = RootNavigationScreen(app: app)
        let orders = OrdersScreen(app: app)
        try requireCondition(root.goToOrders() && orders.waitUntilReady(), in: app, "訂單清單未就緒")

        // When
        orders.tapAddOrder()

        // Then
        try assertJapaneseYenNewOrder(OrderEditScreen(app: app), in: app)
    }

    /// 從首頁點建立第一筆訂單時，預設日圓的新訂單顯示日圓且保留類別主檔選項
    ///
    /// - Throws: 首頁未就緒，或新訂單表單、幣別、類別選項不符預期時拋出測試錯誤
    @MainActor
    func testTapCreateFirstOrder_預設幣別日圓從首頁開啟_幣別為日圓且有類別選項() throws(any Error) {
        // Given
        let app = launch(
            LaunchOptions(
                seed: .lookupsOnly,
                language: .traditionalChinese,
                defaultCurrencyCode: "JPY"
            )
        )
        let dashboard = DashboardScreen(app: app)
        try requireCondition(dashboard.waitUntilReady(), in: app, "首頁未就緒")

        // When
        dashboard.tapCreateFirstOrder()

        // Then
        try assertJapaneseYenNewOrder(OrderEditScreen(app: app), in: app)
    }

    /// 客戶名稱與訂單來源已填，再選商品類別後，儲存按鈕從停用轉為可用
    @MainActor
    func testSelectOption_客戶與來源已填後選商品類別_儲存按鈕轉為可用() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = openOrderEdit(app)
        // 剛開新表單：客戶名／來源／類別皆未填，儲存應停用
        if edit.isSaveEnabled() {
            failWithDiagnostics(in: app, "新表單必填未齊時儲存不應可用")
        }
        edit.typeCustomerName(Self.customerName)
        selectFromPicker(app, open: { edit.openSourcePicker() }, value: Self.orderSource)
        edit.openCategoryPicker()
        let picker = OptionPickerScreen(app: app)
        if !picker.waitUntilReady() {
            failWithDiagnostics(in: app, "商品類別選擇器根 identifier「\(picker.rootIdentifier)」逾時仍未出現")
        }

        // When
        picker.selectOption(Self.category)

        // Then
        // 三項必填齊備後儲存應轉為可用 (可用的按鈕才可點)
        let saveButton = app.buttons[BLAccessibilityID.OrderEdit.saveButton]
        if !saveButton.wait(for: NSPredicate(format: "isEnabled == true"), timeout: 10) {
            failWithDiagnostics(in: app, "填完客戶名、來源與類別後儲存仍不可用")
        }
    }

    /// 填完必填欄位與實付金額後儲存，新訂單出現在清單
    @MainActor
    func testTapSave_填寫必填與實付金額_清單出現新訂單() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = openOrderEdit(app)
        // 先填數字欄，避免鍵盤影響後續欄位
        edit.typeChargedAmount(Self.chargedAmount, in: app)
        edit.typeCustomerName(Self.customerName)
        selectFromPicker(app, open: { edit.openSourcePicker() }, value: Self.orderSource)
        selectFromPicker(app, open: { edit.openCategoryPicker() }, value: Self.category)

        // When
        edit.tapSave()

        // Then
        // 清單一直在表單底下，要先確認表單關閉，否則表單沒關也會通過
        if !edit.rootElement.waitForDisappearance() {
            failWithDiagnostics(in: app, "經選擇器填寫後儲存，編輯表單未關閉")
        }
        // 回到訂單清單：`lookupsOnly` 原本無訂單，建立後清單應至少出現一列
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
    ///
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
        if !root.goToOrders(file: file, line: line) {
            failWithDiagnostics(
                in: app,
                "切到訂單分頁後畫面未就緒",
                file: file,
                line: line
            )
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

        orders.tapAddOrder(file: file, line: line)

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

    /// 確認預設日圓的新訂單顯示日圓，且商品類別選擇器保留主檔選項
    ///
    /// - Parameters:
    ///   - edit: 新訂單的編輯表單
    ///   - app: 受測 App
    /// - Throws: 表單未就緒、幣別不是日圓或缺少商品類別選項時拋出測試錯誤
    @MainActor
    func assertJapaneseYenNewOrder(
        _ edit: OrderEditScreen,
        in app: XCUIApplication
    ) throws(any Error) {
        try requireCondition(edit.waitUntilReady(), in: app, "預設日圓的新訂單表單未就緒")
        edit.submitCustomerName()
        let currencyRow = app.buttons[BLAccessibilityID.OrderEdit.currencyRow]
        try requireCondition(
            currencyRow.wait(for: NSPredicate(format: "label CONTAINS %@", "日圓"), timeout: 10),
            in: app,
            "預設日圓的新訂單幣別未顯示日圓"
        )
        // 類別選項要開啟選擇器才看得到
        edit.openCategoryPicker()
        let picker = OptionPickerScreen(app: app)
        try requireCondition(picker.waitUntilReady(), in: app, "新訂單的類別選擇器未就緒")
        let categoryRow = app.descendants(matching: .any)[
            BLAccessibilityID.OptionPicker.optionRow(Self.category)
        ]
        try requireCondition(categoryRow.waitForExistence(timeout: 10), in: app, "預設日圓的新訂單缺少商品類別選項")
    }

    /// 開啟某個選擇器、等就緒後點選指定值
    ///
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

        picker.selectOption(value, file: file, line: line)
    }
}
