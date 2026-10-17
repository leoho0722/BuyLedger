//
//  InsightsFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證分析功能
@MainActor
struct InsightsFeatureTests {

    /// 分析區間切換後保留在 feature state 內
    @Test
    func binding_切換分析區間_保留所選期間() async {
        // Given
        let store = TestStore(initialState: InsightsFeature.State()) {
            InsightsFeature()
        }

        // When
        await store.send(\.binding.insightsDateRange, .thirtyDays) {
            $0.insightsDateRange = .thirtyDays
        }

        // Then
        #expect(store.state.insightsDateRange == .thirtyDays)
    }

    /// 畫面出現時送出 `.view(.task)`，記錄注入的日期脈絡並轉成 `refresh` 委派交給根功能
    @Test
    func task_畫面出現_轉成refresh委派() async {
        // Given
        let store = TestStore(initialState: InsightsFeature.State()) {
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

    /// 載入失敗畫面的重試鈕與畫面出現相同，同樣記錄日期脈絡並轉成 `refresh` 委派
    @Test
    func retryTapped_點擊重試_轉成refresh委派() async {
        // Given
        let store = TestStore(initialState: InsightsFeature.State()) {
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

    /// 點擊毛利排行的某一團，把開團名稱交給根功能，不改動狀態
    @Test
    func campaignTapped_點擊毛利排行開團_轉成帶開團名稱的委派() async {
        // Given
        let store = TestStore(initialState: InsightsFeature.State()) {
            InsightsFeature()
        }

        // When
        await store.send(.view(.campaignTapped("四月韓國團")))

        // Then
        await store.receive(\.delegate.campaignTapped, "四月韓國團")
    }

    /// 點擊類別排行的某個類別，把類別名稱交給根功能，不改動狀態
    @Test
    func categoryTapped_點擊類別排行_轉成帶類別名稱的委派() async {
        // Given
        let store = TestStore(initialState: InsightsFeature.State()) {
            InsightsFeature()
        }

        // When
        await store.send(.view(.categoryTapped("美妝")))

        // Then
        await store.receive(\.delegate.categoryTapped, "美妝")
    }
}
