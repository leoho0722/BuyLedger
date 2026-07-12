//
//  InsightsStats.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation
import SwiftUI

/// 分析頁的整體統計
///
/// 完全 derive 自訂單清單，不依賴「現在」時間內部讀取：由呼叫端 (View 或測試) 以 `referenceDate` 與 `calendar` 注入基準時間；`palette` 僅供成本結構區塊上色，不含環境相依計算
struct InsightsStats {

    // MARK: - Data Properties

    /// 走勢圖 (依 range 動態：30 天用「日」、6/12 個月用「月」)
    let trendBars: [BLBarChartValue]

    /// 期間內淨獲利總和
    let totalProfit: Decimal

    /// 顯示在走勢卡右上角的成長率字樣 (已 format，例如 `↑ 12.3%`、`— 無對照`)
    let trendDelta: String

    /// 成長率方向旗標：`true` 上升、`false` 下降、`nil` 無對照可比；用來決定走勢卡的字色
    let trendDeltaIsPositive: Bool?

    /// 各分類獲利排行 (由高到低)
    let categories: [InsightsCategory]

    /// 成本結構各區塊
    let costSegments: [InsightsCostSegment]

    /// 全期成本總和
    let totalCost: Decimal

    // MARK: - Static Properties

    /// 視為「已實現」的訂單狀態集合，引用 domain 層的單一事實來源
    static let realizedStatuses = OrderStatus.realizedStatuses

    /// 熱力圖顯示的週數；同時驅動 ``computeHeatmap(orders:referenceDate:calendar:)`` 的回填邏輯與 View 端的 grid 欄位
    static let heatmapWeekCount = 8

    // MARK: - Init

    /// 依訂單清單、趨勢期間與基準時間計算分析頁統計
    /// - Parameters:
    ///   - orders: 目前訂單清單
    ///   - range: 趨勢期間
    ///   - referenceDate: 基準「現在」時間，決定走勢區間與上期對照範圍
    ///   - calendar: 用來分組走勢與計算期間的曆法
    ///   - palette: 目前外觀使用的色盤，供成本結構區塊上色
    init(
        orders: [LedgerOrder],
        range: InsightsDateRange,
        referenceDate: Date,
        calendar: Calendar,
        palette: BLPalette
    ) {
        let realized = orders.filter { InsightsStats.realizedStatuses.contains($0.status) }
        let trendBars = InsightsStats.trendBars(realized: realized, range: range, calendar: calendar, now: referenceDate)

        let totalProfit = trendBars.reduce(Decimal(0)) { $0 + Decimal($1.value) }
        let priorPeriodProfit = InsightsStats.previousPeriodProfit(
            realized: realized,
            range: range,
            calendar: calendar,
            now: referenceDate
        )

        let totalCost = realized.reduce(Decimal.zero) { $0 + $1.summary.totalCost }
        let totalItem = realized.reduce(Decimal.zero) { $0 + $1.itemCost }
        let totalDom = realized.reduce(Decimal.zero) { $0 + $1.domesticShipping }
        let totalIntl = realized.reduce(Decimal.zero) { $0 + $1.internationalShipping }
        let totalFees = realized.reduce(Decimal.zero) { $0 + $1.summary.fees }

        self.trendBars = trendBars
        self.totalProfit = totalProfit
        self.trendDelta = InsightsStats.trendDeltaText(current: totalProfit, previous: priorPeriodProfit)
        self.trendDeltaIsPositive = InsightsStats.trendDeltaDirection(current: totalProfit, previous: priorPeriodProfit)
        self.categories = InsightsStats.categoryBreakdown(orders: orders)
        self.costSegments = [
            InsightsCostSegment(label: "商品金額", value: totalItem, color: palette.accent),
            InsightsCostSegment(label: "國內運費", value: totalDom, color: palette.teal),
            InsightsCostSegment(label: "國際運費", value: totalIntl, color: palette.purple),
            InsightsCostSegment(label: "手續費", value: totalFees, color: palette.orange),
        ].filter { $0.value > 0 }
        self.totalCost = totalCost
    }

    // MARK: - Static Method

    /// 依「合併前收益」歸屬規則彙總各類別獲利 (由高到低)；供 ``init(orders:range:referenceDate:calendar:palette:)`` 與單元測試共用
    ///
    /// 僅葉端訂單入組 (``LedgerOrder/contributesToCategoryBreakdown``)：狀態屬已實現或已合併、且非由合併產生；合併產生的訂單不入組，其收益由合併前舊單以原始類別與金額入帳。一筆訂單的獲利全額計入它的每一個類別；類別為空的訂單不歸入任何卡片
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

