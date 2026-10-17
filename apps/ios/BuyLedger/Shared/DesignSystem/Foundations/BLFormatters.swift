//
//  BLFormatters.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/30.
//

import Foundation

/// 金額、百分比與日期呈現規則的唯一入口
enum BLFormatters {

}

// MARK: - Internal Method

extension BLFormatters {

    /// 依指定 locale 將日期格式化為列表使用的月日短日期
    ///
    /// - Parameters:
    ///   - date: 要格式化的日期
    ///   - locale: 用於呈現的 locale
    /// - Returns: 月日格式字串
    static func shortDate(_ date: Date, locale: Locale) -> String {
        date.formatted(.dateTime.month(.defaultDigits).day(.defaultDigits).locale(locale))
    }

    /// 依指定行事曆與 locale 格式化日區段標題，當天與前一天顯示相對日期
    ///
    /// - Parameters:
    ///   - day: 該區段所屬日期
    ///   - now: 用於判斷「今天／昨天」與同年的基準時間
    ///   - calendar: 用於日期比較與格式化的行事曆，包含時區
    ///   - locale: 用於非相對日期標題的 locale
    /// - Returns: 今天、昨天、同年的月日星期，或跨年的年月日
    static func daySectionTitle(
        for day: Date,
        now: Date,
        calendar: Calendar,
        locale: Locale
    ) -> String {
        let language = AppLanguage(locale: locale)
        if calendar.isDate(day, inSameDayAs: now) {
            return language.localized("common.date.today")
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(day, inSameDayAs: yesterday) {
            return language.localized("common.date.yesterday")
        }

        let isSameYear = calendar.component(.year, from: day)
            == calendar.component(.year, from: now)
        var style: Date.FormatStyle
        if isSameYear {
            style = .dateTime
                .month(.wide)
                .day(.defaultDigits)
                .weekday(.abbreviated)
                .locale(locale)
        } else {
            style = .dateTime
                .year()
                .month(.wide)
                .day(.defaultDigits)
                .locale(locale)
        }
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        return day.formatted(style)
    }

    /// 依指定行事曆與 locale 將區段日期格式化為年與月
    ///
    /// - Parameters:
    ///   - date: 該區段所屬日期
    ///   - calendar: 用於格式化的行事曆，包含時區
    ///   - locale: 用於日期標題的 locale
    /// - Returns: 年月標題字串
    static func yearMonthSectionTitle(_ date: Date, calendar: Calendar, locale: Locale) -> String {
        var style = Date.FormatStyle.dateTime.year().month().locale(locale)
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    /// 依指定行事曆與 locale 將區段日期格式化為年
    ///
    /// - Parameters:
    ///   - date: 該區段所屬日期
    ///   - calendar: 用於格式化的行事曆，包含時區
    ///   - locale: 用於日期標題的 locale
    /// - Returns: 年標題字串
    static func yearSectionTitle(_ date: Date, calendar: Calendar, locale: Locale) -> String {
        var style = Date.FormatStyle.dateTime.year().locale(locale)
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    /// 依指定行事曆與 locale 將區段日期格式化為完整月份
    ///
    /// - Parameters:
    ///   - date: 該區段所屬日期
    ///   - calendar: 用於格式化的行事曆，包含時區
    ///   - locale: 用於日期標題的 locale
    /// - Returns: 月標題字串
    static func monthSectionTitle(_ date: Date, calendar: Calendar, locale: Locale) -> String {
        var style = Date.FormatStyle.dateTime.month(.wide).locale(locale)
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    /// 依指定行事曆的時區與 locale 將日期格式化為 `yyyy/MM/dd HH:mm:ss`
    ///
    /// - Parameters:
    ///   - date: 要格式化的日期
    ///   - calendar: 提供時區的行事曆；年月日固定以西曆印出
    ///   - locale: 用於數字系統等呈現細節的 locale
    /// - Returns: 包含年月日與時分秒的字串
    static func fullTimestamp(_ date: Date, calendar: Calendar, locale: Locale) -> String {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = gregorian
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter.string(from: date)
    }

    /// 依指定 locale 將金額格式化為新台幣；`nil` 顯示為「—」
    ///
    /// - Parameters:
    ///   - amount: 金額，`nil` 代表無可用資料
    ///   - locale: 用於呈現的 locale
    /// - Returns: 含 NT$ 前綴的字串，或無資料時的「—」佔位符
    static func twd(_ amount: Decimal?, locale: Locale) -> String {
        guard let amount else {
            return "—"
        }
        return twd(amount, locale: locale)
    }

    /// 依指定 locale 將金額格式化為新台幣 (無小數位)
    ///
    /// - Parameters:
    ///   - amount: 金額
    ///   - locale: 用於呈現的 locale
    /// - Returns: 含 NT$ 前綴的字串
    static func twd(_ amount: Decimal, locale: Locale) -> String {
        amount.formatted(.currency(code: "TWD").precision(.fractionLength(0)).locale(locale))
    }

    /// 依指定 locale 將比例格式化為百分比
    ///
    /// - Parameters:
    ///   - ratio: 0 到 1 的比例，例如 0.654 表示 65.4%
    ///   - locale: 用於呈現的 locale
    ///   - fractionLength: 小數位數，預設為 1
    /// - Returns: 依指定小數位數呈現的百分比字串
    static func percent(_ ratio: Decimal, locale: Locale, fractionLength: Int = 1) -> String {
        ratio.formatted(.percent.precision(.fractionLength(fractionLength)).locale(locale))
    }

    /// 依指定 locale 將已是百分比尺度的數值格式化為百分比字串
    ///
    /// - Parameters:
    ///   - value: 百分比數值，例如 65.4 表示 65.4%
    ///   - locale: 用於呈現的 locale
    /// - Returns: 含一位小數的百分比字串
    static func percent(scaled value: Decimal, locale: Locale) -> String {
        (value / 100).formatted(.percent.precision(.fractionLength(1)).locale(locale))
    }
}
