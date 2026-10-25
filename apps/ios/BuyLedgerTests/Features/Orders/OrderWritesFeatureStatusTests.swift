//
//  OrderWritesFeatureStatusTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderWritesFeature` 的單元測試，以 `TestStore` 逐步驗證狀態變更請求的成功更新與失敗保留
@MainActor
struct OrderWritesFeatureStatusTests {

    // MARK: - Properties

    /// 失敗情境下應維持不變的原訂單
    private static let original = OrderWritesFeatureTestSupport.original

    /// 不參與操作的另一筆訂單
    private static let other = OrderWritesFeatureTestSupport.other

    /// 驗證狀態變更寫入成功後，回應只更新目標訂單的狀態，其他訂單保留
    @Test
    func statusChangeRequested_寫入成功_成功後更新共用訂單() async {
        // Given
        let initial = OrderWritesFeatureTestSupport.makeState()
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

    /// 驗證狀態變更寫入失敗時，共用清單不套用目標狀態，且只回報一次狀態寫入失敗
    @Test
    func statusChangeRequested_寫入失敗_資料不變並回報失敗() async {
        // Given
        let initial = OrderWritesFeatureTestSupport.makeState()
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
