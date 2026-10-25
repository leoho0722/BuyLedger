//
//  OrderListFeatureFiltersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，以 TestStore 逐步驗證搜尋與篩選條件變更後的選取與列出結果
@MainActor
struct OrderListFeatureFiltersTests {

    /// 驗證搜尋文字命中客戶名稱或商品名稱時，清單只列出符合的訂單，選取改為第一筆符合的訂單
    ///
    /// - Parameter searchCase: 搜尋文字與預期的選取、列出結果
    @Test(arguments: [
        SearchCase(
            query: "mika",
            selectedOrderID: "BL-2604-017",
            expectedOrderIDs: ["BL-2604-017", "BL-2604-011"]
        ),
        SearchCase(
            query: "Aesop",
            selectedOrderID: "BL-2604-016",
            expectedOrderIDs: ["BL-2604-016"]
        ),
    ])
    func searchTextChanged_輸入客戶名稱或商品名稱_篩選訂單(searchCase: SearchCase) async {
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

    /// 驗證選取集運中狀態時，清單只列出集運中的訂單，並改選第一筆集運中的訂單
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

    /// 驗證類別選擇器以空集合套用時，類別篩選清空，清單回到全部訂單並改選第一筆 BL-2604-018
    @Test
    func destination_清除分類篩選_顯示全部訂單() async {
        // Given
        var initial = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.selectedCategories = ["服飾", "書籍"]
        initial.list.selectedOrderID = "BL-2604-017"
        initial.list.destination = .categoryPicker(
            OrderCategoryPickerFeatureTestSupport.makeState(for: initial.list)
        )
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.categoryPicker(.delegate(.applied([])))))) {
            $0.selectedCategories = []
            $0.selectedOrderID = "BL-2604-018"
            $0.destination = nil
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

    /// 驗證已套用狀態篩選時再套用類別 beauty，清單只留下同時符合狀態與類別的 O1，並改選它
    @Test
    func destination_分類與狀態篩選並用_只顯示同時相符訂單() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "O1", category: "beauty", status: .shipping),
            OrdersFeatureTestSupport.makeOrder(id: "O2", category: "beauty", status: .quoting),
            OrdersFeatureTestSupport.makeOrder(id: "O3", category: "snacks", status: .shipping),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.selectedStatus = .shipping
        initial.list.destination = .categoryPicker(
            OrderCategoryPickerFeatureTestSupport.makeState(for: initial.list)
        )
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .destination(.presented(.categoryPicker(.delegate(.applied(["beauty"])))))
        ) {
            $0.selectedCategories = ["beauty"]
            $0.selectedOrderID = "O1"
            $0.destination = nil
        }

        // Then
        await store.receive(\.delegate.selectionChanged)
        let filtered = store.state.filteredOrders
        #expect(filtered.map(\.id) == ["O1"])
    }

    /// 驗證付款方式選為全部 (`nil`) 時，清單回到全部訂單並改選第一筆 BL-2604-018
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

    /// 驗證已套用類別篩選時再選信用卡付款方式，清單只留下同時符合類別與付款方式的 P1，並改選它
    @Test
    func paymentMethodFilterSelected_分類與付款方式篩選並用_只顯示同時相符訂單() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "P1", category: "beauty", paymentMethod: "信用卡"),
            OrdersFeatureTestSupport.makeOrder(id: "P2", category: "beauty", paymentMethod: "現金"),
            OrdersFeatureTestSupport.makeOrder(id: "P3", category: "snacks", paymentMethod: "信用卡"),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.selectedCategories = ["beauty"]
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

    /// 驗證訂單帶多個分類時，只要其中一個符合所選的 beauty 就列出，選取改為第一筆 O1
    @Test
    func destination_訂單含多個分類_符合任一分類即顯示() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            OrdersFeatureTestSupport.makeOrder(
                id: "O1",
                categories: ["beauty"],
                status: .purchased
            ),
            OrdersFeatureTestSupport.makeOrder(
                id: "O2",
                categories: ["beauty", "snacks"],
                status: .quoting
            ),
            OrdersFeatureTestSupport.makeOrder(
                id: "O3",
                categories: ["snacks"],
                status: .purchased
            ),
            OrdersFeatureTestSupport.makeOrder(
                id: "O4",
                categories: ["beauty", "snacks"],
                status: .purchased
            ),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.destination = .categoryPicker(
            OrderCategoryPickerFeatureTestSupport.makeState(for: initial.list)
        )
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .destination(.presented(.categoryPicker(.delegate(.applied(["beauty"])))))
        ) {
            $0.selectedCategories = ["beauty"]
            $0.selectedOrderID = "O1"
            $0.destination = nil
        }

        // Then
        await store.receive(\.delegate.selectionChanged)
        let filtered = store.state.filteredOrders
        #expect(filtered.map(\.id) == ["O1", "O2", "O4"])
    }
}

// MARK: - Nested Types

extension OrderListFeatureFiltersTests {

    /// 訂單搜尋的測試案例，含搜尋文字、預期選取與列出結果
    ///
    /// - Note: 供測試方法的參數使用，型別需為 internal
    struct SearchCase: Sendable {

        /// 搜尋文字
        let query: String

        /// 預期選取的訂單識別碼 (篩選結果的第一筆)
        let selectedOrderID: String

        /// 預期篩選出的訂單識別碼
        let expectedOrderIDs: [String]
    }
}
