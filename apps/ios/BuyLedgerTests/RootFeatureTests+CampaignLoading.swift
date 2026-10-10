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
            Self.suppressCampaignLoadingLookups(&$0)
        }
        await store.send(.view(.task)) {
            $0.campaigns.load.$isLoading.withLock {
                $0 = true
            }
            $0.orders.load.$isLoading.withLock {
                $0 = true
            }
        }
        await Self.receiveLaunchLoadRequests(in: store)

        // When
        await store.send(.orders(.loadRequested))

        // Then
        await store.receive(\.orders.load.loadRequested)
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
        #expect(saved.value.count == 1)
        #expect(saved.value == [closed])
        #expect(store.state.orders.campaigns == [closed])
        #expect(store.state.dashboard.campaigns == [closed])
        #expect(store.state.insights.campaigns == [closed])
    }
}

// MARK: - Private Method

private extension RootFeatureTests {

    /// 讓訂單來源、類別、付款方式與對帳狀態的讀取一律失敗，使本測試只核對開團的讀寫
    ///
    /// - Parameter dependencies: 本測試的依賴集合
    static func suppressCampaignLoadingLookups(_ dependencies: inout DependencyValues) {
        let sources: OrderSourceService.FetchOrderSources = {
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "lookup"))
        }
        let categories: CategoryService.FetchCategories = {
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "lookup"))
        }
        let methods: PaymentMethodService.FetchPaymentMethodInfos = {
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "lookup"))
        }
        let statuses: ReconciliationStatusService.FetchReconciliationStatuses = {
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "lookup"))
        }
        dependencies.orderSourceService.fetchOrderSources = sources
        dependencies.categoryService.fetchCategories = categories
        dependencies.paymentMethodService.fetchPaymentMethodInfos = methods
        dependencies.reconciliationStatusService.fetchReconciliationStatuses = statuses
    }
}
