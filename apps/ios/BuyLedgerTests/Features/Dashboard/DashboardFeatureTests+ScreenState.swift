//
//  DashboardFeatureTests+ScreenState.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

extension DashboardFeatureTests {

    /// 載入失敗時顯示失敗畫面，即使沒有記錄日期也不顯示骨架
    @Test
    func screenState_失敗且無日期_顯示失敗畫面() {
        // Given
        var state = DashboardFeature.State()
        state.loadState = .failed("載入失敗")

        // When
        let screenState = state.screenState

        // Then
        #expect(screenState == .failed("載入失敗"))
    }

    /// 載入中即使已記錄日期也顯示骨架
    @Test
    func screenState_載入中且有日期_顯示載入骨架() {
        // Given
        var state = DashboardFeature.State()
        state.loadState = .loading
        state.dateContext = DashboardDateContext(
            now: DashboardStatsTests.utcDate(month: 5, day: 12, hour: 10),
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let screenState = state.screenState

        // Then
        #expect(screenState == .loading)
    }

    /// 已載入三筆訂單但尚未記錄日期時顯示骨架，不顯示總覽數字
    @Test
    func screenState_已載入三筆訂單但無日期_顯示載入骨架() {
        // Given
        var state = DashboardFeature.State()
        state.loadState = .loaded
        state.orders = [
            DashboardStatsTests.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTests.utcDate(month: 5, day: 3),
                charged: 1_000
            ),
            DashboardStatsTests.makeOrder(
                id: "B",
                status: .delivered,
                date: DashboardStatsTests.utcDate(month: 5, day: 10),
                charged: 500
            ),
            DashboardStatsTests.makeOrder(
                id: "C",
                status: .delivered,
                date: DashboardStatsTests.utcDate(month: 4, day: 20),
                charged: 800
            ),
        ]

        // When
        let screenState = state.screenState

        // Then
        #expect(screenState == .loading)
    }

    /// 已載入但沒有訂單且尚未記錄日期時顯示骨架，不顯示首次使用畫面
    @Test
    func screenState_已載入零筆訂單但無日期_顯示載入骨架() {
        // Given
        var state = DashboardFeature.State()
        state.loadState = .loaded

        // When
        let screenState = state.screenState

        // Then
        #expect(screenState == .loading)
    }

