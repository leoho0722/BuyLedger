//
//  InsightsStats.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation
import SwiftUI

/// 分析頁的整體統計
struct InsightsStats {
    
    // MARK: - Data Properties
    
    /// 走勢圖 (依 range 動態：30 天用「日」、6/12 個月用「月」)
    let trendBars: [BLBarChartValue]
    
    /// 期間內淨獲利總和
    let totalProfit: Decimal
    
    /// 走勢卡顯示的成長率文字
    let trendDelta: String
    
    /// 成長率方向；`nil` 表示沒有比較值
    let trendDeltaIsPositive: Bool?
    
    /// 各分類獲利排行 (由高到低)
    let categories: [InsightsCategory]
    
    /// 成本結構各區塊
    let costSegments: [InsightsCostSegment]
    
    /// 全期成本總和
    let totalCost: Decimal
    
    // MARK: - Static Properties
    
    /// 熱力圖顯示的週數
    static let heatmapWeekCount = 8
    
    // MARK: - Init
    
    /// 依訂單清單、趨勢期間與基準時間計算分析頁統計
    /// - Parameters:
    ///   - orders: 目前訂單清單
    ///   - range: 趨勢期間
    ///   - referenceDate: 基準「現在」時間，決定走勢區間與上期對照範圍
    ///   - calendar: 用來分組走勢與計算期間的曆法
    ///   - locale: App 選定、用於趨勢百分比呈現的 locale
    ///   - palette: 目前外觀使用的色盤，供成本結構區塊上色
    init(
        orders: [LedgerOrder],
        range: InsightsDateRange,
        referenceDate: Date,
        calendar: Calendar,
        locale: Locale,
        palette: BLPalette
    ) {
        let attributedOrders = LedgerOrder.revenueAttributionOrders(from: orders)
        let trendBuckets = InsightsStats.trendBuckets(
            attributedOrders: attributedOrders,
            range: range,
            calendar: calendar,
            now: referenceDate,
            locale: locale
        )
        
        let totalProfit = trendBuckets.reduce(Decimal.zero) { $0 + $1.profit }
        let priorPeriodProfit = InsightsStats.previousPeriodProfit(
            attributedOrders: attributedOrders,
            range: range,
            calendar: calendar,
            now: referenceDate
        )
        
        let totalCost = attributedOrders.reduce(Decimal.zero) { $0 + $1.summary.totalCost }
        let totalItem = attributedOrders.reduce(Decimal.zero) { $0 + $1.itemCost }
        let totalDom = attributedOrders.reduce(Decimal.zero) { $0 + $1.domesticShipping }
        let totalIntl = attributedOrders.reduce(Decimal.zero) { $0 + $1.internationalShipping }
        let totalFees = attributedOrders.reduce(Decimal.zero) { $0 + $1.summary.fees }
        
        let trendDelta = InsightsStats.trendDelta(
            current: totalProfit,
            previous: priorPeriodProfit,
            locale: locale
        )
        
        self.trendBars = trendBuckets.map(\.bar)
        self.totalProfit = totalProfit
        self.trendDelta = trendDelta.text
        self.trendDeltaIsPositive = trendDelta.isPositive
        self.categories = InsightsStats.categoryBreakdown(orders: orders)
        self.costSegments = [
            InsightsCostSegment(label: "商品金額", value: totalItem, color: palette.accent),
            InsightsCostSegment(label: "國內運費", value: totalDom, color: palette.teal),
            InsightsCostSegment(label: "國際運費", value: totalIntl, color: palette.purple),
            InsightsCostSegment(label: "手續費", value: totalFees, color: palette.orange),
        ].filter { $0.value > 0 }
        self.totalCost = totalCost
    }
}

// MARK: - Nested Types

private extension InsightsStats {
    
    /// 走勢圖單一期間的顯示值與精確獲利值
    struct TrendBucket {
        
        // MARK: - Data Properties
        
        /// 提供圖表顯示的值
        let bar: BLBarChartValue
        
        /// 用於精確彙總的 Decimal 獲利
        let profit: Decimal
    }
}

// MARK: - Internal Method

extension InsightsStats {
    
    /// 依合併前收益計算各類別獲利
    /// - Parameter orders: 全部訂單
    /// - Returns: 各類別獲利排行
    static func categoryBreakdown(orders: [LedgerOrder]) -> [InsightsCategory] {
        let attributionOrders = orders.filter(\.contributesToCategoryBreakdown)
        let categoryPairs = attributionOrders.flatMap { order in
            order.categories
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { ($0, order) }
        }
        
        return Dictionary(grouping: categoryPairs, by: \.0)
            .map { name, pairs in
                InsightsCategory(
                    name: name,
                    profit: pairs.reduce(Decimal.zero) { $0 + $1.1.summary.profit }
                )
            }
            .sorted { $0.profit > $1.profit }
    }
    
