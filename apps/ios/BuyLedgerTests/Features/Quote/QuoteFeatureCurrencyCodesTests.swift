//
//  QuoteFeatureCurrencyCodesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Testing

@testable import BuyLedger

/// `QuoteRateFeature.State` 的單元測試，涵蓋報價試算幣別選擇清單的 ISO 代碼
struct QuoteFeatureCurrencyCodesTests {

    /// 驗證 `availableCurrencyCodes` 依 `availableCurrencies` 的順序，回傳各幣別的 ISO 代碼字串
    @Test
    func availableCurrencyCodes_依清單順序_回傳ISO代碼() {
        // Given
        let rateSource = QuoteRateFeature.State(availableCurrencies: [.usd, .twd])

        // When
        let codes = rateSource.availableCurrencyCodes

        // Then
        #expect(codes == ["USD", "TWD"])
    }
}
