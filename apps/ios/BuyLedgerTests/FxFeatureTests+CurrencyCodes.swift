//
//  FxFeatureTests+CurrencyCodes.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension FxFeatureTests {

    /// 幣別選擇清單的 ISO code 字串依清單順序排列
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
