//
//  OrdersFeatureStatusWritesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證訂單狀態變更、批次寫入與失敗後的重試
@MainActor
struct OrdersFeatureStatusWritesTests {

    /// 驗證批次改為 `arrived` 時，已是該狀態的訂單不寫入，其餘訂單一次寫完，並離開多選模式
    @Test
    func list_批次更新多筆訂單_跳過相同狀態並離開選取() async {
        // Given
        let orders = [
            OrdersFeatureTestSupport.makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
            OrdersFeatureTestSupport.makeOrder(id: "O2", categories: ["beauty"], status: .arrived),
            OrdersFeatureTestSupport.makeOrder(id: "O3", categories: ["snacks"], status: .shipping),
        ]
        var initial = OrdersFeature.State(orders: orders)
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.isSelecting = true
        initial.list.selectedOrderIDs = ["O1", "O2", "O3"]
        let savedBatches = LockIsolated<[[LedgerOrder]]>([])
        let expectedOrders = [
            OrdersFeatureTestSupport.withStatus(orders[0], status: .arrived),
            orders[1],
            OrdersFeatureTestSupport.withStatus(orders[2], status: .arrived),
        ]
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrders = { savedOrders in
                savedBatches.withValue {
                    $0.append(savedOrders)
                }
            }
        }

        // When
        await store.send(.list(.view(.batchStatusChanged(.arrived)))) {
            $0.list.isSelecting = false
            $0.list.selectedOrderIDs = []
        }

        // Then
        await store.receive(\.list.delegate.requested) {
            $0.$orders.withLock {
                $0 = expectedOrders
            }
        }
        await store.receive(\.writes.batchStatusChangeRequested)
        await store.receive(\.writes.batchStatusResponse)
        #expect(savedBatches.value.map { $0.map(\.id) } == [["O1", "O3"]])
    }

    /// 驗證把訂單直接改為 `merged` 會被拒絕，寫入失敗提示以 alert 呈現，訂單維持原狀
    @Test
    func list_目標為已合併_拒絕寫入並呈現失敗() async {
        // Given
        let original = LedgerOrder.fixture(id: "O1", status: .confirmed)
        let writeFailureAlert = OrdersFeatureTestSupport.expectedWriteFailureAlert(
            "orders.general.message.orderStatusUpdated"
        )
        let store = TestStore(initialState: OrdersFeature.State(orders: [original])) {
            OrdersFeature()
        }

        // When
        await store.send(.list(.delegate(.requested(.changeStatus(id: "O1", status: .merged)))))

        // Then
        await store.receive(\.writes.statusChangeRequested)
        await store.receive(\.writes.delegate, .failed(.mergedStatusRejected))
        await store.receive(\.presentation.noticeRequested, .alert(writeFailureAlert)) {
            $0.presentation.destination = .alert(writeFailureAlert)
        }
        await store.finish()
        #expect(store.state.orders == [original])
    }

    /// 驗證已合併的來源訂單改為 `confirmed` 時，送出寫入的同時列表更新為新狀態，寫入成功的回應不再改動畫面，並以 `saveOrder` 存入該訂單
    @Test
    func list_合併來源訂單改回一般狀態_成功儲存() async {
        // Given
        let source = OrdersFeatureTestSupport.makeOrder(
            id: "source",
            categories: ["beauty"],
            status: .merged
        )
        var state = OrdersFeature.State(orders: [source])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }

        // When
        await store.send(
            .list(.delegate(.requested(.changeStatus(id: "source", status: .confirmed))))
        )

        // Then
        await store.receive(\.writes.statusChangeRequested) {
            $0.$orders.withLock {
                $0[0] = OrdersFeatureTestSupport.withStatus(source, status: .confirmed)
            }
        }
        await store.receive(\.writes.statusResponse)
        #expect(
            savedOrders.value == [OrdersFeatureTestSupport.withStatus(source, status: .confirmed)]
        )
        await store.finish()
    }

    /// 驗證狀態寫入失敗時，列表維持原狀態，並以 alert 呈現寫入失敗提示
    @Test
    func list_狀態寫入失敗_資料不變並呈現失敗提示() async {
        // Given
        let original = OrdersFeatureTestSupport.makeOrder(
            id: "O1",
            categories: ["beauty"],
            status: .shipping
        )
        let writeFailureAlert = OrdersFeatureTestSupport.expectedWriteFailureAlert(
            "orders.general.message.orderStatusUpdated"
        )
        var initial = OrdersFeature.State(orders: [original])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let failingSave: OrderService.SaveOrder = { _ throws(PersistenceError) in
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = failingSave
        }

        // When
        await store.send(.list(.delegate(.requested(.changeStatus(id: "O1", status: .arrived)))))

        // Then
        await store.receive(\.writes.statusChangeRequested)
        await store.receive(\.writes.statusResponse)
        await store.receive(\.writes.delegate, .failed(.status))
        await store.receive(\.presentation.noticeRequested, .alert(writeFailureAlert)) {
            $0.presentation.destination = .alert(writeFailureAlert)
        }
        await store.finish()
        #expect(store.state.orders == [original])
    }

    /// 驗證狀態寫入失敗並關閉提示後，下一次寫入成功時，列表更新為已抵達
    ///
    /// - Note: 首輪失敗與關閉提示不留下任何狀態，Given 即為失敗並關閉後的狀態
    /// - Note: 首輪失敗的結果由 `list_狀態寫入失敗_資料不變並呈現失敗提示` 守
    @Test
    func list_狀態寫入失敗後再次成功_更新為新狀態() async {
        // Given
        let original = OrdersFeatureTestSupport.makeOrder(
            id: "O1",
            categories: ["beauty"],
            status: .shipping
        )
        var initial = OrdersFeature.State(orders: [original])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { _ in
            }
        }

        // When
        await store.send(.list(.delegate(.requested(.changeStatus(id: "O1", status: .arrived)))))

        // Then
        await store.receive(\.writes.statusChangeRequested) {
            $0.$orders.withLock {
                $0[0] = OrdersFeatureTestSupport.withStatus(original, status: .arrived)
            }
        }
        await store.receive(\.writes.statusResponse)
        #expect(store.state.orders.first?.status == .arrived)
        await store.finish()
    }
}
