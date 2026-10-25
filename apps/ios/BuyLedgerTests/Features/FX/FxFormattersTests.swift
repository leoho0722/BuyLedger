//
//  FxFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `FxFormatters` 的單元測試，預期值為字面值，直接比對格式化後的字串
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
    @Test
    func conversionLabel_有匯率_顯示來源幣別與四位小數匯率() {
        // Given
        let rate = Decimal(sign: .plus, exponent: -3, significand: 24)

        // When
        let label = FxFormatters.conversionLabel(
            from: .krw,
            rate: rate,
            locale: AppLanguage.english.locale
        )

        // Then
        #expect(label == "1 KRW = 0.0240 TWD")
    }

    /// 驗證沒有匯率時，`conversionLabel` 的匯率位置顯示破折號，來源與目標幣別照常顯示
    @Test
    func conversionLabel_無匯率_匯率位置顯示破折號() {
        // Given
        let rate: Decimal? = nil

        // When
        let label = FxFormatters.conversionLabel(
            from: .usd,
            rate: rate,
            locale: AppLanguage.english.locale
        )

        // Then
        #expect(label == "1 USD = — TWD")
    }

    /// 驗證尚未取得匯率快照時，`rateSourceSubtitle` 顯示「尚未連線」
    @Test
    func rateSourceSubtitle_無快照_顯示尚未連線() {
        // Given
        let snapshotDate: Date? = nil

        // When
        let subtitle = FxFormatters.rateSourceSubtitle(
            snapshotDate: snapshotDate,
            locale: AppLanguage.traditionalChinese.locale
        )

        // Then
        #expect(subtitle == "尚未連線")
    }

    /// 驗證有匯率快照時，`rateSourceSubtitle` 以來源名稱 ExchangeRate-API 開頭
    @Test
    func rateSourceSubtitle_有快照_以來源名稱開頭() {
        // Given
        let snapshotDate: Date? = Date(timeIntervalSince1970: 1_777_000_000)

        // When
        let subtitle = FxFormatters.rateSourceSubtitle(
            snapshotDate: snapshotDate,
            locale: AppLanguage.english.locale
        )

        // Then
        #expect(subtitle.hasPrefix("ExchangeRate-API · "))
    }
}
