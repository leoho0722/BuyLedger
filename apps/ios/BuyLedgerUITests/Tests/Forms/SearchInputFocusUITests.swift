//
//  SearchInputFocusUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/5.
//

import XCTest

/// 類別搜尋、訂單清單搜尋、合併候選搜尋與選項選擇器搜尋取得焦點後的游標位置 UI 測試，另守不開搜尋的選項選擇器不呈現搜尋欄
@MainActor
final class SearchInputFocusUITests: BLUITestCase {

    /// 驗證類別搜尋欄收鍵盤後保留既有「保養」，從左側重新聚焦輸入「品」，欄位值為「保養品」；compact 版面使用篩選 sheet，regular 版面使用類別選擇器
    ///
    /// - Throws: 搜尋欄不可互動或版面判斷所需元素缺少時丟出測試錯誤
    func testFocusCategorySearchFromLeft_既有保養輸入品_接續在尾端() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        let field = try openCategorySearch(typing: "保養", in: app)
        try dismissSearchKeyboard(keeping: "保養", in: field, app: app)

        // When
        // 類別搜尋的放大鏡在輸入欄外，文字從輸入欄左緣開始
        try focusSearchFromLeft(field, in: app, dx: 0.02)
        field.typeText("品")

        // Then
        _ = pollUntil(timeout: 3) {
            field.value as? String == "保養品"
        }
        XCTAssertEqual(field.value as? String, "保養品", "類別搜尋應從尾端接續輸入")
    }

    /// 驗證訂單清單搜尋欄收鍵盤後保留既有「林」，從左側重新聚焦輸入「書」，欄位值為「林書」，游標由系統聚焦流程放在文字尾端
    ///
    /// - Throws: 搜尋欄不可互動時丟出測試錯誤
    func testFocusOrderListSearchFromLeft_既有林輸入書_接續在尾端() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        _ = openOrders(in: app)
        let field = try OrdersScreen(app: app).hittableSearchField()
        try settleSearchText("林", in: field, app: app)

        // When
        try focusSearchFromLeft(field, in: app)
        field.typeText("書")

        // Then
        _ = pollUntil(timeout: 3) {
            field.value as? String == "林書"
        }
        XCTAssertEqual(field.value as? String, "林書", "訂單清單搜尋應從尾端接續輸入")
    }

    /// 驗證客戶深連結以客戶名稱取代搜尋文字後，欄位值為「林書宇」，從左側聚焦輸入「小」，欄位值為「林書宇小」
    ///
    /// - Throws: 搜尋欄不可互動或深連結未抵達訂單清單時丟出測試錯誤
    func testFocusOrderListSearchFromLeft_深連結取代既有文字_接續在新文字尾端() throws {
        // Given
        let app = launch(LaunchOptions(seed: .customerRanking))
        _ = openOrders(in: app)
        let field = try OrdersScreen(app: app).hittableSearchField()
        try settleSearchText("陳", in: field, app: app)
        let customers = CustomersScreen.open(from: app)
        try requireCondition(customers.waitUntilReady(), in: app, "客戶名單未就緒")
        customers.tapCustomer(customerName: "林書宇")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "深連結後訂單清單未就緒")
        let replacedField = try orders.hittableSearchField()
        _ = pollUntil(timeout: 3) {
            replacedField.value as? String == "林書宇"
        }
        guard replacedField.value as? String == "林書宇" else {
            app.failWithDiagnostics("深連結應以客戶名稱取代搜尋文字「林書宇」")
            return
        }

        // When
        try focusSearchFromLeft(replacedField, in: app)
        replacedField.typeText("小")

        // Then
        _ = pollUntil(timeout: 3) {
            replacedField.value as? String == "林書宇小"
        }
        XCTAssertEqual(replacedField.value as? String, "林書宇小", "新字應接在深連結帶入的名稱尾端")
    }

    /// 驗證合併候選搜尋欄收鍵盤後保留既有「林書宇」，從左側重新聚焦輸入「小」，欄位值為「林書宇小」，不因點擊位置而插進中間
    ///
    /// - Throws: 搜尋欄不可互動時丟出測試錯誤
    func testFocusMergeCandidateSearchFromLeft_既有林書宇輸入小_接續在尾端() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        openMergeCandidateSheet(in: app)
        let field = try OrdersScreen(app: app).hittableSearchField()
        try settleSearchText("林書宇", in: field, app: app)

        // When
        try focusSearchFromLeft(field, in: app)
        field.typeText("小")

        // Then
        _ = pollUntil(timeout: 3) {
            field.value as? String == "林書宇小"
        }
        XCTAssertEqual(field.value as? String, "林書宇小", "合併候選搜尋應從尾端接續輸入")
    }

    /// 驗證設定頁預設幣別的搜尋欄收鍵盤後保留既有「新台」，從左側重新聚焦輸入「幣」，欄位值為「新台幣」
    ///
    /// - Throws: 搜尋欄不可互動或選擇器未就緒時丟出測試錯誤
    func testFocusOptionPickerSearchFromLeft_既有新台輸入幣_接續在尾端() throws {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly, language: .traditionalChinese))
        let settings = SettingsScreen.navigate(in: app)
        settings.openDefaultCurrency()
        let picker = OptionPickerScreen(app: app)
        try requireCondition(picker.waitUntilReady(), in: app, "幣別選擇器未就緒")
        let field = try OrdersScreen(app: app).hittableSearchField()
        try settleSearchText("新台", in: field, app: app)

        // When
        try focusSearchFromLeft(field, in: app)
        field.typeText("幣")

        // Then
        _ = pollUntil(timeout: 3) {
            field.value as? String == "新台幣"
        }
        XCTAssertEqual(field.value as? String, "新台幣", "選項選擇器搜尋應從尾端接續輸入")
    }

    /// 驗證訂單來源選擇器呈現後不出現搜尋欄，等待有上限後才判定不存在
    ///
    /// - Throws: 訂單編輯表單或選擇器未就緒時丟出測試錯誤
    func testOpenSourcePicker_訂單來源選擇器_不呈現搜尋欄() throws {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try openNewOrderEdit(in: app)
        guard edit.dismissCustomerKeyboard() else {
            return
        }

        // When
        edit.openSourcePicker()

        // Then
        let picker = OptionPickerScreen(app: app)
        try requireCondition(picker.waitUntilReady(), in: app, "訂單來源選擇器未就緒")
        let hasSearchField = pollUntil(timeout: 2) {
            app.searchFields.allElementsBoundByIndex.contains {
                $0.isHittableOnScreen
            }
        }
        XCTAssertFalse(hasSearchField, "訂單來源選擇器不應呈現搜尋欄")
    }
}

