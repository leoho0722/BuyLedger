//
//  DashboardStatsComparisonTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `DashboardStats` 的單元測試，涵蓋本月與上月的成長率計算
struct DashboardStatsComparisonTests {

    /// 驗證本月與上月都有訂單時，`revenueDelta` 與 `profitDelta` 以上月的絕對值為分母計算
    @Test
    func revenueDelta_上月有資料_計算營業額與獲利成長率() {
        // Given
        let orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "cur",
                status: .delivered,
                date: DashboardStatsTestSupport.aprilDate(15),
                charged: 2_000
            ),
            DashboardStatsTestSupport.makeOrder(
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

    /// 驗證上月沒有任何訂單時，`revenueDelta`、`costDelta`、`profitDelta` 與 `marginDelta` 皆為 `nil`，無法比較
    @Test
    func revenueDelta_上月無資料_成長率皆為空值() {
        // Given
        let orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "cur",
                status: .delivered,
                date: DashboardStatsTestSupport.aprilDate(15),
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

    /// 驗證上月獲利為負時，`profitDelta` 以上月絕對值為分母、方向看本月減上月的差額，回升時為正值
    @Test
    func profitDelta_上月獲利為負_方向以本月減上月的差額為準() {
        // Given
        let orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "current",
                status: .delivered,
                date: DashboardStatsTestSupport.aprilDate(15),
                charged: 0,
                itemCost: 50
            ),
            DashboardStatsTestSupport.makeOrder(
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

// MARK: - Private Method

private extension DashboardStatsComparisonTests {

    /// 取得 2026 年 3 月 (`TestDependencies.fixedNow` 前一個月) 的指定日期，UTC 零時
    ///
    /// - Parameter day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
    static func marchDate(_ day: Int) -> Date {
        DashboardStatsTestSupport.utcDate(month: 3, day: day)
    }
}
