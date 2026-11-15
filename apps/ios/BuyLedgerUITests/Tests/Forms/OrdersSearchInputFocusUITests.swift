//
//  OrdersSearchInputFocusUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/5.
//

import XCTest

/// 訂單清單與類別搜尋重新聚焦後文字接續的 UI 測試
@MainActor
final class OrdersSearchInputFocusUITests: BLUITestCase {

    /// 驗證類別搜尋欄收鍵盤後保留既有「保養」，從左側重新聚焦輸入「品」，欄位值為「保養品」；compact 版面使用篩選 sheet，regular 版面使用類別選擇器
    ///
    /// - Throws: 搜尋欄不可互動或版面判斷所需元素缺少時丟出 UITestError.stopped
    func testTapLeftToFocus_類別搜尋既有保養輸入品_接續在尾端() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let field = try openCategorySearch(typing: "保養", in: app)
        try app.dismissSearchKeyboard(keeping: "保養", in: field)

        // When
        // 類別搜尋的放大鏡在輸入欄外，文字從輸入欄左緣開始
        try field.tapLeftToFocus(in: app, dx: 0.02)
        field.typeText("品")

        // Then
        _ = Polling.wait(timeout: 3) {
            field.value as? String == "保養品"
        }
        XCTAssertEqual(field.value as? String, "保養品", "類別搜尋應從尾端接續輸入")
    }

    /// 驗證訂單清單搜尋欄收鍵盤後保留既有「林」，從左側重新聚焦輸入「書」，欄位值為「林書」，游標由系統聚焦流程放在文字尾端
    ///
    /// - Throws: 搜尋欄不可互動時丟出 UITestError.stopped
    func testTapLeftToFocus_訂單搜尋既有林輸入書_接續在尾端() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        _ = try OrdersScreen.open(in: app)
        let field = try app.hittableSearchField()
        try field.tapLeftToFocus(in: app, dx: 0.12)
        field.typeText("林")
        try app.dismissSearchKeyboard(keeping: "林", in: field)

        // When
        try field.tapLeftToFocus(in: app, dx: 0.12)
        field.typeText("書")

        // Then
        _ = Polling.wait(timeout: 3) {
            field.value as? String == "林書"
        }
        XCTAssertEqual(field.value as? String, "林書", "訂單清單搜尋應從尾端接續輸入")
    }

    /// 驗證客戶深連結以客戶名稱取代搜尋文字後，欄位值為「林書宇」，從左側聚焦輸入「小」，欄位值為「林書宇小」
    ///
    /// - Throws: 搜尋欄不可互動或深連結未抵達訂單清單時丟出 UITestError.stopped
    func testTapLeftToFocus_訂單搜尋深連結取代既有文字_接續在新文字尾端() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .customerRanking))
        _ = try OrdersScreen.open(in: app)
        let field = try app.hittableSearchField()
        try field.tapLeftToFocus(in: app, dx: 0.12)
        field.typeText("陳")
        try app.dismissSearchKeyboard(keeping: "陳", in: field)
        let customers = try CustomersScreen.open(in: app)
        try requireCondition(customers.waitUntilReady(), in: app, "客戶名單未就緒")
        try customers.tapCustomer(customerName: "林書宇")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "深連結後訂單清單未就緒")
        let replacedField = try app.hittableSearchField()
        _ = Polling.wait(timeout: 3) {
            replacedField.value as? String == "林書宇"
        }
        try requireCondition(
            replacedField.value as? String == "林書宇",
            in: app,
            "深連結應以客戶名稱取代搜尋文字「林書宇」"
        )

        // When
        try replacedField.tapLeftToFocus(in: app, dx: 0.12)
        replacedField.typeText("小")

        // Then
        _ = Polling.wait(timeout: 3) {
            replacedField.value as? String == "林書宇小"
        }
        XCTAssertEqual(replacedField.value as? String, "林書宇小", "新字應接在深連結帶入的名稱尾端")
    }
}

// MARK: - Private Method

private extension OrdersSearchInputFocusUITests {

    /// 依版面開啟類別搜尋並輸入既有文字
    ///
    /// - Parameters:
    ///   - text: 要預先輸入的既有文字
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已輸入既有文字且仍持有焦點的類別搜尋欄
    /// - Throws: 版面無法判斷或搜尋欄無法聚焦時丟出 UITestError.stopped
    func openCategorySearch(
        typing text: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> XCUIElement {
        let orders = try OrdersScreen.open(in: app, file: file, line: line)
        let layout = try ordersLayout(in: app, file: file, line: line)
        if layout == .compact {
            let sheet = try orders.openFilterSheet(file: file, line: line)
            // 中等高度的 sheet 由 Page Object 展開後輸入
            try sheet.typeFilterSearch(text, file: file, line: line)
            return sheet.filterSearchField
        }
        try requireCondition(
            layout == .regular,
            in: app,
            "無法判斷目前版面，無法開啟類別搜尋",
            file: file,
            line: line
        )
        let picker = try orders.openCategoryPicker(file: file, line: line)
        let field = picker.pickerSearchField
        try field.tapLeftToFocus(in: app, dx: 0.12, file: file, line: line)
        field.typeText(text)
        return field
    }
}
