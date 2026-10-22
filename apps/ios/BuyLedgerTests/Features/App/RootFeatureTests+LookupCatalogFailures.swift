//
//  RootFeatureTests+LookupCatalogFailures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 付款方式讀取失敗仍載入訂單，下次請求必須重讀四種主檔
    @Test
    func insights_重新整理時付款方式讀取失敗_保留空付款方式並於下次重讀四種() async {
        // Given
        let reads = LockIsolated<[LookupKind]>([])
        let orderReads = LockIsolated(0)
        let catalogRelease = AsyncStream<Void>.makeStream()
        let orderRelease = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: Self.makeIsolatedRootState()) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            Self.stubCatalogAndOrders(
                &$0,
                catalogs: [.category: LookupCatalog(categories: ["服飾"])],
                failingKinds: [.paymentMethod],
                catalogRelease: catalogRelease.stream,
                orderRelease: orderRelease.stream,
                reads: reads,
                orderReads: orderReads
            )
        }

        await store.send(.dashboard(.delegate(.refresh)))
        await Self.receiveCatalogRequested(in: store)
        catalogRelease.continuation.finish()
        await Self.receiveCatalogResponse(
            in: store,
            catalogs: [
                .orderSource: LookupCatalog(),
                .category: LookupCatalog(categories: ["服飾"]),
                .reconciliationStatus: LookupCatalog(),
            ],
            expectedCatalog: LookupCatalog(categories: ["服飾"]),
            hasLoaded: false
        )
        await Self.receiveEmptyOrders(in: store, release: orderRelease.continuation)

        // When
        await store.send(.insights(.delegate(.refresh)))

        // Then
        await Self.receiveCatalogRequested(in: store)
        await Self.receiveCatalogResponse(
            in: store,
            catalogs: [
                .orderSource: LookupCatalog(),
                .category: LookupCatalog(categories: ["服飾"]),
                .reconciliationStatus: LookupCatalog(),
            ],
            expectedCatalog: LookupCatalog(categories: ["服飾"]),
            hasLoaded: false,
            shouldLoadOrders: false
        )
        await store.finish()
        #expect(reads.value.filter { $0 == .orderSource }.count == 2)
        #expect(reads.value.filter { $0 == .category }.count == 2)
        #expect(reads.value.filter { $0 == .paymentMethod }.count == 2)
        #expect(reads.value.filter { $0 == .reconciliationStatus }.count == 2)
        #expect(orderReads.value == 1)
        #expect(store.state.more.catalog.catalog.categories == ["服飾"])
        #expect(store.state.more.catalog.catalog.paymentMethods == [])
        #expect(store.state.orders.load.hasLoaded)
    }

    /// 成功的空來源取代舊值，失敗的類別與對帳狀態保留，訂單成功與失敗都不回復目錄
    ///
    /// - Parameter shouldFailOrders: 是否讓訂單讀取失敗
    @Test(arguments: [false, true])
    func dashboard_重新整理時部分主檔失敗_只更新成功來源並獨立處理訂單(shouldFailOrders: Bool) async {
        // Given
        let initial = Self.makeIsolatedRootState()
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
            Self.stubCatalogAndOrders(
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
        await Self.receiveCatalogRequested(in: store)
        #expect(orderReads.value == 0)
        catalogRelease.continuation.finish()
        await Self.receiveCatalogResponse(
            in: store,
            catalogs: [.orderSource: LookupCatalog()],
            expectedCatalog: LookupCatalog(categories: ["既有類別"], reconciliationStatuses: ["既有狀態"]),
            hasLoaded: false
        )
        await Self.receiveEmptyOrders(
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
