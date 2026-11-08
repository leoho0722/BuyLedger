//
//  QuoteFormatters.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

/// 報價試算畫面使用的計算與格式化規則
enum QuoteFormatters {}

// MARK: - Internal Method

extension QuoteFormatters {

    /// 提供目標毛利上限提示，百分比依 App 語言格式化
    ///
    /// - Parameter locale: App 選定、用於百分比呈現的 locale
    /// - Returns: 依 App 語言呈現的目標毛利提示
    static func targetMarginLimitMessage(locale: Locale) -> LocalizedStringResource {
        let targetMargin = 1.0.formatted(.percentUpToOneFractionDigit(locale: locale))

        return LocalizedStringResource(
            "quote.calculator.message.targetMarginLimitNotice",
            defaultValue: "\(targetMargin)"
        )
    }

    /// 計算成本拆解項目占總成本的比例，總成本不足一時以一計算
    ///
    /// - Parameters:
    ///   - value: 拆解項目金額
    ///   - costTWD: 總成本 TWD
    /// - Returns: 項目占總成本的比例
    static func costShare(of value: Decimal, costTWD: Decimal) -> Double {
        let total = max(costTWD, 1)
        return NSDecimalNumber(decimal: value / total).doubleValue
    }
}
