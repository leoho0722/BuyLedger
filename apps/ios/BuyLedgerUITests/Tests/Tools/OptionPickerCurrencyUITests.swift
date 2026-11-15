//
//  OptionPickerCurrencyUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/9/19.
//

import XCTest

/// 四個入口的幣別選擇器列標題與搜尋行為 UI 測試
@MainActor
final class OptionPickerCurrencyUITests: BLUITestCase {

    // MARK: - Properties

    /// 測試使用的幣別原始值
    private static let currencyCode = "TWD"

    /// 搜尋後應被濾除的對照幣別原始值 (預設幣別清單中排在 TWD 之後的第一個)
    private static let nonTargetCurrencyCode = "KRW"

    /// 驗證設定頁幣別選擇器在正體中文下，列標題顯示「新台幣」
    ///
    /// - Throws: 選擇器未就緒時丟出 UITestError.stopped
    func testOptionLabel_設定頁正體中文_顯示名稱() throws {
        // Given
        let picker = try openPicker(.settings, language: .traditionalChinese)

        // When
        let label = try picker.optionLabel(for: Self.currencyCode)

        // Then
        XCTAssertEqual(label, "新台幣")
    }

    /// 驗證設定頁幣別選擇器在正體中文下搜尋「TWD」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出 UITestError.stopped
    func testSearch_設定頁正體中文輸入代碼_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.settings, language: .traditionalChinese)
        try requireSearchBaseline(picker)

        // When
        try picker.search("TWD")

        // Then
        try assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證設定頁幣別選擇器在正體中文下搜尋「新台」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出 UITestError.stopped
    func testSearch_設定頁正體中文輸入名稱_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.settings, language: .traditionalChinese)
        try requireSearchBaseline(picker)

        // When
        try picker.search("新台")

        // Then
        try assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證設定頁幣別選擇器在英文下，列標題顯示「TWD」
    ///
    /// - Throws: 選擇器未就緒時丟出 UITestError.stopped
    func testOptionLabel_設定頁英文_顯示代碼() throws {
        // Given
        let picker = try openPicker(.settings, language: .english)

        // When
        let label = try picker.optionLabel(for: Self.currencyCode)

        // Then
        XCTAssertEqual(label, "TWD")
    }

    /// 驗證設定頁幣別選擇器在英文下搜尋「TWD」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出 UITestError.stopped
    func testSearch_設定頁英文輸入代碼_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.settings, language: .english)
        try requireSearchBaseline(picker)

        // When
        try picker.search("TWD")

        // Then
        try assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證設定頁幣別選擇器在英文下搜尋「Taiwan」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出 UITestError.stopped
    func testSearch_設定頁英文輸入名稱_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.settings, language: .english)
        try requireSearchBaseline(picker)

        // When
        try picker.search("Taiwan")

        // Then
        try assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證報價頁幣別選擇器在正體中文下，列標題顯示「新台幣」
    ///
    /// - Throws: 選擇器未就緒時丟出 UITestError.stopped
    func testOptionLabel_報價頁正體中文_顯示名稱() throws {
        // Given
        let picker = try openPicker(.quote, language: .traditionalChinese)

        // When
        let label = try picker.optionLabel(for: Self.currencyCode)

        // Then
        XCTAssertEqual(label, "新台幣")
    }

    /// 驗證報價頁幣別選擇器在正體中文下搜尋「TWD」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出 UITestError.stopped
    func testSearch_報價頁正體中文輸入代碼_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.quote, language: .traditionalChinese)
        try requireSearchBaseline(picker)

        // When
        try picker.search("TWD")

        // Then
        try assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證報價頁幣別選擇器在正體中文下搜尋「新台」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出 UITestError.stopped
    func testSearch_報價頁正體中文輸入名稱_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.quote, language: .traditionalChinese)
        try requireSearchBaseline(picker)

        // When
        try picker.search("新台")

        // Then
        try assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證報價頁幣別選擇器在英文下，列標題顯示「TWD」
    ///
    /// - Throws: 選擇器未就緒時丟出 UITestError.stopped
    func testOptionLabel_報價頁英文_顯示代碼() throws {
        // Given
        let picker = try openPicker(.quote, language: .english)

        // When
        let label = try picker.optionLabel(for: Self.currencyCode)

        // Then
        XCTAssertEqual(label, "TWD")
    }

    /// 驗證報價頁幣別選擇器在英文下搜尋「TWD」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出 UITestError.stopped
    func testSearch_報價頁英文輸入代碼_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.quote, language: .english)
        try requireSearchBaseline(picker)

        // When
        try picker.search("TWD")

        // Then
        try assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證報價頁幣別選擇器在英文下搜尋「Taiwan」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出 UITestError.stopped
    func testSearch_報價頁英文輸入名稱_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.quote, language: .english)
        try requireSearchBaseline(picker)

        // When
        try picker.search("Taiwan")

        // Then
        try assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證匯率頁幣別選擇器在正體中文下，列標題顯示「新台幣」
    ///
    /// - Throws: 選擇器未就緒時丟出 UITestError.stopped
    func testOptionLabel_匯率頁正體中文_顯示名稱() throws {
        // Given
        let picker = try openPicker(.fx, language: .traditionalChinese)

        // When
        let label = try picker.optionLabel(for: Self.currencyCode)

        // Then
        XCTAssertEqual(label, "新台幣")
    }

    /// 驗證匯率頁幣別選擇器在正體中文下搜尋「TWD」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出 UITestError.stopped
    func testSearch_匯率頁正體中文輸入代碼_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.fx, language: .traditionalChinese)
        try requireSearchBaseline(picker)

        // When
        try picker.search("TWD")

        // Then
        try assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證匯率頁幣別選擇器在正體中文下搜尋「新台」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出 UITestError.stopped
    func testSearch_匯率頁正體中文輸入名稱_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.fx, language: .traditionalChinese)
        try requireSearchBaseline(picker)

        // When
        try picker.search("新台")

        // Then
        try assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證匯率頁幣別選擇器在英文下，列標題顯示「TWD」
    ///
    /// - Throws: 選擇器未就緒時丟出 UITestError.stopped
    func testOptionLabel_匯率頁英文_顯示代碼() throws {
        // Given
        let picker = try openPicker(.fx, language: .english)

        // When
        let label = try picker.optionLabel(for: Self.currencyCode)

        // Then
        XCTAssertEqual(label, "TWD")
    }

    /// 驗證匯率頁幣別選擇器在英文下搜尋「TWD」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出 UITestError.stopped
    func testSearch_匯率頁英文輸入代碼_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.fx, language: .english)
        try requireSearchBaseline(picker)

        // When
        try picker.search("TWD")

        // Then
        try assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證匯率頁幣別選擇器在英文下搜尋「Taiwan」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出 UITestError.stopped
    func testSearch_匯率頁英文輸入名稱_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.fx, language: .english)
        try requireSearchBaseline(picker)

        // When
        try picker.search("Taiwan")

        // Then
        try assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證訂單編輯幣別選擇器在正體中文下，列標題顯示「新台幣」
    ///
    /// - Throws: 選擇器未就緒時丟出 UITestError.stopped
    func testOptionLabel_訂單編輯正體中文_顯示名稱() throws {
        // Given
        let picker = try openPicker(.orderEdit, language: .traditionalChinese)

        // When
        let label = try picker.optionLabel(for: Self.currencyCode)

        // Then
        XCTAssertEqual(label, "新台幣")
    }

    /// 驗證訂單編輯幣別選擇器在正體中文下搜尋「TWD」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出 UITestError.stopped
    func testSearch_訂單編輯正體中文輸入代碼_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.orderEdit, language: .traditionalChinese)
        try requireSearchBaseline(picker)

        // When
        try picker.search("TWD")

        // Then
        try assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證訂單編輯幣別選擇器在正體中文下搜尋「新台」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出 UITestError.stopped
    func testSearch_訂單編輯正體中文輸入名稱_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.orderEdit, language: .traditionalChinese)
        try requireSearchBaseline(picker)

        // When
        try picker.search("新台")

        // Then
        try assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證訂單編輯幣別選擇器在英文下，列標題顯示「TWD」
    ///
    /// - Throws: 選擇器未就緒時丟出 UITestError.stopped
    func testOptionLabel_訂單編輯英文_顯示代碼() throws {
        // Given
        let picker = try openPicker(.orderEdit, language: .english)

        // When
        let label = try picker.optionLabel(for: Self.currencyCode)

        // Then
        XCTAssertEqual(label, "TWD")
    }

    /// 驗證訂單編輯幣別選擇器在英文下搜尋「TWD」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出 UITestError.stopped
    func testSearch_訂單編輯英文輸入代碼_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.orderEdit, language: .english)
        try requireSearchBaseline(picker)

        // When
        try picker.search("TWD")

        // Then
        try assertSearchKeepsOnlyTarget(picker)
    }

    /// 驗證訂單編輯幣別選擇器在英文下搜尋「Taiwan」，保留 TWD 列並隱藏 KRW 列
    ///
    /// - Throws: 選擇器未就緒、對照幣別列不存在或搜尋欄不可互動時丟出 UITestError.stopped
    func testSearch_訂單編輯英文輸入名稱_只保留新台幣列() throws {
        // Given
        let picker = try openPicker(.orderEdit, language: .english)
        try requireSearchBaseline(picker)

        // When
        try picker.search("Taiwan")

        // Then
        try assertSearchKeepsOnlyTarget(picker)
    }
}

