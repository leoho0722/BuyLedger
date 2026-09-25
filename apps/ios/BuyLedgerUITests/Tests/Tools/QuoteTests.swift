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

    /// 試算使用的非預設來源幣別 raw value
    private static let selectedCurrency = "USD"

    // MARK: - Tests

    /// 從更多分頁進報價頁後就緒，輸入商品本金後建議售價有值
    ///
    /// - Throws: 建議售價元素不存在或沒有值時拋出測試錯誤
    @MainActor
    func testQuoteSuggestsPriceAfterPrincipal() throws(any Error) {
        // Given：報價頁已就緒
        let app = launch(LaunchOptions(seed: .empty))
        let quote = openQuote(app)

        // When：輸入商品本金 1000
        quote.typePrincipal("1000", in: app)

        // Then：建議售價應是固定匯率下的 $230
        let missingValueMessage = "輸入本金後建議售價元素不存在"
        let value = try requireValue(
            quote.suggestedPriceValue,
            in: app,
            missingValueMessage
        )
        XCTAssertEqual(
            value,
            "$230",
            "1000 KRW 的固定匯率與預設成本應得到 $230 建議售價"
        )
    }

    /// 開幣別選擇器選 USD 後回報價頁仍就緒且已套用來源幣別
    ///
    /// - Throws: 來源幣別元素不存在或未套用選取值時拋出測試錯誤
    @MainActor
    func testQuoteReadyAfterSelectingCurrency() throws(any Error) {
        // Given：報價頁已就緒，準備選取非預設來源幣別
        let app = launch(LaunchOptions(seed: .empty))
        let quote = openQuote(app)

        // When：開啟選擇器並選取 USD
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

        // Then：報價頁來源幣別應已套用 USD
        let sourceCurrencyCode = try requireValue(
            quote.sourceCurrencyCode,
            in: app,
            "報價頁來源幣別元素不存在"
        )
        XCTAssertEqual(
            sourceCurrencyCode,
            Self.selectedCurrency,
            "報價頁來源幣別應為 \(Self.selectedCurrency)，"
                + "實際為：\(sourceCurrencyCode)"
        )
    }
}

// MARK: - Private Method

private extension QuoteTests {

    /// 從更多分頁導到報價頁並等就緒，回傳報價頁 Page Object
    ///
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
        let quote = QuoteScreen.open(from: app, file: file, line: line)
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
