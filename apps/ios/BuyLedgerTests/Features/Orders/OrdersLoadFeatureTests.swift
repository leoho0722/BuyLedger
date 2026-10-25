//
//  OrdersLoadFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrdersLoadFeature` 的單元測試，以 TestStore 逐步驗證讀取結果寫入共用訂單與載入狀態的情形
@MainActor
struct OrdersLoadFeatureTests {

    /// 驗證讀取成功時，共用的訂單換成讀回的結果，`isLoading` 回到 `false`、`hasLoaded` 變為 `true`，`errorMessage` 維持 `nil`
    @Test
    func loadRequested_讀取成功_更新共用訂單與載入狀態() async {
        // Given
        let order = LedgerOrder.fixture(id: "O1")
        let initial = OrdersLoadFeatureTestSupport.makeState()
        let ordersReader = SharedReader(initial.$orders)
        let loadingReader = SharedReader(initial.$isLoading)
        let loadedReader = SharedReader(initial.$hasLoaded)
        let store = TestStore(initialState: initial) {
            OrdersLoadFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.fetchOrders = {
                [order]
            }
        }

        // When
        await store.send(.loadRequested) {
            $0.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.loadResponse) {
            $0.$isLoading.withLock {
                $0 = false
            }
            $0.$hasLoaded.withLock {
                $0 = true
            }
            $0.$orders.withLock {
                $0 = [order]
            }
        }
        await store.finish()
        #expect(ordersReader.wrappedValue == [order])
        #expect(loadingReader.wrappedValue == false)
        #expect(loadedReader.wrappedValue)
        #expect(store.state.errorMessage == nil)
    }

    /// 驗證讀取失敗時保留原有訂單，`hasLoaded` 維持 `false`，顯示載入失敗原因並回報失敗通知
    @Test
    func loadRequested_訂單讀取失敗_保留資料並委派錯誤() async {
        // Given
        let order = LedgerOrder.fixture(id: "existing")
        let initial = OrdersLoadFeatureTestSupport.makeState(orders: [order])
        let failingFetch: OrderService.FetchOrders = { () throws(PersistenceError) in
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            OrdersLoadFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.fetchOrders = failingFetch
        }

        // When
        await store.send(.loadRequested) {
            $0.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.loadResponse) {
            $0.$isLoading.withLock {
                $0 = false
            }
            $0.$errorMessage.withLock {
                $0 = "orders.general.message.ordersLoadedTry"
            }
        }
        await store.receive(\.delegate.loadFailed)
        await store.finish()
        #expect(store.state.orders == [order])
        #expect(store.state.isLoading == false)
        #expect(store.state.hasLoaded == false)
    }
}
