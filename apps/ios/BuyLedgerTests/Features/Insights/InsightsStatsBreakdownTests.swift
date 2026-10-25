//
//  InsightsStatsBreakdownTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `InsightsStats` 的單元測試，涵蓋成本結構、類別比例與每團毛利排行
struct InsightsStatsBreakdownTests {

    /// 驗證零值成本區塊與未實現訂單不列入，`totalCost` 只累加已實現訂單
    ///
    /// - Note: 兩筆已實現訂單與一筆未實現訂單
    @Test
    func costSegments_零值區塊與未實現訂單_不列入且不累加() {
        // Given
        let orders = [
            InsightsStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 1_000,
                itemCost: 500
            ),
            InsightsStatsTestSupport.makeOrder(
                id: "B",
                status: .pickedUp,
                date: TestDependencies.fixedNow,
                charged: 600,
                itemCost: 300
            ),
            InsightsStatsTestSupport.makeOrder(
                id: "C",
                status: .quoting,
                date: TestDependencies.fixedNow,
                charged: 2_000,
                itemCost: 900
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
        #expect(stats.totalCost == 800)
        #expect(stats.costSegments.map(\.label) == ["orders.detail.label.itemCost"])
        #expect(stats.costSegments.first?.value == 800)
    }

    /// 驗證四個成本區塊皆有金額時，`costSegments` 依序帶入金額與對應的語意色調
    @Test
    func costSegments_四區塊皆有金額_依序帶對應語意色調() {
        // Given
        let orders = [
            InsightsStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 1_000,
                itemCost: 300,
                domesticShipping: 50,
                internationalShipping: 80,
                cardFeeRate: 1
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
        #expect(
            stats.costSegments.map(\.label) == [
                "orders.detail.label.itemCost",
                "orders.detail.label.localShipping",
                "orders.detail.label.internationalShipping",
                "orders.detail.label.fees",
            ]
        )
        #expect(stats.costSegments.map(\.value) == [300, 50, 80, 1_000])
        #expect(stats.costSegments.map(\.tone) == [.accent, .teal, .purple, .orange])
    }

    /// 驗證 `categoryBreakdown` 以第一名獲利為分母，獲利為負的類別比例夾限為零
    @Test
    func categoryBreakdown_第一名為分母_負獲利類別比例為零() {
        // Given
        let orders = [
            InsightsStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 100,
                categories: ["beauty"]
            ),
            InsightsStatsTestSupport.makeOrder(
                id: "B",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 0,
                itemCost: 20,
                categories: ["snacks"]
            ),
        ]

        // When
        let breakdown = InsightsStats.categoryBreakdown(orders: orders)

        // Then
        #expect(breakdown.map(\.name) == ["beauty", "snacks"])
        #expect(breakdown.map(\.ratio) == [1.0, 0.0])
    }

    /// 驗證第一名獲利為零或負值時分母不成立，`categoryBreakdown` 各類別比例全為零
    ///
    /// - Parameter scenario: 第一名與第二名類別的商品成本
    @Test(arguments: [
        CategoryCostScenario(firstItemCost: Decimal(0), secondItemCost: Decimal(0)),
        CategoryCostScenario(firstItemCost: Decimal(50), secondItemCost: Decimal(80)),
    ])
    func categoryBreakdown_第一名獲利為零或負_各類別比例全為零(scenario: CategoryCostScenario) {
        // Given
        let orders = [
            InsightsStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 0,
                itemCost: scenario.firstItemCost,
                categories: ["beauty"]
            ),
            InsightsStatsTestSupport.makeOrder(
                id: "B",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 0,
                itemCost: scenario.secondItemCost,
                categories: ["snacks"]
            ),
        ]

        // When
        let breakdown = InsightsStats.categoryBreakdown(orders: orders)

        // Then
        #expect(breakdown.map(\.ratio) == [0.0, 0.0])
    }

    /// 驗證 `campaignProfitRanking` 依毛利由高到低排序並排除沒有訂單的開團，名次由 1 起算，第一名比例為 1
    @Test
    func campaignProfitRanking_依毛利遞減且排除無訂單開團_名次由一起算() {
        // Given
        let campaigns = [
            Campaign(
                id: "1",
                name: "A團",
                openDate: Date(timeIntervalSince1970: 0),
                status: .ongoing,
                notes: ""
            ),
            Campaign(
                id: "2",
                name: "B團",
                openDate: Date(timeIntervalSince1970: 0),
                status: .ongoing,
                notes: ""
            ),
            Campaign(
                id: "3",
                name: "C團",
                openDate: Date(timeIntervalSince1970: 0),
                status: .ongoing,
                notes: ""
            ),
        ]
        let orders = [
            InsightsStatsTestSupport.makeOrder(
                id: "O1",
                status: .delivered,
                date: Date(timeIntervalSince1970: 0),
                charged: 500,
                campaignNames: ["A團"]
            ),
            InsightsStatsTestSupport.makeOrder(
                id: "O2",
                status: .delivered,
                date: Date(timeIntervalSince1970: 0),
                charged: 2_000,
                campaignNames: ["B團"]
            ),
        ]

        // When
        let ranks = InsightsStats.campaignProfitRanking(campaigns: campaigns, orders: orders)

        // Then
        #expect(ranks.map(\.campaignName) == ["B團", "A團"])
        #expect(ranks.map(\.rank) == [1, 2])
        #expect(ranks.first?.ratio == 1.0)
    }
}

// MARK: - Nested Types

extension InsightsStatsBreakdownTests {

    /// 一組第一名與第二名類別商品成本的測試資料
    struct CategoryCostScenario: Sendable {

        /// 第一名類別的商品成本，使其獲利為零或負值
        let firstItemCost: Decimal

        /// 第二名類別的商品成本
        let secondItemCost: Decimal
    }
}
