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

    /// 驗證目標毛利提示依 App 語言呈現百分比與完整句子
    ///
    /// - Parameter scenario: 測試語言與預期提示
    @Test(arguments: [
        LocalizedMessageCase(language: .traditionalChinese, expected: "目標毛利需低於 100% 才能計算建議售價。"),
        LocalizedMessageCase(
            language: .english,
            expected: "The target margin must be below 100% to calculate a suggested price."
        ),
    ])
    func targetMarginLimitMessage_各語言_顯示相符提示(scenario: LocalizedMessageCase) {
        // Given
        let locale = scenario.language.locale

        // When
        let message = QuoteFormatters.targetMarginLimitMessage(locale: locale)

        // Then
        #expect(message.key == "quote.calculator.message.targetMarginLimitNotice")
        #expect(scenario.language.resolve(message) == scenario.expected)
    }

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

// MARK: - Nested Types

extension QuoteFormattersTests {

    /// 本地化提示測試使用的語言與預期字串
    struct LocalizedMessageCase: Sendable {

        /// 測試使用的 App 語言
        let language: AppLanguage

        /// 該語言的完整預期提示
        let expected: String
    }
}
