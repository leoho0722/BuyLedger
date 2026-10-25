//
//  OrdersLoadFeatureRequestsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrdersLoadFeature` 的單元測試，以 TestStore 逐步驗證載入請求的重複略過、失敗後的重新讀取與錯誤回報
@MainActor
struct OrdersLoadFeatureRequestsTests {

    /// 驗證第一次讀取尚未完成時再送出載入請求，會被略過只讀取一次，讀取完成後才回寫訂單與載入旗標
    @Test
    func loadRequested_第一次讀取暫停時重複請求_只讀取一次() async {
        // Given
        let order = LedgerOrder.fixture(id: "O1")
        let reads = LockIsolated(0)
        let started = AsyncStream<Void>.makeStream()
        let release = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: OrdersLoadFeatureTestSupport.makeState()) {
            OrdersLoadFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.fetchOrders = {
                reads.withValue {
                    $0 += 1
                }
                started.continuation.yield(())
                var iterator = release.stream.makeAsyncIterator()
                _ = await iterator.next()
                return [order]
            }
        }
        await store.send(.loadRequested) {
            $0.$isLoading.withLock {
                $0 = true
            }
        }

        // When
        await store.send(.loadRequested)

        // Then
        var iterator = started.stream.makeAsyncIterator()
        _ = await iterator.next()
        #expect(reads.value == 1)
        #expect(store.state.isLoading)
        release.continuation.finish()
        started.continuation.finish()
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
        #expect(reads.value == 1)
    }

    /// 驗證讀取失敗時，顯示載入失敗原因並送出 `delegate.loadFailed` 通知
    @Test
    func loadRequested_讀取失敗_回報錯誤並委派父層() async {
        // Given
        let fetch: OrderService.FetchOrders = { () throws(PersistenceError) in
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "read"))
        }
        let store = TestStore(initialState: OrdersLoadFeatureTestSupport.makeState()) {
            OrdersLoadFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.fetchOrders = fetch
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
    }

    /// 驗證失敗後再次請求時，先清除 `errorMessage` 並重新讀取，讀取成功後回寫訂單，`errorMessage` 維持 `nil`
    @Test
    func loadRequested_失敗後再次請求_清除錯誤並重新讀取() async {
        // Given
        let order = LedgerOrder.fixture(id: "O1")
        let reads = LockIsolated(0)
        let initial = OrdersLoadFeatureTestSupport.makeState()
        initial.$errorMessage.withLock {
            $0 = "orders.general.message.ordersLoadedTry"
        }
        let fetch: OrderService.FetchOrders = {
            reads.withValue {
                $0 += 1
            }
            return [order]
        }
        let store = TestStore(initialState: initial) {
            OrdersLoadFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.fetchOrders = fetch
        }

        // When
        await store.send(.loadRequested) {
            $0.$isLoading.withLock {
                $0 = true
            }
            $0.$errorMessage.withLock {
                $0 = nil
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
        #expect(reads.value == 1)
        #expect(store.state.errorMessage == nil)
    }

    /// 驗證已成功載入時送出載入請求，直接略過，不呼叫 `fetchOrders`
    @Test
    func loadRequested_已載入_略過讀取() async {
        // Given
        let initial = OrdersLoadFeatureTestSupport.makeState()
        initial.$hasLoaded.withLock {
            $0 = true
        }
        let store = TestStore(initialState: initial) {
            OrdersLoadFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.loadRequested)

        // Then
        await store.finish()
        #expect(store.state.hasLoaded)
        #expect(store.state.isLoading == false)
    }
}
