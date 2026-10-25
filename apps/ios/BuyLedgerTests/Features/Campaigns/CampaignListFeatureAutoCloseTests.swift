//
//  CampaignListFeatureAutoCloseTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignListFeature` 的單元測試，以 TestStore 逐步驗證共用開團已結單時的載入請求
@MainActor
struct CampaignListFeatureAutoCloseTests {

    /// 驗證共用開團已結單時，列表不改動共用資料，只送出載入請求
    @Test
    func task_共用開團已結單_保持共用資料並委派載入() async {
        // Given
        let closed = Campaign(
            id: "past",
            name: "測試開團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: nil,
            status: .closed,
            settledDate: nil,
            notes: ""
        )
        let initial = CampaignListFeatureTestSupport.makeState(campaigns: [closed])
        initial.$hasLoaded = SharedReader(value: true)
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
        #expect(store.state.campaigns == [closed])
        #expect(store.state.loadState == .loaded)
    }
}
