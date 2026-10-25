//
//  CampaignListFeatureLoadingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignListFeature` 的單元測試，以 TestStore 逐步驗證載入中的 `task` 與重試請求
@MainActor
struct CampaignListFeatureLoadingTests {

    /// 驗證載入中再次出現時，仍送出載入請求，唯讀的載入中旗標不變
    @Test
    func task_載入中再次出現_委派載入而不改唯讀旗標() async {
        // Given
        let initial = CampaignListFeatureTestSupport.makeState()
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

    /// 驗證載入中按下重試時，仍送出載入請求，唯讀的載入中旗標不變
    @Test
    func retryTapped_載入中重試_委派載入而不改唯讀旗標() async {
        // Given
        let initial = CampaignListFeatureTestSupport.makeState()
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
