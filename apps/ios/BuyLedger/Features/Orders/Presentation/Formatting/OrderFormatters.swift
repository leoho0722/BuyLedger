//
//  OrderFormatters.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import SwiftUI

/// 訂單畫面使用的格式化工具
enum OrderFormatters {

}

// MARK: - Internal Method

extension OrderFormatters {

    /// 組合收款與帶正負號獲利的文字，供訂單列的無障礙值朗讀
    ///
    /// - Parameters:
    ///   - revenue: 實際收款
    ///   - profit: 獲利，非負數前面加上「+」
    ///   - locale: App 選定、用於金額呈現的 locale
    /// - Returns: 以空格分隔的收款與獲利字串，例如「NT$1,000 +NT$200」
    static func revenueAndProfitText(revenue: Decimal, profit: Decimal, locale: Locale) -> String {
        "\(twd(revenue, locale: locale)) \(signedTWD(profit, locale: locale))"
    }

    /// 將新台幣金額格式化為帶正負號的字串，非負數前面加上「+」
    ///
    /// - Parameters:
    ///   - amount: 要格式化的金額，負數保留金額本身的負號
    ///   - locale: App 選定、用於金額呈現的 locale
    /// - Returns: 帶正負號的新台幣金額字串
    static func signedTWD(_ amount: Decimal, locale: Locale) -> String {
        (amount >= 0 ? "+" : "") + twd(amount, locale: locale)
    }

    /// 將金額格式化為前面一律加上「-」的新台幣字串
    ///
    /// - Parameters:
    ///   - amount: 要格式化的金額，例如無卡折抵金額
    ///   - locale: App 選定、用於金額呈現的 locale
    /// - Returns: 前面加上「-」的新台幣金額字串
    static func minusTWD(_ amount: Decimal, locale: Locale) -> String {
        "-" + twd(amount, locale: locale)
    }

    /// 將金額格式化為前面一律加上「+」的新台幣字串
    ///
    /// - Parameters:
    ///   - amount: 要格式化的金額，例如無卡補款金額
    ///   - locale: App 選定、用於金額呈現的 locale
    /// - Returns: 前面加上「+」的新台幣金額字串
    static func plusTWD(_ amount: Decimal, locale: Locale) -> String {
        "+" + twd(amount, locale: locale)
    }

    /// 將新台幣金額格式化為無小數位字串
    ///
    /// - Parameters:
    ///   - amount: 要格式化的金額
    ///   - locale: App 選定、用於金額呈現的 locale
    /// - Returns: 依選定 locale 呈現的新台幣金額字串
    static func twd(_ amount: Decimal, locale: Locale) -> String {
        BLFormatters.twd(amount, locale: locale)
    }

    /// 將原始幣別金額格式化為無小數位字串
    ///
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

    /// 格式化訂單毛利率；收款非正數時顯示「—」
    ///
    /// - Parameters:
    ///   - summary: 訂單財務摘要
    ///   - locale: App 選定、用於百分比呈現的 locale
    /// - Returns: 毛利率百分比；收款非正數時為「—」
    static func marginPercent(_ summary: OrderSummary, locale: Locale) -> String {
        guard summary.revenue > 0 else {
            return "—"
        }
        return percent(summary.margin, locale: locale)
    }

    /// 將比例格式化為百分比
    ///
    /// - Parameters:
    ///   - value: 「0」到「1」之間的比例
    ///   - locale: App 選定、用於百分比呈現的 locale
    /// - Returns: 百分比字串
    static func percent(_ value: Decimal, locale: Locale) -> String {
        BLFormatters.percent(value, locale: locale)
    }

    /// 將日期格式化為列表使用的短日期
    ///
    /// - Parameters:
    ///   - date: 要格式化的日期
    ///   - locale: App 選定、用於日期呈現的 locale
    /// - Returns: 月日格式字串
    static func shortDate(_ date: Date, locale: Locale) -> String {
        BLFormatters.shortDate(date, locale: locale)
    }

    /// 將某一日格式化為訂單列表日期區段的標題
    ///
    /// - Parameters:
    ///   - day: 該區段所屬日期 (通常為當日起始時刻)
    ///   - referenceDate: 用於判斷「今天／昨天」的基準時間
    ///   - calendar: 用於日期比較與格式化的行事曆，包含時區
    ///   - locale: App 選定、用於非相對日期標題的 locale
    /// - Returns: 區段標題字串
    static func daySectionTitle(
        for day: Date,
        referenceDate: Date,
        calendar: Calendar,
        locale: Locale
    ) -> String {
        BLFormatters.daySectionTitle(
            for: day,
            now: referenceDate,
            calendar: calendar,
            locale: locale
        )
    }

    /// 將日期格式化為 yyyy/MM/dd HH:mm:ss
    ///
    /// - Parameters:
    ///   - date: 要格式化的日期
    ///   - calendar: 用於格式化的行事曆，包含時區
    ///   - locale: 用於數字系統等 locale 相依細節的 locale
    /// - Returns: 包含年月日與時分秒的字串
    static func fullTimestamp(_ date: Date, calendar: Calendar, locale: Locale) -> String {
        BLFormatters.fullTimestamp(date, calendar: calendar, locale: locale)
    }

    /// 串接已選開團名稱，以頓號分隔並保留原名稱與順序
    ///
    /// - Parameter names: 草稿目前選取的開團名稱清單
    /// - Returns: 以頓號分隔的開團名稱字串
    /// - Note: 僅負責串接名稱，呼叫端需先處理空陣列情況
    static func campaignsDisplayText(_ names: [String]) -> String {
        names.joined(separator: "、")
    }

    /// 提供付款方式篩選觸發鈕的標題，未選取時顯示本地化的「全部」
    ///
    /// - Parameters:
    ///   - paymentMethod: 目前選取的付款方式；`nil` 代表全部
    ///   - locale: App 選定的 locale
    /// - Returns: 「付款方式：」加上付款方式原名，或本地化的「全部」
    static func paymentMethodFilterTitle(
        _ paymentMethod: String?,
        locale: Locale
    ) -> LocalizedStringKey {
        let language = AppLanguage(locale: locale)
        let current = paymentMethod ?? language.localized("common.action.label.all")
        return LocalizedStringKey(
            language.localizedString(forKey: "orders.filter.label.paymentMethodFormat", current)
        )
    }

    /// 提供商品類別篩選觸發鈕的標題，多選時顯示本地化項數
    ///
    /// - Parameters:
    ///   - categories: 目前選取的商品類別；空集合代表全部
    ///   - locale: App 選定的 locale
    /// - Returns: 「類別：」加上類別原名、項數或本地化的「全部」
    static func categoryFilterTitle(
        _ categories: Set<String>,
        locale: Locale
    ) -> LocalizedStringKey {
        let language = AppLanguage(locale: locale)
        if categories.count >= 2 {
            return LocalizedStringKey(
                language.localizedString(
                    forKey: "orders.filter.label.categoryCountFormat",
                    categories.count
                )
            )
        }
        let sortedCategories = categories.sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        }
        let current = sortedCategories.first ?? language.localized("common.action.label.all")
        return LocalizedStringKey(
            language.localizedString(forKey: "orders.filter.label.categoryFormat", current)
        )
    }

    /// 將訂單類別清單格式化為 tag 顯示文字，略過空白與空字串項目
    ///
    /// - Parameter categories: 訂單的類別清單
    /// - Returns: 以頓號連接的類別文字；沒有有效類別時為空字串
    static func categoriesTagText(for categories: [String]) -> String {
        categories
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "、")
    }
}
