//
//  DashboardStatsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證總覽統計的本月彙總與營收歸屬
struct DashboardStatsTests {

    /// 本月兩筆已實現訂單 (已交付與出貨中) 的營業額、成本、獲利與筆數逐一加總
    @Test
    func init_本月兩筆已實現訂單_彙總營業額成本獲利與筆數() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "A",
                status: .delivered,
                date: Self.aprilDate(10),
                charged: 1_000,
                itemCost: 200
            ),
            Self.makeOrder(
                id: "B",
                status: .shipping,
                date: Self.aprilDate(20),
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

    /// 合併來源被還原為確認狀態後，因合併結果仍列有來源編號而不計入，營業額只計入合併結果
    @Test
    func init_合併來源還原為確認狀態_來源仍不計入營業額() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "A",
                status: .merged,
                date: Self.aprilDate(5),
                charged: 1_000
            ),
            Self.makeOrder(
                id: "B",
                status: .merged,
                date: Self.aprilDate(5),
                charged: 2_000
            ),
            Self.makeOrder(
                id: "M",
                status: .delivered,
                date: Self.aprilDate(5),
                charged: 2_500,
                mergedSourceIDs: ["A", "B"]
            ),
        ]

        // When
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

        // Then
        #expect(original.revenue == 2_500)
        #expect(sourceAReverted.revenue == 2_500)
        #expect(bothSourcesReverted.revenue == 2_500)
    }

    /// 連續合併時，中間的合併結果也列為來源，只有最終的合併結果被計入
    @Test
    func init_連續合併_只計入最終的合併結果() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "A",
                status: .delivered,
                date: Self.aprilDate(5),
                charged: 100
            ),
            Self.makeOrder(
                id: "B",
                status: .delivered,
                date: Self.aprilDate(5),
                charged: 200
            ),
            Self.makeOrder(
                id: "M1",
                status: .merged,
                date: Self.aprilDate(5),
                charged: 300,
                mergedSourceIDs: ["A", "B"]
            ),
            Self.makeOrder(
                id: "C",
                status: .delivered,
                date: Self.aprilDate(5),
                charged: 400
            ),
            Self.makeOrder(
                id: "M2",
                status: .delivered,
                date: Self.aprilDate(5),
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

    /// 報價中、已取消與已合併的訂單不計入本月的筆數與營業額
    @Test
    func init_報價取消與已合併訂單_排除於本月彙總() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "A",
                status: .quoting,
                date: Self.aprilDate(5),
                charged: 1_000
            ),
            Self.makeOrder(
                id: "B",
                status: .cancelled,
                date: Self.aprilDate(5),
                charged: 1_000
            ),
            Self.makeOrder(
                id: "C",
                status: .merged,
                date: Self.aprilDate(5),
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

    /// 刪除合併結果後，來源因不再列於任何合併結果之下而恢復計入營收歸屬
    @Test
    func init_刪除合併結果_來源恢復計入營收歸屬() {
        // Given
        let sources = [
            Self.makeOrder(
                id: "A",
                status: .confirmed,
                date: Self.aprilDate(5),
                charged: 1_000
            ),
            Self.makeOrder(
                id: "B",
                status: .confirmed,
                date: Self.aprilDate(5),
                charged: 2_000
            ),
        ]
        let result = Self.makeOrder(
            id: "M",
            status: .delivered,
            date: Self.aprilDate(5),
            charged: 2_500,
            mergedSourceIDs: ["A", "B"]
        )

        // When
        let withResult = DashboardStats(
            orders: sources + [result],
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let afterDeletion = DashboardStats(
            orders: sources,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(withResult.revenue == 2_500)
        #expect(afterDeletion.revenue == 3_000)
        #expect(afterDeletion.orderCount == 2)
    }

    /// 取消合併結果後，來源仍因列於該結果之下而維持排除，營業額與筆數皆為零
    @Test
    func init_取消合併結果_來源維持排除不計營收() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "A",
                status: .confirmed,
                date: Self.aprilDate(5),
                charged: 1_000
            ),
            Self.makeOrder(
                id: "B",
                status: .confirmed,
                date: Self.aprilDate(5),
                charged: 2_000
            ),
            Self.makeOrder(
                id: "M",
                status: .cancelled,
                date: Self.aprilDate(5),
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
