//
//  CampaignLoadFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignLoadFeature` 的單元測試，以 TestStore 逐步驗證載入流程、失敗錯誤回報與已載入時略過讀取
@MainActor
struct CampaignLoadFeatureTests {

    /// 驗證讀取成功時，共用的開團清單更新，載入中旗標清為 `false`、已載入旗標設為 `true`
    @Test
    func loadRequested_讀取成功_共用清單與載入狀態更新() async {
        // Given
        let campaign = Campaign(
            id: "C1",
            name: "測試開團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let store = TestStore(initialState: CampaignLoadFeatureTestSupport.makeState()) {
            CampaignLoadFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                [campaign]
            }
        }

        // When
        await store.send(.loadRequested) {
            $0.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.campaignsResponse.success) {
            $0.$isLoading.withLock {
                $0 = false
            }
            $0.$hasLoaded.withLock {
                $0 = true
            }
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
        }
        await store.finish()
        #expect(store.state.campaigns == [campaign])
    }

    /// 驗證讀取失敗時，共用清單保留原值，已載入旗標維持 `false` 以便下次重試，並送出載入失敗的通知
    @Test
    func loadRequested_讀取失敗_保留共用清單並委派錯誤() async {
        // Given
        let campaign = Campaign(
            id: "C1",
            name: "測試開團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let failingFetch: CampaignService.FetchCampaigns = { () throws(PersistenceError) in
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(
            initialState: CampaignLoadFeatureTestSupport.makeState(campaigns: [campaign])
        ) {
            CampaignLoadFeature()
        } withDependencies: {
            $0.campaignService.fetchCampaigns = failingFetch
        }

        // When
        await store.send(.loadRequested) {
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
            $0.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.campaignsResponse.failure) {
            $0.$isLoading.withLock {
                $0 = false
            }
            $0.$errorMessage.withLock {
                $0 = "campaigns.list.message.campaignsLoadedTry"
            }
        }
        await store.receive(\.delegate.loadFailed)
        await store.finish()
        #expect(store.state.campaigns == [campaign])
        #expect(store.state.hasLoaded == false)
        #expect(store.state.isLoading == false)
    }

    /// 驗證已載入後再次請求時略過讀取，載入中旗標維持 `false`
    @Test
    func loadRequested_已載入_略過讀取() async {
        // Given
        let initial = CampaignLoadFeatureTestSupport.makeState()
        initial.$hasLoaded.withLock {
            $0 = true
        }
        let store = TestStore(initialState: initial) {
            CampaignLoadFeature()
        }

        // When
        await store.send(.loadRequested)

        // Then
        await store.finish()
        #expect(store.state.hasLoaded)
        #expect(store.state.isLoading == false)
    }
}