    /// 計算各開團毛利排行與相對比例
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
            .map { ($0, summaries[$0.name] ?? CampaignSummary(campaignName: $0.name, orders: [])) }
            .filter { $0.1.orderCount > 0 }
            .sorted { $0.1.profit > $1.1.profit }
        let topProfit = max(NSDecimalNumber(decimal: ranked.first?.1.profit ?? 1).doubleValue, 1)
        return ranked.enumerated().map { index, item in
            CampaignProfitRank(
                id: item.0.id,
                rank: index + 1,
                campaignName: item.0.name,
                profit: item.1.profit,
                ratio: NSDecimalNumber(decimal: item.1.profit).doubleValue / topProfit
            )
        }
    }
    
    /// 計算過去 N 週每天的下單筆數
    /// - Parameters:
    ///   - orders: 目前訂單清單
    ///   - referenceDate: 基準「現在」時間，決定「本週」的位置
    ///   - calendar: 計算週界的行事曆；熱力圖固定週一為每週起點
    /// - Returns: 鍵為 `HeatmapKey`、值為訂單筆數
    static func computeHeatmap(
        orders: [LedgerOrder],
        referenceDate: Date,
        calendar: Calendar
    ) -> [HeatmapKey: Int]  {
        var calendar = calendar
        // 熱力圖以週一為每週起點，分組也使用週一。
        calendar.firstWeekday = 2
        let now = referenceDate
        let weekCount = InsightsStats.heatmapWeekCount
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return [:]
        }
        
        var result: [HeatmapKey: Int] = [:]
        
        for order in orders {
            // 依週起點差距計算欄位，避免跨週誤差
            guard let orderWeekStart = calendar.dateInterval(of: .weekOfYear, for: order.date)?.start else {
                continue
            }
            let daysBetween = calendar.dateComponents(
                [.day],
                from: orderWeekStart,
                to: currentWeekStart
            ).day ?? 0
            let weeksAgo = daysBetween / 7
            let weekIndex = (weekCount - 1) - weeksAgo
            
            guard weekIndex >= 0, weekIndex < weekCount else {
                continue
            }
            
            // weekday: 1=週日 ... 7=週六；轉成 0=週一 ... 6=週日
            let raw = calendar.component(.weekday, from: order.date)
            let weekday = (raw + 5) % 7
            
            let key = HeatmapKey(week: weekIndex, weekday: weekday)
            result[key, default: 0] += 1
        }
        
        return result
    }
}

// MARK: - Private Method

private extension InsightsStats {
    
    /// 計算上一個等長期間的淨獲利
    /// - Parameters:
    ///   - attributedOrders: 依營收歸屬口徑計入的訂單
    ///   - range: 趨勢期間
    ///   - calendar: 用來算日期的曆法
    ///   - now: 目前期間的結束基準
    /// - Returns: 對等期間的累計獲利；無對等資料時為 `nil`
    static func previousPeriodProfit(
        attributedOrders: [LedgerOrder],
        range: InsightsDateRange,
        calendar: Calendar,
        now: Date
    ) -> Decimal? {
        let component: Calendar.Component
        let length: Int
        
        switch range {
        case .thirtyDays:
            component = .day
            length = 30
        case .sixMonths:
            component = .month
            length = 6
        case .twelveMonths:
            component = .month
            length = 12
        }
        
        guard let priorEnd = calendar.date(byAdding: component, value: -length, to: now),
              let priorStart = calendar.date(byAdding: component, value: -length, to: priorEnd) else {
            return nil
        }
        
        let total = attributedOrders
            .filter { (priorStart..<priorEnd).contains($0.date) }
            .reduce(Decimal.zero) { $0 + $1.summary.profit }
        
        // 沒有任何訂單落在前一同期 → 視為「無資料可比」
        guard total != 0 else {
            return nil
        }
        return total
    }
    
    /// 根據本期/上期累計獲利產生趨勢文字與方向旗標
    /// - Parameters:
    ///   - current: 本期累計
    ///   - previous: 上期累計；`nil` 代表無資料可比
    ///   - locale: App 選定、用於百分比呈現的 locale
    /// - Returns: trend card 右上角字串與方向旗標
    static func trendDelta(
        current: Decimal,
        previous: Decimal?,
        locale: Locale
    ) -> (text: String, isPositive: Bool?) {
        guard let previous, previous != 0 else {
            return ("— 無對照", nil)
        }
        let isPositive = current >= previous
        let ratio = (current - previous) / abs(previous)
        let arrow = isPositive ? "↑" : "↓"
        let formatted = BLFormatters.percent(abs(ratio), locale: locale)
        return ("\(arrow) \(formatted)", isPositive)
    }
    
