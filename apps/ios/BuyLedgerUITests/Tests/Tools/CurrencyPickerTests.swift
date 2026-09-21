//
//  CurrencyPickerTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/9/19.
//

import XCTest

/// 驗證四個幣別選擇器共用的列標題與搜尋行為
final class CurrencyPickerTests: BLUITestCase {

    // MARK: - Properties

    /// 測試的幣別原始值
    private static let currencyCode = "TWD"

    // MARK: - Tests

    /// 設定頁的幣別列在正體中文顯示本地化名稱，且可用兩種關鍵字搜尋
    @MainActor
    func testSettingsPickerUsesTraditionalChineseNameAndSearches() {
        assertPicker(
            for: .settings,
            language: .traditionalChinese,
            expectedLabel: "新台幣",
            nameKeyword: "新台"
        )
    }

    /// 設定頁的幣別列在英文顯示 ISO 代碼，且可用兩種關鍵字搜尋
    @MainActor
    func testSettingsPickerUsesEnglishCodeAndSearches() {
        assertPicker(
            for: .settings,
            language: .english,
            expectedLabel: "TWD",
            nameKeyword: "Taiwan"
        )
    }

    /// 報價頁的幣別列在正體中文顯示本地化名稱，且可用兩種關鍵字搜尋
    @MainActor
    func testQuotePickerUsesTraditionalChineseNameAndSearches() {
        assertPicker(
            for: .quote,
            language: .traditionalChinese,
            expectedLabel: "新台幣",
            nameKeyword: "新台"
        )
    }

    /// 報價頁的幣別列在英文顯示 ISO 代碼，且可用兩種關鍵字搜尋
    @MainActor
    func testQuotePickerUsesEnglishCodeAndSearches() {
        assertPicker(
            for: .quote,
            language: .english,
            expectedLabel: "TWD",
            nameKeyword: "Taiwan"
        )
    }

    /// 匯率頁的幣別列在正體中文顯示本地化名稱，且可用兩種關鍵字搜尋
    @MainActor
    func testFxPickerUsesTraditionalChineseNameAndSearches() {
        assertPicker(
            for: .fx,
            language: .traditionalChinese,
            expectedLabel: "新台幣",
            nameKeyword: "新台"
        )
    }

    /// 匯率頁的幣別列在英文顯示 ISO 代碼，且可用兩種關鍵字搜尋
    @MainActor
    func testFxPickerUsesEnglishCodeAndSearches() {
        assertPicker(
            for: .fx,
            language: .english,
            expectedLabel: "TWD",
            nameKeyword: "Taiwan"
        )
    }

    /// 訂單編輯的幣別列在正體中文顯示本地化名稱，且可用兩種關鍵字搜尋
    @MainActor
    func testOrderEditPickerUsesTraditionalChineseNameAndSearches() {
        assertPicker(
            for: .orderEdit,
            language: .traditionalChinese,
            expectedLabel: "新台幣",
            nameKeyword: "新台"
        )
    }

    /// 訂單編輯的幣別列在英文顯示 ISO 代碼，且可用兩種關鍵字搜尋
    @MainActor
    func testOrderEditPickerUsesEnglishCodeAndSearches() {
        assertPicker(
            for: .orderEdit,
            language: .english,
            expectedLabel: "TWD",
            nameKeyword: "Taiwan"
        )
    }
}

// MARK: - Nested Types

private extension CurrencyPickerTests {

    /// 要驗證的幣別選擇器入口
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

@MainActor
private extension CurrencyPickerTests {

    /// 開啟指定畫面的幣別選擇器並驗證列標題與搜尋
    ///
    /// - Parameters:
    ///   - destination: 幣別選擇器入口
    ///   - language: App 內語言
    ///   - expectedLabel: TWD 列預期的 accessibility label
    ///   - nameKeyword: 幣別名稱搜尋關鍵字
    func assertPicker(
        for destination: Destination,
        language: LaunchOptions.Language,
        expectedLabel: String,
        nameKeyword: String
    ) {
        let app = launch(LaunchOptions(seed: .lookupsOnly, language: language))
        openPicker(destination, in: app)

        let picker = OptionPickerScreen(app: app)
        guard picker.waitUntilReady() else {
            failWithDiagnostics(
                in: app,
                "幣別選擇器根 identifier「\(picker.rootIdentifier)」逾時仍未出現"
            )
            return
        }

        let label = picker.optionLabel(for: Self.currencyCode)
        XCTAssertEqual(
            label,
            expectedLabel,
            "\(String(describing: destination)) 的 TWD 列標籤不符合語言規則"
        )

        picker.search(Self.currencyCode)
        XCTAssertNotNil(
            picker.optionLabel(for: Self.currencyCode),
            "\(String(describing: destination)) 以 ISO 代碼搜尋時應保留 TWD 列"
        )

        picker.search(nameKeyword)
        XCTAssertNotNil(
            picker.optionLabel(for: Self.currencyCode),
            "\(String(describing: destination)) 以幣別名稱搜尋時應保留 TWD 列"
        )
    }

    /// 依入口開啟對應的幣別選擇器
    ///
    /// - Parameters:
    ///   - destination: 幣別選擇器入口
    ///   - app: 受測 App
    func openPicker(_ destination: Destination, in app: XCUIApplication) {
        switch destination {
        case .settings:
            let root = RootNavigationScreen(app: app)
            guard root.goToMore() else {
                failWithDiagnostics(in: app, "更多頁未就緒，無法開啟設定")
                return
            }

            let settingsRow = app.descendants(matching: .any)[BLAccessibilityID.More.row(.settings)]
            settingsRow.tapAfterWaiting(in: app)

            let settings = SettingsScreen(app: app)
            guard settings.waitUntilReady() else {
                failWithDiagnostics(in: app, "設定頁未就緒，無法開啟預設幣別")
                return
            }
            settings.openDefaultCurrency()

        case .quote:
            let quote = QuoteScreen.open(from: app)
            guard quote.waitUntilReady() else {
                failWithDiagnostics(in: app, "報價頁未就緒，無法開啟幣別選擇器")
                return
            }
            quote.openCurrencyPicker()

        case .fx:
            let fx = FxScreen.open(from: app)
            guard fx.waitUntilReady() else {
                failWithDiagnostics(in: app, "匯率頁未就緒，無法開啟幣別選擇器")
                return
            }
            fx.openCurrencyPicker()

        case .orderEdit:
            let root = RootNavigationScreen(app: app)
            guard root.goToOrders() else {
                failWithDiagnostics(in: app, "訂單頁未就緒，無法開啟訂單編輯")
                return
            }

            let orders = OrdersScreen(app: app)
            guard orders.waitUntilReady() else {
                failWithDiagnostics(in: app, "訂單清單未就緒，無法開啟訂單編輯")
                return
            }
            orders.tapAddOrder()

            let edit = OrderEditScreen(app: app)
            guard edit.waitUntilReady() else {
                failWithDiagnostics(in: app, "訂單編輯表單未就緒，無法開啟幣別選擇器")
                return
            }
            edit.openCurrencyPicker()
        }
    }
}
