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
