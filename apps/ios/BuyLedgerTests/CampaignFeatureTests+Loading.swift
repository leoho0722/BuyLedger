//
//  CampaignFeatureTests+Loading.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 首次讀取失敗後，列表再次出現或點重試會經容器重新讀取
    ///
    /// - Parameter interaction: 列表要求載入的入口
    @Test(arguments: [CampaignListFeature.Action.View.task, .retryTapped])
    func list_首次讀取失敗後再請求_重讀並顯示開團(interaction: CampaignListFeature.Action.View) async {
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
        let responses = AsyncStream<Result<[Campaign], PersistenceError>>.makeStream()
        let calls = LockIsolated(0)
        let fetch: CampaignService.FetchCampaigns = { () throws(PersistenceError) in
            calls.withValue {
                $0 += 1
            }
            var iterator = responses.stream.makeAsyncIterator()
            guard let result = await iterator.next() else {
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "stream ended")
                )
            }
            return try result.get()
        }
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = fetch
        }
        await store.send(.loadRequested) {
            $0.load.$isLoading.withLock {
                $0 = true
            }
        }
        await store.receive(\.load.loadRequested)
        let error = TestDependencies.makeUnderlyingError(message: "first")
        responses.continuation.yield(.failure(.fetchFailed(underlying: error)))
        await store.receive(\.load.campaignsResponse.failure) {
            $0.load.$isLoading.withLock {
                $0 = false
            }
            $0.load.$errorMessage.withLock {
                $0 = "campaigns.list.message.campaignsLoadedTry"
            }
        }
        await store.receive(\.load.delegate.loadFailed)

        // When
        await store.send(.list(.view(interaction))) {
            $0.list.dateContext = CampaignDateContext(
                now: Date(timeIntervalSince1970: 1_777_507_200),
                calendar: TestDependencies.fixedCalendar
            )
            $0.load.$isLoading.withLock {
                $0 = true
            }
            $0.load.$errorMessage.withLock {
                $0 = nil
            }
        }

        // Then
        await store.receive(\.list.delegate.loadRequested)
        await store.receive(\.load.loadRequested)
        responses.continuation.yield(.success([campaign]))
        responses.continuation.finish()
        await store.receive(\.load.campaignsResponse.success) {
            $0.load.$isLoading.withLock {
                $0 = false
            }
            $0.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
        }
        await store.finish()
        #expect(calls.value == 2)
        #expect(store.state.list.campaigns == [campaign])
        #expect(store.state.list.loadState == .loaded)
        #expect(store.state.list.errorMessage == nil)
    }
}
