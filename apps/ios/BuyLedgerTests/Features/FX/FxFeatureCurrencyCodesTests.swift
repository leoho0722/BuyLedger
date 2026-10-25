//
//  FxFeatureCurrencyCodesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Testing

@testable import BuyLedger

/// `FxFeature.State` 的單元測試，涵蓋幣別選擇清單的 ISO 代碼
struct FxFeatureCurrencyCodesTests {

    /// 驗證 `availableCurrencyCodes` 依 `availableCurrencies` 的順序回傳 ISO 代碼字串
    @Test
    func availableCurrencyCodes_依清單順序_回傳ISO代碼() {
        // Given
        let state = FxFeature.State(availableCurrencies: [.usd, .twd])

        // When
        let codes = state.availableCurrencyCodes

        // Then
        #expect(codes == ["USD", "TWD"])
    }
}
