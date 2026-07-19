//
//  InsightsStatsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct InsightsStatsTests {

    // MARK: - Tests

    @Test func trendBarsForThirtyDaysProduceThirtyDailyBucketsSummingToTotalProfit() {
        let orders = [
            Self.makeOrder(id: "A", status: .delivered, date: TestDependencies.fixedNow, charged: 1_000, itemCost: 300),
        ]
        let stats = InsightsStats(
            orders: orders,
            range: .thirtyDays,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar,
            locale: Locale(identifier: "zh-Hant"),
            palette: BLPalette(isDark: false)
        )

        #expect(stats.trendBars.count == 30)
        #expect(stats.totalProfit == 700)
    }

    @Test func trendDeltaComparesCurrentAgainstPriorTwelveMonthPeriodWhenBothHaveData() {
        // SBE：本期 (近 12 個月，含 fixedNow) 獲利 1000；上期 (再前 12 個月) 獲利 400 → 上升 100%+
        let orders = [
            Self.makeOrder(id: "cur", status: .delivered, date: TestDependencies.fixedNow, charged: 1_000),
            Self.makeOrder(id: "prev", status: .delivered, date: Self.date(year: 2025, month: 2, day: 15), charged: 400),
        ]
        let stats = InsightsStats(
            orders: orders,
            range: .twelveMonths,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar,
            locale: Locale(identifier: "zh-Hant"),
            palette: BLPalette(isDark: false)
        )

        #expect(stats.totalProfit == 1_000)
        #expect(stats.trendDeltaIsPositive == true)
        #expect(stats.trendDelta.hasPrefix("↑"))
    }

    @Test func trendDeltaHasNoComparisonWhenPriorPeriodEmpty() {
        let orders = [
            Self.makeOrder(id: "cur", status: .delivered, date: TestDependencies.fixedNow, charged: 1_000),
        ]
        let stats = InsightsStats(
            orders: orders,
            range: .twelveMonths,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar,
            locale: Locale(identifier: "zh-Hant"),
            palette: BLPalette(isDark: false)
        )

        #expect(stats.trendDelta == "— 無對照")
        #expect(stats.trendDeltaIsPositive == nil)
    }

    @Test func costSegmentsExcludeZeroValueSegmentsAndTotalCostAggregatesAcrossAllRealizedOrders() {
        // 只有商品金額非零：成本結構只應出現「商品金額」一個區塊
        let orders = [
            Self.makeOrder(id: "A", status: .delivered, date: TestDependencies.fixedNow, charged: 1_000, itemCost: 500),
        ]
        let stats = InsightsStats(
            orders: orders,
            range: .twelveMonths,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar,
            locale: Locale(identifier: "zh-Hant"),
            palette: BLPalette(isDark: false)
        )

        #expect(stats.totalCost == 500)
        #expect(stats.costSegments.map(\.label) == ["商品金額"])
        #expect(stats.costSegments.first?.value == 500)
    }

    @Test func campaignProfitRankingSortsDescendingAndExcludesCampaignsWithoutOrders() {
        let campaigns = [
            Campaign(id: "1", name: "A團", openDate: Date(timeIntervalSince1970: 0), status: .ongoing, notes: ""),
            Campaign(id: "2", name: "B團", openDate: Date(timeIntervalSince1970: 0), status: .ongoing, notes: ""),
            Campaign(id: "3", name: "C團", openDate: Date(timeIntervalSince1970: 0), status: .ongoing, notes: ""),
        ]
        let orders = [
            Self.makeOrder(id: "O1", status: .delivered, date: Date(timeIntervalSince1970: 0), charged: 500, campaignNames: ["A團"]),
            Self.makeOrder(id: "O2", status: .delivered, date: Date(timeIntervalSince1970: 0), charged: 2_000, campaignNames: ["B團"]),
        ]

        let ranks = InsightsStats.campaignProfitRanking(campaigns: campaigns, orders: orders)

        #expect(ranks.map(\.campaignName) == ["B團", "A團"])
        #expect(ranks.map(\.rank) == [1, 2])
        #expect(ranks.first?.ratio == 1.0)
    }

    @Test func computeHeatmapPlacesTodaysOrderInLastWeekAndCorrectWeekday() {
        // fixedNow (2026-04-30) 為週四；firstWeekday 校正後 0=週一...6=週日 → 週四對應 index 3
        let today = TestDependencies.fixedNow
        let orders = [Self.makeOrder(id: "A", status: .quoting, date: today, charged: 1)]

        let cells = InsightsStats.computeHeatmap(
            orders: orders,
            referenceDate: today,
            calendar: TestDependencies.fixedCalendar
        )

        let key = HeatmapKey(week: InsightsStats.heatmapWeekCount - 1, weekday: 3)
        #expect(cells[key] == 1)
        #expect(cells.values.reduce(0, +) == 1)
    }

    @Test func computeHeatmapExcludesOrdersOlderThanTheDisplayedWindow() {
        let oldDate = TestDependencies.fixedCalendar.date(byAdding: .day, value: -100, to: TestDependencies.fixedNow)!
        let orders = [Self.makeOrder(id: "A", status: .quoting, date: oldDate, charged: 1)]

        let cells = InsightsStats.computeHeatmap(
            orders: orders,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        #expect(cells.isEmpty)
    }

    // MARK: - Helper

    /// 建立指定年月日的 UTC 日期
    private static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        return components.date!
    }

    /// 建立僅填入 ``InsightsStats`` 相關欄位的訂單；其餘成本／費率欄位皆為 0，使 profit = charged − itemCost
    private static func makeOrder(
        id: String,
        status: OrderStatus,
        date: Date,
        charged: Decimal,
        itemCost: Decimal = 0,
        categories: [String] = [],
        campaignNames: [String] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .regular),
            status: status,
            currency: .twd,
            date: date,
            items: [LedgerOrderItem(name: "item", quantity: 1, unitPrice: 0)],
            itemCost: itemCost,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: charged,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: categories,
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: campaignNames,
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}
