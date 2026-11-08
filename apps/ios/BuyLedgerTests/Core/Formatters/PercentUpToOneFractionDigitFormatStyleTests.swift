//
//  PercentUpToOneFractionDigitFormatStyleTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/8.
//

import Foundation
import Testing

@testable import BuyLedger

/// `PercentUpToOneFractionDigitFormatStyle` 的單元測試
struct PercentUpToOneFractionDigitFormatStyleTests {

    /// 驗證各語言與比例值都顯示為最多一位小數的百分比
    ///
    /// - Parameter scenario: App 語言、比例與預期百分比
    @Test(arguments: [
        PercentFormatCase(language: .traditionalChinese, ratio: 0, expected: "0%"),
        PercentFormatCase(language: .traditionalChinese, ratio: 1, expected: "100%"),
        PercentFormatCase(language: .traditionalChinese, ratio: 0.015, expected: "1.5%"),
        PercentFormatCase(language: .traditionalChinese, ratio: 0.1234, expected: "12.3%"),
        PercentFormatCase(language: .english, ratio: 0, expected: "0%"),
        PercentFormatCase(language: .english, ratio: 1, expected: "100%"),
        PercentFormatCase(language: .english, ratio: 0.015, expected: "1.5%"),
        PercentFormatCase(language: .english, ratio: 0.1234, expected: "12.3%"),
    ])
    func percentUpToOneFractionDigit_各語言與比例值_顯示預期百分比(scenario: PercentFormatCase) {
        // Given
        let locale = scenario.language.locale

        // When
        let text = scenario.ratio.formatted(.percentUpToOneFractionDigit(locale: locale))

        // Then
        #expect(text == scenario.expected)
    }
}

// MARK: - Nested Types

extension PercentUpToOneFractionDigitFormatStyleTests {

    /// 百分比格式測試使用的語言、比例與預期文字
    struct PercentFormatCase: Sendable {

        /// 測試使用的 App 語言
        let language: AppLanguage

        /// 要格式化的比例
        let ratio: Double

        /// 預期顯示的百分比
        let expected: String
    }
}