    /// 計算每團毛利排行：排除無歸屬訂單的團，依毛利由高到低排序，並附上相對最高毛利的比例
    /// - Parameters:
    ///   - campaigns: 目前所有開團
    ///   - orders: 目前所有訂單；用於以 ``CampaignSummary`` 彙總各團毛利
    /// - Returns: 已排序並附上名次與比例的排行資料；無可排行開團時為空陣列
    static func campaignProfitRanking(campaigns: [Campaign], orders: [LedgerOrder]) -> [CampaignProfitRank] {
        let ranked = campaigns
            .map { ($0, CampaignSummary(campaignName: $0.name, orders: orders)) }
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

    /// 計算過去 N 週 (N = ``heatmapWeekCount``) 每天的下單筆數 (不分狀態，只看建立日期)
    /// - Parameters:
    ///   - orders: 目前訂單清單
    ///   - referenceDate: 基準「現在」時間，決定「本週」的位置
    ///   - calendar: 用來計算週界的曆法 (內部會強制 `firstWeekday = 2`，讓熱力圖以週一為每週起點)
    /// - Returns: 鍵為 `HeatmapKey`、值為訂單筆數
    static func computeHeatmap(orders: [LedgerOrder], referenceDate: Date, calendar: Calendar) -> [HeatmapKey: Int] {
        var calendar = calendar
        // 熱力圖視覺上以週一為每週起點 (列為 一…日)，週欄分組需與之對齊，否則週日訂單會落到相鄰欄
        calendar.firstWeekday = 2
        let now = referenceDate
        let weekCount = InsightsStats.heatmapWeekCount
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return [:]
        }

        var result: [HeatmapKey: Int] = [:]

        for order in orders {
            // 以「訂單所屬週起點」對「本週起點」相差幾週決定欄位；兩者皆對齊週界，避免用任意日期相減造成跨週 off-by-one
            guard let orderWeekStart = calendar.dateInterval(of: .weekOfYear, for: order.date)?.start else {
                continue
            }
            let daysBetween = calendar.dateComponents([.day], from: orderWeekStart, to: currentWeekStart).day ?? 0
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

    /// 計算上一個對等期間的淨獲利總和，例如目前是「最近 30 天」就回傳「30 天前那 30 天」的累計
    /// - Parameters:
    ///   - realized: 已實現的訂單
    ///   - range: 趨勢期間
    ///   - calendar: 用來算日期的曆法
    ///   - now: 目前期間的結束基準
    /// - Returns: 對等期間的累計獲利；無對等資料時為 `nil`
    private static func previousPeriodProfit(
        realized: [LedgerOrder],
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

        let total = realized
            .filter { (priorStart..<priorEnd).contains($0.date) }
            .reduce(Decimal.zero) { $0 + $1.summary.profit }

        // 沒有任何訂單落在前一同期 → 視為「無資料可比」
        guard total != 0 else {
            return nil
        }
        return total
    }

    /// 根據本期/上期累計獲利產生 `↑ 12.3%` 或 `— 無對照` 等顯示字串
    /// - Parameters:
    ///   - current: 本期累計
    ///   - previous: 上期累計；`nil` 代表無資料可比
    /// - Returns: trend card 右上角字串
    private static func trendDeltaText(current: Decimal, previous: Decimal?) -> String {
        guard let previous, previous != 0 else {
            return "— 無對照"
        }
        let delta = (current - previous) / previous
        let arrow = delta >= 0 ? "↑" : "↓"
        let absDelta = delta < 0 ? -delta : delta
        let formatted = absDelta.formatted(.percent.precision(.fractionLength(1)))
        return "\(arrow) \(formatted)"
    }

    /// 對應 ``trendDeltaText(current:previous:)`` 的方向旗標，方便 view 決定文字色
    /// - Parameters:
    ///   - current: 本期累計
    ///   - previous: 上期累計；`nil` 代表無資料可比
    /// - Returns: `true` 上升、`false` 下降、`nil` 無對照
    private static func trendDeltaDirection(current: Decimal, previous: Decimal?) -> Bool? {
        guard let previous, previous != 0 else {
            return nil
        }
        return current >= previous
    }

    /// 依 range 產生對應的 bar chart 資料：30 天逐日、6/12 個月逐月
    /// - Parameters:
    ///   - realized: 已實現的訂單
    ///   - range: 趨勢期間
    ///   - calendar: 用來分組的曆法
    ///   - now: 基準日
    /// - Returns: 對應每段時間的累計獲利
    private static func trendBars(
        realized: [LedgerOrder],
        range: InsightsDateRange,
        calendar: Calendar,
        now: Date
    ) -> [BLBarChartValue] {
        switch range {
        case .thirtyDays:
            return (0..<30).reversed().compactMap { offset in
                guard let dayStart = calendar.date(byAdding: .day, value: -offset, to: now),
                      let interval = calendar.dateInterval(of: .day, for: dayStart) else {
                    return nil
                }

                let dayProfit = realized
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

                return BLBarChartValue(
                    label: label,
                    value: NSDecimalNumber(decimal: dayProfit).doubleValue
                )
            }

        case .sixMonths, .twelveMonths:
            let monthCount = range == .sixMonths ? 6 : 12

            return (0..<monthCount).reversed().compactMap { offset in
                guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: now),
                      let interval = calendar.dateInterval(of: .month, for: monthStart) else {
                    return nil
                }

                let monthProfit = realized
                    .filter { (interval.start..<interval.end).contains($0.date) }
                    .reduce(Decimal.zero) { $0 + $1.summary.profit }

                // 6 個月用 YYYY/MM；12 個月空間較窄，改用 YY/MM (皆為 verbatim 精確格式)
                let monthFormat: Date.FormatString = range == .sixMonths
                    ? "\(year: .padded(4))/\(month: .twoDigits)"
                    : "\(year: .twoDigits)/\(month: .twoDigits)"
                let label = monthStart.formatted(
                    .verbatim(monthFormat, timeZone: calendar.timeZone, calendar: calendar)
                )

                return BLBarChartValue(
                    label: label,
                    value: NSDecimalNumber(decimal: monthProfit).doubleValue
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
