//
//  RootFeatureTests+LookupCatalog.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 啟動先完成四種主檔讀取，再開始訂單讀取
    @Test
    func task_主檔尚未完成_等待四種讀取後才載入訂單() async {
        // Given
        let initial = Self.makeIsolatedRootState()
        initial.campaigns.load.$hasLoaded.withLock {
            $0 = true
        }
        initial.more.catalog.$catalog.withLock {
            $0.orderSources = ["舊來源"]
            $0.categories = ["舊類別"]
            $0.reconciliationStatuses = ["舊狀態"]
        }
        let catalogReader = SharedReader(initial.more.catalog.$catalog)
        let reads = LockIsolated<[LookupKind]>([])
        let orderReads = LockIsolated(0)
        let catalogRelease = AsyncStream<Void>.makeStream()
        let orderRelease = AsyncStream<Void>.makeStream()
        let currencyRelease = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            Self.stubCatalogAndOrders(
                &$0,
                catalogs: [
                    .orderSource: LookupCatalog(orderSources: ["IG"]),
                    .category: LookupCatalog(categories: ["服飾", "美妝"]),
                    .paymentMethod: LookupCatalog(paymentMethods: [
                        PaymentMethodInfo(
                            name: "orders.edit.label.bankTransfer",
                            isCardless: false,
                            isBankTransfer: true,
                            isCashOnDelivery: false
                        ),
                    ]),
                    .reconciliationStatus: LookupCatalog(reconciliationStatuses: ["待對帳"]),
                ],
                catalogRelease: catalogRelease.stream,
                orderRelease: orderRelease.stream,
                reads: reads,
                orderReads: orderReads
            )
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
        }

        // When
        await store.send(.view(.task))

        // Then
        await Self.receiveLaunchCatalogRequests(in: store)
        #expect(orderReads.value == 0)
        #expect(store.state.orders.load.isLoading == false)
        #expect(store.state.more.catalog.catalog.categories == ["舊類別"])
        catalogRelease.continuation.finish()
        await Self.receiveCatalogResponse(
            in: store,
            catalogs: [
                .orderSource: LookupCatalog(orderSources: ["IG"]),
                .category: LookupCatalog(categories: ["服飾", "美妝"]),
                .paymentMethod: LookupCatalog(paymentMethods: [
                    PaymentMethodInfo(
                        name: "orders.edit.label.bankTransfer",
                        isCardless: false,
                        isBankTransfer: true,
                        isCashOnDelivery: false
                    ),
                ]),
                .reconciliationStatus: LookupCatalog(reconciliationStatuses: ["待對帳"]),
            ],
            expectedCatalog: LookupCatalog(
                orderSources: ["IG"],
                categories: ["服飾", "美妝"],
                paymentMethods: [
                    PaymentMethodInfo(
                        name: "orders.edit.label.bankTransfer",
                        isCardless: false,
                        isBankTransfer: true,
                        isCashOnDelivery: false
                    ),
                ],
                reconciliationStatuses: ["待對帳"]
            ),
            hasLoaded: true
        )
        #expect(
            Set(reads.value) == [.orderSource, .category, .paymentMethod, .reconciliationStatus]
        )
        #expect(reads.value.count == 4)
        await Self.receiveEmptyOrders(in: store, release: orderRelease.continuation)
        currencyRelease.continuation.finish()
        await store.receive(\.launch.currencyCodesResponse.success, [])
        await store.finish()
        #expect(orderReads.value == 1)
        #expect(catalogReader.wrappedValue.orderSources == ["IG"])
        #expect(catalogReader.wrappedValue.categories == ["服飾", "美妝"])
        #expect(
            catalogReader.wrappedValue.paymentMethods == [
                PaymentMethodInfo(
                    name: "orders.edit.label.bankTransfer",
                    isCardless: false,
                    isBankTransfer: true,
                    isCashOnDelivery: false
                ),
            ]
        )
        #expect(catalogReader.wrappedValue.reconciliationStatuses == ["待對帳"])
    }

    /// 訂單載入完成後首次開啟新表單，即可選取主檔中的兩個類別
    @Test
    func dashboard_主檔與訂單載入後首次新增_表單含兩個主檔類別() async {
        // Given
        let initial = Self.makeIsolatedRootState()
        initial.launch.$currencyCodes.withLock {
            $0 = [.twd]
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
            $0.uuid = .constant(UUID(0))
            Self.stubCatalogAndOrders(
                &$0,
                catalogs: [.category: LookupCatalog(categories: ["服飾", "美妝"])],
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
                .category: LookupCatalog(categories: ["服飾", "美妝"]),
                .paymentMethod: LookupCatalog(),
                .reconciliationStatus: LookupCatalog(),
            ],
            expectedCatalog: LookupCatalog(categories: ["服飾", "美妝"]),
            hasLoaded: true
        )
        await Self.receiveEmptyOrders(in: store, release: orderRelease.continuation)

        // When
        await store.send(.dashboard(.delegate(.newOrderTapped))) {
            $0.selectedTab = .orders
            $0.orders.presentation.destination = .edit(
                OrderEditFeature.State(
                    id: UUID(0),
                    options: OrderEditOptions(
                        categories: ["服飾", "美妝"],
                        currencyCodes: [.twd],
                        calendar: TestDependencies.fixedCalendar
                    ),
                    currentDate: TestDependencies.fixedNow
                )
            )
        }

        // Then
        let categories = (
            store.state.orders.presentation.destination?.edit?.pickers.options.categories
        )
        #expect(Set(categories ?? []) == ["服飾", "美妝"])
        #expect(store.state.more.catalog.catalog.categories == ["服飾", "美妝"])
        #expect(orderReads.value == 1)
        await store.finish()
    }
}
