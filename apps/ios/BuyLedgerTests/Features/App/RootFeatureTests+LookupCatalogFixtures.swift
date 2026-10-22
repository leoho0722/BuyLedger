//
//  RootFeatureTests+LookupCatalogFixtures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

// MARK: - Internal Method

extension RootFeatureTests {

    /// 建立有等待閘門的主檔與訂單讀取替身，分別記錄已完成的主檔種類與訂單讀取次數
    ///
    /// - Parameters:
    ///   - dependencies: 測試依賴集合
    ///   - catalogs: 各種類成功讀取時回傳的目錄
    ///   - failingKinds: 讀取失敗的主檔種類
    ///   - catalogRelease: 主檔讀取的等待閘門
    ///   - orderRelease: 訂單讀取的等待閘門
    ///   - reads: 已完成讀取的主檔種類
    ///   - orderReads: 訂單讀取次數
    ///   - shouldFailOrders: 是否讓訂單讀取失敗
    static func stubCatalogAndOrders(
        _ dependencies: inout DependencyValues,
        catalogs: [LookupKind: LookupCatalog],
        failingKinds: Set<LookupKind> = [],
        catalogRelease: AsyncStream<Void>,
        orderRelease: AsyncStream<Void>,
        reads: LockIsolated<[LookupKind]>,
        orderReads: LockIsolated<Int>,
        shouldFailOrders: Bool = false
    ) {
        let fetchItems: LookupService.FetchItems = { kind throws(PersistenceError) in
            var iterator = catalogRelease.makeAsyncIterator()
            _ = await iterator.next()
            reads.withValue {
                $0.append(kind)
            }
            guard !failingKinds.contains(kind) else {
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "lookup")
                )
            }
            return catalogs[kind] ?? LookupCatalog()
        }
        let fetchOrders: OrderService.FetchOrders = { () throws(PersistenceError) in
            orderReads.withValue {
                $0 += 1
            }
            var iterator = orderRelease.makeAsyncIterator()
            _ = await iterator.next()
            guard !shouldFailOrders else {
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "orders")
                )
            }
            return []
        }
        dependencies.lookupService.fetchItems = fetchItems
        dependencies.orderService.fetchOrders = fetchOrders
    }

    /// 接收單次主檔請求的前置轉送，讀取需由呼叫端的串流阻擋
    ///
    /// - Parameter store: 已送出訂單載入意圖的測試 `store`
    static func receiveCatalogRequested(in store: TestStoreOf<RootFeature>) async {
        await store.receive(\.more.catalogLoadRequested)
        await store.receive(\.more.catalog.loadRequested) {
            $0.more.catalog.isLoading = true
        }
    }

    /// 接收主檔讀取結果，斷言字面值目錄，再接收逐層轉送的訂單載入
    ///
    /// - Parameters:
    ///   - store: 已釋放主檔讀取的測試 `store`
    ///   - catalogs: 預期的各種類回應
    ///   - expectedCatalog: 預期的完整目錄，由案例以字面值提供
    ///   - hasLoaded: 是否四種皆讀取成功
    ///   - shouldLoadOrders: 是否開始新的訂單讀取，已載入的訂單不重讀
    static func receiveCatalogResponse(
        in store: TestStoreOf<RootFeature>,
        catalogs: [LookupKind: LookupCatalog],
        expectedCatalog: LookupCatalog,
        hasLoaded: Bool,
        shouldLoadOrders: Bool = true
    ) async {
        await store.receive(\.more.catalog.catalogResponse, catalogs) {
            $0.more.catalog.isLoading = false
            $0.more.catalog.hasLoaded = hasLoaded
            $0.more.catalog.$catalog.withLock {
                $0 = expectedCatalog
            }
            if shouldLoadOrders {
                $0.orders.load.$isLoading.withLock {
                    $0 = true
                }
                $0.orders.load.$errorMessage.withLock {
                    $0 = nil
                }
            }
        }
        await Self.receiveCatalogFinished(in: store)
    }

    /// 釋放空訂單清單的讀取，核對載入狀態與首頁、分析頁的投影
    ///
    /// - Parameters:
    ///   - store: 訂單正在讀取中的測試 `store`
    ///   - release: 訂單讀取的等待閘門
    ///   - shouldFail: 是否預期訂單讀取失敗
    static func receiveEmptyOrders(
        in store: TestStoreOf<RootFeature>,
        release: AsyncStream<Void>.Continuation,
        shouldFail: Bool = false
    ) async {
        release.finish()
        await store.receive(\.orders.load.loadResponse) {
            $0.orders.load.$isLoading.withLock {
                $0 = false
            }
            if shouldFail {
                $0.orders.load.$errorMessage.withLock {
                    $0 = "orders.general.message.ordersLoadedTry"
                }
                $0.dashboard.loadState = .failed("orders.general.message.ordersLoadedTry")
                $0.insights.loadState = .failed("orders.general.message.ordersLoadedTry")
            } else {
                $0.orders.$orders.withLock {
                    $0 = []
                }
                $0.campaigns.$orders.withLock {
                    $0 = []
                }
                $0.more.$orders.withLock {
                    $0 = []
                }
                $0.dashboard.orders = []
                $0.insights.orders = []
                $0.orders.load.$hasLoaded.withLock {
                    $0 = true
                }
                $0.dashboard.loadState = .loaded
                $0.insights.loadState = .loaded
            }
        }
        if shouldFail {
            await store.receive(\.orders.load.delegate.loadFailed)
        }
    }
}