// MARK: - Nested Types

private extension OptionPickerCurrencyUITests {

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

private extension OptionPickerCurrencyUITests {

    /// 以指定語言啟動 App，從指定入口取得已就緒的幣別選擇器
    ///
    /// - Parameters:
    ///   - destination: 幣別選擇器入口
    ///   - language: App 內語言
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的幣別選擇器
    /// - Throws: 入口或選擇器無法開啟時丟出 UITestError.stopped
    func openPicker(
        _ destination: Destination,
        language: LaunchOptions.Language,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OptionPickerScreen {
        let app = try launch(
            LaunchOptions(seed: .lookupsOnly, language: language),
            file: file,
            line: line
        )
        switch destination {
        case .settings:
            let settings = try SettingsScreen.open(in: app, file: file, line: line)
            try requireCondition(
                settings.waitUntilReady(),
                in: app,
                "設定頁未就緒，無法開啟預設幣別",
                file: file,
                line: line
            )
            return try settings.openDefaultCurrency(file: file, line: line)

        case .quote:
            let quote = try QuoteScreen.open(in: app, file: file, line: line)
            try requireCondition(
                quote.waitUntilReady(),
                in: app,
                "報價頁未就緒，無法開啟幣別選擇器",
                file: file,
                line: line
            )
            return try quote.openCurrencyPicker(file: file, line: line)

        case .fx:
            let fx = try FxScreen.open(in: app, file: file, line: line)
            try requireCondition(
                fx.waitUntilReady(),
                in: app,
                "匯率頁未就緒，無法開啟幣別選擇器",
                file: file,
                line: line
            )
            return try fx.openCurrencyPicker(file: file, line: line)

        case .orderEdit:
            let orders = try OrdersScreen.open(in: app, file: file, line: line)
            try requireCondition(
                orders.waitUntilReady(),
                in: app,
                "訂單清單未就緒，無法開啟訂單編輯",
                file: file,
                line: line
            )
            let edit = try orders.tapAddOrder(file: file, line: line)
            return try edit.openCurrencyPicker(file: file, line: line)
        }
    }

    /// 確認搜尋前存在 KRW 對照列，避免空資料造成搜尋測試誤判
    ///
    /// - Parameters:
    ///   - picker: 已就緒的幣別選擇器
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 對照幣別列不存在時丟出 UITestError.stopped
    func requireSearchBaseline(
        _ picker: OptionPickerScreen,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try requireCondition(
            picker.hasOption(Self.nonTargetCurrencyCode),
            in: picker.app,
            "搜尋前幣別選擇器沒有對照幣別「\(Self.nonTargetCurrencyCode)」",
            file: file,
            line: line
        )
    }

    /// 確認搜尋結果保留 TWD 列並濾除 KRW 列
    ///
    /// - Parameters:
    ///   - picker: 已完成搜尋的幣別選擇器
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: TWD 列不存在或讀值失敗時丟出 UITestError.stopped
    func assertSearchKeepsOnlyTarget(
        _ picker: OptionPickerScreen,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let label = try picker.optionLabel(for: Self.currencyCode, file: file, line: line)
        XCTAssertNotNil(label, "搜尋後應保留 TWD 列", file: file, line: line)
        XCTAssertTrue(
            picker.waitForOptionDismissal(Self.nonTargetCurrencyCode),
            "搜尋後不應保留 KRW 列",
            file: file,
            line: line
        )
    }
}
