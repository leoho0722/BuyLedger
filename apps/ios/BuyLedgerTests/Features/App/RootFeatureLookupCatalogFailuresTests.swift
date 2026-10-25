//
//  RootFeatureLookupCatalogFailuresTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 TestStore 驗證重新整理時部分主檔讀取失敗，目錄如何保留已有內容
@MainActor
struct RootFeatureLookupCatalogFailuresTests {

    /// 驗證上次付款方式讀取失敗、目錄未完成載入時重新整理，四種主檔各重讀一次；付款方式再次失敗時維持空值、其餘主檔照常更新，目錄仍不標記為已載入，且已載入的訂單不重讀
    @Test
    func insights_上次付款方式讀取失敗後重新整理_重讀四種並保留空付款方式() async {
        // Given
        var initial = RootFeatureTestSupport.makeIsolatedRootState()
        initial.more.catalog.$catalog.withLock {
            $0 = LookupCatalog(categories: ["服飾"])
        }
        initial.orders.load.$hasLoaded.withLock {
            $0 = true
        }
        initial.dashboard.loadState = .loaded
        initial.insights.loadState = .loaded
        let reads = LockIsolated<[LookupKind]>([])
        let catalogRelease = AsyncStream<Void>.makeStream()
        let fetchItems: LookupService.FetchItems = { kind throws(PersistenceError) in
            var iterator = catalogRelease.stream.makeAsyncIterator()
            _ = await iterator.next()
            reads.withValue {
                $0.append(kind)
            }
            guard kind != .paymentMethod else {
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "lookup")
                )
            }
            return kind == .category ? LookupCatalog(categories: ["服飾"]) : LookupCatalog()
        }
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.lookupService.fetchItems = fetchItems
        }

        // When
        await store.send(.insights(.delegate(.refresh)))

        // Then
        await RootFeatureTestSupport.receiveCatalogRequested(in: store)
        catalogRelease.continuation.finish()
        await RootFeatureTestSupport.receiveCatalogResponse(
            in: store,
            catalogs: [
                .orderSource: LookupCatalog(
                    orderSources: [],
                    categories: [],
                    paymentMethods: [],
                    reconciliationStatuses: []
                ),
                .category: LookupCatalog(categories: ["服飾"]),
                .reconciliationStatus: LookupCatalog(
                    orderSources: [],
                    categories: [],
                    paymentMethods: [],
                    reconciliationStatuses: []
                ),
            ],
            expectedCatalog: LookupCatalog(categories: ["服飾"]),
            hasLoaded: false,
            shouldLoadOrders: false
        )
        await store.finish()
        #expect(reads.value.filter { $0 == .orderSource }.count == 1)
        #expect(reads.value.filter { $0 == .category }.count == 1)
        #expect(reads.value.filter { $0 == .paymentMethod }.count == 1)
        #expect(reads.value.filter { $0 == .reconciliationStatus }.count == 1)
        #expect(store.state.more.catalog.catalog.categories == ["服飾"])
        #expect(store.state.more.catalog.catalog.paymentMethods == [])
        #expect(store.state.orders.load.hasLoaded)
    }

    /// 驗證重新整理時成功來源取代舊值、失敗的類別與對帳狀態保留，訂單成功或失敗都不回復已更新的目錄
    ///
    /// - Parameter shouldFailOrders: 是否讓訂單讀取失敗
    @Test(arguments: [false, true])
    func dashboard_重新整理時部分主檔失敗_只更新成功來源並獨立處理訂單(shouldFailOrders: Bool) async {
        // Given
        let initial = RootFeatureTestSupport.makeIsolatedRootState()
        let existing = LedgerOrder.fixture(id: "existing", date: TestDependencies.fixedNow)
        initial.orders.$orders.withLock {
            $0 = [existing]
        }
        initial.more.catalog.$catalog.withLock {
            $0.orderSources = ["舊來源"]
            $0.categories = ["既有類別"]
            $0.reconciliationStatuses = ["既有狀態"]
        }
        let reads = LockIsolated<[LookupKind]>([])
        let orderReads = LockIsolated(0)
        let catalogRelease = AsyncStream<Void>.makeStream()
        let orderRelease = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            RootFeatureTestSupport.stubCatalogAndOrders(
                &$0,
                catalogs: [.orderSource: LookupCatalog()],
                failingKinds: [.category, .paymentMethod, .reconciliationStatus],
                catalogRelease: catalogRelease.stream,
                orderRelease: orderRelease.stream,
                reads: reads,
                orderReads: orderReads,
                shouldFailOrders: shouldFailOrders
            )
        }

        // When
        await store.send(.dashboard(.delegate(.refresh)))

        // Then
        await RootFeatureTestSupport.receiveCatalogRequested(in: store)
        #expect(orderReads.value == 0)
        catalogRelease.continuation.finish()
        await RootFeatureTestSupport.receiveCatalogResponse(
            in: store,
            catalogs: [
                .orderSource: LookupCatalog(
                    orderSources: [],
                    categories: [],
                    paymentMethods: [],
                    reconciliationStatuses: []
                ),
            ],
            expectedCatalog: LookupCatalog(categories: ["既有類別"], reconciliationStatuses: ["既有狀態"]),
            hasLoaded: false
        )
        await RootFeatureTestSupport.receiveEmptyOrders(
            in: store,
            release: orderRelease.continuation,
            shouldFail: shouldFailOrders
        )
        await store.finish()
        #expect(store.state.more.catalog.catalog.orderSources == [])
        #expect(store.state.more.catalog.catalog.categories == ["既有類別"])
        #expect(store.state.more.catalog.catalog.reconciliationStatuses == ["既有狀態"])
        #expect(store.state.more.catalog.hasLoaded == false)
        #expect(reads.value.count == 4)
        #expect(orderReads.value == 1)
        if shouldFailOrders {
            #expect(store.state.orders.orders == [existing])
            #expect(store.state.orders.load.hasLoaded == false)
        } else {
            #expect(store.state.orders.orders == [])
            #expect(store.state.orders.load.hasLoaded)
        }
    }
}
