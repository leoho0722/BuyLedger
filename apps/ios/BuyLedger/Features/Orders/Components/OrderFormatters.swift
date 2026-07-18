//
//  OrderFormatters.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 訂單畫面使用的格式化工具
enum OrderFormatters {}

// MARK: - Internal Method

extension OrderFormatters {

    /// 將新台幣金額格式化為無小數位字串
    /// - Parameters:
    ///   - amount: 要格式化的金額
    ///   - locale: App 選定、用於金額呈現的 locale
    /// - Returns: 依選定 locale 呈現的新台幣金額字串
    static func twd(_ amount: Decimal, locale: Locale) -> String {
        amount.formatted(
            .currency(code: CurrencyCode.twd.code)
            .precision(.fractionLength(0))
            .locale(locale)
        )
    }

    /// 將原始幣別金額格式化為無小數位字串
    /// - Parameters:
    ///   - amount: 要格式化的金額
    ///   - currency: 金額所屬幣別
    ///   - locale: App 選定、用於金額呈現的 locale
    /// - Returns: 包含幣別符號的金額字串
    static func currency(_ amount: Decimal, currency: CurrencyCode, locale: Locale) -> String {
        amount.formatted(
            .currency(code: currency.code)
            .precision(.fractionLength(0))
            .locale(locale)
        )
    }

    /// 將比例格式化為百分比
    /// - Parameters:
    ///   - value: `0` 到 `1` 之間的比例
    ///   - locale: App 選定、用於百分比呈現的 locale
    /// - Returns: 百分比字串
    static func percent(_ value: Decimal, locale: Locale) -> String {
        value.formatted(.percent.precision(.fractionLength(1)).locale(locale))
    }

    /// 將日期格式化為列表使用的短日期
    /// - Parameters:
    ///   - date: 要格式化的日期
    ///   - locale: App 選定、用於日期呈現的 locale
    /// - Returns: 月日格式字串
    static func shortDate(_ date: Date, locale: Locale) -> String {
        date.formatted(
            .dateTime
                .month(.defaultDigits)
                .day(.defaultDigits)
                .locale(locale)
        )
    }

    /// 將某一日格式化為訂單列表日期區段的標題
    ///
    /// 今天／昨天以相對字串呈現；同年內顯示「M月d日 週X」，跨年則顯示「yyyy年M月d日」。相對判斷以 `referenceDate` 為基準，
    /// caller 應從 `@Dependency(\.date)` 取得當下時間以維持可測試性
    /// - Parameters:
    ///   - day: 該區段所屬日期 (通常為當日起始時刻)
    ///   - referenceDate: 用於判斷「今天／昨天」的基準時間
    ///   - calendar: 用於日期比較與分解的曆法
    ///   - locale: App 選定、用於非相對日期標題的 locale
    /// - Returns: 區段標題字串
    static func daySectionTitle(
        for day: Date,
        referenceDate: Date,
        calendar: Calendar,
        locale: Locale
    ) -> String {
        if calendar.isDate(day, inSameDayAs: referenceDate) {
            return "今天"
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate),
           calendar.isDate(day, inSameDayAs: yesterday) {
            return "昨天"
        }

        let sameYear = calendar.component(.year, from: day) == calendar.component(.year, from: referenceDate)
        if sameYear {
            return day.formatted(
                .dateTime
                    .month(.wide)
                    .day(.defaultDigits)
                    .weekday(.abbreviated)
                    .locale(locale)
            )
        }

        return day.formatted(
            .dateTime
                .year()
                .month(.wide)
                .day(.defaultDigits)
                .locale(locale)
        )
    }

    /// 將日期格式化為 `yyyy/MM/dd HH:mm:ss`
    ///
    /// pattern 固定，locale 由呼叫端提供 (通常由 view 端 `@Environment(\.locale)` 讀取 App 語言偏好)
    /// - Parameters:
    ///   - date: 要格式化的日期
    ///   - locale: 用於數字系統等 locale 相依細節的 locale
    /// - Returns: 包含年月日與時分秒的字串
    static func fullTimestamp(_ date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        formatter.locale = locale
        return formatter.string(from: date)
    }
}
