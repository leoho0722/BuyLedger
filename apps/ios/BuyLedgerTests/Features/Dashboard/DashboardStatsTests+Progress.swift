//
//  DashboardStatsTests+Progress.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

extension DashboardStatsTests {

    /// 本月獲利超過月目標時，目標進度夾限在 1
    @Test
    func goalProgress_獲利超過目標_進度夾限為一() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "A",
                status: .delivered,
                date: Self.aprilDate(10),
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

    /// 使用者未設定月目標時，目標進度為零，不論本月獲利多少
    @Test
    func goalProgress_未設定目標_進度為零() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "A",
                status: .delivered,
                date: Self.aprilDate(10),
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

    /// 進行中數量只計入確認、已採購、出貨中、部分到貨與已到貨，報價與已交付不計入
    @Test
    func activeCount_只計入進行中狀態_排除報價與已交付() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "A",
                status: .confirmed,
                date: Self.aprilDate(1),
                charged: 100
            ),
            Self.makeOrder(
                id: "B",
                status: .shipping,
                date: Self.aprilDate(1),
                charged: 100
            ),
            Self.makeOrder(
                id: "C",
                status: .delivered,
                date: Self.aprilDate(1),
                charged: 100
            ),
            Self.makeOrder(
                id: "D",
                status: .quoting,
                date: Self.aprilDate(1),
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

    /// 近期訂單超過四筆時，只取日期由新到舊的前四筆
    @Test
    func recentOrders_超過四筆_取日期由新到舊的前四筆() {
        // Given
        let orders = (1...6).map {
            Self.makeOrder(
                id: "O\($0)",
                status: .delivered,
                date: Self.aprilDate($0),
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

    /// 沒有任何訂單時，走勢固定為十二個月的零值
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

    /// 走勢的最後一個月等於本月的淨獲利，本月有獲利 800 時最後一點為 800
    @Test
    func sparkline_本月有獲利_最後一個月等於本月獲利() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "A",
                status: .delivered,
                date: Self.aprilDate(10),
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
