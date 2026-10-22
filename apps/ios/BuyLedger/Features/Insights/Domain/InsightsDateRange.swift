//
//  InsightsDateRange.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation

/// 分析頁可選的趨勢期間
enum InsightsDateRange: String, CaseIterable, Sendable {

    /// 過去 30 天
    case thirtyDays

    /// 過去 6 個月
    case sixMonths

    /// 過去 12 個月
    case twelveMonths
}

// MARK: - Computed Properties

extension InsightsDateRange {

    /// 顯示在 segmented control 上的標題
    var title: String {
        switch self {
        case .thirtyDays:
            "insights.chart.label.thirtyDays"

        case .sixMonths:
            "insights.chart.label.sixMonths"

        case .twelveMonths:
            "dashboard.overview.label.twelveMonths"
        }
    }

    /// 趨勢卡片標題
    var trendCardTitle: String {
        switch self {
        case .thirtyDays:
            "insights.chart.label.thirtyDayNetProfit"

        case .sixMonths:
            "insights.chart.label.sixMonthNetProfit"

        case .twelveMonths:
            "insights.chart.label.twelveMonthNetProfit"
        }
    }
}

// MARK: - Identifiable

extension InsightsDateRange: Identifiable {

    /// 用 raw value 當識別值
    var id: String {
        rawValue
    }
}
