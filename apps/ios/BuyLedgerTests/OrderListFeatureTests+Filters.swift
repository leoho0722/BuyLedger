//
//  OrderListFeatureTests+Filters.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 搜尋輸入依客戶名稱或商品名稱篩選訂單
    ///
    /// - Parameter searchCase: 搜尋文字與預期的選取、列出結果
    @Test(arguments: [
        OrdersFeatureTests.SearchCase(
            query: "mika",
            selectedOrderID: "BL-2604-017",
            expectedOrderIDs: ["BL-2604-017", "BL-2604-011"]
        ),
        OrdersFeatureTests.SearchCase(
            query: "Aesop",
            selectedOrderID: "BL-2604-016",
            expectedOrderIDs: ["BL-2604-016"]
        ),
    ])
    func searchTextChanged_輸入客戶名稱或商品名稱_篩選訂單(searchCase: OrdersFeatureTests.SearchCase) async {
        // Given
        var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: state.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.searchTextChanged(searchCase.query))) {
            $0.searchText = searchCase.query
            $0.selectedOrderID = searchCase.selectedOrderID
        }

        // Then
        await store.receive(\.delegate.selectionChanged)
        let filtered = store.state.filteredOrders
        #expect(filtered.map(\.id) == searchCase.expectedOrderIDs)
    }

    /// 選取集運中篩選時，只列出集運中的訂單並改選第一筆相符訂單
    @Test
    func statusFilterSelected_選取訂單狀態_只顯示相符訂單() async {
        // Given
        var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: state.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.statusFilterSelected(.shipping))) {
            $0.selectedStatus = .shipping
            $0.selectedOrderID = "BL-2604-018"
        }

        // Then
        await store.receive(\.delegate.selectionChanged)
        let filtered = store.state.filteredOrders

        #expect(filtered.allSatisfy { $0.status == .shipping })
        #expect(filtered.map(\.id) == ["BL-2604-018", "BL-2604-011"])
    }

    /// 清除分類篩選後，清單回到全部訂單並改選第一筆
    @Test
    func categoryFilterSelected_清除分類篩選_顯示全部訂單() async {
        // Given
        var initial = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.selectedCategory = "服飾"
        initial.list.selectedOrderID = "BL-2604-017"
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.categoryFilterSelected(nil))) {
            $0.selectedCategory = nil
            $0.selectedOrderID = "BL-2604-018"
        }

        // Then
        await store.receive(\.delegate.selectionChanged)
        let filtered = store.state.filteredOrders
        #expect(
            filtered.map(\.id) == [
                "BL-2604-018",
                "BL-2604-017",
                "BL-2604-016",
                "BL-2604-015",
                "BL-2604-014",
                "BL-2604-013",
                "BL-2604-012",
                "BL-2604-011",
            ]
        )
    }

    /// 已套用狀態篩選時再選分類，只留下兩個條件都符合的訂單
    @Test
    func categoryFilterSelected_分類與狀態篩選並用_只顯示同時相符訂單() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            OrdersFeatureTests.makeOrder(id: "O1", category: "beauty", status: .shipping),
            OrdersFeatureTests.makeOrder(id: "O2", category: "beauty", status: .quoting),
            OrdersFeatureTests.makeOrder(id: "O3", category: "snacks", status: .shipping),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.selectedStatus = .shipping
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.categoryFilterSelected("beauty"))) {
            $0.selectedCategory = "beauty"
            $0.selectedOrderID = "O1"
        }

        // Then
        await store.receive(\.delegate.selectionChanged)
        let filtered = store.state.filteredOrders
        #expect(filtered.map(\.id) == ["O1"])
    }

    /// 清除付款方式篩選後，清單回到全部訂單並改選第一筆
    @Test
    func paymentMethodFilterSelected_清除付款方式篩選_顯示全部訂單() async {
        // Given
        var initial = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.selectedPaymentMethod = "銀行轉帳"
        initial.list.selectedOrderID = "BL-2604-017"
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.paymentMethodFilterSelected(nil))) {
            $0.selectedPaymentMethod = nil
            $0.selectedOrderID = "BL-2604-018"
        }

        // Then
        await store.receive(\.delegate.selectionChanged)
        let filtered = store.state.filteredOrders
        #expect(
            filtered.map(\.id) == [
                "BL-2604-018",
                "BL-2604-017",
                "BL-2604-016",
                "BL-2604-015",
                "BL-2604-014",
                "BL-2604-013",
                "BL-2604-012",
                "BL-2604-011",
            ]
        )
    }

    /// 已套用分類篩選時再選付款方式，只留下兩個條件都符合的訂單
    @Test
    func paymentMethodFilterSelected_分類與付款方式篩選並用_只顯示同時相符訂單() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            OrdersFeatureTests.makeOrder(id: "P1", category: "beauty", paymentMethod: "信用卡"),
            OrdersFeatureTests.makeOrder(id: "P2", category: "beauty", paymentMethod: "現金"),
            OrdersFeatureTests.makeOrder(id: "P3", category: "snacks", paymentMethod: "信用卡"),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.selectedCategory = "beauty"
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.paymentMethodFilterSelected("信用卡"))) {
            $0.selectedPaymentMethod = "信用卡"
            $0.selectedOrderID = "P1"
        }

        // Then
        await store.receive(\.delegate.selectionChanged)
        let filtered = store.state.filteredOrders
        #expect(filtered.map(\.id) == ["P1"])
    }

    /// 訂單有多個分類時，只要其中一個符合所選分類就顯示
    @Test
    func categoryFilterSelected_訂單含多個分類_符合任一分類即顯示() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            OrdersFeatureTests.makeOrder(id: "O1", categories: ["beauty"], status: .purchased),
            OrdersFeatureTests.makeOrder(
                id: "O2",
                categories: ["beauty", "snacks"],
                status: .quoting
            ),
            OrdersFeatureTests.makeOrder(id: "O3", categories: ["snacks"], status: .purchased),
            OrdersFeatureTests.makeOrder(
                id: "O4",
                categories: ["beauty", "snacks"],
                status: .purchased
            ),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.categoryFilterSelected("beauty"))) {
            $0.selectedCategory = "beauty"
            $0.selectedOrderID = "O1"
        }

        // Then
        await store.receive(\.delegate.selectionChanged)
        let filtered = store.state.filteredOrders
        #expect(filtered.map(\.id) == ["O1", "O2", "O4"])
    }
}
