//
//  CampaignLoadFeatureTests+Requests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignLoadFeatureTests {

    /// 第一次讀取暫停時再請求不重讀，釋放後只自動結單一次
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
        let store = TestStore(initialState: Self.makeState()) {
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
        var iterator = started.stream.makeAsyncIterator()
        _ = await iterator.next()

        // When
        await store.send(.loadRequested)

        // Then
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

    /// 第一次失敗後再請求會清除錯誤並重新讀取
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
            let count = calls.withValue {
                $0 += 1
                return $0
            }
            if count == 1 {
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "first read")
                )
            }
            return [campaign]
        }
        let store = TestStore(initialState: Self.makeState()) {
            CampaignLoadFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = fetch
        }
        await store.send(.loadRequested) {
            $0.$isLoading.withLock {
                $0 = true
            }
        }
        await store.receive(\.campaignsResponse.failure) {
            $0.$isLoading.withLock {
                $0 = false
            }
            $0.$errorMessage.withLock {
                $0 = "開團載入失敗，請稍後再試。"
            }
        }
        await store.receive(\.delegate.loadFailed)

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
        #expect(calls.value == 2)
        #expect(store.state.errorMessage == nil)
    }
}