    /// 依 range 產生對應的 bar chart 資料：30 天逐日、6/12 個月逐月
    /// - Parameters:
    ///   - attributedOrders: 依營收歸屬口徑計入的訂單
    ///   - range: 趨勢期間
    ///   - calendar: 用來分組的曆法
    ///   - now: 基準日
    ///   - locale: App 選定、用於無障礙數值描述的 locale
    /// - Returns: 對應每段時間的累計獲利
    static func trendBuckets(
        attributedOrders: [LedgerOrder],
        range: InsightsDateRange,
        calendar: Calendar,
        now: Date,
        locale: Locale
    ) -> [TrendBucket] {
        switch range {
        case .thirtyDays:
            return (0..<30)
                .reversed()
                .compactMap { offset -> TrendBucket? in
                    guard let dayStart = calendar.date(byAdding: .day, value: -offset, to: now),
                          let interval = calendar.dateInterval(of: .day, for: dayStart) else {
                        return nil
                    }

                    let dayProfit = attributedOrders
                        .filter { (interval.start..<interval.end).contains($0.date) }
                        .reduce(Decimal.zero) { $0 + $1.summary.profit }

                    // 30 天逐日標籤格式：MM/dd (verbatim，不受 locale 影響)
                    let label = dayStart.formatted(
                        .verbatim(
                            "\(month: .twoDigits)/\(day: .twoDigits)",
                            timeZone: calendar.timeZone,
                            calendar: calendar
                        )
                    )

                    return TrendBucket(
                        bar: BLBarChartValue(
                            label: label,
                            value: NSDecimalNumber(decimal: dayProfit).doubleValue,
                            valueDescription: BLFormatters.twd(dayProfit, locale: locale)
                        ),
                        profit: dayProfit
                    )
                }
            
        case .sixMonths, .twelveMonths:
            let monthCount = range == .sixMonths ? 6 : 12
            
            return (0..<monthCount)
                .reversed()
                .compactMap { offset -> TrendBucket? in
                    guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: now),
                          let interval = calendar.dateInterval(of: .month, for: monthStart) else {
                        return nil
                    }

                    let monthProfit = attributedOrders
                        .filter { (interval.start..<interval.end).contains($0.date) }
                        .reduce(Decimal.zero) { $0 + $1.summary.profit }

                    // 6 個月用 YYYY/MM；12 個月空間較窄，改用 YY/MM (皆為 verbatim 精確格式)
                    let sixMonthFormat: Date.FormatString = "\(year: .padded(4))/\(month: .twoDigits)"
                    let twelveMonthFormat: Date.FormatString = "\(year: .twoDigits)/\(month: .twoDigits)"
                    let monthFormat: Date.FormatString = range == .sixMonths ? sixMonthFormat : twelveMonthFormat
                    let label = monthStart.formatted(
                        .verbatim(monthFormat, timeZone: calendar.timeZone, calendar: calendar)
                    )

                    return TrendBucket(
                        bar: BLBarChartValue(
                            label: label,
                            value: NSDecimalNumber(decimal: monthProfit).doubleValue,
                            valueDescription: BLFormatters.twd(monthProfit, locale: locale)
                        ),
                        profit: monthProfit
                    )
                }
        }
    }
}

/// 類別排行資料
struct InsightsCategory: Identifiable {
    
    // MARK: - Identifiable Properties
    
    /// 用 name 當識別值
    var id: String { name }
    
    // MARK: - Data Properties
    
    /// 類別名稱
    let name: String
    
    /// 該類別累計獲利
    let profit: Decimal
}

/// 成本結構單一區塊
struct InsightsCostSegment: Identifiable {
    
    // MARK: - Identifiable Properties
    
    /// 用 label 當識別值
    var id: String { label }
    
    // MARK: - Data Properties
    
    /// 顯示在 legend 的標籤
    let label: String
    
    /// 此區塊金額
    let value: Decimal
    
    /// 顯示色彩
    let color: Color
}

/// 熱力圖鍵
struct HeatmapKey: Hashable {
    
    // MARK: - Data Properties
    
    /// 第幾週 (0 為最早、7 為本週)
    let week: Int
    
    /// 第幾天 (0 為週一、6 為週日)
    let weekday: Int
}

/// 每團毛利排行的單列資料
struct CampaignProfitRank: Identifiable {
    
    // MARK: - Identifiable Properties
    
    /// 對應開團的識別值
    let id: Campaign.ID
    
    // MARK: - Data Properties
    
    /// 名次 (由 1 起算，依毛利由高到低)
    let rank: Int
    
    /// 開團名稱
    let campaignName: String
    
    /// 該團毛利
    let profit: Decimal
    
    /// 相對於最高毛利團的比例 (0...1)，供進度條呈現
    let ratio: Double
}
