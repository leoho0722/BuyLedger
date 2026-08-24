//
//  QuoteTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 報價試算的進入、建議售價與幣別選擇流程測試
final class QuoteTests: BLUITestCase {

    // MARK: - Static Properties

    /// 試算使用的來源幣別 raw value
    private static let selectedCurrency = "KRW"

    // MARK: - Tests

    /// 從更多分頁進報價頁後就緒，輸入商品本金後建議售價有值
    @MainActor
    func testQuoteSuggestsPriceAfterPrincipal() {
        let app = launch(LaunchOptions(seed: .empty))
        let quote = openQuote(app)

        quote.typePrincipal("1000", in: app)

        if quote.suggestedPriceValue.isEmpty {
            failWithDiagnostics(
                in: app,
                "輸入本金後建議售價「\(BLAccessibilityID.Quote.suggestedPriceValue)」的 value 仍為空"
            )
        }
    }

    /// 開幣別選擇器選 KRW 後回報價頁仍就緒
    @MainActor
    func testQuoteReadyAfterSelectingCurrency() {
        let app = launch(LaunchOptions(seed: .empty))
        let quote = openQuote(app)

        quote.openCurrencyPicker()

        let picker = OptionPickerScreen(app: app)
        if !picker.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "幣別選擇器根 identifier「\(picker.rootIdentifier)」逾時仍未出現"
            )
        }
        picker.selectOption(Self.selectedCurrency)

        // 單選點列即套用並自動關閉選擇器，回到報價頁
        if !quote.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "選幣別後報價頁根 identifier「\(quote.rootIdentifier)」逾時仍未回到前景"
            )
        }
    }
}

// MARK: - Private Method

private extension QuoteTests {

    /// 從更多分頁導到報價頁並等就緒，回傳報價頁 Page Object
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 已就緒的報價頁 Page Object
    @MainActor
    func openQuote(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> QuoteScreen {
        let quote = QuoteScreen.open(from: app)
        if !quote.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "報價頁根 identifier「\(quote.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
        return quote
    }
}
