//
//  CurrencyPickerTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/9/19.
//

import XCTest

/// 四個幣別選擇器共用的列標題與搜尋行為 UI 測試
@MainActor
final class CurrencyPickerTests: BLUITestCase {

    // MARK: - Properties

    /// 測試使用的幣別原始值
    private static let currencyCode = "TWD"

    /// 搜尋後應被濾除的對照幣別原始值 (預設幣別清單中排在 TWD 之後的第一個)
    private static let nonTargetCurrencyCode = "KRW"

    /// 驗證設定頁幣別選擇器在正體中文下，列標題顯示「新台幣」
    ///
    /// - Throws: 選擇器未就緒時丟出測試錯誤
    func testOptionLabel_設定頁正體中文_顯示名稱() throws {
        // Given
        let picker = try openPicker(.settings, language: .traditionalChinese)

        // When
        let label = picker.optionLabel(for: Self.currencyCode)

        // Then
        XCTAssertEqual(label, "新台幣")
    }

    /// 驗證設定頁幣別選擇器在正體中文下搜尋「TWD」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出測試錯誤
    func testSearch_設定頁正體中文輸入代碼_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.settings, language: .traditionalChinese)
        try requireSearchBaseline(picker)

        // When
        try picker.search("TWD")

        // Then
        assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證設定頁幣別選擇器在正體中文下搜尋「新台」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出測試錯誤
    func testSearch_設定頁正體中文輸入名稱_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.settings, language: .traditionalChinese)
        try requireSearchBaseline(picker)

        // When
        try picker.search("新台")

        // Then
        assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證設定頁幣別選擇器在英文下，列標題顯示「TWD」
    ///
    /// - Throws: 選擇器未就緒時丟出測試錯誤
    func testOptionLabel_設定頁英文_顯示代碼() throws {
        // Given
        let picker = try openPicker(.settings, language: .english)

        // When
        let label = picker.optionLabel(for: Self.currencyCode)

        // Then
        XCTAssertEqual(label, "TWD")
    }

    /// 驗證設定頁幣別選擇器在英文下搜尋「TWD」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出測試錯誤
    func testSearch_設定頁英文輸入代碼_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.settings, language: .english)
        try requireSearchBaseline(picker)

        // When
        try picker.search("TWD")

        // Then
        assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證設定頁幣別選擇器在英文下搜尋「Taiwan」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出測試錯誤
    func testSearch_設定頁英文輸入名稱_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.settings, language: .english)
        try requireSearchBaseline(picker)

        // When
        try picker.search("Taiwan")

        // Then
        assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證報價頁幣別選擇器在正體中文下，列標題顯示「新台幣」
    ///
    /// - Throws: 選擇器未就緒時丟出測試錯誤
    func testOptionLabel_報價頁正體中文_顯示名稱() throws {
        // Given
        let picker = try openPicker(.quote, language: .traditionalChinese)

        // When
        let label = picker.optionLabel(for: Self.currencyCode)

        // Then
        XCTAssertEqual(label, "新台幣")
    }

    /// 驗證報價頁幣別選擇器在正體中文下搜尋「TWD」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出測試錯誤
    func testSearch_報價頁正體中文輸入代碼_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.quote, language: .traditionalChinese)
        try requireSearchBaseline(picker)

        // When
        try picker.search("TWD")

        // Then
        assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證報價頁幣別選擇器在正體中文下搜尋「新台」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出測試錯誤
    func testSearch_報價頁正體中文輸入名稱_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.quote, language: .traditionalChinese)
        try requireSearchBaseline(picker)

        // When
        try picker.search("新台")

        // Then
        assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證報價頁幣別選擇器在英文下，列標題顯示「TWD」
    ///
    /// - Throws: 選擇器未就緒時丟出測試錯誤
    func testOptionLabel_報價頁英文_顯示代碼() throws {
        // Given
        let picker = try openPicker(.quote, language: .english)

        // When
        let label = picker.optionLabel(for: Self.currencyCode)

        // Then
        XCTAssertEqual(label, "TWD")
    }

    /// 驗證報價頁幣別選擇器在英文下搜尋「TWD」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出測試錯誤
    func testSearch_報價頁英文輸入代碼_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.quote, language: .english)
        try requireSearchBaseline(picker)

        // When
        try picker.search("TWD")

        // Then
        assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證報價頁幣別選擇器在英文下搜尋「Taiwan」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出測試錯誤
    func testSearch_報價頁英文輸入名稱_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.quote, language: .english)
        try requireSearchBaseline(picker)

        // When
        try picker.search("Taiwan")

        // Then
        assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證匯率頁幣別選擇器在正體中文下，列標題顯示「新台幣」
    ///
    /// - Throws: 選擇器未就緒時丟出測試錯誤
    func testOptionLabel_匯率頁正體中文_顯示名稱() throws {
        // Given
        let picker = try openPicker(.fx, language: .traditionalChinese)

        // When
        let label = picker.optionLabel(for: Self.currencyCode)

        // Then
        XCTAssertEqual(label, "新台幣")
    }

    /// 驗證匯率頁幣別選擇器在正體中文下搜尋「TWD」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出測試錯誤
    func testSearch_匯率頁正體中文輸入代碼_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.fx, language: .traditionalChinese)
        try requireSearchBaseline(picker)

        // When
        try picker.search("TWD")

        // Then
        assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證匯率頁幣別選擇器在正體中文下搜尋「新台」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出測試錯誤
    func testSearch_匯率頁正體中文輸入名稱_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.fx, language: .traditionalChinese)
        try requireSearchBaseline(picker)

        // When
        try picker.search("新台")

        // Then
        assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證匯率頁幣別選擇器在英文下，列標題顯示「TWD」
    ///
    /// - Throws: 選擇器未就緒時丟出測試錯誤
    func testOptionLabel_匯率頁英文_顯示代碼() throws {
        // Given
        let picker = try openPicker(.fx, language: .english)

        // When
        let label = picker.optionLabel(for: Self.currencyCode)

        // Then
        XCTAssertEqual(label, "TWD")
    }

    /// 驗證匯率頁幣別選擇器在英文下搜尋「TWD」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出測試錯誤
    func testSearch_匯率頁英文輸入代碼_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.fx, language: .english)
        try requireSearchBaseline(picker)

        // When
        try picker.search("TWD")

        // Then
        assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證匯率頁幣別選擇器在英文下搜尋「Taiwan」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出測試錯誤
    func testSearch_匯率頁英文輸入名稱_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.fx, language: .english)
        try requireSearchBaseline(picker)

        // When
        try picker.search("Taiwan")

        // Then
        assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證訂單編輯幣別選擇器在正體中文下，列標題顯示「新台幣」
    ///
    /// - Throws: 選擇器未就緒時丟出測試錯誤
    func testOptionLabel_訂單編輯正體中文_顯示名稱() throws {
        // Given
        let picker = try openPicker(.orderEdit, language: .traditionalChinese)

        // When
        let label = picker.optionLabel(for: Self.currencyCode)

        // Then
        XCTAssertEqual(label, "新台幣")
    }

    /// 驗證訂單編輯幣別選擇器在正體中文下搜尋「TWD」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出測試錯誤
    func testSearch_訂單編輯正體中文輸入代碼_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.orderEdit, language: .traditionalChinese)
        try requireSearchBaseline(picker)

        // When
        try picker.search("TWD")

        // Then
        assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證訂單編輯幣別選擇器在正體中文下搜尋「新台」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出測試錯誤
    func testSearch_訂單編輯正體中文輸入名稱_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.orderEdit, language: .traditionalChinese)
        try requireSearchBaseline(picker)

        // When
        try picker.search("新台")

        // Then
        assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證訂單編輯幣別選擇器在英文下，列標題顯示「TWD」
    ///
    /// - Throws: 選擇器未就緒時丟出測試錯誤
    func testOptionLabel_訂單編輯英文_顯示代碼() throws {
        // Given
        let picker = try openPicker(.orderEdit, language: .english)

        // When
        let label = picker.optionLabel(for: Self.currencyCode)

        // Then
        XCTAssertEqual(label, "TWD")
    }

    /// 驗證訂單編輯幣別選擇器在英文下搜尋「TWD」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出測試錯誤
    func testSearch_訂單編輯英文輸入代碼_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.orderEdit, language: .english)
        try requireSearchBaseline(picker)

        // When
        try picker.search("TWD")

        // Then
        assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證訂單編輯幣別選擇器在英文下搜尋「Taiwan」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出測試錯誤
    func testSearch_訂單編輯英文輸入名稱_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.orderEdit, language: .english)
        try requireSearchBaseline(picker)

        // When
        try picker.search("Taiwan")

        // Then
        assertSearchKeepsOnlyTarget(picker)
    }
}

