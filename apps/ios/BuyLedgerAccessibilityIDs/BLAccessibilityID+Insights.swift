//
//  BLAccessibilityID+Insights.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

// MARK: - Nested Types

extension BLAccessibilityID {

    /// 分析頁
    enum Insights {

        /// 分析頁的根 accessibility identifier
        static let root = "insights.root"

        /// 分析頁無資料狀態容器
        static let emptyState = "insights.emptyState"

        /// 分析頁期間選擇器
        static let rangePicker = "insights.rangePicker"

        /// 趨勢圖表
        static let trendChart = "insights.chart.trend"

        /// 趨勢卡總獲利數值
        static let trendTotalProfit = "insights.trend.totalProfit"

        /// 成本圓餅圖
        static let costDonut = "insights.chart.costDonut"

        /// 期間選項，key 取 ``InsightsDateRange`` 的 `rawValue`
        ///
        /// - Parameter rangeID: 分析期間識別值
        /// - Returns: 對應期間選項的 accessibility identifier
        static func rangeSegment(_ rangeID: String) -> String {
            option("insights.rangeSegment", key: rangeID)
        }

        /// 類別排行列，key 取類別名 (點擊深連結到訂單)
        ///
        /// - Parameter category: 類別名稱
        /// - Returns: 對應類別排行列的 accessibility identifier
        static func categoryRankRow(category: String) -> String {
            BLAccessibilityID.row("insights.categoryRank.row", key: category)
        }

        /// 每團毛利排行列，key 取開團識別值 (點擊深連結到開團詳情)
        ///
        /// - Parameter campaignID: 開團識別值
        /// - Returns: 對應開團排行列的 accessibility identifier
        static func campaignRankRow(campaignID: String) -> String {
            BLAccessibilityID.row("insights.campaignRank.row", key: campaignID)
        }
    }
}
