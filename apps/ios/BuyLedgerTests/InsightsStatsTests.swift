//
//  InsightsStatsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation
import Testing
@testable import BuyLedger

/// 驗證分析統計
@MainActor
struct InsightsStatsTests {
    
    // MARK: - Tests
    
    @Test func trendBarsForThirtyDaysProduceThirtyDailyBucketsSummingToTotalProfit() {
        let orders = [
            Self.makeOrder(
                id: "A", status: .delivered, date: TestDependencies.fixedNow, charged: 1_000,
                itemCost: 300)
        ]
        let stats = InsightsStats(
            orders: orders,
            range: .thirtyDays,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar,
            locale: Locale(identifier: "zh-Hant"),
            palette: BLPalette()
        )
        
        #expect(stats.trendBars.count == 30)
        #expect(stats.totalProfit == 700)
    }
    
    @Test func trendDeltaComparesCurrentAgainstPriorTwelveMonthPeriodWhenBothHaveData() {
        // 本期獲利 1000、上期獲利 400，應顯示成長。
        let orders = [
            Self.makeOrder(
                id: "cur", status: .delivered, date: TestDependencies.fixedNow, charged: 1_000),
            Self.makeOrder(
                id: "prev", status: .delivered, date: Self.date(year: 2025, month: 2, day: 15),
                charged: 400),
        ]
        let stats = InsightsStats(
            orders: orders,
            range: .twelveMonths,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar,
            locale: Locale(identifier: "zh-Hant"),
            palette: BLPalette()
        )
        
        #expect(stats.totalProfit == 1_000)
        #expect(stats.trendDeltaIsPositive == true)
        #expect(stats.trendDelta.hasPrefix("↑"))
    }
    
    @Test func trendDeltaHasNoComparisonWhenPriorPeriodEmpty() {
        let orders = [
            Self.makeOrder(
                id: "cur", status: .delivered, date: TestDependencies.fixedNow, charged: 1_000)
        ]
        let stats = InsightsStats(
            orders: orders,
            range: .twelveMonths,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar,
            locale: Locale(identifier: "zh-Hant"),
            palette: BLPalette()
        )
        
        #expect(stats.trendDelta == "— 無對照")
        #expect(stats.trendDeltaIsPositive == nil)
    }
    
    @Test(arguments: [
        (current: Decimal(50), previous: Decimal(-100), text: "↑ 150.0%", isPositive: true),
        (current: Decimal(-50), previous: Decimal(-100), text: "↑ 50.0%", isPositive: true),
        (current: Decimal(-200), previous: Decimal(-100), text: "↓ 100.0%", isPositive: false),
    ])
    func trendDeltaUsesMatchingDirectionAndMagnitudeWhenPreviousPeriodIsNegative(
        current: Decimal,
        previous: Decimal,
        text: String,
        isPositive: Bool
    ) {
        let orders = [
            Self.makeOrder(
                id: "current", status: .delivered, date: TestDependencies.fixedNow,
                charged: current > 0 ? current : 0, itemCost: current < 0 ? -current : 0),
            Self.makeOrder(
                id: "previous", status: .delivered, date: Self.date(year: 2025, month: 2, day: 15),
                charged: previous > 0 ? previous : 0, itemCost: previous < 0 ? -previous : 0),
        ]
        let stats = InsightsStats(
            orders: orders,
            range: .twelveMonths,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar,
            locale: Locale(identifier: "zh-Hant"),
            palette: BLPalette()
        )
        
        #expect(stats.trendDelta == text)
        #expect(stats.trendDeltaIsPositive == isPositive)
    }
    
    @Test func totalProfitEqualsDecimalSumOfPeriodBuckets() {
        let orders = [
            Self.makeOrder(
                id: "first", status: .delivered, date: Self.date(year: 2026, month: 3, day: 1),
                charged: Decimal(string: "100.123456789123456789")!),
            Self.makeOrder(
                id: "second", status: .delivered, date: TestDependencies.fixedNow,
                charged: Decimal(string: "200.987654321987654321")!),
        ]
        let stats = InsightsStats(
            orders: orders,
            range: .twelveMonths,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar,
            locale: Locale(identifier: "zh-Hant"),
            palette: BLPalette()
        )
        
        #expect(stats.totalProfit == Decimal(string: "301.111111111111111110")!)
    }
    
    @Test func costSegmentsExcludeZeroValueSegmentsAndTotalCostAggregatesAcrossAllRealizedOrders() {
        // 只有商品金額非零：成本結構只應出現「商品金額」一個區塊
        let orders = [
            Self.makeOrder(
                id: "A", status: .delivered, date: TestDependencies.fixedNow, charged: 1_000,
                itemCost: 500)
        ]
        let stats = InsightsStats(
            orders: orders,
            range: .twelveMonths,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar,
            locale: Locale(identifier: "zh-Hant"),
            palette: BLPalette()
        )
        
        #expect(stats.totalCost == 500)
        #expect(stats.costSegments.map(\.label) == ["商品金額"])
        #expect(stats.costSegments.first?.value == 500)
    }
    
    @Test func campaignProfitRankingSortsDescendingAndExcludesCampaignsWithoutOrders() {
        let campaigns = [
            Campaign(
                id: "1", name: "A團", openDate: Date(timeIntervalSince1970: 0), status: .ongoing,
                notes: ""),
            Campaign(
                id: "2", name: "B團", openDate: Date(timeIntervalSince1970: 0), status: .ongoing,
                notes: ""),
            Campaign(
                id: "3", name: "C團", openDate: Date(timeIntervalSince1970: 0), status: .ongoing,
                notes: ""),
        ]
        let orders = [
            Self.makeOrder(
                id: "O1", status: .delivered, date: Date(timeIntervalSince1970: 0), charged: 500,
                campaignNames: ["A團"]),
            Self.makeOrder(
                id: "O2", status: .delivered, date: Date(timeIntervalSince1970: 0), charged: 2_000,
                campaignNames: ["B團"]),
        ]
        
        let ranks = InsightsStats.campaignProfitRanking(campaigns: campaigns, orders: orders)
        
        #expect(ranks.map(\.campaignName) == ["B團", "A團"])
        #expect(ranks.map(\.rank) == [1, 2])
        #expect(ranks.first?.ratio == 1.0)
    }
    
    @Test func computeHeatmapPlacesTodaysOrderInLastWeekAndCorrectWeekday() {
        // 週四應落在星期索引 3
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
        let oldDate = TestDependencies.fixedCalendar.date(
            byAdding: .day, value: -100, to: TestDependencies.fixedNow)!
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
    /// - Parameters:
    ///   - year: 西元年
    ///   - month: 月份
    ///   - day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
    private static func date(
        year: Int,
        month: Int,
        day: Int
    ) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        return components.date!
    }
    
    /// 建立只含 InsightsStats 所需欄位的訂單
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - status: 訂單狀態
    ///   - date: 訂單日期
    ///   - charged: 客戶實付金額
    ///   - itemCost: 商品成本
    ///   - categories: 商品類別
    ///   - campaignNames: 開團名稱
    /// - Returns: 建立的測試訂單
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
