//
//  FxFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `FxFormatters` 的單元測試，以字面值驗證鍵值與解析後的文字
struct FxFormattersTests {

    /// 驗證 `unitRateLabel` 對美元回傳 1 加上幣別代碼的標籤
    @Test
    func unitRateLabel_美元_顯示一單位與代碼() {
        // Given
        let currency = CurrencyCode.usd

        // When
        let label = FxFormatters.unitRateLabel(currency)

        // Then
        #expect(label == "1 USD")
    }

    /// 驗證有匯率時，`conversionLabel` 依 App 語言呈現來源幣別與四位小數的匯率
    ///
    /// - Parameter language: 解析換算說明的 App 語言
    @Test(arguments: [AppLanguage.english, .traditionalChinese])
    func conversionLabel_有匯率_顯示來源幣別與四位小數匯率(language: AppLanguage) {
        // Given
        let rate = Decimal(sign: .plus, exponent: -3, significand: 24)

        // When
        let label = FxFormatters.conversionLabel(from: .krw, rate: rate, locale: language.locale)

        // Then
        #expect(label.key == "fx.rates.label.conversionRate")
        #expect(language.resolve(label) == "1 KRW = 0.0240 TWD")
    }

    /// 驗證沒有匯率時，`conversionLabel` 的匯率位置顯示破折號，來源與目標幣別照常顯示
    ///
    /// - Parameter language: 解析換算說明的 App 語言
    @Test(arguments: [AppLanguage.english, .traditionalChinese])
    func conversionLabel_無匯率_匯率位置顯示破折號(language: AppLanguage) {
        // Given
        let rate: Decimal? = nil

        // When
        let label = FxFormatters.conversionLabel(from: .usd, rate: rate, locale: language.locale)

        // Then
        #expect(label.key == "fx.rates.label.conversionRate")
        #expect(language.resolve(label) == "1 USD = — TWD")
    }

    /// 驗證尚未取得匯率快照時，`rateSourceSubtitle` 依 App 語言顯示尚未連線
    ///
    /// - Parameter scenario: 解析語言與完整預期文字
    @Test(arguments: [
        SubtitleScenario(language: .traditionalChinese, expected: "尚未連線"),
        SubtitleScenario(language: .english, expected: "Not connected"),
    ])
    func rateSourceSubtitle_無快照_顯示尚未連線(scenario: SubtitleScenario) {
        // Given
        let snapshotDate: Date? = nil

        // When
        let subtitle = FxFormatters.rateSourceSubtitle(
            snapshotDate: snapshotDate,
            locale: scenario.language.locale
        )

        // Then
        #expect(subtitle.key == "fx.rates.label.connected")
        #expect(scenario.language.resolve(subtitle) == scenario.expected)
    }

    /// 驗證有匯率快照時，`rateSourceSubtitle` 顯示來源名稱與非空的時間文字
    ///
    /// - Parameter language: 解析來源副標的 App 語言
    /// - Note: 快照時間沿用系統時區，各機器輸出可能不同，因此不斷言完整時間文字
    @Test(arguments: [AppLanguage.english, .traditionalChinese])
    func rateSourceSubtitle_有快照_顯示來源與非空時間(language: AppLanguage) {
        // Given
        let expectedPrefix = "ExchangeRate-API · "
        let snapshotDate: Date? = Date(timeIntervalSince1970: 1_777_000_000)

        // When
        let subtitle = FxFormatters.rateSourceSubtitle(
            snapshotDate: snapshotDate,
            locale: language.locale
        )
        let text = language.resolve(subtitle)
        let timestamp = text.dropFirst(expectedPrefix.count)

        // Then
        #expect(subtitle.key == "fx.rates.label.sourceTimestamp")
        #expect(text.hasPrefix(expectedPrefix))
        #expect(timestamp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
    }
}

// MARK: - Nested Types

extension FxFormattersTests {

    /// 匯率副標的解析語言與字面值預期
    struct SubtitleScenario: Sendable {

        /// 解析副標的 App 語言
        let language: AppLanguage

        /// 該語言下的完整預期文字
        let expected: String
    }
}
