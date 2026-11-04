//
//  ValueParsing.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 依 locale 產生預期文字並比對朗讀元素的輔助型別
enum ValueParsing {}

// MARK: - Internal Method

extension ValueParsing {

    /// 依幣別格式化金額 (含貨幣符號與千分位)
    ///
    /// - Parameters:
    ///   - amount: 金額
    ///   - currencyCode: 幣別三碼代號
    ///   - locale: 格式化使用的 locale
    /// - Returns: 格式化後的金額字串
    static func formatCurrency(
        _ amount: Decimal,
        currencyCode: String,
        locale: Locale = .current
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale
        let number = NSDecimalNumber(decimal: amount)
        return formatter.string(from: number) ?? number.stringValue
    }

    /// 格式化十進位數 (含千分位)，用於無貨幣符號的金額或數量
    ///
    /// - Parameters:
    ///   - value: 數值
    ///   - fractionDigits: 固定小數位數
    ///   - locale: 格式化使用的 locale
    /// - Returns: 格式化後的十進位數字串
    static func formatDecimal(
        _ value: Decimal,
        fractionDigits: Int = 0,
        locale: Locale = .current
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        let number = NSDecimalNumber(decimal: value)
        return formatter.string(from: number) ?? number.stringValue
    }

    /// 把 0...1 的比例格式化為百分比字串 (0.42 得 42%)
    ///
    /// - Parameters:
    ///   - fraction: 0...1 的比例值
    ///   - fractionDigits: 固定小數位數
    ///   - locale: 格式化使用的 locale
    /// - Returns: 格式化後的百分比字串
    static func formatPercent(
        _ fraction: Double,
        fractionDigits: Int = 0,
        locale: Locale = .current
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = locale
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: fraction)) ?? "\(fraction)"
    }

    /// 格式化日期 (預設只到日、不含時間)
    ///
    /// - Parameters:
    ///   - date: 日期
    ///   - dateStyle: 日期樣式
    ///   - locale: 格式化使用的 locale
    ///   - timeZone: 格式化使用的時區
    /// - Returns: 格式化後的日期字串
    static func formatShortDate(
        _ date: Date,
        dateStyle: DateFormatter.Style = .medium,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = dateStyle
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
