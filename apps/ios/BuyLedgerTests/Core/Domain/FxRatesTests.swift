//
//  FxRatesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/19.
//

import Foundation
import Testing

@testable import BuyLedger

/// `FxRates` 的單元測試，涵蓋 Preview 預設匯率
struct FxRatesTests {

    /// 驗證 `toTWD` 的預設匯率中，新台幣為 1，韓元、日圓與美元分別為 0.0228、0.2105 與 32.45
    @Test
    func toTWD_預覽匯率_對應預設四個幣別數值() {
        // Given
        let expectedKRW = NSDecimalNumber(string: "0.0228").decimalValue
        let expectedJPY = NSDecimalNumber(string: "0.2105").decimalValue
        let expectedUSD = NSDecimalNumber(string: "32.45").decimalValue

        // When
        let actualRates = FxRates.toTWD

        // Then
        #expect(actualRates[.twd] == Decimal(1))
        #expect(actualRates[.krw] == expectedKRW)
        #expect(actualRates[.jpy] == expectedJPY)
        #expect(actualRates[.usd] == expectedUSD)
    }
}
