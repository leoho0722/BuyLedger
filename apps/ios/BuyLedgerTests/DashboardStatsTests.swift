//
//  DashboardStatsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation
import Testing
@testable import BuyLedger

/// 驗證總覽統計
@MainActor
struct DashboardStatsTests {
    
    // MARK: - Tests
    
    @Test func currentMonthAggregatesRevenueCostAndProfitFromRealizedOrders() {
        // 本月兩筆訂單的總收款為 1500、成本為 300、獲利為 1200
        let orders = [
            Self.makeOrder(
                id: "A", status: .delivered, date: Self.aprilDate(10), charged: 1_000, itemCost: 200
            ),
            Self.makeOrder(
                id: "B", status: .shipping, date: Self.aprilDate(20), charged: 500, itemCost: 100),
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
    
    @Test func mergeSourcesAndResultAreNeverCountedTogetherAfterRevertingSources() {
        let orders = [
            Self.makeOrder(id: "A", status: .merged, date: Self.aprilDate(5), charged: 1_000),
            Self.makeOrder(id: "B", status: .merged, date: Self.aprilDate(5), charged: 2_000),
            Self.makeOrder(
                id: "M",
                status: .delivered,
                date: Self.aprilDate(5),
                charged: 2_500,
                mergedSourceIDs: ["A", "B"]
            ),
        ]
        
        let original = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let sourceAReverted = DashboardStats(
            orders: orders.map {
                $0.id == "A" ? Self.replacingStatus(of: $0, with: .confirmed) : $0
            },
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let bothSourcesReverted = DashboardStats(
            orders: orders.map {
                ["A", "B"].contains($0.id) ? Self.replacingStatus(of: $0, with: .confirmed) : $0
            },
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        
        #expect(original.revenue == 2_500)
        #expect(sourceAReverted.revenue == 2_500)
        #expect(bothSourcesReverted.revenue == 2_500)
    }
    
    @Test func chainedMergeIsCountedOnlyByFinalDashboardResult() {
        // 連續合併後只計入最終結果。
        let orders = [
            Self.makeOrder(id: "A", status: .delivered, date: Self.aprilDate(5), charged: 100),
            Self.makeOrder(id: "B", status: .delivered, date: Self.aprilDate(5), charged: 200),
            Self.makeOrder(
                id: "M1", status: .merged, date: Self.aprilDate(5), charged: 300,
                mergedSourceIDs: ["A", "B"]),
            Self.makeOrder(id: "C", status: .delivered, date: Self.aprilDate(5), charged: 400),
            Self.makeOrder(
                id: "M2", status: .delivered, date: Self.aprilDate(5), charged: 700,
                mergedSourceIDs: ["M1", "C"]),
        ]
        
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        
        #expect(stats.revenue == 700)
        #expect(stats.orderCount == 1)
    }
    
    @Test func quotingCancelledAndMergedOrdersAreExcludedFromMonthlyTotals() {
        let orders = [
            Self.makeOrder(id: "A", status: .quoting, date: Self.aprilDate(5), charged: 1_000),
            Self.makeOrder(id: "B", status: .cancelled, date: Self.aprilDate(5), charged: 1_000),
            Self.makeOrder(id: "C", status: .merged, date: Self.aprilDate(5), charged: 1_000),
        ]
        let stats = DashboardStats(
            orders: orders, monthlyGoal: 0, referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar)
        
        #expect(stats.orderCount == 0)
        #expect(stats.revenue == 0)
    }
    
    @Test func deletingMergeResultRestoresItsSourcesToRevenueAttribution() {
        // 來源資格由現存結果推導，刪除結果後不再視為來源
        let sources = [
            Self.makeOrder(id: "A", status: .confirmed, date: Self.aprilDate(5), charged: 1_000),
            Self.makeOrder(id: "B", status: .confirmed, date: Self.aprilDate(5), charged: 2_000),
        ]
        let result = Self.makeOrder(
            id: "M", status: .delivered, date: Self.aprilDate(5), charged: 2_500,
            mergedSourceIDs: ["A", "B"])
        
        let withResult = DashboardStats(
            orders: sources + [result], monthlyGoal: 0, referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar)
        let afterDeletion = DashboardStats(
            orders: sources, monthlyGoal: 0, referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar)
        
        #expect(withResult.revenue == 2_500)
        #expect(afterDeletion.revenue == 3_000)
        #expect(afterDeletion.orderCount == 2)
    }
    
    @Test func cancellingMergeResultKeepsItsSourcesExcluded() {
        let orders = [
            Self.makeOrder(id: "A", status: .confirmed, date: Self.aprilDate(5), charged: 1_000),
            Self.makeOrder(id: "B", status: .confirmed, date: Self.aprilDate(5), charged: 2_000),
            Self.makeOrder(
                id: "M", status: .cancelled, date: Self.aprilDate(5), charged: 2_500,
                mergedSourceIDs: ["A", "B"]),
        ]
        let stats = DashboardStats(
            orders: orders, monthlyGoal: 0, referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar)
        
        #expect(stats.revenue == 0)
        #expect(stats.orderCount == 0)
    }
    
    @Test func previousMonthWithDataProducesRevenueAndProfitDelta() {
        // 本月兩筆訂單的總收款為 1500、成本為 300、獲利為 1200
        let orders = [
            Self.makeOrder(id: "cur", status: .delivered, date: Self.aprilDate(15), charged: 2_000),
            Self.makeOrder(
                id: "prev", status: .delivered, date: Self.marchDate(15), charged: 1_000),
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
            Self.makeOrder(id: "cur", status: .delivered, date: Self.aprilDate(15), charged: 2_000)
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
    
    @Test func profitDeltaKeepsDirectionWhenPreviousMonthProfitIsNegative() {
        let orders = [
            Self.makeOrder(
                id: "current", status: .delivered, date: Self.aprilDate(15), charged: 0,
                itemCost: 50),
            Self.makeOrder(
                id: "previous", status: .delivered, date: Self.marchDate(15), charged: 0,
                itemCost: 100),
        ]
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        
        #expect(stats.profitDelta == 0.5)
    }
    
    @Test func goalProgressClampsToOneWhenProfitExceedsGoal() {
        let orders = [
            Self.makeOrder(id: "A", status: .delivered, date: Self.aprilDate(10), charged: 2_000)
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
            Self.makeOrder(id: "A", status: .delivered, date: Self.aprilDate(10), charged: 2_000)
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
            Self.makeOrder(
                id: "O\(day)", status: .delivered, date: Self.aprilDate(day), charged: 100)
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
            Self.makeOrder(
                id: "A", status: .delivered, date: Self.aprilDate(10), charged: 1_000, itemCost: 200
            )
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
    /// - Parameter day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
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
    /// - Parameter day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
    private static func marchDate(_ day: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = 2026
        components.month = 3
        components.day = day
        return components.date!
    }
    
    /// 建立只含 DashboardStats 所需欄位的訂單
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - status: 訂單狀態
    ///   - date: 訂單日期
    ///   - charged: 客戶實付金額
    ///   - itemCost: 商品成本
    ///   - mergedSourceIDs: 被合併的來源訂單編號
    /// - Returns: 建立的測試訂單
    private static func makeOrder(
        id: String,
        status: OrderStatus,
        date: Date,
        charged: Decimal,
        itemCost: Decimal = 0,
        mergedSourceIDs: [String] = []
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
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: mergedSourceIDs
        )
    }
    
    /// 建立只替換狀態的訂單複本
    /// - Parameters:
    ///   - order: 原始訂單
    ///   - status: 新的訂單狀態
    /// - Returns: 套用新狀態後的訂單
    private static func replacingStatus(of order: LedgerOrder, with status: OrderStatus) -> LedgerOrder {
        LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: status,
            currency: order.currency,
            date: order.date,
            items: order.items,
            itemCost: order.itemCost,
            domesticShipping: order.domesticShipping,
            internationalShipping: order.internationalShipping,
            foreignDomesticShipping: order.foreignDomesticShipping,
            cardFeeRate: order.cardFeeRate,
            platformFeeRate: order.platformFeeRate,
            paymentFeeRate: order.paymentFeeRate,
            chargedAmount: order.chargedAmount,
            cardlessDeductionAmount: order.cardlessDeductionAmount,
            cardlessSupplementAmount: order.cardlessSupplementAmount,
            orderSource: order.orderSource,
            categories: order.categories,
            paymentMethod: order.paymentMethod,
            notes: order.notes,
            reconciliationStatus: order.reconciliationStatus,
            campaignNames: order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }
}
