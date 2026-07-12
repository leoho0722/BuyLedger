//
//  DashboardStatsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct DashboardStatsTests {

    // MARK: - Tests

    @Test func currentMonthAggregatesRevenueCostAndProfitFromRealizedOrders() {
        // SBE：本月兩筆已實現訂單 (charged 1000/itemCost 200、charged 500/itemCost 100) → revenue 1500、cost 300、profit 1200
        let orders = [
            Self.makeOrder(id: "A", status: .delivered, date: Self.aprilDate(10), charged: 1_000, itemCost: 200),
            Self.makeOrder(id: "B", status: .shipping, date: Self.aprilDate(20), charged: 500, itemCost: 100),
        ]
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        #expect(stats.revenue == 1_500)
        #expect(stats.cost == 300)
        #expect(stats.profit == 1_200)
        #expect(stats.orderCount == 2)
    }

    @Test func quotingCancelledAndMergedOrdersAreExcludedFromMonthlyTotals() {
        let orders = [
            Self.makeOrder(id: "A", status: .quoting, date: Self.aprilDate(5), charged: 1_000),
            Self.makeOrder(id: "B", status: .cancelled, date: Self.aprilDate(5), charged: 1_000),
            Self.makeOrder(id: "C", status: .merged, date: Self.aprilDate(5), charged: 1_000),
        ]
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        #expect(stats.orderCount == 0)
        #expect(stats.revenue == 0)
    }

    @Test func previousMonthWithDataProducesRevenueAndProfitDelta() {
        // SBE：本月 revenue 2000、上月 revenue 1000 (皆 itemCost 0) → revenueDelta = profitDelta = +1.0 (+100%)
        let orders = [
            Self.makeOrder(id: "cur", status: .delivered, date: Self.aprilDate(15), charged: 2_000),
            Self.makeOrder(id: "prev", status: .delivered, date: Self.marchDate(15), charged: 1_000),
        ]
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        #expect(stats.revenue == 2_000)
        #expect(stats.revenueDelta == 1)
        #expect(stats.profitDelta == 1)
    }

    @Test func previousMonthWithoutDataYieldsNilDeltas() {
        let orders = [
            Self.makeOrder(id: "cur", status: .delivered, date: Self.aprilDate(15), charged: 2_000),
        ]
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        #expect(stats.revenueDelta == nil)
        #expect(stats.costDelta == nil)
        #expect(stats.profitDelta == nil)
        #expect(stats.marginDelta == nil)
    }

    @Test func goalProgressClampsToOneWhenProfitExceedsGoal() {
        let orders = [
            Self.makeOrder(id: "A", status: .delivered, date: Self.aprilDate(10), charged: 2_000),
        ]
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 1_000,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        #expect(stats.goal == 1_000)
        #expect(stats.goalProgress == 1.0)
    }

    @Test func goalProgressIsZeroWhenGoalUnset() {
        let orders = [
            Self.makeOrder(id: "A", status: .delivered, date: Self.aprilDate(10), charged: 2_000),
        ]
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        #expect(stats.goalProgress == 0)
    }

    @Test func activeCountCountsOnlyInFlightStatuses() {
        let orders = [
            Self.makeOrder(id: "A", status: .confirmed, date: Self.aprilDate(1), charged: 100),
            Self.makeOrder(id: "B", status: .shipping, date: Self.aprilDate(1), charged: 100),
            Self.makeOrder(id: "C", status: .delivered, date: Self.aprilDate(1), charged: 100),
            Self.makeOrder(id: "D", status: .quoting, date: Self.aprilDate(1), charged: 100),
        ]
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        #expect(stats.activeCount == 2)
    }

    @Test func recentOrdersReturnsAtMostFourNewestByDateDescending() {
        let orders = (1...6).map { day in
            Self.makeOrder(id: "O\(day)", status: .delivered, date: Self.aprilDate(day), charged: 100)
        }
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        #expect(stats.recentOrders.count == 4)
        #expect(stats.recentOrders.map(\.id) == ["O6", "O5", "O4", "O3"])
    }

    @Test func sparklineHasTwelveMonthsZeroFilledWhenNoOrders() {
        let stats = DashboardStats(
            orders: [],
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        #expect(stats.sparkline.count == 12)
        #expect(stats.sparkline.allSatisfy { $0 == 0 })
    }

    @Test func sparklineLastMonthReflectsCurrentMonthProfit() {
        let orders = [
            Self.makeOrder(id: "A", status: .delivered, date: Self.aprilDate(10), charged: 1_000, itemCost: 200),
        ]
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        #expect(stats.sparkline.last == 800)
    }

    // MARK: - Helper

    /// April 2026 (``TestDependencies/fixedNow`` 所在月份) 指定日期，UTC
    private static func aprilDate(_ day: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = 2026
        components.month = 4
        components.day = day
        return components.date!
    }

    /// March 2026 (``TestDependencies/fixedNow`` 前一個月) 指定日期，UTC
    private static func marchDate(_ day: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = 2026
        components.month = 3
        components.day = day
        return components.date!
    }

    /// 建立僅填入 ``DashboardStats`` 相關欄位的訂單；其餘成本／費率欄位皆為 0，使 profit = charged − itemCost
    private static func makeOrder(
        id: String,
        status: OrderStatus,
        date: Date,
        charged: Decimal,
        itemCost: Decimal = 0
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
            categories: [],
            paymentMethod: "",
            notes: "",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}
