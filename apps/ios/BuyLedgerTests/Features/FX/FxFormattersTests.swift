//
//  FxFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證匯率工具的格式化輸出，預期值以字面值比對
struct FxFormattersTests {

    /// 一單位幣別的標籤為數字一加上幣別代碼
    @Test
    func unitRateLabel_美元_顯示一單位與代碼() {
        // Given
        let currency = CurrencyCode.usd

        // When
        let label = FxFormatters.unitRateLabel(currency)

        // Then
        #expect(label == "1 USD")
    }

    /// 有匯率時換算說明依 App 語言呈現來源幣別與四位小數的匯率
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

    /// 沒有匯率時換算說明的匯率位置顯示破折號
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

    /// 尚未取得匯率快照時副標顯示尚未連線
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

    /// 有匯率快照時副標以來源名稱開頭，後接快照時間
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
