//
//  InsightsStats.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation

/// 分析頁的整體統計，依訂單、趨勢期間與基準時間計算
struct InsightsStats: Equatable {

    // MARK: - Properties

    /// 走勢圖每段期間的標籤與淨獲利，30 天逐日、6 與 12 個月逐月
    let trendBuckets: [InsightsTrendBucket]

    /// 期間內淨獲利總和
    let totalProfit: Decimal

    /// 本期相對上期的比值，即本期減上期後除以上期絕對值；`nil` 表示沒有比較值
    let trendRatio: Decimal?

    /// 各分類獲利排行 (由高到低)
    let categories: [InsightsCategory]

    /// 成本結構各區塊，金額為零的區塊不列入
    let costSegments: [InsightsCostSegment]

    /// 全期成本總和
    let totalCost: Decimal

    // MARK: - Init

    /// 依訂單清單、趨勢期間與基準時間計算分析頁統計
    ///
    /// - Parameters:
    ///   - orders: 目前訂單清單
    ///   - range: 趨勢期間
    ///   - referenceDate: 基準「現在」時間，決定走勢區間與上期對照範圍
    ///   - calendar: 用來分組走勢與計算期間的曆法
    init(
        orders: [LedgerOrder],
        range: InsightsDateRange,
        referenceDate: Date,
        calendar: Calendar
    ) {
        let attributedOrders = LedgerOrder.revenueAttributionOrders(from: orders)
        let trendBuckets = InsightsStats.makeTrendBuckets(
            attributedOrders: attributedOrders,
            range: range,
            calendar: calendar,
            now: referenceDate
        )
        let totalProfit = trendBuckets.map(\.profit).reduce(Decimal.zero, +)
        let priorPeriodProfit = InsightsStats.previousPeriodProfit(
            attributedOrders: attributedOrders,
            range: range,
            calendar: calendar,
            now: referenceDate
        )
        let totalItem = attributedOrders.map(\.itemCost).reduce(Decimal.zero, +)
        let totalDom = attributedOrders.map(\.domesticShipping).reduce(Decimal.zero, +)
        let totalIntl = attributedOrders.map(\.internationalShipping).reduce(Decimal.zero, +)
        let totalFees = attributedOrders.map(\.summary.fees).reduce(Decimal.zero, +)

        self.trendBuckets = trendBuckets
        self.totalProfit = totalProfit
        self.trendRatio = InsightsStats.comparisonRatio(
            current: totalProfit,
            previous: priorPeriodProfit
        )
        self.categories = InsightsStats.categoryBreakdown(orders: orders)
        self.costSegments = [
            InsightsCostSegment(
                label: "orders.detail.label.itemCost",
                value: totalItem,
                tone: .accent
            ),
            InsightsCostSegment(
                label: "orders.detail.label.localShipping",
                value: totalDom,
                tone: .teal
            ),
            InsightsCostSegment(
                label: "orders.detail.label.internationalShipping",
                value: totalIntl,
                tone: .purple
            ),
            InsightsCostSegment(label: "orders.detail.label.fees", value: totalFees, tone: .orange),
        ]
            .filter { $0.value > 0 }
        self.totalCost = attributedOrders.map(\.summary.totalCost).reduce(Decimal.zero, +)
    }
}

// MARK: - Internal Method

extension InsightsStats {

    /// 依合併前收益計算各類別獲利與相對第一名的比例
    ///
    /// - Parameter orders: 全部訂單
    /// - Returns: 各類別獲利排行，比例以第一名獲利為分母並夾在 0 到 1 之間
    static func categoryBreakdown(orders: [LedgerOrder]) -> [InsightsCategory] {
        var profitByName: [String: Decimal] = [:]
        for order in orders.filter(\.contributesToCategoryBreakdown) {
            let profit = order.summary.profit
            for category in order.categories {
                let name = category.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty {
                    profitByName[name, default: 0] += profit
                }
            }
        }

        let ranked = profitByName
            .map { (name: $0.key, profit: $0.value) }
            .sorted { lhs, rhs in lhs.profit > rhs.profit }
        let topProfit = NSDecimalNumber(decimal: ranked.first?.profit ?? 0).doubleValue
        return ranked.map {
            InsightsCategory(
                name: $0.name,
                profit: $0.profit,
                ratio: InsightsStats.categoryRatio(profit: $0.profit, topProfit: topProfit)
            )
        }
    }

    /// 計算各開團毛利排行與相對比例
    ///
    /// - Parameters:
    ///   - campaigns: 目前所有開團
    ///   - orders: 目前所有訂單；用於以 ``CampaignSummary`` 彙總各團毛利
    /// - Returns: 已排序並附上名次與比例的排行資料；無可排行開團時為空陣列
    static func campaignProfitRanking(
        campaigns: [Campaign],
        orders: [LedgerOrder]
    ) -> [CampaignProfitRank] {
        // 單次掃描訂單，批次建立各團投影
        let summaries = CampaignSummary.batch(campaignNames: campaigns.map(\.name), orders: orders)
        let ranked = campaigns
            .map { campaign in
                let summary = summaries[campaign.name]
                    ?? CampaignSummary(campaignName: campaign.name, orders: [])
                return (campaign: campaign, summary: summary)
            }
            .filter { $0.summary.orderCount > 0 }
            .sorted { lhs, rhs in lhs.summary.profit > rhs.summary.profit }
        let topProfit = max(
            NSDecimalNumber(decimal: ranked.first?.summary.profit ?? 1).doubleValue,
            1
        )
        return ranked.enumerated().map { index, item in
            CampaignProfitRank(
                id: item.campaign.id,
                rank: index + 1,
                campaignName: item.campaign.name,
                profit: item.summary.profit,
                ratio: NSDecimalNumber(decimal: item.summary.profit).doubleValue / topProfit
            )
        }
    }
}

// MARK: - Private Method

private extension InsightsStats {

    /// 把類別獲利換算為相對第一名類別獲利的比例
    ///
    /// - Parameters:
    ///   - profit: 該類別的累計獲利
    ///   - topProfit: 第一名類別的累計獲利；非正數時無法作為分母
    /// - Returns: 0 到 1 之間的比例，分母不為正時為 0
    static func categoryRatio(profit: Decimal, topProfit: Double) -> Double {
        guard topProfit > 0 else {
            return 0
        }
        let ratio = NSDecimalNumber(decimal: profit).doubleValue / topProfit
        return min(max(ratio, 0), 1)
    }
}
