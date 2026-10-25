//
//  InsightsStatsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation
import Testing

@testable import BuyLedger

/// `InsightsStats` 的單元測試，涵蓋走勢區間與上期比較
struct InsightsStatsTests {

    // MARK: - Properties

    /// 解析字面值 `Decimal` 用的固定 locale，避免十進位字串解析受執行環境影響
    private static let posixLocale = Locale(identifier: "en_US_POSIX")

    /// 驗證三十天區間產生三十段逐日走勢，首尾標籤為 04/01 與 04/30，各段獲利合計與 `totalProfit` 同為 700
    @Test
    func trendBuckets_三十天區間_產生三十段逐日且合計為總獲利() {
        // Given
        let orders = [
            InsightsStatsTestSupport.makeOrder(
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
        #expect(stats.trendBuckets.map(\.profit).reduce(0, +) == 700)
    }

    /// 驗證六個月與十二個月區間的最後一段為基準月，標籤分別為四位年與兩位年加兩位月份
    ///
    /// - Parameter scenario: 趨勢期間、預期的段數與預期的最後一段標籤
    @Test(arguments: [
        TrendBucketScenario(range: .sixMonths, bucketCount: 6, lastLabel: "2026/04"),
        TrendBucketScenario(range: .twelveMonths, bucketCount: 12, lastLabel: "26/04"),
    ])
    func trendBuckets_六與十二個月區間_最後一段為基準月標籤(scenario: TrendBucketScenario) {
        // Given
        let orders = [
            InsightsStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 1_000
            ),
        ]

        // When
        let stats = InsightsStats(
            orders: orders,
            range: scenario.range,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.trendBuckets.count == scenario.bucketCount)
        #expect(stats.trendBuckets.last?.label == scenario.lastLabel)
    }

    /// 驗證十二個月區間本期獲利為 1,000、上期為 400 時，`totalProfit` 為 1,000，`trendRatio` 為 1.5，即本期減上期後除以上期絕對值
    ///
    /// - Throws: 測試用日期或數值無法組成時丟出
    @Test
    func trendRatio_上期有訂單_為本期減上期除以上期絕對值() throws {
        // Given
        let previousDate = try Self.date(year: 2025, month: 2, day: 15)
        let orders = [
            InsightsStatsTestSupport.makeOrder(
                id: "cur",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 1_000
            ),
            InsightsStatsTestSupport.makeOrder(
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

    /// 驗證上期沒有任何訂單時，`trendRatio` 為 `nil`，沒有比較值
    @Test
    func trendRatio_上期無訂單_無比較值() {
        // Given
        let orders = [
            InsightsStatsTestSupport.makeOrder(
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

    /// 驗證上期有訂單但合計獲利為零時，`trendRatio` 為 `nil`，沒有比較值
    ///
    /// - Throws: 測試用日期無法組成時丟出
    @Test
    func trendRatio_上期合計為零_無比較值() throws {
        // Given
        let previousDate = try Self.date(year: 2025, month: 2, day: 15)
        let orders = [
            InsightsStatsTestSupport.makeOrder(
                id: "cur",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 1_000
            ),
            InsightsStatsTestSupport.makeOrder(
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

    /// 驗證上期獲利為負時，`trendRatio` 的正負與幅度依差額除以上期絕對值決定
    ///
    /// - Parameter scenario: 本期獲利、上期獲利與預期比值的十進位字串
    /// - Throws: 測試用日期或數值無法組成時丟出
    @Test(arguments: [
        TrendRatioScenario(current: Decimal(50), previous: Decimal(-100), ratioText: "1.5"),
        TrendRatioScenario(current: Decimal(-50), previous: Decimal(-100), ratioText: "0.5"),
        TrendRatioScenario(current: Decimal(-200), previous: Decimal(-100), ratioText: "-1"),
    ])
    func trendRatio_上期為負_依差額與上期絕對值計算(scenario: TrendRatioScenario) throws {
        // Given
        let previousDate = try Self.date(year: 2025, month: 2, day: 15)
        let orders = [
            InsightsStatsTestSupport.makeOrder(
                id: "current",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: scenario.current > 0 ? scenario.current : 0,
                itemCost: scenario.current < 0 ? -scenario.current : 0
            ),
            InsightsStatsTestSupport.makeOrder(
                id: "previous",
                status: .delivered,
                date: previousDate,
                charged: scenario.previous > 0 ? scenario.previous : 0,
                itemCost: scenario.previous < 0 ? -scenario.previous : 0
            ),
        ]
        let expectedRatio = try Self.decimal(scenario.ratioText)

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

    /// 驗證十二個月區間的 `totalProfit` 以 `Decimal` 精確加總，不經過 `Double` 近似
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
            InsightsStatsTestSupport.makeOrder(
                id: "first",
                status: .delivered,
                date: firstDate,
                charged: firstCharged
            ),
            InsightsStatsTestSupport.makeOrder(
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

// MARK: - Nested Types

extension InsightsStatsTests {

    /// 一組趨勢期間與預期的段數、最後一段標籤
    struct TrendBucketScenario: Sendable {

        /// 趨勢期間
        let range: InsightsDateRange

        /// 預期的段數
        let bucketCount: Int

        /// 預期的最後一段標籤
        let lastLabel: String
    }

    /// 一組本期獲利、上期獲利與預期的比值字串
    struct TrendRatioScenario: Sendable {

        /// 本期獲利
        let current: Decimal

        /// 上期獲利
        let previous: Decimal

        /// 預期比值的十進位字串
        let ratioText: String
    }
}

// MARK: - Private Method

private extension InsightsStatsTests {

    /// 建立指定年月日的 UTC 日期
    ///
    /// - Parameters:
    ///   - year: 西元年
    ///   - month: 月份
    ///   - day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
    /// - Throws: 年月日無法組成有效日期時丟出
    static func date(year: Int, month: Int, day: Int) throws -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        return try #require(components.date)
    }

    /// 解析十進位字面值字串為 `Decimal`，測試的預期比值由此取得
    ///
    /// - Parameter text: 十進位字面值字串
    /// - Returns: 解析後的 `Decimal`
    /// - Throws: 字串無法解析時丟出
    static func decimal(_ text: String) throws -> Decimal {
        try #require(Decimal(string: text, locale: posixLocale))
    }
}
