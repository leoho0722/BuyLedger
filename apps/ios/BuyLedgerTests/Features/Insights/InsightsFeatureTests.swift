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

/// `InsightsFeature` 的單元測試，以 TestStore 核對期間選取及重新整理、開團與類別查看請求
@MainActor
struct InsightsFeatureTests {

    /// 驗證切換分析區間為 `.thirtyDays` 後，`insightsDateRange` 保留所選期間
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

    /// 驗證畫面出現送出 `.view(.task)` 時，`dateContext` 記錄注入的現在時間與行事曆，並轉成 `delegate(.refresh)` 交給根功能
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

    /// 驗證點擊重試時，`dateContext` 記錄注入的現在時間與行事曆，並轉成 `delegate(.refresh)`，與畫面出現相同
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

    /// 驗證點擊毛利排行中的開團時，把開團名稱以 `delegate(.campaignTapped)` 交給根功能，State 維持不變
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

    /// 驗證點擊類別排行中的類別時，把類別名稱以 `delegate(.categoryTapped)` 交給根功能，State 維持不變
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
