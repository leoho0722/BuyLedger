//
//  OrdersLoadFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// 訂單讀取結果與共用載入狀態的測試
@MainActor
struct OrdersLoadFeatureTests {

    /// 成功載入時替換共用訂單並更新載入旗標
    @Test
    func loadRequested_讀取成功_更新共用訂單與載入狀態() async {
        // Given
        let order = LedgerOrder.fixture(id: "O1")
        let initial = Self.makeState()
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

    /// 訂單讀取失敗時保留原有訂單，不標記為已載入並通知父層
    @Test
    func loadRequested_訂單讀取失敗_保留資料並委派錯誤() async {
        // Given
        let order = LedgerOrder.fixture(id: "existing")
        let initial = Self.makeState(orders: [order])
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

// MARK: - Internal Method

extension OrdersLoadFeatureTests {

    /// 建立使用獨立記憶體儲存的載入狀態，訂單與載入狀態不外溢到其他測試
    ///
    /// - Parameter orders: 初始訂單
    /// - Returns: 尚未開始讀取的載入狀態
    static func makeState(orders: [LedgerOrder] = []) -> OrdersLoadFeature.State {
        withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            let shared = Shared<[LedgerOrder]>(value: [])
            shared.withLock {
                $0 = orders
            }
            return OrdersLoadFeature.State(orders: shared)
        }
    }
}
