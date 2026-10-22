//
//  InsightsStatsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證分析統計的走勢區間與上期比較
struct InsightsStatsTests {

    // MARK: - Properties

    /// `posixLocale` 是解析字面值 `Decimal` 用的固定 locale，避免十進位字串解析受執行環境影響
    private static let posixLocale = Locale(identifier: "en_US_POSIX")

    /// 三十天區間產生三十段逐日走勢，最後一段是基準日，合計等於期間總獲利
    @Test
    func trendBuckets_三十天區間_產生三十段逐日且合計為總獲利() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "A",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 1_000,
                itemCost: 300
            ),
        ]

        // When
        let stats = InsightsStats(
            orders: orders,
            range: .thirtyDays,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.trendBuckets.count == 30)
        #expect(stats.trendBuckets.first?.label == "04/01")
        #expect(stats.trendBuckets.last?.label == "04/30")
        #expect(stats.totalProfit == 700)
    }

    /// 六個月與十二個月區間的最後一段是基準月，標籤分別為四位年與兩位年加兩位月份
    ///
    /// - Parameters:
    ///   - range: 趨勢期間
    ///   - bucketCount: 預期的段數
    ///   - lastLabel: 預期的最後一段標籤
    @Test(arguments: [
        (range: InsightsDateRange.sixMonths, bucketCount: 6, lastLabel: "2026/04"),
        (range: InsightsDateRange.twelveMonths, bucketCount: 12, lastLabel: "26/04"),
    ])
    func trendBuckets_六與十二個月區間_最後一段為基準月標籤(
        range: InsightsDateRange,
        bucketCount: Int,
        lastLabel: String
    ) {
        // Given
        let orders = [
            Self.makeOrder(
                id: "A",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 1_000
            ),
        ]

        // When
        let stats = InsightsStats(
            orders: orders,
            range: range,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.trendBuckets.count == bucketCount)
        #expect(stats.trendBuckets.last?.label == lastLabel)
    }

    /// 上期有訂單時，比值為本期減上期後除以上期絕對值
    ///
    /// - Throws: 測試用日期或數值無法組成時丟出
    @Test
    func trendRatio_上期有訂單_為本期減上期除以上期絕對值() throws {
        // Given
        let previousDate = try Self.date(year: 2025, month: 2, day: 15)
        let orders = [
            Self.makeOrder(
                id: "cur",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 1_000
            ),
            Self.makeOrder(
                id: "prev",
                status: .delivered,
                date: previousDate,
                charged: 400
            ),
        ]
        let expectedRatio = try Self.decimal("1.5")

        // When
        let stats = InsightsStats(
            orders: orders,
            range: .twelveMonths,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.totalProfit == 1_000)
        #expect(stats.trendRatio == expectedRatio)
    }

    /// 上期沒有任何訂單時沒有比較值，比值為 `nil`
    @Test
    func trendRatio_上期無訂單_無比較值() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "cur",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 1_000
            ),
        ]

        // When
        let stats = InsightsStats(
            orders: orders,
            range: .twelveMonths,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.trendRatio == nil)
    }

    /// 上期有訂單但合計獲利為零時沒有比較值，比值為 `nil`
    ///
    /// - Throws: 測試用日期無法組成時丟出
    @Test
    func trendRatio_上期合計為零_無比較值() throws {
        // Given
        let previousDate = try Self.date(year: 2025, month: 2, day: 15)
        let orders = [
            Self.makeOrder(
                id: "cur",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 1_000
            ),
            Self.makeOrder(
                id: "prev",
                status: .delivered,
                date: previousDate,
                charged: 0
            ),
        ]

        // When
        let stats = InsightsStats(
            orders: orders,
            range: .twelveMonths,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.trendRatio == nil)
    }

    /// 上期獲利為負時，比值的正負與幅度依差額除以上期絕對值決定
    ///
    /// - Parameters:
    ///   - current: 本期獲利
    ///   - previous: 上期獲利
    ///   - ratioText: 預期比值的十進位字串
    /// - Throws: 測試用日期或數值無法組成時丟出
    @Test(arguments: [
        (current: Decimal(50), previous: Decimal(-100), ratioText: "1.5"),
        (current: Decimal(-50), previous: Decimal(-100), ratioText: "0.5"),
        (current: Decimal(-200), previous: Decimal(-100), ratioText: "-1"),
    ])
    func trendRatio_上期為負_依差額與上期絕對值計算(
        current: Decimal,
        previous: Decimal,
        ratioText: String
    ) throws {
        // Given
        let previousDate = try Self.date(year: 2025, month: 2, day: 15)
        let orders = [
            Self.makeOrder(
                id: "current",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: current > 0 ? current : 0,
                itemCost: current < 0 ? -current : 0
            ),
            Self.makeOrder(
                id: "previous",
                status: .delivered,
                date: previousDate,
                charged: previous > 0 ? previous : 0,
                itemCost: previous < 0 ? -previous : 0
            ),
        ]
        let expectedRatio = try Self.decimal(ratioText)

        // When
        let stats = InsightsStats(
            orders: orders,
            range: .twelveMonths,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.trendRatio == expectedRatio)
    }

    /// 期間總獲利等於各段獲利的 `Decimal` 精確加總，不經過 `Double` 近似
    ///
    /// - Throws: 測試用日期或數值無法組成時丟出
    @Test
    func totalProfit_十二個月區間_等於各段小數精確加總() throws {
        // Given
        let firstDate = try Self.date(year: 2026, month: 3, day: 1)
        let firstCharged = try Self.decimal("100.123456789123456789")
        let secondCharged = try Self.decimal("200.987654321987654321")
        let expectedTotal = try Self.decimal("301.111111111111111110")
        let orders = [
            Self.makeOrder(
                id: "first",
                status: .delivered,
                date: firstDate,
                charged: firstCharged
            ),
            Self.makeOrder(
                id: "second",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: secondCharged
            ),
        ]

        // When
        let stats = InsightsStats(
            orders: orders,
            range: .twelveMonths,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.totalProfit == expectedTotal)
    }
}

// MARK: - Private Method

private extension InsightsStatsTests {

    /// 把十進位字面值字串解析為 `Decimal`，測試的預期比值由此取得
    ///
    /// - Parameter text: 十進位字面值字串
    /// - Returns: 解析後的 `Decimal`
    /// - Throws: 字串無法解析時丟出
    static func decimal(_ text: String) throws -> Decimal {
        try #require(Decimal(string: text, locale: posixLocale))
    }
}
