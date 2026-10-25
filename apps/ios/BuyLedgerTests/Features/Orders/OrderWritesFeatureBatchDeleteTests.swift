//
//  OrderWritesFeatureBatchDeleteTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderWritesFeature` 的單元測試，以 `TestStore` 逐步驗證批次狀態變更與刪除請求的成功更新與失敗保留
@MainActor
struct OrderWritesFeatureBatchDeleteTests {

    // MARK: - Properties

    /// 失敗情境下應維持不變的原訂單
    private static let original = OrderWritesFeatureTestSupport.original

    /// 不參與操作的另一筆訂單
    private static let other = OrderWritesFeatureTestSupport.other

    /// 驗證批次狀態變更寫入成功時，`saveOrders` 收到整批訂單，回應只依編號更新共用清單中的現有訂單，編號不存在的訂單不插入
    @Test
    func batchStatusChangeRequested_寫入成功_依編號更新現有訂單() async {
        // Given
        let initial = OrderWritesFeatureTestSupport.makeState()
        let changed = [
            LedgerOrder.fixture(id: "O1", status: .arrived, categories: ["美妝"]),
            LedgerOrder.fixture(id: "MISSING", status: .arrived),
        ]
        let sharedOrders = initial.$orders
        let observedOrders = LockIsolated<[[LedgerOrder]]>([])
        let calls = LockIsolated<[[LedgerOrder]]>([])
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        } withDependencies: {
            $0.orderService.saveOrders = { orders in
                observedOrders.withValue {
                    $0.append(sharedOrders.wrappedValue)
                }
                calls.withValue {
                    $0.append(orders)
                }
            }
        }

        // When
        await store.send(.batchStatusChangeRequested(changed))

        // Then
        await store.receive(\.batchStatusResponse.success, changed) {
            $0.$orders.withLock {
                $0[0] = changed[0]
            }
        }
        await store.finish()
        #expect(observedOrders.value == [[Self.original, Self.other]])
        #expect(calls.value == [changed])
        #expect(initial.orders == [changed[0], Self.other])
    }

    /// 驗證批次寫入失敗時，共用清單維持原值、不套用任何變更，並回報批次狀態變更失敗
    @Test
    func batchStatusChangeRequested_寫入失敗_整批不變並回報失敗() async {
        // Given
        let initial = OrderWritesFeatureTestSupport.makeState()
        let changed = [
            LedgerOrder.fixture(id: "O1", status: .arrived, categories: ["美妝"]),
            LedgerOrder.fixture(id: "OTHER", status: .arrived, categories: ["食品"]),
        ]
        let sharedOrders = initial.$orders
        let observedOrders = LockIsolated<[[LedgerOrder]]>([])
        let calls = LockIsolated<[[LedgerOrder]]>([])
        let failingSave: OrderService.SaveOrders = { orders throws(PersistenceError) in
            observedOrders.withValue {
                $0.append(sharedOrders.wrappedValue)
            }
            calls.withValue {
                $0.append(orders)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "batch"))
        }
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        } withDependencies: {
            $0.orderService.saveOrders = failingSave
        }

        // When
        await store.send(.batchStatusChangeRequested(changed))

        // Then
        await store.receive(\.batchStatusResponse.failure)
        await store.receive(\.delegate, .failed(.batchStatus))
        await store.finish()
        #expect(observedOrders.value == [[Self.original, Self.other]])
        #expect(calls.value == [changed])
        #expect(initial.orders == [Self.original, Self.other])
    }

    /// 驗證刪除寫入成功後才移除共用清單中的目標訂單，並通知訂單已刪除
    @Test
    func deleteRequested_刪除成功_移除訂單並通知容器() async {
        // Given
        let initial = OrderWritesFeatureTestSupport.makeState()
        let sharedOrders = initial.$orders
        let observedOrders = LockIsolated<[[LedgerOrder]]>([])
        let calls = LockIsolated<[String]>([])
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        } withDependencies: {
            $0.orderService.removeOrder = { id in
                observedOrders.withValue {
                    $0.append(sharedOrders.wrappedValue)
                }
                calls.withValue {
                    $0.append(id)
                }
            }
        }

        // When
        await store.send(.deleteRequested("O1"))

        // Then
        await store.receive(\.deleteResponse.success, "O1") {
            $0.$orders.withLock {
                $0 = [Self.other]
            }
        }
        await store.receive(\.delegate, .deleted("O1"))
        await store.finish()
        #expect(observedOrders.value == [[Self.original, Self.other]])
        #expect(calls.value == ["O1"])
        #expect(initial.orders == [Self.other])
    }

    /// 驗證刪除寫入失敗時，共用清單保留原訂單，並回報刪除失敗
    @Test
    func deleteRequested_刪除失敗_保留訂單並回報失敗() async {
        // Given
        let initial = OrderWritesFeatureTestSupport.makeState()
        let sharedOrders = initial.$orders
        let observedOrders = LockIsolated<[[LedgerOrder]]>([])
        let calls = LockIsolated<[String]>([])
        let failingDelete: OrderService.RemoveOrder = { id throws(PersistenceError) in
            observedOrders.withValue {
                $0.append(sharedOrders.wrappedValue)
            }
            calls.withValue {
                $0.append(id)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "delete"))
        }
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        } withDependencies: {
            $0.orderService.removeOrder = failingDelete
        }

        // When
        await store.send(.deleteRequested("O1"))

        // Then
        await store.receive(\.deleteResponse.failure)
        await store.receive(\.delegate, .failed(.delete))
        await store.finish()
        #expect(observedOrders.value == [[Self.original, Self.other]])
        #expect(calls.value == ["O1"])
        #expect(initial.orders == [Self.original, Self.other])
    }
}
