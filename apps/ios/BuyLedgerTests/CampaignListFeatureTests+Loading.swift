//
//  CampaignListFeatureTests+Loading.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignListFeatureTests {

    /// 載入中仍向容器請求，去重由載入子層統一處理
    @Test
    func task_載入中再次出現_委派載入而不改唯讀旗標() async {
        // Given
        let initial = Self.makeState()
        initial.$isLoading = SharedReader(value: true)
        let store = TestStore(initialState: initial) {
            CampaignListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.task)) {
            $0.dateContext = CampaignDateContext(
                now: Date(timeIntervalSince1970: 1_777_507_200),
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.delegate.loadRequested)
        await store.finish()
        #expect(store.state.isLoading)
        #expect(store.state.hasLoaded == false)
    }

    /// 重試在載入中仍送出請求，列表不自行清除讀取旗標
    @Test
    func retryTapped_載入中重試_委派載入而不改唯讀旗標() async {
        // Given
        let initial = Self.makeState()
        initial.$isLoading = SharedReader(value: true)
        let store = TestStore(initialState: initial) {
            CampaignListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.retryTapped)) {
            $0.dateContext = CampaignDateContext(
                now: Date(timeIntervalSince1970: 1_777_507_200),
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.delegate.loadRequested)
        await store.finish()
        #expect(store.state.isLoading)
    }
}