// MARK: - Private Method

private extension SearchInputFocusUITests {

    /// 依版面開啟類別搜尋並輸入既有文字：compact 開整合篩選 sheet，regular 開類別選擇器
    ///
    /// - Parameters:
    ///   - text: 要預先輸入的既有文字
    ///   - app: 受測 App
    /// - Returns: 已輸入既有文字且仍持有焦點的類別搜尋欄
    /// - Throws: 版面無法判斷或搜尋欄無法聚焦時丟出測試錯誤
    func openCategorySearch(typing text: String, in app: XCUIApplication) throws -> XCUIElement {
        let orders = openOrders(in: app)
        if isCompactLayout(app) {
            orders.openFilterSheet()
            // 篩選 sheet 停在中等高度時搜尋欄可能在可視區外，由 Page Object 展開後輸入
            OrderFilterSheetScreen(app: app).typeFilterSearch(text)
            return app.textFields[BLAccessibilityID.Orders.filterSearchField].firstMatch
        }
        try requireCondition(isRegularLayout(app), in: app, "無法判斷目前版面，無法開啟類別搜尋")
        orders.openCategoryPicker()
        let field = app.textFields[BLAccessibilityID.Orders.categoryPickerSearchField].firstMatch
        try focusSearchFromLeft(field, in: app)
        field.typeText(text)
        return field
    }

