//
//  OrderWritesFeatureReceiptTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderWritesFeature` 的單元測試，以 `TestStore` 逐步驗證收款狀態切換請求的成功更新與失敗保留
@MainActor
struct OrderWritesFeatureReceiptTests {

    // MARK: - Properties

    /// 失敗情境下應維持不變的原訂單
    private static let original = OrderWritesFeatureTestSupport.original

    /// 不參與操作的另一筆訂單
    private static let other = OrderWritesFeatureTestSupport.other

    /// 驗證收款切換的寫入服務尚未完成前共用清單維持原值，寫入成功的回應到達後只更新目標訂單，其他訂單保留
    @Test
    func receiptToggleRequested_寫入成功_成功後更新共用訂單() async {
        // Given
        let initial = OrderWritesFeatureTestSupport.makeState()
        let expected = LedgerOrder.fixture(
            id: "O1",
            status: .confirmed,
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

    /// 驗證收款切換寫入失敗時，共用清單不套用目標值，且只回報一次收款狀態寫入失敗
    @Test
    func receiptToggleRequested_寫入失敗_資料不變並回報失敗() async {
        // Given
        let initial = OrderWritesFeatureTestSupport.makeState()
        let expected = LedgerOrder.fixture(
            id: "O1",
            status: .confirmed,
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
