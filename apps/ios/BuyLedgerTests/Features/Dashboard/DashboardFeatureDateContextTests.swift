//
//  DashboardFeatureDateContextTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `DashboardFeature` 的單元測試，以 TestStore 逐步驗證畫面出現與重試時，日期脈絡改用注入的現在時間與行事曆
@MainActor
struct DashboardFeatureDateContextTests {

    /// 驗證已記錄舊日期脈絡時畫面出現，`dateContext` 覆寫為注入的現在時間與行事曆，並送出 `delegate(.refresh)`
    ///
    /// - Note: 舊日期早於注入值一天
    /// - Note: 舊行事曆的週起點為星期一，與注入值不同
    @Test
    func task_舊日期脈絡存在時畫面出現_覆寫為注入的日期與行事曆() async {
        // Given
        var staleCalendar = TestDependencies.fixedCalendar
        staleCalendar.firstWeekday = 2
        var initial = DashboardFeature.State()
        initial.dateContext = DashboardDateContext(
            now: Date(timeIntervalSince1970: 1_777_420_800),
            calendar: staleCalendar
        )
        let store = TestStore(initialState: initial) {
            DashboardFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.task)) {
            $0.dateContext = DashboardDateContext(
                now: Date(timeIntervalSince1970: 1_777_507_200),
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.delegate.refresh)
    }

    /// 驗證載入失敗且有舊日期脈絡時點擊重試，`dateContext` 覆寫為注入的現在時間與行事曆，並送出 `delegate(.refresh)`
    ///
    /// - Note: 舊日期與舊行事曆的設定同畫面出現測試，差別是初始狀態為載入失敗
    /// - Note: 覆寫的時點在送出 `delegate(.refresh)` 之前
    @Test
    func retryTapped_載入失敗且有舊日期脈絡時點擊重試_覆寫為注入的日期與行事曆() async {
        // Given
        var staleCalendar = TestDependencies.fixedCalendar
        staleCalendar.firstWeekday = 2
        var initial = DashboardFeature.State()
        initial.loadState = .failed("網路連線失敗")
        initial.dateContext = DashboardDateContext(
            now: Date(timeIntervalSince1970: 1_777_420_800),
            calendar: staleCalendar
        )
        let store = TestStore(initialState: initial) {
            DashboardFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.retryTapped)) {
            $0.dateContext = DashboardDateContext(
                now: Date(timeIntervalSince1970: 1_777_507_200),
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.delegate.refresh)
    }

    /// 驗證載入失敗後隔天早上重試時，`dateContext` 在送出 `delegate(.refresh)` 前改為重試當下，統計只計入 5 月的訂單
    ///
    /// - Note: 對應規格範例「retrying the next morning」
    /// - Note: 行事曆固定 UTC；記錄 2026-05-12 10:00 後載入失敗，2026-05-13 09:00 重試
    /// - Note: 5 月與 4 月各一筆訂單，只有 5 月那筆計入本月營收與單數
    @Test
    func retryTapped_載入失敗隔天早上重試_記錄日期先更新且月份數字取五月() async {
        // Given
        var initial = DashboardFeature.State()
        initial.loadState = .failed("網路連線失敗")
        initial.orders = [
            DashboardStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: DashboardStatsTestSupport.utcDate(month: 5, day: 3),
                charged: 1_000
            ),
            DashboardStatsTestSupport.makeOrder(
                id: "B",
                status: .delivered,
                date: DashboardStatsTestSupport.utcDate(month: 4, day: 28),
                charged: 500
            ),
        ]
        initial.dateContext = DashboardDateContext(
            now: DashboardStatsTestSupport.utcDate(month: 5, day: 12, hour: 10),
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            DashboardFeature()
        } withDependencies: {
            $0.date = .constant(DashboardStatsTestSupport.utcDate(month: 5, day: 13, hour: 9))
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.retryTapped)) {
            $0.dateContext = DashboardDateContext(
                now: DashboardStatsTestSupport.utcDate(month: 5, day: 13, hour: 9),
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.delegate.refresh)
        #expect(store.state.stats?.revenue == 1_000)
        #expect(store.state.stats?.orderCount == 1)
    }
}
