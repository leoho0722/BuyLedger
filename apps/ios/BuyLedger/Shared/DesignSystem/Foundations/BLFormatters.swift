//
//  BLFormatters.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/30.
//

import Foundation

/// 金額與百分比呈現規則的唯一入口
enum BLFormatters {}

// MARK: - Internal Method

extension BLFormatters {
    
    /// 依指定 locale 將金額格式化為新台幣 (無小數位)
    /// - Parameters:
    ///   - amount: 金額
    ///   - locale: 用於呈現的 locale
    /// - Returns: 含 NT$ 前綴的字串
    static func twd(_ amount: Decimal, locale: Locale) -> String {
        amount.formatted(
            .currency(code: CurrencyCode.twd.code)
            .precision(.fractionLength(0))
            .locale(locale)
        )
    }
    
    /// 依指定 locale 將金額格式化為新台幣；`nil` 顯示為「—」
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
    
    /// 依指定 locale 將比例格式化為百分比
    /// - Parameters:
    ///   - ratio: 0 到 1 的比例，例如 0.654 表示 65.4%
    ///   - locale: 用於呈現的 locale
    /// - Returns: 含一位小數的百分比字串
    static func percent(_ ratio: Decimal, locale: Locale) -> String {
        ratio.formatted(.percent.precision(.fractionLength(1)).locale(locale))
    }
    
    /// 依指定 locale 將已是百分比尺度的數值格式化為百分比字串
    /// - Parameters:
    ///   - value: 百分比數值，例如 65.4 表示 65.4%
    ///   - locale: 用於呈現的 locale
    /// - Returns: 含一位小數的百分比字串
    static func percent(scaled value: Decimal, locale: Locale) -> String {
        value.formatted(.number.precision(.fractionLength(1)).locale(locale)) + "%"
    }
}
