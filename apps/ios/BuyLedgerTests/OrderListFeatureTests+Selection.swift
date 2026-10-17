//
//  OrderListFeatureTests+Selection.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 多選中離開多選模式時，已勾選的訂單一併清空
    @Test
    func selectionModeToggled_多選中已勾選訂單_離開並清空勾選() async {
        // Given
        let initialOrders = [
            OrdersFeatureTests.makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
        ]
        var initial = OrdersFeature.State(orders: initialOrders)
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.isSelecting = true
        initial.list.selectedOrderIDs = ["O1"]
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.selectionModeToggled)) {
            $0.isSelecting = false
            $0.selectedOrderIDs = []
        }

        // Then
        #expect(store.state.selectedOrderIDs.isEmpty)
        #expect(store.state.isSelecting == false)
    }

    /// 多選模式中點選未勾選的訂單後，將它加入勾選清單
    @Test
    func orderSelectionToggled_未勾選訂單_加入勾選() async {
        // Given
        let initialOrders = [
            OrdersFeatureTests.makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
        ]
        var initial = OrdersFeature.State(orders: initialOrders)
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.isSelecting = true
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.orderSelectionToggled("O1"))) {
            $0.selectedOrderIDs = ["O1"]
        }

        // Then
        #expect(store.state.selectedOrderIDs == ["O1"])
    }

    /// 尚未進入多選模式時切換，進入多選模式
    @Test
    func selectionModeToggled_未在多選_進入多選() async {
        // Given
        let store = TestStore(initialState: OrdersFeature.State().list) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.selectionModeToggled)) {
            $0.isSelecting = true
        }

        // Then
        #expect(store.state.isSelecting)
    }

    /// 多選模式中再次點選已勾選訂單，將它移出勾選清單
    @Test
    func orderSelectionToggled_已勾選訂單_取消勾選() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            OrdersFeatureTests.makeOrder(id: "O1", category: "beauty"),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.isSelecting = true
        initial.list.selectedOrderIDs = ["O1"]
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.orderSelectionToggled("O1"))) {
            $0.selectedOrderIDs = []
        }

        // Then
        #expect(store.state.selectedOrderIDs.isEmpty)
    }

    /// 按下清除勾選後清空已勾選訂單，仍停在多選模式
    @Test
    func clearSelectionTapped_已勾選多筆_清空勾選並留在多選() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            OrdersFeatureTests.makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
            OrdersFeatureTests.makeOrder(id: "O2", categories: ["snacks"], status: .quoting),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.isSelecting = true
        initial.list.selectedOrderIDs = ["O1", "O2"]
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.clearSelectionTapped)) { $0.selectedOrderIDs = [] }

        // Then
        #expect(store.state.selectedOrderIDs.isEmpty)
        #expect(store.state.isSelecting)
    }

    /// 多選中點選全選後，只勾選目前篩選出的訂單
    @Test
    func selectAllTapped_多選中_勾選全部篩選後訂單() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            OrdersFeatureTests.makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
            OrdersFeatureTests.makeOrder(id: "O2", categories: ["snacks"], status: .quoting),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.isSelecting = true
        initial.list.selectedCategory = "beauty"
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.selectAllTapped)) { $0.selectedOrderIDs = ["O1"] }

        // Then
        #expect(store.state.selectedOrderIDs == ["O1"])
    }

    /// 批次目標狀態是已合併時不寫入任何訂單，也不離開多選
    @Test
    func batchStatusChanged_目標狀態為已合併_不寫入並維持選取() async {
        // Given
        let orders = [
            OrdersFeatureTests.makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
        ]
        var initial = OrdersFeature.State(orders: orders)
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.isSelecting = true
        initial.list.selectedOrderIDs = ["O1"]
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.batchStatusChanged(.merged)))

        // Then
        #expect(store.state.orders == orders)
        #expect(store.state.isSelecting)
        #expect(store.state.selectedOrderIDs == ["O1"])
    }
}
