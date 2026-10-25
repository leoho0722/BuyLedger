//
//  CampaignLoadFeatureRequestsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignLoadFeature` 的單元測試，以 TestStore 逐步驗證重複請求的去重與失敗後的重新讀取
@MainActor
struct CampaignLoadFeatureRequestsTests {

    /// 驗證第一次讀取尚未完成時再次請求不重新讀取，讀取完成後只自動結單一次
    @Test
    func loadRequested_第一次讀取暫停時重複請求_只讀取與結單一次() async {
        // Given
        let overdue = Campaign.fixture(
            id: "past",
            name: "三月日本團",
            closeDate: Date(timeIntervalSince1970: 1_776_643_200),
            status: .ongoing
        )
        let closed = Campaign(
            id: "past",
            name: "三月日本團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: Date(timeIntervalSince1970: 1_776_643_200),
            status: .closed,
            settledDate: nil,
            notes: ""
        )
        let reads = LockIsolated(0)
        let saved = LockIsolated<[Campaign]>([])
        let started = AsyncStream<Void>.makeStream()
        let release = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: CampaignLoadFeatureTestSupport.makeState()) {
            CampaignLoadFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                reads.withValue {
                    $0 += 1
                }
                started.continuation.yield(())
                var iterator = release.stream.makeAsyncIterator()
                _ = await iterator.next()
                return [overdue]
            }
            $0.campaignService.saveCampaign = { campaign in
                saved.withValue {
                    $0.append(campaign)
                }
            }
        }
        await store.send(.loadRequested) {
            $0.$isLoading.withLock {
                $0 = true
            }
        }

        // When
        await store.send(.loadRequested)

        // Then
        var iterator = started.stream.makeAsyncIterator()
        _ = await iterator.next()
        #expect(reads.value == 1)
        #expect(store.state.isLoading)
        release.continuation.finish()
        started.continuation.finish()
        await store.receive(\.campaignsResponse.success) {
            $0.$isLoading.withLock {
                $0 = false
            }
            $0.$hasLoaded.withLock {
                $0 = true
            }
            $0.$campaigns.withLock {
                $0 = [closed]
            }
        }
        await store.receive(\.autoCloseResponse)
        await store.finish()
        #expect(reads.value == 1)
        #expect(saved.value.count == 1)
        #expect(saved.value == [closed])
    }

    /// 驗證首次讀取失敗後再次請求，會先清除錯誤訊息，再重新讀取成功
    @Test
    func loadRequested_首次讀取失敗後再次請求_重新讀取成功() async {
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
        let calls = LockIsolated(0)
        let fetch: CampaignService.FetchCampaigns = {
            calls.withValue {
                $0 += 1
            }
            return [campaign]
        }
        let initial = CampaignLoadFeatureTestSupport.makeState()
        initial.$isLoading.withLock {
            $0 = false
        }
        initial.$hasLoaded.withLock {
            $0 = false
        }
        initial.$errorMessage.withLock {
            $0 = "campaigns.list.message.campaignsLoadedTry"
        }
        let store = TestStore(initialState: initial) {
            CampaignLoadFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = fetch
        }

        // When
        await store.send(.loadRequested) {
            $0.$isLoading.withLock {
                $0 = true
            }
            $0.$errorMessage.withLock {
                $0 = nil
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
        #expect(calls.value == 1)
        #expect(store.state.errorMessage == nil)
    }
}
