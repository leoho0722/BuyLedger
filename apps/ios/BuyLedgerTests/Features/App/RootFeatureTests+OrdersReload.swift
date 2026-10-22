//
//  RootFeatureTests+OrdersReload.swift
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

    /// 建立訂單首次載入失敗的根狀態，總覽與分析頁都停在失敗畫面
    ///
    /// - Returns: 訂單載入失敗的根狀態
    static func makeOrdersLoadFailedState() -> RootFeature.State {
        var initial = Self.makeIsolatedRootState()
        initial.orders.load.$errorMessage.withLock {
            $0 = "orders.general.message.ordersLoadedTry"
        }
        initial.dashboard.loadState = .failed("orders.general.message.ordersLoadedTry")
        initial.insights.loadState = .failed("orders.general.message.ordersLoadedTry")
        return initial
    }

    /// 讓訂單重新載入先停在 `release`，釋放後回傳 `loaded`，並記下實際讀取次數
    ///
    /// - Parameters:
    ///   - dependencies: 本測試的依賴集合
    ///   - loaded: 載入成功時回傳的訂單
    ///   - reads: 記錄訂單讀取次數
    ///   - release: 控制載入何時完成的串流
    ///   - catalogRelease: 控制主檔讀取何時完成的串流
    static func stubOrdersReload(
        _ dependencies: inout DependencyValues,
        loaded: LedgerOrder,
        reads: LockIsolated<Int>,
        release: AsyncStream<Void>,
        catalogRelease: AsyncStream<Void>
    ) {
        dependencies.orderService.fetchOrders = {
            reads.withValue {
                $0 += 1
            }
            var iterator = release.makeAsyncIterator()
            _ = await iterator.next()
            return [loaded]
        }
        let fetchItems: LookupService.FetchItems = { _ in
            var iterator = catalogRelease.makeAsyncIterator()
            _ = await iterator.next()
            return LookupCatalog()
        }
        dependencies.lookupService.fetchItems = fetchItems
    }

    /// 接收根功能轉送的訂單重新載入，確認總覽與分析頁回到載入中，釋放後接收載入成功的同步結果
    ///
    /// - Parameters:
    ///   - store: 已送出重試事件的測試 `store`
    ///   - loaded: 載入成功後同步到各頁的訂單
    ///   - release: 控制載入何時完成的 `continuation`
    ///   - catalogRelease: 控制主檔讀取何時完成的 `continuation`
    static func receiveOrdersReload(
        in store: TestStoreOf<RootFeature>,
        loaded: LedgerOrder,
        release: AsyncStream<Void>.Continuation,
        catalogRelease: AsyncStream<Void>.Continuation
    ) async {
        await store.receive(\.more.catalogLoadRequested)
        await store.receive(\.more.catalog.loadRequested) {
            $0.more.catalog.isLoading = true
        }
        catalogRelease.finish()
        await store.receive(
            \.more.catalog.catalogResponse,
            [
                .orderSource: LookupCatalog(),
                .category: LookupCatalog(),
                .paymentMethod: LookupCatalog(),
                .reconciliationStatus: LookupCatalog(),
            ]
        ) {
            $0.more.catalog.isLoading = false
            $0.more.catalog.hasLoaded = true
            $0.orders.load.$isLoading.withLock {
                $0 = true
            }
            $0.orders.load.$errorMessage.withLock {
                $0 = nil
            }
        }
        await store.receive(\.more.catalog.delegate.loadFinished)
        await store.receive(\.more.delegate.catalogLoadFinished)
        await store.receive(\.orders.rootRequest.load)
        await store.receive(\.orders.load.loadRequested) {
            $0.dashboard.loadState = .loading
            $0.insights.loadState = .loading
        }
        release.finish()
        await store.receive(\.orders.load.loadResponse) {
            $0.orders.load.$isLoading.withLock {
                $0 = false
            }
            $0.orders.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.orders.$orders.withLock {
                $0 = [loaded]
            }
            $0.campaigns.$orders.withLock {
                $0 = [loaded]
            }
            $0.more.$orders.withLock {
                $0 = [loaded]
            }
            $0.orders.list.selectedOrderID = "RETRY-ORDER"
            $0.orders.detail.regularDetail = OrderDetailFeature.State(
                orderID: "RETRY-ORDER",
                orders: SharedReader($0.orders.$orders)
            )
            $0.dashboard.orders = [loaded]
            $0.dashboard.loadState = .loaded
            $0.insights.orders = [loaded]
            $0.insights.loadState = .loaded
        }
    }
}
