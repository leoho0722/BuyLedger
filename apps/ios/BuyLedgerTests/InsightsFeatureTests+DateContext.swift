//
//  InsightsFeatureTests+DateContext.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension InsightsFeatureTests {

    /// 畫面再次出現時，以注入的現在時間與行事曆覆寫先前記錄的日期脈絡
    ///
    /// - Note: 舊日期早於注入值一天；舊行事曆的週起點為星期一，與注入值不同
    @Test
    func task_舊日期脈絡存在時畫面出現_覆寫為注入的日期與行事曆() async {
        // Given
        var staleCalendar = TestDependencies.fixedCalendar
        staleCalendar.firstWeekday = 2
        var initial = InsightsFeature.State()
        initial.dateContext = InsightsDateContext(
            now: Date(timeIntervalSince1970: 1_777_420_800),
            calendar: staleCalendar
        )
        let store = TestStore(initialState: initial) {
            InsightsFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.task)) {
            $0.dateContext = InsightsDateContext(
                now: Date(timeIntervalSince1970: 1_777_507_200),
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.delegate.refresh)
    }

    /// 載入失敗後點擊重試，同樣以注入的現在時間與行事曆覆寫舊的日期脈絡，再轉成 `refresh` 委派
    ///
    /// - Note: 舊日期與舊行事曆的設定與畫面出現測試相同，起點為載入失敗
    /// - Note: 覆寫的時點在送出委派之前
    @Test
    func retryTapped_載入失敗且有舊日期脈絡時點擊重試_覆寫為注入的日期與行事曆() async {
        // Given
        var staleCalendar = TestDependencies.fixedCalendar
        staleCalendar.firstWeekday = 2
        var initial = InsightsFeature.State()
        initial.loadState = .failed("網路連線失敗")
        initial.dateContext = InsightsDateContext(
            now: Date(timeIntervalSince1970: 1_777_420_800),
            calendar: staleCalendar
        )
        let store = TestStore(initialState: initial) {
            InsightsFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.retryTapped)) {
            $0.dateContext = InsightsDateContext(
                now: Date(timeIntervalSince1970: 1_777_507_200),
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.delegate.refresh)
    }
}
