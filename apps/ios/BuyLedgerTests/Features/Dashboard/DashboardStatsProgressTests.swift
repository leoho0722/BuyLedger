//
//  DashboardStatsProgressTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `DashboardStats` 的單元測試，涵蓋月目標進度、進行中數量、近期訂單與獲利走勢
struct DashboardStatsProgressTests {

    /// 驗證本月獲利超過月目標時，`goalProgress` 夾限在 1，`goal` 仍為設定的目標金額
    @Test
    func goalProgress_獲利超過目標_進度夾限為一() {
        // Given
        let orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTestSupport.aprilDate(10),
                charged: 2_000
            ),
        ]

        // When
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 1_000,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.goal == 1_000)
        #expect(stats.goalProgress == 1.0)
    }

    /// 驗證未設定月目標 (`monthlyGoal` 為 0) 時，`goalProgress` 為零，不論本月獲利多少
    @Test
    func goalProgress_未設定目標_進度為零() {
        // Given
        let orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTestSupport.aprilDate(10),
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
        #expect(stats.goalProgress == 0)
    }

    /// 驗證確認與出貨中的訂單計入 `activeCount`，報價與已交付的不計入，四筆訂單中只計兩筆
    @Test
    func activeCount_只計入進行中狀態_排除報價與已交付() {
        // Given
        let orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .confirmed,
                date: DashboardStatsTestSupport.aprilDate(1),
                charged: 100
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "B",
                status: .shipping,
                date: DashboardStatsTestSupport.aprilDate(1),
                charged: 100
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "C",
                status: .delivered,
                date: DashboardStatsTestSupport.aprilDate(1),
                charged: 100
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "D",
                status: .quoting,
                date: DashboardStatsTestSupport.aprilDate(1),
                charged: 100
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
        #expect(stats.activeCount == 2)
    }

    /// 驗證近期訂單超過四筆時，`recentOrders` 只取日期由新到舊的前四筆
    @Test
    func recentOrders_超過四筆_取日期由新到舊的前四筆() {
        // Given
        let orders = (1...6).map {
            DashboardStatsTestSupport.makeOrder(
                id: "O\($0)",
                status: .delivered,
                date: DashboardStatsTestSupport.aprilDate($0),
                charged: 100
            )
        }

        // When
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.recentOrders.count == 4)
        #expect(stats.recentOrders.map(\.id) == ["O6", "O5", "O4", "O3"])
    }

    /// 驗證沒有任何訂單時，`sparkline` 固定為十二個月的零值
    @Test
    func sparkline_沒有訂單_十二個月皆為零() {
        // Given
        let orders: [LedgerOrder] = []

        // When
        let stats = DashboardStats(
            orders: orders,
            monthlyGoal: 0,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(stats.sparkline.count == 12)
        #expect(stats.sparkline.allSatisfy { $0 == 0 })
    }

    /// 驗證本月有獲利時，`sparkline` 最後一點等於本月獲利，此例為 800
    @Test
    func sparkline_本月有獲利_最後一個月等於本月獲利() {
        // Given
        let orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTestSupport.aprilDate(10),
                charged: 1_000,
                itemCost: 200
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
        #expect(stats.sparkline.last == 800)
    }
}
