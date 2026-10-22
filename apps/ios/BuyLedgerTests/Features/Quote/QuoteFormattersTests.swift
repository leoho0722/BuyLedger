//
//  QuoteFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證報價試算的占比計算，預期值以字面值比對
struct QuoteFormattersTests {

    /// 總成本大於一時，項目占比為項目金額除以總成本
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

    /// 總成本不足一時以一計算分母，避免除以零或接近零的數
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

    /// 項目與總成本皆為零時占比為零
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