    /// 已載入、已記錄日期且沒有訂單時顯示首次使用畫面
    @Test
    func screenState_已載入零筆訂單且有日期_顯示首次使用畫面() {
        // Given
        var state = DashboardFeature.State()
        state.loadState = .loaded
        state.dateContext = DashboardDateContext(
            now: DashboardStatsTests.utcDate(month: 5, day: 12, hour: 10),
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let screenState = state.screenState

        // Then
        #expect(screenState == .onboarding)
    }

    /// 已載入三筆訂單且已記錄日期時顯示總覽數字，本月營業額與筆數只計入記錄日期所在的月份
    @Test
    func screenState_已載入三筆訂單且有日期_顯示總覽數字() {
        // Given
        var state = DashboardFeature.State()
        state.loadState = .loaded
        state.orders = [
            DashboardStatsTests.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTests.utcDate(month: 5, day: 3),
                charged: 1_000
            ),
            DashboardStatsTests.makeOrder(
                id: "B",
                status: .delivered,
                date: DashboardStatsTests.utcDate(month: 5, day: 10),
                charged: 500
            ),
            DashboardStatsTests.makeOrder(
                id: "C",
                status: .delivered,
                date: DashboardStatsTests.utcDate(month: 4, day: 20),
                charged: 800
            ),
        ]
        state.dateContext = DashboardDateContext(
            now: DashboardStatsTests.utcDate(month: 5, day: 12, hour: 10),
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let screenState = state.screenState

        // Then
        switch screenState {
        case .overview(let stats):
            #expect(stats.revenue == 1_500)
            #expect(stats.orderCount == 2)
            #expect(stats.revenueDelta == 0.875)

        case .failed, .loading, .onboarding:
            Issue.record("已載入且有日期時應顯示總覽數字")
        }
    }

    /// 每個月各一筆訂單時，本月只計入 5 月 3 日的訂單，並以 4 月為上月比較
    ///
    /// - Note: 記錄日期為 2026-05-12 10:00 UTC，行事曆固定為 UTC
    @Test
    func stats_每個月各一筆訂單_只計入本月並以上月為比較() {
        // Given
        var state = DashboardFeature.State()
        state.loadState = .loaded
        state.orders = [
            DashboardStatsTests.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTests.utcDate(month: 5, day: 3),
                charged: 1_000
            ),
            DashboardStatsTests.makeOrder(
                id: "B",
                status: .delivered,
                date: DashboardStatsTests.utcDate(month: 4, day: 20),
                charged: 800
            ),
        ]
        state.dateContext = DashboardDateContext(
            now: DashboardStatsTests.utcDate(month: 5, day: 12, hour: 10),
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let stats = state.stats

        // Then
        #expect(stats?.revenue == 1_000)
        #expect(stats?.orderCount == 1)
        #expect(stats?.revenueDelta == 0.25)
    }

    /// 記錄期間新增本月訂單時，數字立即重算，記錄日期維持不變
    ///
    /// - Note: 記錄日期為 2026-05-12 10:00 UTC，新增的訂單在 5 月 10 日、營業額 500
    @Test
    func stats_記錄日期之後新增本月訂單_數字重算且記錄日期不變() {
        // Given
        let recorded = DashboardDateContext(
            now: DashboardStatsTests.utcDate(month: 5, day: 12, hour: 10),
            calendar: TestDependencies.fixedCalendar
        )
        var state = DashboardFeature.State()
        state.loadState = .loaded
        state.orders = [
            DashboardStatsTests.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTests.utcDate(month: 5, day: 3),
                charged: 1_000
            ),
        ]
        state.dateContext = recorded

        // When
        state.orders.append(
            DashboardStatsTests.makeOrder(
                id: "B",
                status: .delivered,
                date: DashboardStatsTests.utcDate(month: 5, day: 10),
                charged: 500
            )
        )

        // Then
        #expect(state.stats?.revenue == 1_500)
        #expect(state.dateContext == recorded)
    }

    /// 跨月回到前景後，記錄的日期改為新月份，前月訂單計入上月
    ///
    /// - Note: 原記錄 2026-05-31 23:50 UTC；回到前景於 2026-06-01 00:30 UTC 時由 Root 取代記錄
    @Test
    func stats_跨月回到前景後_記錄日期改為新月份且前月訂單計入上月() {
        // Given
        var state = DashboardFeature.State()
        state.loadState = .loaded
        state.orders = [
            DashboardStatsTests.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTests.utcDate(month: 5, day: 31),
                charged: 1_000
            ),
        ]
        state.dateContext = DashboardDateContext(
            now: Date(timeIntervalSince1970: 1_780_271_400),
            calendar: TestDependencies.fixedCalendar
        )

        // When
        state.refreshDateContext(
            now: Date(timeIntervalSince1970: 1_780_273_800),
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(state.stats?.revenue == 0)
        #expect(state.stats?.orderCount == 0)
        #expect(state.stats?.revenueDelta == -1)
    }

    /// 月目標改變時，目標進度以同一個記錄日期立即重算，記錄日期維持不變
    ///
    /// - Note: 本月獲利為 1,000，目標由 2,000 改為 4,000，進度由 0.5 變為 0.25
    @Test
    func stats_月目標改變_目標進度以同一記錄日期重算() {
        // Given
        let recorded = DashboardDateContext(
            now: DashboardStatsTests.utcDate(month: 5, day: 12, hour: 10),
            calendar: TestDependencies.fixedCalendar
        )
        var state = DashboardFeature.State()
        state.loadState = .loaded
        state.orders = [
            DashboardStatsTests.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTests.utcDate(month: 5, day: 3),
                charged: 1_000
            ),
        ]
        state.monthlyProfitGoalTWD = 2_000
        state.dateContext = recorded

        // When
        state.monthlyProfitGoalTWD = 4_000

        // Then
        #expect(state.stats?.goalProgress == 0.25)
        #expect(state.dateContext == recorded)
    }
}
