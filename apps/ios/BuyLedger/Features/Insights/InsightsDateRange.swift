//
//  InsightsDateRange.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation

/// 分析頁可選的趨勢期間
enum InsightsDateRange: String, CaseIterable, Identifiable, Sendable {

    // MARK: - Cases

    /// 過去 30 天
    case thirtyDays

    /// 過去 6 個月
    case sixMonths

    /// 過去 12 個月
    case twelveMonths

    // MARK: - Identifiable Properties

    /// 區間穩定識別
    var id: String { rawValue }

    // MARK: - Display Properties

    /// 顯示在 segmented control 上的標題
    var title: String {
        switch self {
        case .thirtyDays:
            "30 天"
        case .sixMonths:
            "6 個月"
        case .twelveMonths:
            "12 個月"
        }
    }

    /// 顯示在 trend card 上的子標題
    var trendCardTitle: String {
        switch self {
        case .thirtyDays:
            "30 天淨獲利"
        case .sixMonths:
            "6 個月淨獲利"
        case .twelveMonths:
            "12 個月淨獲利"
        }
    }
}
