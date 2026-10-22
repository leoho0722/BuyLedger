//
//  InsightsStats+Trend.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

// MARK: - Internal Method

extension InsightsStats {

    /// 依 `range` 產生走勢圖資料：30 天逐日、6 與 12 個月逐月，由舊到新排列
    ///
    /// - Parameters:
    ///   - attributedOrders: 依營收歸屬口徑計入的訂單
    ///   - range: 趨勢期間
    ///   - calendar: 用來分組與格式化標籤的曆法，包含時區
    ///   - now: 基準日
    /// - Returns: 各段期間的標籤與淨獲利
    static func makeTrendBuckets(
        attributedOrders: [LedgerOrder],
        range: InsightsDateRange,
        calendar: Calendar,
        now: Date
    ) -> [InsightsTrendBucket] {
        switch range {
        case .thirtyDays:
            return dailyTrendBuckets(
                attributedOrders: attributedOrders,
                calendar: calendar,
                now: now
            )

        case .sixMonths:
            return monthlyTrendBuckets(
                attributedOrders: attributedOrders,
                monthCount: 6,
                labelFormat: "\(year: .padded(4))/\(month: .twoDigits)",
                calendar: calendar,
                now: now
            )

        case .twelveMonths:
            return monthlyTrendBuckets(
                attributedOrders: attributedOrders,
                monthCount: 12,
                labelFormat: "\(year: .twoDigits)/\(month: .twoDigits)",
                calendar: calendar,
                now: now
            )
        }
    }

    /// 計算上一個等長期間的淨獲利
    ///
    /// - Parameters:
    ///   - attributedOrders: 依營收歸屬口徑計入的訂單
    ///   - range: 趨勢期間
    ///   - calendar: 用來算日期的曆法
    ///   - now: 目前期間的結束基準
    /// - Returns: 對等期間的累計獲利；無對等資料或合計為零時為 `nil`
    static func previousPeriodProfit(
        attributedOrders: [LedgerOrder],
        range: InsightsDateRange,
        calendar: Calendar,
        now: Date
    ) -> Decimal? {
        let unit: Calendar.Component
        let length: Int

        switch range {
        case .thirtyDays:
            unit = .day
            length = 30

        case .sixMonths:
            unit = .month
            length = 6

        case .twelveMonths:
            unit = .month
            length = 12
        }

        let offset = -length
        guard let priorEnd = calendar.date(byAdding: unit, value: offset, to: now),
              let priorStart = calendar.date(byAdding: unit, value: offset, to: priorEnd) else {
            return nil
        }

        let total = attributedOrders
            .filter { (priorStart..<priorEnd).contains($0.date) }
            .map(\.summary.profit)
            .reduce(Decimal.zero, +)

        // 沒有任何訂單落在前一同期即視為無資料可比
        guard total != 0 else {
            return nil
        }
        return total
    }

    /// 計算本期相對上期的比值，即本期減上期後除以上期絕對值
    ///
    /// - Parameters:
    ///   - current: 本期累計獲利
    ///   - previous: 上期累計獲利；`nil` 代表無資料可比
    /// - Returns: 比值，`0.5` 表示成長 50%；上期無資料或合計為零時為 `nil`
    static func comparisonRatio(current: Decimal, previous: Decimal?) -> Decimal? {
        guard let previous, previous != 0 else {
            return nil
        }
        return (current - previous) / abs(previous)
    }
}

// MARK: - Private Method

private extension InsightsStats {

    /// 產生過去 30 天逐日的走勢段，標籤格式為 `MM/dd`
    ///
    /// - Parameters:
    ///   - attributedOrders: 依營收歸屬口徑計入的訂單
    ///   - calendar: 用來分組與格式化標籤的曆法，包含時區
    ///   - now: 基準日
    /// - Returns: 30 段逐日的標籤與淨獲利，由舊到新排列
    static func dailyTrendBuckets(
        attributedOrders: [LedgerOrder],
        calendar: Calendar,
        now: Date
    ) -> [InsightsTrendBucket] {
        var buckets: [InsightsTrendBucket] = []
        for offset in (0..<30).reversed() {
            if let dayStart = calendar.date(byAdding: .day, value: -offset, to: now),
               let interval = calendar.dateInterval(of: .day, for: dayStart) {
                let dayProfit = attributedOrders
                    .filter { (interval.start..<interval.end).contains($0.date) }
                    .map(\.summary.profit)
                    .reduce(Decimal.zero, +)

                // 30 天逐日標籤格式：MM/dd (verbatim，不受 locale 影響)
                let label = dayStart.formatted(
                    .verbatim(
                        "\(month: .twoDigits)/\(day: .twoDigits)",
                        timeZone: calendar.timeZone,
                        calendar: calendar
                    )
                )
                buckets.append(InsightsTrendBucket(label: label, profit: dayProfit))
            }
        }
        return buckets
    }

    /// 產生過去若干個月逐月的走勢段，由舊到新排列
    ///
    /// - Parameters:
    ///   - attributedOrders: 依營收歸屬口徑計入的訂單
    ///   - monthCount: 要產生的月數
    ///   - labelFormat: 每段的標籤格式，為 verbatim 格式字串
    ///   - calendar: 用來分組與格式化標籤的曆法，包含時區
    ///   - now: 基準日
    /// - Returns: 每個月的標籤與淨獲利，由舊到新排列
    static func monthlyTrendBuckets(
        attributedOrders: [LedgerOrder],
        monthCount: Int,
        labelFormat: Date.FormatString,
        calendar: Calendar,
        now: Date
    ) -> [InsightsTrendBucket] {
        var buckets: [InsightsTrendBucket] = []
        for offset in (0..<monthCount).reversed() {
            if let monthStart = calendar.date(byAdding: .month, value: -offset, to: now),
               let interval = calendar.dateInterval(of: .month, for: monthStart) {
                let monthProfit = attributedOrders
                    .filter { (interval.start..<interval.end).contains($0.date) }
                    .map(\.summary.profit)
                    .reduce(Decimal.zero, +)

                let label = monthStart.formatted(
                    .verbatim(labelFormat, timeZone: calendar.timeZone, calendar: calendar)
                )
                buckets.append(InsightsTrendBucket(label: label, profit: monthProfit))
            }
        }
        return buckets
    }
}
