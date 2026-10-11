//
//  OrdersFeatureTests+StatusWrites.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 批次改狀態只寫入狀態真的有變的訂單，一次寫完並離開多選
    @Test
    func list_批次更新多筆訂單_跳過相同狀態並離開選取() async {
        // Given
        let orders = [
            Self.makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
            Self.makeOrder(id: "O2", categories: ["beauty"], status: .arrived),
            Self.makeOrder(id: "O3", categories: ["snacks"], status: .shipping),
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
            Self.withStatus(orders[0], status: .arrived),
            orders[1],
            Self.withStatus(orders[2], status: .arrived),
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

    /// 把訂單直接改成已合併會被拒絕，並以寫入失敗提示呈現
    @Test
    func list_目標為已合併_拒絕寫入並呈現失敗() async {
        // Given
        let original = LedgerOrder.fixture(id: "O1", status: .confirmed)
        let writeFailureAlert = Self.expectedWriteFailureAlert("orders.general.message.orderStatusUpdated")
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
        #expect(store.state.load.errorMessage == nil)
    }

    /// 已合併的來源訂單可以改回一般狀態，寫入成功後才更新畫面
    @Test
    func list_合併來源訂單改回一般狀態_成功儲存() async {
        // Given
        let source = Self.makeOrder(id: "source", categories: ["beauty"], status: .merged)
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
                $0[0] = Self.withStatus(source, status: .confirmed)
            }
        }
        await store.receive(\.writes.statusResponse)
        #expect(savedOrders.value == [Self.withStatus(source, status: .confirmed)])
        await store.finish()
    }

    /// 狀態寫入失敗並關閉提示後，下一次寫入成功就不再留下錯誤狀態
    @Test
    func list_狀態寫入失敗後再次成功_不殘留錯誤狀態() async {
        // Given
        let original = Self.makeOrder(id: "O1", categories: ["beauty"], status: .shipping)
        let writeFailureAlert = Self.expectedWriteFailureAlert("orders.general.message.orderStatusUpdated")
        var initial = OrdersFeature.State(orders: [original])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let shouldFail = LockIsolated(true)
        let saveOrder: OrderService.SaveOrder = { _ in
            if shouldFail.value {
                throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
            }
        }
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = saveOrder
        }

        await store.send(.list(.delegate(.requested(.changeStatus(id: "O1", status: .arrived)))))
        await store.receive(\.writes.statusChangeRequested)
        await store.receive(\.writes.statusResponse)
        await store.receive(\.writes.delegate, .failed(.status))
        await store.receive(\.presentation.noticeRequested, .alert(writeFailureAlert)) {
            $0.presentation.destination = .alert(writeFailureAlert)
        }
        await store.send(.presentation(.destination(.dismiss))) {
            $0.presentation.destination = nil
        }
        shouldFail.setValue(false)

        // When
        await store.send(.list(.delegate(.requested(.changeStatus(id: "O1", status: .arrived)))))

        // Then
        await store.receive(\.writes.statusChangeRequested) {
            $0.$orders.withLock {
                $0[0] = Self.withStatus(original, status: .arrived)
            }
        }
        await store.receive(\.writes.statusResponse)
        #expect(store.state.load.errorMessage == nil)
        #expect(store.state.presentation.destination?.alert == nil)
        await store.finish()
    }
}
