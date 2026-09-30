//
//  FxRatesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/19.
//

import Foundation
import Testing
@testable import BuyLedger

/// 驗證 Preview 匯率
struct FxRatesTests {

    // MARK: - Tests

    /// Preview 匯率應精確對應預設的四個幣別數值
    @Test func previewRatesMatchExpectedValues() {
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
