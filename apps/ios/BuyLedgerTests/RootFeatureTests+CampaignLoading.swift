//
//  RootFeatureTests+CampaignLoading.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 啟動載入與訂單分頁載入同時進行時，過期的開團只自動結單並寫回一次
    @Test
    func orders_啟動與訂單分頁同時載入_過期開團只結單一次() async {
        // Given
        let overdue = Campaign.fixture(
            id: "march",
            name: "三月日本團",
            closeDate: Date(timeIntervalSince1970: 1_776_643_200),
            status: .ongoing
        )
        var closed = overdue
        closed.status = .closed
        let reads = LockIsolated(0)
        let saved = LockIsolated<[Campaign]>([])
        let campaignRelease = AsyncStream<Void>.makeStream()
        let orderRelease = AsyncStream<Void>.makeStream()
        let currencyRelease = AsyncStream<Void>.makeStream()
        let catalogRelease = AsyncStream<Void>.makeStream()
        let lookupReads = LockIsolated(0)
        let store = TestStore(initialState: Self.makeIsolatedRootState()) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                let call = reads.withValue {
                    $0 += 1
                    return $0
                }
                if call == 1 {
                    var iterator = campaignRelease.stream.makeAsyncIterator()
                    _ = await iterator.next()
                }
                return [overdue]
            }
            $0.campaignService.saveCampaign = { campaign in
                saved.withValue {
                    $0.append(campaign)
                }
            }
            $0.orderService.fetchOrders = {
                var iterator = orderRelease.stream.makeAsyncIterator()
                _ = await iterator.next()
                return []
            }
            $0.currencyMetadataService.refreshIfStale = { _ in
                var iterator = currencyRelease.stream.makeAsyncIterator()
                _ = await iterator.next()
                return false
            }
            $0.currencyMetadataService.fetchCodes = {
                []
            }
            $0.significantTimeChangeService.changes = {
                AsyncStream {
                    $0.finish()
                }
            }
            Self.suppressCampaignLoadingLookups(
                &$0,
                release: catalogRelease.stream,
                reads: lookupReads
            )
        }
        await store.send(.view(.task)) {
            $0.campaigns.load.$isLoading.withLock {
                $0 = true
            }
        }
        await Self.receiveLaunchCatalogRequests(in: store)
        catalogRelease.continuation.finish()
        await store.receive(\.more.catalog.catalogResponse, [:]) {
            $0.more.catalog.isLoading = false
            $0.orders.load.$isLoading.withLock {
                $0 = true
            }
        }
        await Self.receiveCatalogFinished(in: store)

        // When
        await store.send(.orders(.list(.view(.task)))) {
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.orders.list.delegate.loadRequested)
        await store.receive(\.orders.delegate.loadRequested)
        await store.receive(\.more.catalogLoadRequested)
        await store.receive(\.more.catalog.loadRequested) {
            $0.more.catalog.isLoading = true
        }
        await store.receive(\.more.catalog.catalogResponse, [:]) {
            $0.more.catalog.isLoading = false
        }
        await Self.receiveCatalogFinished(in: store)
        campaignRelease.continuation.finish()
        await store.receive(\.campaigns.load.campaignsResponse.success) {
            $0.campaigns.load.$isLoading.withLock {
                $0 = false
            }
            $0.campaigns.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.campaigns.$campaigns.withLock {
                $0 = [closed]
            }
            $0.orders.campaigns = [closed]
            $0.dashboard.campaigns = [closed]
            $0.insights.campaigns = [closed]
        }
        await store.receive(\.campaigns.load.autoCloseResponse)
        orderRelease.continuation.finish()
        await store.receive(\.orders.load.loadResponse) {
            $0.orders.load.$isLoading.withLock {
                $0 = false
            }
            $0.orders.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.dashboard.loadState = .loaded
            $0.insights.loadState = .loaded
        }
        currencyRelease.continuation.finish()
        await store.receive(\.launch.currencyCodesResponse.success, [])
        await store.finish()
        #expect(reads.value == 1)
        #expect(lookupReads.value == 8)
        #expect(saved.value.count == 1)
        #expect(saved.value == [closed])
        #expect(store.state.orders.campaigns == [closed])
        #expect(store.state.dashboard.campaigns == [closed])
        #expect(store.state.insights.campaigns == [closed])
    }
}

// MARK: - Private Method

private extension RootFeatureTests {

    /// 讓四種主檔讀取一律失敗，並記錄實際讀取次數以驗證重試
    ///
    /// - Parameters:
    ///   - dependencies: 本測試的依賴集合
    ///   - release: 控制主檔讀取何時完成的串流
    ///   - reads: 主檔讀取次數
    static func suppressCampaignLoadingLookups(
        _ dependencies: inout DependencyValues,
        release: AsyncStream<Void>,
        reads: LockIsolated<Int>
    ) {
        let fetchItems: LookupService.FetchItems = { _ throws(PersistenceError) in
            reads.withValue {
                $0 += 1
            }
            var iterator = release.makeAsyncIterator()
            _ = await iterator.next()
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "lookup"))
        }
        dependencies.lookupService.fetchItems = fetchItems
    }
}
