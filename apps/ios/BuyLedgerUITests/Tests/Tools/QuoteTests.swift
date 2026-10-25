//
//  QuoteTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 報價試算的進入、建議售價與幣別選擇流程 UI 測試
@MainActor
final class QuoteTests: BLUITestCase {

    // MARK: - Properties

    /// 試算使用的非預設來源幣別 raw value
    private static let selectedCurrency = "USD"

    /// 驗證從更多分頁進入報價頁後，輸入商品本金 1000，建議售價顯示 $230
    ///
    /// - Throws: 建議售價元素不存在或沒有值時丟出測試錯誤
    func testTypePrincipal_輸入商品本金_顯示建議售價() throws {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        let quote = openQuote(app)

        // When
        quote.typePrincipal("1000", in: app)

        // Then
        let missingValueMessage = "輸入本金後建議售價元素不存在"
        let value = try requireValue(quote.suggestedPriceValue, in: app, missingValueMessage)
        XCTAssertEqual(value, "$230", "1000 KRW 的固定匯率與預設成本應得到 $230 建議售價")
    }

    /// 驗證報價頁開幣別選擇器選取 USD 後，單選即套用並自動關閉選擇器，回到報價頁且來源幣別為 USD
    ///
    /// - Throws: 幣別選擇器未就緒、來源幣別元素不存在或未套用選取值時丟出測試錯誤
    func testSelectOption_選取非預設幣別_報價頁套用來源幣別() throws {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        let quote = openQuote(app)
        quote.openCurrencyPicker()
        let picker = OptionPickerScreen(app: app)
        try requireCondition(
            picker.waitUntilReady(),
            in: app,
            "幣別選擇器根 identifier「\(picker.rootIdentifier)」逾時仍未出現"
        )

        // When
        picker.selectOption(Self.selectedCurrency)

        // Then
        if !quote.waitUntilReady() {
            failWithDiagnostics(in: app, "選幣別後報價頁根 identifier「\(quote.rootIdentifier)」逾時仍未回到前景")
        }
        let sourceCurrencyCode = try requireValue(quote.sourceCurrencyCode, in: app, "報價頁來源幣別元素不存在")
        XCTAssertEqual(
            sourceCurrencyCode,
            Self.selectedCurrency,
            "報價頁來源幣別應為 \(Self.selectedCurrency)"
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
