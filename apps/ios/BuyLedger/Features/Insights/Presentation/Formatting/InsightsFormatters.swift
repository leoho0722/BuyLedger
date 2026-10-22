//
//  InsightsFormatters.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

/// 分析頁的文字、標籤與圖表值格式化，畫面只負責呈現
enum InsightsFormatters {

}

// MARK: - Nested Types

extension InsightsFormatters {

    /// 成本圈狀圖的單一區段，金額已轉為 `Double` 並附上本地化金額描述
    struct CostSlice: Equatable, Sendable {

        /// 區段名稱的本地化 key
        let label: String

        /// 區段數值，供圈狀圖計算占比
        let value: Double

        /// 供輔助技術朗讀的本地化金額描述
        let valueDescription: String

        /// 畫面依此選擇區段顏色的語意色調
        let tone: InsightsCostSegment.Tone
    }
}

// MARK: - Internal Method

extension InsightsFormatters {

    /// 依與上期的比值產生走勢卡的成長率文字，沒有比值時顯示比較說明
    ///
    /// - Parameters:
    ///   - ratio: 本期相對上期的比值；`nil` 表示沒有比較值
    ///   - locale: App 選定、用於百分比呈現的 `locale`
    /// - Returns: 含上升或下降箭頭與百分比的文字；沒有比值時為比較說明的本地化 key
    static func trendDelta(_ ratio: Decimal?, locale: Locale) -> String {
        guard let ratio else {
            return "insights.chart.label.comparison"
        }
        let arrow = ratio >= 0 ? "↑" : "↓"
        let formatted = BLFormatters.percent(abs(ratio), locale: locale)
        return "\(arrow) \(formatted)"
    }

    /// 把走勢段轉成長條圖資料，獲利由 `Decimal` 轉為 `Double` 供圖表使用
    ///
    /// - Parameters:
    ///   - buckets: 走勢段，保留原有順序
    ///   - locale: App 選定、用於金額描述的 `locale`
    /// - Returns: 與走勢段同順序的長條圖資料
    static func trendBars(_ buckets: [InsightsTrendBucket], locale: Locale) -> [BLBarChartValue] {
        buckets.map {
            BLBarChartValue(
                label: $0.label,
                value: NSDecimalNumber(decimal: $0.profit).doubleValue,
                valueDescription: BLFormatters.twd($0.profit, locale: locale)
            )
        }
    }

    /// 組出類別與開團排行列的標題，名次在前、名稱在後
    ///
    /// - Parameters:
    ///   - rank: 名次，由 1 起算
    ///   - name: 類別或開團名稱
    /// - Returns: 例如 `1. 美妝保養` 的標題
    static func rankTitle(rank: Int, name: String) -> String {
        "\(rank). \(name)"
    }

    /// 把成本區塊轉成圈狀圖區段，金額轉為 `Double` 並附上本地化金額描述
    ///
    /// - Parameters:
    ///   - segments: 成本結構區塊，保留原有順序
    ///   - locale: App 選定、用於金額描述的 `locale`
    /// - Returns: 與成本區塊同順序的圈狀圖區段，顏色由畫面依語意色調決定
    static func costDonutSlices(_ segments: [InsightsCostSegment], locale: Locale) -> [CostSlice] {
        segments.map {
            CostSlice(
                label: $0.label,
                value: NSDecimalNumber(decimal: $0.value).doubleValue,
                valueDescription: BLFormatters.twd($0.value, locale: locale),
                tone: $0.tone
            )
        }
    }

    /// 組出熱力圖欄位的週次標籤
    ///
    /// - Parameter weekNumber: 週次，由 1 起算
    /// - Returns: 例如 `W3` 的標籤
    static func weekLabel(_ weekNumber: Int) -> String {
        "W\(weekNumber)"
    }

    /// 依行事曆與 App 語言取得由週一起排的 7 個星期縮寫
    ///
    /// - Parameters:
    ///   - calendar: 記錄的行事曆，複製後套用 App 語言取得星期名稱
    ///   - locale: App 選定的 `locale`
    /// - Returns: 由週一排到週日的星期縮寫
    static func weekdayLabels(calendar: Calendar, locale: Locale) -> [String] {
        var localizedCalendar = calendar
        localizedCalendar.locale = locale
        let symbols = localizedCalendar.veryShortStandaloneWeekdaySymbols
        return (0..<7).map {
            symbols[($0 + 1) % symbols.count]
        }
    }
}
