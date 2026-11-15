//
//  QuoteUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 報價試算、來源幣別、轉向續輸入與鍵盤狀態的 UI 測試
@MainActor
final class QuoteUITests: BLUITestCase {

    // MARK: - Properties

    /// 試算使用的非預設來源幣別 raw value
    private static let selectedCurrency = "USD"

    /// 驗證從更多分頁進入報價頁後，輸入商品本金 1000，建議售價顯示 $30
    ///
    /// - Throws: 建議售價元素不存在或沒有值時丟出 UITestError.stopped
    func testTypePrincipal_輸入商品本金_顯示建議售價() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let quote = try QuoteScreen.open(in: app)

        // When
        try quote.typePrincipal("1000")

        // Then
        let missingValueMessage = "輸入本金後建議售價元素不存在"
        let value = try requireValue(quote.suggestedPriceValue(), in: app, missingValueMessage)
        XCTAssertEqual(value, "$30", "1000 KRW × 0.0228 = 22.8 TWD，進位為 $30 建議售價")
    }

    /// 驗證報價頁開幣別選擇器選取 USD 後，單選即套用並自動關閉選擇器，回到報價頁且來源幣別為 USD
    ///
    /// - Throws: 幣別選擇器未就緒、來源幣別元素不存在或未套用選取值時丟出 UITestError.stopped
    func testCurrencySelected_選取非預設幣別_報價頁套用來源幣別() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let quote = try QuoteScreen.open(in: app)
        let picker = try quote.openCurrencyPicker()

        // When
        try picker.selectOption(Self.selectedCurrency)

        // Then
        if !quote.waitUntilReady() {
            failWithDiagnostics(in: app, "選幣別後報價頁根 identifier「\(quote.rootIdentifier)」逾時仍未回到前景")
        }
        let sourceCurrencyCode = try requireValue(
            quote.sourceCurrencyCode(),
            in: app,
            "報價頁來源幣別元素不存在"
        )
        XCTAssertEqual(sourceCurrencyCode, "USD", "報價頁來源幣別應為 USD")
    }

    /// 驗證本金欄輸入後旋轉，再續輸入的數字仍寫回同一欄並保持鍵盤焦點
    ///
    /// - Throws: 本金欄未就緒、旋轉失敗或欄位失去焦點時丟出 UITestError.stopped
    func testItemPrice_轉向後續輸入_本金寫回同一欄() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let quote = try QuoteScreen.open(in: app)
        try quote.replacePrincipalKeepingKeyboard("1")

        // When
        try rotateToLandscape(app)

        // Then
        try requireCondition(quote.isPrincipalFieldFocused(), in: app, "旋轉後本金欄失去鍵盤焦點")

        // When
        quote.appendPrincipal("0")

        // Then
        let value = try requireValue(quote.principalFieldValue(), in: app, "旋轉後本金欄元素不存在")
        XCTAssertEqual(value, "10", "旋轉後續輸入的數字應寫回本金欄")
    }

    /// 驗證使用者收起數字鍵盤後旋轉，本金欄輸入值保留，鍵盤與本金欄焦點維持收起，不因重排重新彈出
    ///
    /// - Throws: 本金欄未就緒或旋轉失敗時丟出 UITestError.stopped
    func testRotateToLandscape_收鍵盤後轉向_鍵盤保持收起() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let quote = try QuoteScreen.open(in: app)
        try quote.replacePrincipalKeepingKeyboard("1")
        try quote.dismissPrincipalKeyboard()

        // When
        try rotateToLandscape(app)

        // Then
        let value = try requireValue(quote.principalFieldValue(), in: app, "收鍵盤後旋轉本金欄元素不存在")
        XCTAssertEqual(value, "1", "收鍵盤後旋轉，本金欄應保留使用者輸入的值")
        XCTAssertFalse(quote.isPrincipalFieldFocused(), "使用者收起鍵盤後，旋轉不應把本金欄重新設為焦點")
        if !app.keyboards.firstMatch.waitForNonExistence(timeout: 3) {
            failWithDiagnostics(in: app, "使用者收起鍵盤後旋轉，鍵盤被重新彈出")
        }
    }
}
