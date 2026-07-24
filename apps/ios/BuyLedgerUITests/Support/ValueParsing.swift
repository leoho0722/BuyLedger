//
//  ValueParsing.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 以當次 locale 產生金額／百分比／日期的預期字串，並比對合併朗讀元素的文字
///
/// 中英模式的千分位、小數點與日期格式不同，一律用 `NumberFormatter`／`DateFormatter` 產生預期值，
/// 不在測試裡寫死字面值；locale 由呼叫端傳入 (預設 `.current`)、與啟動的 App 語言對齊
enum ValueParsing {}

// MARK: - Internal Method

extension ValueParsing {

    /// 依幣別格式化金額 (含貨幣符號與千分位)
    /// - Parameters:
    ///   - amount: 金額
    ///   - currencyCode: 幣別三碼代號 (如 `TWD`)
    ///   - locale: 格式化 locale
    /// - Returns: 格式化後字串
    static func formatCurrency(_ amount: Decimal, currencyCode: String, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale
        let number = NSDecimalNumber(decimal: amount)
        return formatter.string(from: number) ?? number.stringValue
    }

    /// 格式化十進位數 (含千分位)，用於無貨幣符號的金額或數量
    /// - Parameters:
    ///   - value: 數值
    ///   - fractionDigits: 固定小數位數
    ///   - locale: 格式化 locale
    /// - Returns: 格式化後字串
    static func formatDecimal(_ value: Decimal, fractionDigits: Int = 0, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        let number = NSDecimalNumber(decimal: value)
        return formatter.string(from: number) ?? number.stringValue
    }

    /// 把 0...1 的比例格式化為百分比字串 (0.42 得 42%)
    /// - Parameters:
    ///   - fraction: 0...1 的比例值
    ///   - fractionDigits: 固定小數位數
    ///   - locale: 格式化 locale
    /// - Returns: 格式化後字串
    static func formatPercent(_ fraction: Double, fractionDigits: Int = 0, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = locale
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: fraction)) ?? "\(fraction)"
    }

    /// 格式化日期 (預設只到日、不含時間)
    /// - Parameters:
    ///   - date: 日期
    ///   - dateStyle: 日期樣式
    ///   - locale: 格式化 locale
    ///   - timeZone: 時區，固定傳入避免跨機器差異
    /// - Returns: 格式化後字串
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

// MARK: - Display Properties

extension XCUIElement {

    /// 合併朗讀後承載的完整文字 (label 串接 value)
    ///
    /// `accessibilityElement(children: .combine)` 的列會把子元素文字併進 `label`，
    /// 主要數值有時另放在 `value`，兩者一起串成長字串才不漏比對
    var combinedText: String {
        let valueText = (value as? String) ?? ""
        return [label, valueText]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

// MARK: - Internal Method

extension XCUIElement {

    /// 合併文字是否含指定字串
    /// - Parameter text: 預期包含的文字
    /// - Returns: 是否包含
    func combinedTextContains(_ text: String) -> Bool {
        combinedText.contains(text)
    }

    /// 合併文字是否含指定幣別金額
    /// - Parameters:
    ///   - amount: 金額
    ///   - code: 幣別三碼代號
    ///   - locale: 格式化 locale
    /// - Returns: 是否包含
    func combinedTextContains(currency amount: Decimal, code: String, locale: Locale = .current) -> Bool {
        combinedTextContains(ValueParsing.formatCurrency(amount, currencyCode: code, locale: locale))
    }

    /// 合併文字是否含指定十進位數
    /// - Parameters:
    ///   - value: 數值
    ///   - fractionDigits: 固定小數位數
    ///   - locale: 格式化 locale
    /// - Returns: 是否包含
    func combinedTextContains(decimal value: Decimal, fractionDigits: Int = 0, locale: Locale = .current) -> Bool {
        combinedTextContains(ValueParsing.formatDecimal(value, fractionDigits: fractionDigits, locale: locale))
    }

    /// 合併文字是否含指定百分比
    /// - Parameters:
    ///   - fraction: 0...1 的比例值
    ///   - fractionDigits: 固定小數位數
    ///   - locale: 格式化 locale
    /// - Returns: 是否包含
    func combinedTextContains(percent fraction: Double, fractionDigits: Int = 0, locale: Locale = .current) -> Bool {
        combinedTextContains(ValueParsing.formatPercent(fraction, fractionDigits: fractionDigits, locale: locale))
    }

    /// 合併文字是否含指定日期
    /// - Parameters:
    ///   - date: 日期
    ///   - dateStyle: 日期樣式
    ///   - locale: 格式化 locale
    ///   - timeZone: 時區
    /// - Returns: 是否包含
    func combinedTextContains(
        date: Date,
        dateStyle: DateFormatter.Style = .medium,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> Bool {
        combinedTextContains(
            ValueParsing.formatShortDate(date, dateStyle: dateStyle, locale: locale, timeZone: timeZone)
        )
    }
}
