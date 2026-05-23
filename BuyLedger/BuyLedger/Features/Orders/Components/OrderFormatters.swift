//
//  OrderFormatters.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 訂單畫面使用的格式化工具。
enum OrderFormatters {
    
    // MARK: - Format Method
    
    /// 將新台幣金額格式化為無小數位字串。
    /// - Parameter amount: 要格式化的金額。
    /// - Returns: 使用台灣地區格式的金額字串。
    static func twd(_ amount: Decimal) -> String {
        amount.formatted(
            .currency(code: CurrencyCode.twd.code)
            .precision(.fractionLength(0))
            .locale(Locale(identifier: "zh_TW"))
        )
    }
    
    /// 將原始幣別金額格式化為無小數位字串。
    /// - Parameters:
    ///   - amount: 要格式化的金額。
    ///   - currency: 金額所屬幣別。
    /// - Returns: 包含幣別符號的金額字串。
    static func currency(_ amount: Decimal, currency: CurrencyCode) -> String {
        amount.formatted(
            .currency(code: currency.code)
            .precision(.fractionLength(0))
            .locale(Locale(identifier: "zh_TW"))
        )
    }
    
    /// 將比例格式化為百分比。
    /// - Parameter value: `0` 到 `1` 之間的比例。
    /// - Returns: 百分比字串。
    static func percent(_ value: Decimal) -> String {
        value.formatted(.percent.precision(.fractionLength(1)))
    }
    
    /// 將日期格式化為列表使用的短日期。
    /// - Parameter date: 要格式化的日期。
    /// - Returns: 月日格式字串。
    static func shortDate(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .month(.defaultDigits)
                .day(.defaultDigits)
                .locale(Locale(identifier: "zh_TW"))
        )
    }

    /// 將日期格式化為 `yyyy/MM/dd HH:mm`。
    ///
    /// 採固定 pattern + `en_US_POSIX` locale，確保跨地區設定皆輸出一致的格式（不被 24/12 小時或分隔符差異影響）。秒精度對使用者沒有意義（`DatePicker(.compact)` 也不支援編輯到秒），故省略。
    /// - Parameter date: 要格式化的日期。
    /// - Returns: 包含年月日與時分的字串。
    static func minuteTimestamp(_ date: Date) -> String {
        minuteTimestampFormatter.string(from: date)
    }

    // MARK: - Static Properties

    /// 用於 ``minuteTimestamp(_:)`` 的固定格式 formatter。
    private static let minuteTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
