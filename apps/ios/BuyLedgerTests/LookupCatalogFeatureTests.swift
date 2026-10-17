//
//  LookupCatalogFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證主檔目錄的載入、讀取失敗保留與新增寫入
@MainActor
struct LookupCatalogFeatureTests {

    /// 四種主檔都讀取成功時設為已載入，並以字面值替換四份目錄
    @Test
    func loadRequested_四種主檔都讀取成功_設定已載入並回報完成() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let reads = LockIsolated<[LookupKind]>([])
            let failingKinds = LockIsolated<Set<LookupKind>>([])
            let paymentMethods = [PaymentMethodInfo(name: "信用卡", flags: .none)]
            let catalogs: [LookupKind: LookupCatalog] = [
                .orderSource: LookupCatalog(orderSources: ["蝦皮"]),
                .category: LookupCatalog(categories: ["服飾", "美妝"]),
                .paymentMethod: LookupCatalog(paymentMethods: paymentMethods),
                .reconciliationStatus: LookupCatalog(reconciliationStatuses: ["已對帳"]),
            ]
            let store = TestStore(initialState: LookupCatalogFeature.State()) {
                LookupCatalogFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
                $0.lookupService.fetchItems = Self.makeFetchItems(
                    catalogs: catalogs,
                    failingKinds: failingKinds,
                    reads: reads
                )
            }

            // When
            await store.send(.loadRequested) {
                $0.isLoading = true
            }

            // Then
            await store.receive(\.catalogResponse) {
                $0.isLoading = false
                $0.hasLoaded = true
                $0.$catalog.withLock {
                    $0.orderSources = ["蝦皮"]
                    $0.categories = ["服飾", "美妝"]
                    $0.paymentMethods = [PaymentMethodInfo(name: "信用卡", flags: .none)]
                    $0.reconciliationStatuses = ["已對帳"]
                }
            }
            await store.receive(\.delegate, .loadFinished)
            #expect(reads.value.count == 4)
            await store.finish()
        }
    }

    /// 付款方式讀取失敗時，其他種類照常替換，但不設為已載入
    @Test
    func loadRequested_付款方式讀取失敗_其他種類照常替換且不設為已載入() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let reads = LockIsolated<[LookupKind]>([])
            let failingKinds = LockIsolated<Set<LookupKind>>([.paymentMethod])
            let catalogs: [LookupKind: LookupCatalog] = [
                .category: LookupCatalog(categories: ["服飾"]),
            ]
            let store = TestStore(initialState: LookupCatalogFeature.State()) {
                LookupCatalogFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
                $0.lookupService.fetchItems = Self.makeFetchItems(
                    catalogs: catalogs,
                    failingKinds: failingKinds,
                    reads: reads
                )
            }

            // When
            await store.send(.loadRequested) {
                $0.isLoading = true
            }

            // Then
            await store.receive(\.catalogResponse) {
                $0.isLoading = false
                $0.$catalog.withLock {
                    $0.categories = ["服飾"]
                }
            }
            await store.receive(\.delegate, .loadFinished)
            #expect(store.state.hasLoaded == false)
            await store.finish()
        }
    }

    /// 付款方式讀取失敗時保留原有付款方式，不以空清單覆寫
    @Test
    func loadRequested_付款方式讀取失敗_保留原有付款方式() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var initialState = LookupCatalogFeature.State()
            initialState.$catalog.withLock {
                $0.paymentMethods = [PaymentMethodInfo(name: "信用卡", flags: .none)]
            }
            let reads = LockIsolated<[LookupKind]>([])
            let failingKinds = LockIsolated<Set<LookupKind>>([.paymentMethod])
            let store = TestStore(initialState: initialState) {
                LookupCatalogFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
                $0.lookupService.fetchItems = Self.makeFetchItems(
                    catalogs: [:],
                    failingKinds: failingKinds,
                    reads: reads
                )
            }

            // When
            await store.send(.loadRequested) {
                $0.isLoading = true
            }

            // Then
            await store.receive(\.catalogResponse) {
                $0.isLoading = false
            }
            await store.receive(\.delegate, .loadFinished)
            #expect(store.state.catalog.paymentMethods.map(\.name) == ["信用卡"])
            #expect(store.state.hasLoaded == false)
            await store.finish()
        }
    }

    /// 上次有一種讀取失敗時，下一次載入請求重新讀取四種主檔
    @Test
    func loadRequested_上次有一種讀取失敗_再次請求重讀四種() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var initialState = LookupCatalogFeature.State()
            initialState.$catalog.withLock {
                $0.categories = ["服飾"]
            }
            let reads = LockIsolated<[LookupKind]>([])
            let failingKinds = LockIsolated<Set<LookupKind>>([])
            let catalogs: [LookupKind: LookupCatalog] = [
                .category: LookupCatalog(categories: ["服飾"]),
            ]
            let store = TestStore(initialState: initialState) {
                LookupCatalogFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
                $0.lookupService.fetchItems = Self.makeFetchItems(
                    catalogs: catalogs,
                    failingKinds: failingKinds,
                    reads: reads
                )
            }

            // When
            await store.send(.loadRequested) {
                $0.isLoading = true
            }

            // Then
            await store.receive(\.catalogResponse) {
                $0.isLoading = false
                $0.hasLoaded = true
            }
            await store.receive(\.delegate, .loadFinished)
            #expect(reads.value.count == 4)
            await store.finish()
        }
    }

    /// 已全部讀取過時不重讀，立即回報完成且目錄不變
    @Test
    func loadRequested_已全部讀取過_不讀取並立即回報完成() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var initialState = LookupCatalogFeature.State()
            initialState.hasLoaded = true
            initialState.$catalog.withLock {
                $0.categories = ["服飾"]
                $0.paymentMethods = [PaymentMethodInfo(name: "信用卡", flags: .none)]
            }
            let store = TestStore(initialState: initialState) {
                LookupCatalogFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
            }

            // When
            await store.send(.loadRequested)

            // Then
            await store.receive(\.delegate, .loadFinished)
            await store.finish()
        }
    }

    /// 讀取進行中再次請求載入時略過，不重讀也不送出任何動作
    @Test
    func loadRequested_讀取進行中_略過不重讀() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var initialState = LookupCatalogFeature.State()
            initialState.isLoading = true
            let store = TestStore(initialState: initialState) {
                LookupCatalogFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
            }

            // When
            await store.send(.loadRequested)

            // Then
            await store.finish()
        }
    }
}

// MARK: - Private Method

private extension LookupCatalogFeatureTests {

    /// 建立讀取主檔的替身，記錄每次讀取的種類；`failingKinds` 內的種類讀取失敗，其餘回傳 `catalogs`
    ///
    /// - Parameters:
    ///   - catalogs: 各種類讀取成功時回傳的目錄，未列出者為空目錄
    ///   - failingKinds: 要讀取失敗的種類，測試可在兩次請求之間改寫
    ///   - reads: 依讀取順序記錄的種類
    /// - Returns: 可注入 `lookupService.fetchItems` 的替身
    static func makeFetchItems(
        catalogs: [LookupKind: LookupCatalog],
        failingKinds: LockIsolated<Set<LookupKind>>,
        reads: LockIsolated<[LookupKind]>
    ) -> LookupService.FetchItems {
        let underlying = TestDependencies.makeUnderlyingError(message: "讀取失敗")
        return { kind throws(PersistenceError) in
            reads.withValue {
                $0.append(kind)
            }
            guard !failingKinds.value.contains(kind) else {
                throw .fetchFailed(underlying: underlying)
            }
            return catalogs[kind] ?? LookupCatalog()
        }
    }
}
