//
//  DashboardFeatureScreenStateTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `DashboardFeature.State` 的單元測試，直接以 State 計算 `screenState` 與 `stats`，不經 TestStore
struct DashboardFeatureScreenStateTests {

    /// 驗證載入失敗時，`screenState` 為失敗畫面，即使尚未記錄日期也不顯示骨架
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

    /// 驗證載入中時，即使已記錄日期，`screenState` 仍為載入骨架
    @Test
    func screenState_載入中且有日期_顯示載入骨架() {
        // Given
        var state = DashboardFeature.State()
        state.loadState = .loading
        state.dateContext = DashboardDateContext(
            now: DashboardStatsTestSupport.utcDate(month: 5, day: 12, hour: 10),
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let screenState = state.screenState

        // Then
        #expect(screenState == .loading)
    }

    /// 驗證已載入三筆訂單但尚未記錄日期時，`screenState` 為載入骨架，不顯示總覽數字
    @Test
    func screenState_已載入三筆訂單但無日期_顯示載入骨架() {
        // Given
        var state = DashboardFeature.State()
        state.loadState = .loaded
        state.orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTestSupport.utcDate(month: 5, day: 3),
                charged: 1_000
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "B",
                status: .delivered,
                date: DashboardStatsTestSupport.utcDate(month: 5, day: 10),
                charged: 500
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "C",
                status: .delivered,
                date: DashboardStatsTestSupport.utcDate(month: 4, day: 20),
                charged: 800
            ),
        ]

        // When
        let screenState = state.screenState

        // Then
        #expect(screenState == .loading)
    }

    /// 驗證已載入但沒有訂單、尚未記錄日期時，`screenState` 為載入骨架，不顯示首次使用畫面
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

    /// 驗證已載入、已記錄日期且沒有訂單時，`screenState` 為首次使用畫面 (`.onboarding`)
    @Test
    func screenState_已載入零筆訂單且有日期_顯示首次使用畫面() {
        // Given
        var state = DashboardFeature.State()
        state.loadState = .loaded
        state.dateContext = DashboardDateContext(
            now: DashboardStatsTestSupport.utcDate(month: 5, day: 12, hour: 10),
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let screenState = state.screenState

        // Then
        #expect(screenState == .onboarding)
    }

    /// 驗證已載入三筆訂單且已記錄日期時，`screenState` 為總覽，本月營業額與筆數只計入記錄日期所在月份的訂單
    ///
    /// - Throws: 畫面狀態不是總覽時由 `#require` 丟出測試失敗
    @Test
    func screenState_已載入三筆訂單且有日期_顯示總覽數字() throws {
        // Given
        var state = DashboardFeature.State()
        state.loadState = .loaded
        state.orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTestSupport.utcDate(month: 5, day: 3),
                charged: 1_000
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "B",
                status: .delivered,
                date: DashboardStatsTestSupport.utcDate(month: 5, day: 10),
                charged: 500
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "C",
                status: .delivered,
                date: DashboardStatsTestSupport.utcDate(month: 4, day: 20),
                charged: 800
            ),
        ]
        state.dateContext = DashboardDateContext(
            now: DashboardStatsTestSupport.utcDate(month: 5, day: 12, hour: 10),
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let screenState = state.screenState

        // Then
        let stats = try #require(Self.overviewStats(of: screenState))
        #expect(stats.revenue == 1_500)
        #expect(stats.orderCount == 2)
        #expect(stats.revenueDelta == 0.875)
    }

    /// 驗證 4 月與 5 月各一筆訂單時，`stats` 的本月只計入 5 月 3 日的訂單，並以 4 月為上月比較
    ///
    /// - Note: 記錄日期為 2026-05-12 10:00 UTC，行事曆固定為 UTC
    @Test
    func stats_每個月各一筆訂單_只計入本月並以上月為比較() {
        // Given
        var state = DashboardFeature.State()
        state.loadState = .loaded
        state.orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTestSupport.utcDate(month: 5, day: 3),
                charged: 1_000
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "B",
                status: .delivered,
                date: DashboardStatsTestSupport.utcDate(month: 4, day: 20),
                charged: 800
            ),
        ]
        state.dateContext = DashboardDateContext(
            now: DashboardStatsTestSupport.utcDate(month: 5, day: 12, hour: 10),
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let stats = state.stats

        // Then
        #expect(stats?.revenue == 1_000)
        #expect(stats?.orderCount == 1)
        #expect(stats?.revenueDelta == 0.25)
    }

    /// 驗證記錄日期之後新增本月訂單時，`stats` 立即把新訂單的金額計入本月營業額
    ///
    /// - Note: 記錄日期為 2026-05-12 10:00 UTC，新增的訂單在 5 月 10 日、營業額 500
    @Test
    func stats_記錄日期之後新增本月訂單_本月營業額立即重算() {
        // Given
        let recorded = DashboardDateContext(
            now: DashboardStatsTestSupport.utcDate(month: 5, day: 12, hour: 10),
            calendar: TestDependencies.fixedCalendar
        )
        var state = DashboardFeature.State()
        state.loadState = .loaded
        state.orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTestSupport.utcDate(month: 5, day: 3),
                charged: 1_000
            ),
        ]
        state.dateContext = recorded

        // When
        state.orders.append(
            DashboardStatsTestSupport.makeOrder(
                id: "B",
                status: .delivered,
                date: DashboardStatsTestSupport.utcDate(month: 5, day: 10),
                charged: 500
            )
        )

        // Then
        #expect(state.stats?.revenue == 1_500)
    }

    /// 驗證跨月後以 `refreshDateContext` 取代記錄日期，5 月 31 日的訂單改計入上月，本月營業額與筆數歸零
    ///
    /// - Note: 原記錄 2026-05-31 23:50 UTC；回到前景於 2026-06-01 00:30 UTC 時由 Root 取代記錄
    @Test
    func stats_跨月回到前景後_記錄日期改為新月份且前月訂單計入上月() {
        // Given
        var state = DashboardFeature.State()
        state.loadState = .loaded
        state.orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTestSupport.utcDate(month: 5, day: 31),
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

    /// 驗證月目標改變時，`stats` 的目標進度依新目標立即重算
    ///
    /// - Note: 本月獲利為 1,000，目標由 2,000 改為 4,000，進度由 0.5 變為 0.25
    @Test
    func stats_月目標改變_目標進度立即重算() {
        // Given
        let recorded = DashboardDateContext(
            now: DashboardStatsTestSupport.utcDate(month: 5, day: 12, hour: 10),
            calendar: TestDependencies.fixedCalendar
        )
        var state = DashboardFeature.State()
        state.loadState = .loaded
        state.orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTestSupport.utcDate(month: 5, day: 3),
                charged: 1_000
            ),
        ]
        state.monthlyProfitGoalTWD = 2_000
        state.dateContext = recorded

        // When
        state.monthlyProfitGoalTWD = 4_000

        // Then
        #expect(state.stats?.goalProgress == 0.25)
    }
}

// MARK: - Private Method

private extension DashboardFeatureScreenStateTests {

    /// 取出總覽畫面的統計數字，其他畫面狀態回傳 `nil`
    ///
    /// - Parameter screenState: 首頁目前的畫面狀態
    /// - Returns: 總覽畫面的統計數字，不是總覽時為 `nil`
    static func overviewStats(
        of screenState: DashboardFeature.State.ScreenState
    ) -> DashboardStats? {
        guard case .overview(let stats) = screenState else {
            return nil
        }
        return stats
    }
}