// MARK: - Nested Types

private extension CurrencyPickerTests {

    /// 幣別選擇器的開啟入口
    enum Destination {

        /// 設定頁的預設幣別
        case settings

        /// 報價頁的來源幣別
        case quote

        /// 匯率頁的來源幣別
        case fx

        /// 訂單編輯的幣別
        case orderEdit
    }
}

// MARK: - Private Method

private extension CurrencyPickerTests {

    /// 以指定語言啟動 App，開啟指定入口的幣別選擇器並等就緒
    ///
    /// - Parameters:
    ///   - destination: 幣別選擇器入口
    ///   - language: App 內語言
    /// - Returns: 已就緒的幣別選擇器 Page Object
    /// - Throws: 入口畫面或幣別選擇器未就緒時丟出測試錯誤
    func openPicker(
        _ destination: Destination,
        language: LaunchOptions.Language
    ) throws -> OptionPickerScreen {
        let app = launch(LaunchOptions(seed: .lookupsOnly, language: language))
        switch destination {
        case .settings:
            let root = RootNavigationScreen(app: app)
            try requireCondition(root.goToMore(), in: app, "更多頁未就緒，無法開啟設定")
            let settingsRow = app.descendants(matching: .any)[BLAccessibilityID.More.row(.settings)]
            settingsRow.tapAfterWaiting(in: app)
            let settings = SettingsScreen(app: app)
            try requireCondition(settings.waitUntilReady(), in: app, "設定頁未就緒，無法開啟預設幣別")
            settings.openDefaultCurrency()

        case .quote:
            let quote = QuoteScreen.open(from: app)
            try requireCondition(quote.waitUntilReady(), in: app, "報價頁未就緒，無法開啟幣別選擇器")
            quote.openCurrencyPicker()

        case .fx:
            let fx = FxScreen.open(from: app)
            try requireCondition(fx.waitUntilReady(), in: app, "匯率頁未就緒，無法開啟幣別選擇器")
            fx.openCurrencyPicker()

        case .orderEdit:
            let root = RootNavigationScreen(app: app)
            try requireCondition(root.goToOrders(), in: app, "訂單頁未就緒，無法開啟訂單編輯")
            let orders = OrdersScreen(app: app)
            try requireCondition(orders.waitUntilReady(), in: app, "訂單清單未就緒，無法開啟訂單編輯")
            orders.tapAddOrder()
            let edit = OrderEditScreen(app: app)
            try requireCondition(edit.waitUntilReady(), in: app, "訂單編輯表單未就緒，無法開啟幣別選擇器")
            edit.openCurrencyPicker()
        }

        let picker = OptionPickerScreen(app: app)
        try requireCondition(
            picker.waitUntilReady(),
            in: app,
            "幣別選擇器根 identifier「\(picker.rootIdentifier)」逾時仍未出現"
        )
        return picker
    }

