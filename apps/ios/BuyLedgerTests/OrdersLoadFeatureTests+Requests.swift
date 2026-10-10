//
//  OrdersLoadFeatureTests+Requests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrdersLoadFeatureTests {

    /// 第一次讀取尚未完成時的第二個請求不重讀訂單或主檔
    @Test
    func loadRequested_第一次讀取暫停時重複請求_只讀取一次() async {
        // Given
        let order = LedgerOrder.fixture(id: "O1")
        let reads = LockIsolated(0)
        let lookupReads = LockIsolated(0)
        let started = AsyncStream<Void>.makeStream()
        let release = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: Self.makeState()) {
            OrdersLoadFeature()
        } withDependencies: {
            Self.suppressLookups(&$0)
            $0.orderService.fetchOrders = {
                reads.withValue {
                    $0 += 1
                }
                started.continuation.yield(())
                var iterator = release.stream.makeAsyncIterator()
                _ = await iterator.next()
                return [order]
            }
            $0.orderSourceService.fetchOrderSources = {
                lookupReads.withValue {
                    $0 += 1
                }
                return []
            }
        }
        await store.send(.loadRequested) {
            $0.$isLoading.withLock {
                $0 = true
            }
        }
        var iterator = started.stream.makeAsyncIterator()
        _ = await iterator.next()

        // When
        await store.send(.loadRequested)

        // Then
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
        #expect(lookupReads.value == 1)
    }

    /// 讀取失敗時回報錯誤並委派父層
    @Test
    func loadRequested_讀取失敗_回報錯誤並委派父層() async {
        // Given
        let fetch: OrderService.FetchOrders = {
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "read"))
        }
        let store = TestStore(initialState: Self.makeState()) {
            OrdersLoadFeature()
        } withDependencies: {
            $0.orderService.fetchOrders = fetch
            Self.suppressLookups(&$0)
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
                $0 = "訂單載入失敗，請稍後再試。"
            }
        }
        await store.receive(\.delegate.loadFailed)
        await store.finish()
    }

    /// 讀取失敗後再次請求會清除錯誤並重新讀取訂單
    @Test
    func loadRequested_失敗後再次請求_清除錯誤並重新讀取() async {
        // Given
        let order = LedgerOrder.fixture(id: "O1")
        let reads = LockIsolated(0)
        let initial = Self.makeState()
        initial.$errorMessage.withLock {
            $0 = "訂單載入失敗，請稍後再試。"
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
            $0.orderService.fetchOrders = fetch
            Self.suppressLookups(&$0)
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

    /// 已成功載入時不呼叫任何讀取服務
    @Test
    func loadRequested_已載入_略過讀取() async {
        // Given
        let initial = Self.makeState()
        initial.$hasLoaded.withLock {
            $0 = true
        }
        let store = TestStore(initialState: initial) {
            OrdersLoadFeature()
        }

        // When
        await store.send(.loadRequested)

        // Then
        await store.finish()
        #expect(store.state.hasLoaded)
        #expect(store.state.isLoading == false)
    }
}