    /// 切到訂單分頁並等待清單就緒
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的訂單清單 Page Object
    func openOrders(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OrdersScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders(file: file, line: line) {
            app.failWithDiagnostics("切到訂單分頁後畫面未就緒", file: file, line: line)
        }
        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            app.failWithDiagnostics("訂單清單尚未就緒", file: file, line: line)
        }
        return orders
    }

    /// 點搜尋欄左側 (避開放大鏡) 取得焦點，等鍵盤就位
    ///
    /// - Parameters:
    ///   - field: 搜尋欄
    ///   - app: 受測 App
    ///   - dx: 欄位內點擊位置的水平比例，預設避開 `.searchable` 內建的放大鏡
    /// - Throws: 無法取得焦點時丟出測試錯誤
    func focusSearchFromLeft(
        _ field: XCUIElement,
        in app: XCUIApplication,
        dx: CGFloat = 0.12
    ) throws {
        let hasFocus = field.tapLeftToFocus(in: app, dx: dx)
        try requireCondition(hasFocus, in: app, "點搜尋欄左側後未取得焦點")
    }

    /// 送 return 收起鍵盤，斷言文字保留且焦點已解除
    ///
    /// - Parameters:
    ///   - text: 收鍵盤後應保留的文字
    ///   - field: 搜尋欄
    ///   - app: 受測 App
    /// - Throws: 文字未保留或焦點未解除時丟出測試錯誤
    func dismissSearchKeyboard(
        keeping text: String,
        in field: XCUIElement,
        app: XCUIApplication
    ) throws {
        field.typeText(XCUIKeyboardKey.return.rawValue)
        let predicate = NSPredicate(format: "hasKeyboardFocus == true")
        let hasDismissed = pollUntil(timeout: 5) {
            !predicate.evaluate(with: field) && !app.keyboards.firstMatch.exists
        }
        try requireCondition(hasDismissed, in: app, "收鍵盤後搜尋欄仍持有焦點")
        try requireCondition(field.value as? String == text, in: app, "收鍵盤後搜尋欄應保留既有文字")
        try requireCondition(!predicate.evaluate(with: field), in: app, "收鍵盤後搜尋欄應已失焦")
    }

    /// 寫入既有文字並收起鍵盤，斷言文字保留且焦點已解除
    ///
    /// - Parameters:
    ///   - text: 要預先寫入的既有文字
    ///   - field: 搜尋欄
    ///   - app: 受測 App
    /// - Throws: 無法聚焦、文字未保留或焦點未解除時丟出測試錯誤
    func settleSearchText(_ text: String, in field: XCUIElement, app: XCUIApplication) throws {
        try focusSearchFromLeft(field, in: app)
        field.typeText(text)
        try dismissSearchKeyboard(keeping: text, in: field, app: app)
    }

    /// 開啟合併候選 sheet：點來源訂單、進詳情、點更多選單的合併
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openMergeCandidateSheet(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let orders = openOrders(in: app, file: file, line: line)
        orders.tapOrder(orderID: "UITEST-MRG-001", file: file, line: line)
        let detail = OrderDetailScreen(app: app)
        if !detail.waitUntilReady() {
            app.failWithDiagnostics("來源訂單詳情尚未就緒", file: file, line: line)
        }
        detail.openMoreMenu(file: file, line: line)
        if !detail.tapMerge(file: file, line: line) {
            app.failWithDiagnostics("無法開啟合併候選", file: file, line: line)
        }
    }

    /// 從訂單分頁新增訂單並等待編輯表單就緒
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 已就緒的新訂單編輯表單 Page Object
    /// - Throws: 編輯表單未就緒時丟出測試錯誤
    func openNewOrderEdit(in app: XCUIApplication) throws -> OrderEditScreen {
        let orders = openOrders(in: app)
        orders.tapAddOrder()
        let edit = OrderEditScreen(app: app)
        try requireCondition(edit.waitUntilReady(), in: app, "新訂單編輯表單未就緒")
        return edit
    }
}
