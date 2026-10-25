//
//  DashboardStatsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation
import Testing

@testable import BuyLedger

/// `DashboardStats` 的單元測試，涵蓋本月彙總與營收歸屬
struct DashboardStatsTests {

    /// 驗證本月兩筆已實現訂單 (已交付與出貨中) 時，`DashboardStats` 逐一加總營業額、成本、獲利與筆數
    @Test
    func init_本月兩筆已實現訂單_彙總營業額成本獲利與筆數() {
        // Given
        let orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTestSupport.aprilDate(10),
                charged: 1_000,
                itemCost: 200
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "B",
                status: .shipping,
                date: DashboardStatsTestSupport.aprilDate(20),
                charged: 500,
                itemCost: 100
            ),
        ]

        // When
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.revenue == 1_500)
        #expect(stats.cost == 300)
        #expect(stats.profit == 1_200)
        #expect(stats.orderCount == 2)
    }

    /// 驗證合併來源還原為確認狀態後，合併結果仍列有其編號，來源不計入，營業額只計入合併結果
    ///
    /// - Parameter revertedIDs: 還原為確認狀態的來源訂單編號，空陣列代表沒有來源被還原
    @Test(arguments: [[], ["A"], ["A", "B"]])
    func init_合併來源還原為確認狀態_來源仍不計入營業額(revertedIDs: [String]) {
        // Given
        let orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .merged,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 1_000
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "B",
                status: .merged,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 2_000
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "M",
                status: .delivered,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 2_500,
                mergedSourceIDs: ["A", "B"]
            ),
        ]

        // When
        let stats = DashboardStats(
            orders: orders.map {
                revertedIDs.contains($0.id) ? Self.replacingStatus(of: $0, with: .confirmed) : $0
            },
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.revenue == 2_500)
    }

    /// 驗證連續合併時，中間的合併結果 M1 也列為來源，只有最終的 M2 計入營業額與筆數
    @Test
    func init_連續合併_只計入最終的合併結果() {
        // Given
        let orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 100
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "B",
                status: .delivered,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 200
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "M1",
                status: .merged,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 300,
                mergedSourceIDs: ["A", "B"]
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "C",
                status: .delivered,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 400
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "M2",
                status: .delivered,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 700,
                mergedSourceIDs: ["M1", "C"]
            ),
        ]

        // When
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.revenue == 700)
        #expect(stats.orderCount == 1)
    }

    /// 驗證報價中、已取消與已合併的訂單不計入本月的筆數與營業額
    @Test
    func init_報價取消與已合併訂單_排除於本月彙總() {
        // Given
        let orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .quoting,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 1_000
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "B",
                status: .cancelled,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 1_000
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "C",
                status: .merged,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 1_000
            ),
        ]

        // When
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.orderCount == 0)
        #expect(stats.revenue == 0)
    }

    /// 驗證合併結果存在時，來源因合併結果仍列有其編號而不計入營收，營收只計入合併結果
    @Test
    func init_合併結果存在_來源不計入營收() {
        // Given
        let sources = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .confirmed,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 1_000
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "B",
                status: .confirmed,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 2_000
            ),
        ]
        let result = DashboardStatsTestSupport.makeOrder(
            id: "M",
            status: .delivered,
            date: DashboardStatsTestSupport.aprilDate(5),
            charged: 2_500,
            mergedSourceIDs: ["A", "B"]
        )

        // When
        let stats = DashboardStats(
            orders: sources + [result],
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.revenue == 2_500)
    }

    /// 驗證刪除合併結果後，來源因沒有合併結果再列有其編號而恢復計入營收與筆數，此例為營收 3,000、2 筆
    @Test
    func init_刪除合併結果_來源恢復計入營收歸屬() {
        // Given
        let sources = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .confirmed,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 1_000
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "B",
                status: .confirmed,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 2_000
            ),
        ]

        // When
        let afterDeletion = DashboardStats(
            orders: sources,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(afterDeletion.revenue == 3_000)
        #expect(afterDeletion.orderCount == 2)
    }

    /// 驗證合併結果已取消時，來源仍因合併結果列有其編號而維持排除，營業額與筆數皆為零
    @Test
    func init_取消合併結果_來源維持排除不計營收() {
        // Given
        let orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .confirmed,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 1_000
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "B",
                status: .confirmed,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 2_000
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "M",
                status: .cancelled,
                date: DashboardStatsTestSupport.aprilDate(5),
                charged: 2_500,
                mergedSourceIDs: ["A", "B"]
            ),
        ]

        // When
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.revenue == 0)
        #expect(stats.orderCount == 0)
    }
}

// MARK: - Private Method

private extension DashboardStatsTests {

    /// 建立只替換狀態的訂單複本
    ///
    /// - Parameters:
    ///   - order: 原始訂單
    ///   - status: 新的訂單狀態
    /// - Returns: 套用新狀態後的訂單
    static func replacingStatus(of order: LedgerOrder, with status: OrderStatus) -> LedgerOrder {
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
