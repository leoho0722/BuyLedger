//
//  OrderListFeatureFiltersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，以 `TestStore` 逐步驗證搜尋與篩選條件變更後的列出結果
@MainActor
struct OrderListFeatureFiltersTests {

    /// 驗證搜尋文字命中客戶名稱或商品名稱時，只列出符合的訂單，不委派任何請求
    ///
    /// - Parameter searchCase: 搜尋文字與預期的列出結果
    @Test(arguments: [
        SearchCase(query: "mika", expectedOrderIDs: ["BL-2604-017", "BL-2604-011"]),
        SearchCase(query: "Aesop", expectedOrderIDs: ["BL-2604-016"]),
    ])
    func searchTextChanged_多組查詢_只列出符合的訂單(searchCase: SearchCase) async {
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
        }

        // Then
        let filtered = store.state.filteredOrders
        #expect(filtered.map(\.id) == searchCase.expectedOrderIDs)
    }

    /// 驗證套用集運中狀態時，只列出相符訂單，不委派任何請求
    @Test
    func statusFilterSelected_集運中狀態_只列出相符訂單() async {
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
        }

        // Then
        let filtered = store.state.filteredOrders
        #expect(filtered.allSatisfy { $0.status == .shipping })
        #expect(filtered.map(\.id) == ["BL-2604-018", "BL-2604-011"])
    }

    /// 驗證清除類別篩選後列出全部訂單，不委派任何請求
    @Test
    func destination_清除分類篩選_列出全部訂單() async {
        // Given
        var initial = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.selectedCategories = ["服飾", "書籍"]
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
            $0.destination = nil
        }

        // Then
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

    /// 驗證已套用狀態篩選時再套用類別 beauty，只列出同時符合的 O1，不委派任何請求
    @Test
    func destination_分類與狀態篩選並用_只列出同時符合的訂單() async {
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
            $0.destination = nil
        }

        // Then
        let filtered = store.state.filteredOrders
        #expect(filtered.map(\.id) == ["O1"])
    }

    /// 驗證清除付款方式篩選後列出全部訂單，不委派任何請求
    @Test
    func paymentMethodFilterSelected_清除付款方式篩選_列出全部訂單() async {
        // Given
        var initial = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.selectedPaymentMethod = "銀行轉帳"
        let store = TestStore(initialState: initial.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.paymentMethodFilterSelected(nil))) {
            $0.selectedPaymentMethod = nil
        }

        // Then
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

    /// 驗證已套用類別篩選時再選信用卡付款方式，只列出同時符合的 P1，不委派任何請求
    @Test
    func paymentMethodFilterSelected_分類與付款方式篩選並用_只列出同時符合的訂單() async {
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
        }

        // Then
        let filtered = store.state.filteredOrders
        #expect(filtered.map(\.id) == ["P1"])
    }

    /// 驗證訂單帶多個分類時，符合任一所選類別就列出，不委派任何請求
    @Test
    func destination_訂單含多個分類_符合任一類別只列出命中訂單() async {
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
            $0.destination = nil
        }

        // Then
        let filtered = store.state.filteredOrders
        #expect(filtered.map(\.id) == ["O1", "O2", "O4"])
    }
}

// MARK: - Nested Types

extension OrderListFeatureFiltersTests {

    /// 訂單搜尋的測試案例，含搜尋文字與預期列出結果
    ///
    /// - Note: 供測試方法的參數使用，型別需為 internal
    struct SearchCase: Sendable {

        /// 搜尋文字
        let query: String

        /// 預期篩選出的訂單識別碼
        let expectedOrderIDs: [String]
    }
}
