//
//  OrderWritesFeatureTests+Receipt.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderWritesFeatureTests {

    /// 寫入服務完成前資料維持原值，成功回應只更新目標訂單
    @Test
    func receiptToggleRequested_寫入成功_成功後更新共用訂單() async {
        // Given
        let initial = Self.makeState()
        let expected = LedgerOrder.fixture(
            id: "O1",
            categories: ["美妝"],
            paymentReceiptStatus: .received
        )
        let sharedOrders = initial.$orders
        let observedOrders = LockIsolated<[[LedgerOrder]]>([])
        let calls = LockIsolated<[LedgerOrder]>([])
        let release = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                observedOrders.withValue {
                    $0.append(sharedOrders.wrappedValue)
                }
                calls.withValue {
                    $0.append(order)
                }
                var iterator = release.stream.makeAsyncIterator()
                _ = await iterator.next()
            }
        }

        // When
        await store.send(.receiptToggleRequested(id: "O1", status: .received))

        // Then
        #expect(initial.orders == [Self.original, Self.other])
        release.continuation.finish()
        await store.receive(\.receiptResponse.success, expected) {
            $0.$orders.withLock {
                $0 = [expected, Self.other]
            }
        }
        await store.finish()
        #expect(observedOrders.value == [[Self.original, Self.other]])
        #expect(calls.value == [expected])
        #expect(initial.orders == [expected, Self.other])
    }

    /// 寫入失敗時不套用目標值，並發出一次失敗委派
    @Test
    func receiptToggleRequested_寫入失敗_資料不變並回報失敗() async {
        // Given
        let initial = Self.makeState()
        let expected = LedgerOrder.fixture(
            id: "O1",
            categories: ["美妝"],
            paymentReceiptStatus: .received
        )
        let sharedOrders = initial.$orders
        let observedOrders = LockIsolated<[[LedgerOrder]]>([])
        let calls = LockIsolated<[LedgerOrder]>([])
        let failingSave: OrderService.SaveOrder = { order throws(PersistenceError) in
            observedOrders.withValue {
                $0.append(sharedOrders.wrappedValue)
            }
            calls.withValue {
                $0.append(order)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "receipt"))
        }
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        } withDependencies: {
            $0.orderService.saveOrder = failingSave
        }

        // When
        await store.send(.receiptToggleRequested(id: "O1", status: .received))

        // Then
        await store.receive(\.receiptResponse.failure)
        await store.receive(\.delegate, .failed(.receipt))
        await store.finish()
        #expect(observedOrders.value == [[Self.original, Self.other]])
        #expect(calls.value == [expected])
        #expect(initial.orders == [Self.original, Self.other])
    }
}
