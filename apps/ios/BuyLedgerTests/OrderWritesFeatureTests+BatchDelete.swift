//
//  OrderWritesFeatureTests+BatchDelete.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderWritesFeatureTests {

    /// 批次成功回應依編號更新現有訂單，不插入不存在的資料列
    @Test
    func batchStatusChangeRequested_寫入成功_依編號更新現有訂單() async {
        // Given
        let initial = Self.makeState()
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

    /// 批次寫入失敗時整批資料維持原值
    @Test
    func batchStatusChangeRequested_寫入失敗_整批不變並回報失敗() async {
        // Given
        let initial = Self.makeState()
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

    /// 刪除落盤成功才移除共用訂單，並交回容器清理選取與詳情
    @Test
    func deleteRequested_刪除成功_移除訂單並通知容器() async {
        // Given
        let initial = Self.makeState()
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

    /// 刪除失敗時清單保留原訂單，交回容器呈現失敗
    @Test
    func deleteRequested_刪除失敗_保留訂單並回報失敗() async {
        // Given
        let initial = Self.makeState()
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
