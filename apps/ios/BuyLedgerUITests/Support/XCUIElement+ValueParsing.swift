//
//  XCUIElement+ValueParsing.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - Computed Properties

extension XCUIElement {

    /// 合併朗讀後承載的完整文字 (`label` 串接 `value`)
    var combinedText: String {
        let valueText = (value as? String) ?? ""
        return [label, valueText]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

// MARK: - Internal Method

extension XCUIElement {

    /// 判定合併文字是否含指定字串
    ///
    /// - Parameter text: 預期包含的文字
    /// - Returns: 是否包含指定文字
    func combinedTextContains(_ text: String) -> Bool {
        combinedText.contains(text)
    }

    /// 判定合併文字是否含指定幣別金額
    ///
    /// - Parameters:
    ///   - amount: 金額
    ///   - code: 幣別三碼代號
    ///   - locale: 格式化使用的 locale
    /// - Returns: 是否包含格式化後的金額
    func combinedTextContains(
        currency amount: Decimal,
        code: String,
        locale: Locale = .current
    ) -> Bool {
        combinedTextContains(
            ValueParsing.formatCurrency(amount, currencyCode: code, locale: locale)
        )
    }

    /// 判定合併文字是否含指定十進位數
    ///
    /// - Parameters:
    ///   - value: 數值
    ///   - fractionDigits: 固定小數位數
    ///   - locale: 格式化使用的 locale
    /// - Returns: 是否包含格式化後的十進位數值
    func combinedTextContains(
        decimal value: Decimal,
        fractionDigits: Int = 0,
        locale: Locale = .current
    ) -> Bool {
        combinedTextContains(
            ValueParsing.formatDecimal(value, fractionDigits: fractionDigits, locale: locale)
        )
    }

    /// 判定合併文字是否含指定百分比
    ///
    /// - Parameters:
    ///   - fraction: 0...1 的比例值
    ///   - fractionDigits: 固定小數位數
    ///   - locale: 格式化使用的 locale
    /// - Returns: 是否包含格式化後的百分比
    func combinedTextContains(
        percent fraction: Double,
        fractionDigits: Int = 0,
        locale: Locale = .current
    ) -> Bool {
        combinedTextContains(
            ValueParsing.formatPercent(fraction, fractionDigits: fractionDigits, locale: locale)
        )
    }

    /// 判定合併文字是否含指定日期
    ///
    /// - Parameters:
    ///   - date: 日期
    ///   - dateStyle: 日期樣式
    ///   - locale: 格式化使用的 locale
    ///   - timeZone: 格式化使用的時區
    /// - Returns: 是否包含格式化後的日期
    func combinedTextContains(
        date: Date,
        dateStyle: DateFormatter.Style = .medium,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> Bool {
        combinedTextContains(
            ValueParsing.formatShortDate(
                date,
                dateStyle: dateStyle,
                locale: locale,
                timeZone: timeZone
            )
        )
    }
}