    /// 確認搜尋前存在對照幣別列，避免未載入資料時也能通過搜尋測試
    ///
    /// - Parameter picker: 已就緒的幣別選擇器
    /// - Throws: 對照幣別列不存在時丟出測試錯誤
    func requireSearchBaseline(_ picker: OptionPickerScreen) throws {
        let nonTargetRow = picker.app.descendants(matching: .any)[
            BLAccessibilityID.OptionPicker.optionRow(Self.nonTargetCurrencyCode)
        ]
        try requireCondition(
            nonTargetRow.waitForExistence(timeout: 10),
            in: picker.app,
            "搜尋前幣別選擇器沒有對照幣別「\(Self.nonTargetCurrencyCode)」"
        )
    }

    /// 確認搜尋結果保留 TWD 列並濾除 KRW 列
    ///
    /// - Parameter picker: 已完成搜尋的幣別選擇器
    func assertSearchKeepsOnlyTarget(_ picker: OptionPickerScreen) {
        let nonTargetRow = picker.app.descendants(matching: .any)[
            BLAccessibilityID.OptionPicker.optionRow(Self.nonTargetCurrencyCode)
        ]
        XCTAssertNotNil(picker.optionLabel(for: Self.currencyCode), "搜尋後應保留 TWD 列")
        XCTAssertTrue(nonTargetRow.waitForDisappearance(), "搜尋後不應保留 KRW 列")
    }
}
