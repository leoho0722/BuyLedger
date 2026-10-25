//
//  OrderListFeatureSelectionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，以 TestStore 逐步驗證多選模式的勾選、清除、全選與批次狀態變更
@MainActor
struct OrderListFeatureSelectionTests {

    /// 驗證多選中已勾選訂單時按下切換，離開多選模式並清空所有勾選
    @Test
    func selectionModeToggled_多選中已勾選訂單_離開並清空勾選() async {
        // Given
        let initialOrders = [
            OrdersFeatureTestSupport.makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
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
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
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

    /// 驗證多選模式中點選未勾選的訂單 O1 時，將它加入勾選清單
    @Test
    func orderSelectionToggled_未勾選訂單_加入勾選() async {
        // Given
        let initialOrders = [
            OrdersFeatureTestSupport.makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
        ]
        var initial = OrdersFeature.State(orders: initialOrders)
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.isSelecting = true
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.orderSelectionToggled("O1"))) {
            $0.selectedOrderIDs = ["O1"]
        }

        // Then
        #expect(store.state.selectedOrderIDs == ["O1"])
    }

    /// 驗證未在多選模式時按下切換，進入多選模式
    @Test
    func selectionModeToggled_未在多選_進入多選() async {
        // Given
        let store = TestStore(initialState: OrdersFeature.State().list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.selectionModeToggled)) {
            $0.isSelecting = true
        }

        // Then
        #expect(store.state.isSelecting)
    }

    /// 驗證多選模式中再次點選已勾選的訂單 O1 時，將它移出勾選清單
    @Test
    func orderSelectionToggled_已勾選訂單_取消勾選() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "O1", category: "beauty"),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.isSelecting = true
        initial.list.selectedOrderIDs = ["O1"]
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.orderSelectionToggled("O1"))) {
            $0.selectedOrderIDs = []
        }

        // Then
        #expect(store.state.selectedOrderIDs.isEmpty)
    }

    /// 驗證已勾選多筆訂單時按下清除勾選，清空所有勾選，但仍停留在多選模式
    @Test
    func clearSelectionTapped_已勾選多筆_清空勾選並留在多選() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
            OrdersFeatureTestSupport.makeOrder(id: "O2", categories: ["snacks"], status: .quoting),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.isSelecting = true
        initial.list.selectedOrderIDs = ["O1", "O2"]
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.clearSelectionTapped)) {
            $0.selectedOrderIDs = []
        }

        // Then
        #expect(store.state.selectedOrderIDs.isEmpty)
        #expect(store.state.isSelecting)
    }

    /// 驗證多選中按下全選時，只勾選目前篩選出的 O1，篩選外的 O2 不會被勾選
    @Test
    func selectAllTapped_多選中_勾選全部篩選後訂單() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
            OrdersFeatureTestSupport.makeOrder(id: "O2", categories: ["snacks"], status: .quoting),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.isSelecting = true
        initial.list.selectedCategories = ["beauty"]
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.selectAllTapped)) {
            $0.selectedOrderIDs = ["O1"]
        }

        // Then
        #expect(store.state.selectedOrderIDs == ["O1"])
    }

    /// 驗證批次改狀態的目標為已合併時，不寫入任何訂單，多選模式與既有勾選都保留
    @Test
    func batchStatusChanged_目標狀態為已合併_不寫入並維持選取() async {
        // Given
        let orders = [
            OrdersFeatureTestSupport.makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
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
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.batchStatusChanged(.merged)))

        // Then
        #expect(store.state.orders == orders)
        #expect(store.state.isSelecting)
        #expect(store.state.selectedOrderIDs == ["O1"])
    }
}
