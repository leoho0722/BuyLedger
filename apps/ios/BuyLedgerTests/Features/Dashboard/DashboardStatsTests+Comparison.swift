//
//  DashboardStatsTests+Comparison.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

extension DashboardStatsTests {

    /// 本月與上月都有訂單時，營業額與獲利的成長率以上月的絕對值為分母計算
    @Test
    func revenueDelta_上月有資料_計算營業額與獲利成長率() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "cur",
                status: .delivered,
                date: Self.aprilDate(15),
                charged: 2_000
            ),
            Self.makeOrder(
                id: "prev",
                status: .delivered,
                date: Self.marchDate(15),
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
        #expect(stats.revenue == 2_000)
        #expect(stats.revenueDelta == 1)
        #expect(stats.profitDelta == 1)
    }

    /// 上月沒有任何訂單時，營業額、成本、獲利與毛利率的成長率皆為空值，無法比較
    @Test
    func revenueDelta_上月無資料_成長率皆為空值() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "cur",
                status: .delivered,
                date: Self.aprilDate(15),
                charged: 2_000
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
        #expect(stats.revenueDelta == nil)
        #expect(stats.costDelta == nil)
        #expect(stats.profitDelta == nil)
        #expect(stats.marginDelta == nil)
    }

    /// 上月獲利為負數時，成長率以上月絕對值為分母，本月較上月回升時仍為正值
    @Test
    func profitDelta_上月獲利為負_方向以本月減上月的差額為準() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "current",
                status: .delivered,
                date: Self.aprilDate(15),
                charged: 0,
                itemCost: 50
            ),
            Self.makeOrder(
                id: "previous",
                status: .delivered,
                date: Self.marchDate(15),
                charged: 0,
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
        #expect(stats.profitDelta == 0.5)
    }
}
