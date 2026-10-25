//
//  QuoteFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `QuoteFormatters` 的單元測試，涵蓋占比計算，預期值以字面值比對
struct QuoteFormattersTests {

    /// 驗證總成本大於一時，占比為項目金額除以總成本，此例 1000 除以 4000 得 0.25
    @Test
    func costShare_總成本大於一_回傳項目占比() {
        // Given
        let value: Decimal = 1_000
        let costTWD: Decimal = 4_000

        // When
        let share = QuoteFormatters.costShare(of: value, costTWD: costTWD)

        // Then
        #expect(share == 0.25)
    }

    /// 驗證總成本不足一時以一作為分母，項目 0.5 在總成本為零時占比仍為 0.5，避免除以接近零的數
    @Test
    func costShare_總成本不足一_以一作為分母() {
        // Given
        let value: Decimal = 0.5
        let costTWD: Decimal = 0

        // When
        let share = QuoteFormatters.costShare(of: value, costTWD: costTWD)

        // Then
        #expect(share == 0.5)
    }

    /// 驗證項目與總成本都為零時，占比回傳 0
    @Test
    func costShare_項目與總成本皆為零_回傳零() {
        // Given
        let value: Decimal = 0
        let costTWD: Decimal = 0

        // When
        let share = QuoteFormatters.costShare(of: value, costTWD: costTWD)

        // Then
        #expect(share == 0)
    }
}
