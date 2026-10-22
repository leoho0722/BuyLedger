//
//  FxFormatters.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/23.
//

import Foundation

/// 匯率工具專用的格式化規則
enum FxFormatters {

}

// MARK: - Internal Method

extension FxFormatters {

    /// 依指定 `locale` 格式化匯率快照時間
    ///
    /// - Parameters:
    ///   - date: 匯率快照日期；無日期時為 `nil`
    ///   - locale: 用於呈現的 `locale`
    /// - Returns: 月日與時分字串，或無日期時的破折號
    static func snapshotTimestamp(_ date: Date?, locale: Locale) -> String {
        guard let date else {
            return "—"
        }
        return date.formatted(
            .dateTime
                .month(.defaultDigits)
                .day(.defaultDigits)
                .hour(.defaultDigits(amPM: .omitted))
                .minute(.twoDigits)
                .locale(locale)
        )
    }

    /// 組出換算說明，依 App 語言呈現一單位來源幣別等於多少 TWD
    ///
    /// - Parameters:
    ///   - currency: 來源幣別
    ///   - rate: 一單位來源幣別對應的新台幣匯率；無資料時為 `nil`
    ///   - locale: App 選定、用於呈現的 `locale`
    /// - Returns: 依 App 語言解析後的換算說明，無匯率時匯率位置為破折號
    static func conversionLabel(
        from currency: CurrencyCode,
        rate: Decimal?,
        locale: Locale
    ) -> String {
        AppLanguage.format(
            "fx.rates.label.conversionRate",
            currency.rawValue,
            FxFormatters.rate(rate, locale: locale),
            locale: locale
        )
    }

    /// 依指定 `locale` 格式化匯率；無資料時顯示破折號
    ///
    /// - Parameters:
    ///   - rate: 一單位來源幣別對應的新台幣匯率
    ///   - locale: 用於呈現的 `locale`
    /// - Returns: 四位小數的匯率字串，或無資料時的破折號
    static func rate(_ rate: Decimal?, locale: Locale) -> String {
        guard let rate else {
            return "—"
        }
        return rate.formatted(.number.precision(.fractionLength(4)).locale(locale))
    }

    /// 依指定 `locale` 格式化快速金額
    ///
    /// - Parameters:
    ///   - amount: 快速金額
    ///   - locale: 用於呈現的 `locale`
    /// - Returns: 不含小數位的金額字串
    static func presetAmount(_ amount: Decimal, locale: Locale) -> String {
        amount.formatted(.number.precision(.fractionLength(0)).locale(locale))
    }

    /// 組出一單位幣別與代碼的標籤，例如 `1 USD`
    ///
    /// - Parameter currency: 來源幣別
    /// - Returns: 一單位幣別與代碼的字串
    static func unitRateLabel(_ currency: CurrencyCode) -> String {
        "1 \(currency.rawValue)"
    }

    /// 組出即時匯率列的副標，未連線時顯示尚未連線，有快照時顯示來源與快照時間
    ///
    /// - Parameters:
    ///   - snapshotDate: 最新匯率快照時間；無快照時為 `nil`
    ///   - locale: App 選定、用於呈現的 `locale`
    /// - Returns: 依 App 語言解析後的副標文字
    static func rateSourceSubtitle(snapshotDate: Date?, locale: Locale) -> String {
        guard snapshotDate != nil else {
            return AppLanguage(locale: locale).localized("fx.rates.label.connected")
        }
        return AppLanguage.format(
            "fx.rates.label.sourceTimestamp",
            snapshotTimestamp(snapshotDate, locale: locale),
            locale: locale
        )
    }
}
