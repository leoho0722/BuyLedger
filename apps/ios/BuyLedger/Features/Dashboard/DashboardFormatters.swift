//
//  DashboardFormatters.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import SwiftUI

/// 總覽頁的金額、變化率、走勢摘要與日期子標格式化工具，輸出與畫面現行呈現相同
enum DashboardFormatters {

}

// MARK: - Internal Method

extension DashboardFormatters {

    /// 將記錄的現在時間格式化為大標題上方的日期子標，套用記錄的曆法與時區
    ///
    /// - Parameters:
    ///   - context: 記錄的現在時間與行事曆
    ///   - locale: App 選定的 `locale`
    /// - Returns: 依記錄的曆法與時區呈現的月、日與星期
    static func dateSubtitle(for context: DashboardDateContext, locale: Locale) -> String {
        var style = Date.FormatStyle.dateTime
        style.calendar = context.calendar
        style.timeZone = context.calendar.timeZone
        style.locale = locale
        style = style
            .month(.wide)
            .day(.defaultDigits)
            .weekday(.wide)
        return context.now.formatted(style)
    }

    /// 將獲利金額格式化為含正負號的新台幣字串，大於 0 時於金額前加上 `+`
    ///
    /// - Parameters:
    ///   - profit: 獲利金額
    ///   - locale: App 選定、用於金額呈現的 `locale`
    /// - Returns: 顯示在 hero 卡上的金額字串
    static func signedProfit(_ profit: Decimal, locale: Locale) -> String {
        let formatted = BLFormatters.twd(profit, locale: locale)
        return profit > 0 ? "+\(formatted)" : formatted
    }

    /// 把獲利變化率轉成 hero 卡上的 `↑ 24.3% MoM` 風格字串，沒有上月資料時顯示 `— MoM`
    ///
    /// - Parameters:
    ///   - delta: 成長率，例如 `0.243` 表示 +24.3%
    ///   - locale: App 選定、用於百分比呈現的 `locale`
    /// - Returns: 大於或等於 0 為 `↑`，否則為 `↓`，百分比取絕對值
    static func profitDelta(_ delta: Decimal?, locale: Locale) -> String {
        guard let delta else {
            return "— MoM"
        }
        let arrow = delta >= 0 ? "↑" : "↓"
        let magnitude = delta < 0 ? -delta : delta
        let formatted = BLFormatters.percent(magnitude, locale: locale)
        return "\(arrow) \(formatted) MoM"
    }

    /// 產生走勢圖的無障礙摘要，依首尾比較選擇上升、下降或持平的敘述
    ///
    /// - Parameters:
    ///   - points: 近 12 個月的淨獲利走勢值
    ///   - locale: App 選定、用於金額與敘述的 `locale`
    /// - Returns: 少於兩點時為無資料的標題鍵，否則為帶點數與最低、最高獲利的敘述
    static func sparklineSummary(_ points: [Double], locale: Locale) -> LocalizedStringKey {
        guard points.count > 1,
              let first = points.first,
              let last = points.last,
              let lowest = points.min(),
              let highest = points.max() else {
            return LocalizedStringKey("dashboard.overview.label.monthlyProfitTrend")
        }

        // 三個方向各自成句、不拼接片語：拼接的句子無法在其他語言正確重組
        let low = BLFormatters.twd(Decimal(lowest), locale: locale)
        let high = BLFormatters.twd(Decimal(highest), locale: locale)
        let key: String
        if last > first {
            key = "dashboard.overview.accessibility.trendUp"
        } else if last < first {
            key = "dashboard.overview.accessibility.trendDown"
        } else {
            key = "dashboard.overview.accessibility.trendFlat"
        }
        let text = AppLanguage.format(
            key,
            points.count,
            low,
            high,
            locale: locale
        )
        return LocalizedStringKey(text)
    }

    /// 將目標進度與目標金額格式化為 hero 卡上的文字，例如 `14% / $80,000`
    ///
    /// - Parameters:
    ///   - progress: 目標進度 (0 ~ 1)
    ///   - goal: 月目標金額
    ///   - locale: App 選定、用於金額呈現的 `locale`
    /// - Returns: 進度取整數百分比，後接 ` / ` 與目標金額
    static func goalProgress(_ progress: CGFloat, goal: Decimal, locale: Locale) -> String {
        "\(Int(progress * 100))% / \(BLFormatters.twd(goal, locale: locale))"
    }

    /// 將營業額、成本等的 MoM 變化率格式化為 KPI 卡的說明文字，沒有上月資料時顯示 `— MoM`
    ///
    /// - Parameters:
    ///   - delta: 成長率，例如 `0.182` 表示 +18.2%
    ///   - locale: App 選定、用於百分比呈現的 `locale`
    /// - Returns: 大於或等於 0 時加上 `+`，後接百分比與 ` MoM`
    static func percentDelta(_ delta: Decimal?, locale: Locale) -> String {
        guard let delta else {
            return "— MoM"
        }
        let formatted = BLFormatters.percent(delta, locale: locale)
        let prefix = delta >= 0 ? "+" : ""
        return "\(prefix)\(formatted) MoM"
    }

    /// 將毛利率的百分點變化格式化為 KPI 卡的說明文字，沒有上月資料時顯示 `— MoM`
    ///
    /// - Parameters:
    ///   - delta: 百分點差，例如 `0.024` 表示 +2.4pt
    ///   - locale: App 選定、用於數字呈現的 `locale`
    /// - Returns: 百分點乘 100 後取一位小數，大於或等於 0 時加上 `+`，後接 ` pt MoM`
    static func marginDelta(_ delta: Decimal?, locale: Locale) -> String {
        guard let delta else {
            return "— MoM"
        }
        let percentagePoints = delta * 100
        let formatted = percentagePoints.formatted(
            .number.precision(.fractionLength(1)).locale(locale)
        )
        let prefix = delta >= 0 ? "+" : ""
        return "\(prefix)\(formatted) pt MoM"
    }

    /// 組出到貨進度文字，以已到貨與進行中數量以斜線連接
    ///
    /// - Parameters:
    ///   - arrived: 已到貨數量
    ///   - active: 進行中數量
    /// - Returns: 例如 `2/5`
    static func deliveryProgress(arrived: Int, active: Int) -> String {
        "\(arrived)/\(active)"
    }
}
