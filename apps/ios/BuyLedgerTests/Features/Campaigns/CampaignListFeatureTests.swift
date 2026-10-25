//
//  CampaignListFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignListFeature` 的單元測試，以 TestStore 逐步驗證日期脈絡更新與載入請求
@MainActor
struct CampaignListFeatureTests {

    /// 驗證列表出現時更新日期脈絡並送出載入請求，不改動載入中與已載入的旗標
    @Test
    func task_列表出現_更新日期脈絡並委派載入() async {
        // Given
        let store = TestStore(initialState: CampaignListFeatureTestSupport.makeState()) {
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
        #expect(store.state.hasLoaded == false)
        #expect(store.state.isLoading == false)
    }

    /// 驗證載入失敗後按下重試，只更新日期脈絡並送出載入請求，列表不清除唯讀的錯誤訊息
    @Test
    func retryTapped_載入失敗_委派載入並保留唯讀錯誤() async {
        // Given
        let initial = CampaignListFeatureTestSupport.makeState()
        initial.$errorMessage = SharedReader(value: "campaigns.list.message.campaignsLoadedTry")
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
        #expect(store.state.loadState == .failed("campaigns.list.message.campaignsLoadedTry"))
    }
}
