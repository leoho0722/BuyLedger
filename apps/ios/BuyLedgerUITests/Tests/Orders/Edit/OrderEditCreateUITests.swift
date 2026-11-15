//
//  OrderEditCreateUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 新增訂單的預設幣別、主檔選項與必填檢查 UI 測試
@MainActor
final class OrderEditCreateUITests: BLUITestCase {

    // MARK: - Properties

    /// 建單填入的客戶名稱 (使用者資料，中英兩語言皆可輸入)
    private static let customerName = "測試客戶"

    /// 選取的訂單來源 (`lookupsOnly` 主檔既有項目)
    private static let orderSource = "蝦皮"

    /// 選取的商品類別 (`lookupsOnly` 主檔既有項目)
    private static let category = "美妝"

    /// 填入的客戶實付金額
    private static let chargedAmount = "4200"

    /// 驗證預設幣別為日圓時，從訂單分頁新增的表單以 ISO 代碼 JPY 表示幣別
    ///
    /// - Throws: 必要的 UI 操作或幣別不符時丟出 UITestError.stopped
    func testNewOrderTapped_預設幣別日圓_幣別顯示日圓() throws {
        // Given
        let app = try launchWithJapaneseYenDefault()
        let orders = try OrdersScreen.open(in: app)

        // When
        let edit = try orders.tapAddOrder()
        try edit.submitCustomerName()

        // Then
        try assertCurrencyIsJapaneseYen(edit, in: app)
    }

    /// 驗證預設幣別為日圓時，從訂單分頁新增後的類別選擇器仍列出主檔的美妝選項
    ///
    /// - Throws: 必要的 UI 操作或主檔選項缺少時丟出 UITestError.stopped
    func testCategoryPickerTapped_預設幣別日圓_新訂單類別選擇器保留主檔選項() throws {
        // Given
        let app = try launchWithJapaneseYenDefault()
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        try edit.submitCustomerName()

        // When
        let picker = try edit.openCategoryPicker()

        // Then
        try assertCategoryPickerHasLookupOption(picker, in: app)
    }

    /// 驗證預設幣別為日圓時，首頁建立第一筆訂單的表單以 ISO 代碼 JPY 表示幣別
    ///
    /// - Throws: 必要的 UI 操作、表單未就緒或幣別不符時丟出 UITestError.stopped
    func testNewOrderTapped_首頁建立第一筆訂單且預設幣別日圓_幣別顯示日圓() throws {
        // Given
        let app = try launchWithJapaneseYenDefault()
        let dashboard = try DashboardScreen.open(in: app)
        try requireCondition(dashboard.waitUntilReady(), in: app, "首頁未就緒")

        // When
        let edit = try dashboard.tapCreateFirstOrder()
        try edit.submitCustomerName()

        // Then
        try assertCurrencyIsJapaneseYen(edit, in: app)
    }

    /// 驗證預設幣別為日圓時，首頁建單後的類別選擇器仍列出主檔的美妝選項
    ///
    /// - Throws: 必要的 UI 操作或主檔選項缺少時丟出 UITestError.stopped
    func testCategoryPickerTapped_預設幣別日圓_首頁建單後類別選擇器保留主檔選項() throws {
        // Given
        let app = try launchWithJapaneseYenDefault()
        let dashboard = try DashboardScreen.open(in: app)
        try requireCondition(dashboard.waitUntilReady(), in: app, "首頁未就緒")
        let edit = try dashboard.tapCreateFirstOrder()
        try edit.submitCustomerName()

        // When
        let picker = try edit.openCategoryPicker()

        // Then
        try assertCategoryPickerHasLookupOption(picker, in: app)
    }

    /// 驗證新訂單填妥客戶與來源後選取商品類別，儲存按鈕由停用轉為可用
    ///
    /// - Throws: 必要的 UI 操作或必填檢查前置不成立時丟出 UITestError.stopped
    func testCategorySelected_客戶與來源已填後選商品類別_儲存按鈕轉為可用() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        let isSaveEnabled = try edit.isSaveEnabled()
        try requireCondition(!isSaveEnabled, in: app, "新表單必填未齊時儲存不應可用")
        try edit.typeCustomerName(Self.customerName)
        try edit.openSourcePicker().selectOption(Self.orderSource)
        let picker = try edit.openCategoryPicker()

        // When
        try picker.selectOption(Self.category)

        // Then
        XCTAssertTrue(edit.waitForSaveEnabled(), "填完客戶名、來源與類別後儲存仍不可用")
    }

    /// 驗證填完必填與實付金額後儲存，表單關閉且清單出現客戶為測試客戶的新訂單列
    ///
    /// - Throws: 必要的 UI 操作或欄位輸入失敗時丟出 UITestError.stopped
    func testSaveTapped_填寫必填與實付金額_清單出現新訂單() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        // 先填數字欄，避免鍵盤影響後續欄位
        try edit.typeChargedAmount(Self.chargedAmount)
        try edit.typeCustomerName(Self.customerName)
        try edit.openSourcePicker().selectOption(Self.orderSource)
        try edit.openCategoryPicker().selectOption(Self.category)

        // When
        try edit.tapSave()

        // Then
        XCTAssertTrue(edit.rootElement.waitForDisappearance(), "經選擇器填寫後儲存，編輯表單未關閉")
        let orders = OrdersScreen(app: app)
        XCTAssertTrue(orders.waitUntilReady(), "儲存後訂單清單未就緒")
        XCTAssertTrue(
            orders.orderRow(customerName: Self.customerName).waitForExistence(timeout: 10),
            "建立訂單後清單沒有客戶為測試客戶的訂單列"
        )
    }
}

// MARK: - Private Method

private extension OrderEditCreateUITests {

    /// 以預設幣別日圓、正體中文與 lookupsOnly 主檔啟動 App
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已啟動的受測 App
    /// - Throws: App 無法進入前景時丟出 UITestError.stopped
    func launchWithJapaneseYenDefault(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> XCUIApplication {
        try launch(
            LaunchOptions(
                seed: .lookupsOnly,
                language: .traditionalChinese,
                defaultCurrencyCode: "JPY"
            ),
            file: file,
            line: line
        )
    }

    /// 確認新訂單幣別列的完整 accessibility value 為 JPY
    ///
    /// - Parameters:
    ///   - edit: 新訂單的編輯表單
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 幣別值不存在或不是 JPY 時丟出 UITestError.stopped
    func assertCurrencyIsJapaneseYen(
        _ edit: OrderEditScreen,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try requireCondition(
            edit.currencyCode() == "JPY",
            in: app,
            "預設日圓的新訂單幣別代碼應為 JPY",
            file: file,
            line: line
        )
    }

    /// 確認已就緒的商品類別選擇器列出主檔的美妝選項
    ///
    /// - Parameters:
    ///   - picker: 呈現動作回傳的類別選擇器
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 商品類別選項缺少時丟出 UITestError.stopped
    func assertCategoryPickerHasLookupOption(
        _ picker: OptionPickerScreen,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try requireCondition(
            picker.hasOption(Self.category),
            in: app,
            "預設日圓的新訂單缺少商品類別選項",
            file: file,
            line: line
        )
    }
}
