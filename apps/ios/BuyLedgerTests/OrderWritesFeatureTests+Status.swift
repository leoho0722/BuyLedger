//
//  OrderWritesFeatureTests+Status.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderWritesFeatureTests {

    /// 成功回應只更新目標訂單，其他訂單保留
    @Test
    func statusChangeRequested_寫入成功_成功後更新共用訂單() async {
        // Given
        let initial = Self.makeState()
        let expected = LedgerOrder.fixture(id: "O1", status: .arrived, categories: ["美妝"])
        let sharedOrders = initial.$orders
        let observedOrders = LockIsolated<[[LedgerOrder]]>([])
        let calls = LockIsolated<[LedgerOrder]>([])
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
            }
        }

        // When
        await store.send(.statusChangeRequested(id: "O1", status: .arrived))

        // Then
        await store.receive(\.statusResponse.success, expected) {
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
    func statusChangeRequested_寫入失敗_資料不變並回報失敗() async {
        // Given
        let initial = Self.makeState()
        let expected = LedgerOrder.fixture(id: "O1", status: .arrived, categories: ["美妝"])
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
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "status"))
        }
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        } withDependencies: {
            $0.orderService.saveOrder = failingSave
        }

        // When
        await store.send(.statusChangeRequested(id: "O1", status: .arrived))

        // Then
        await store.receive(\.statusResponse.failure)
        await store.receive(\.delegate, .failed(.status))
        await store.finish()
        #expect(observedOrders.value == [[Self.original, Self.other]])
        #expect(calls.value == [expected])
        #expect(initial.orders == [Self.original, Self.other])
    }
}
