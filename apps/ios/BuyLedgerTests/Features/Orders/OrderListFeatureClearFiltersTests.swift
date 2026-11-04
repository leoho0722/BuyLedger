//
//  OrderListFeatureClearFiltersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，以 `TestStore` 逐步驗證清除篩選的重設與結果顯示
@MainActor
struct OrderListFeatureClearFiltersTests {

    /// 驗證清除三項篩選後，`purchased` 狀態與 Alice 搜尋保留，結果列出符合條件的訂單，且不委派任何請求
    ///
    /// - Throws: 前置篩選結果不符預期時由 `#require` 丟出
    @Test
    func clearFiltersTapped_狀態搜尋與三項篩選並用_清除三項並保留狀態與搜尋() async throws {
        // Given
        let state = OrderListFeatureTestSupport.makeClearFiltersState()
        try #require(state.filteredOrders.map(\.id) == ["matched"])
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.clearFiltersTapped)) {
            $0.selectedDatePeriod = .all
            $0.selectedCategories = []
            $0.selectedPaymentMethod = nil
        }

        // Then
        #expect(store.state.selectedStatus == .status(.purchased))
        #expect(store.state.searchText == "Alice")
        #expect(
            store.state.filteredOrders.map(\.id) == [
                "restored",
                "dateOnly",
                "categoryOnly",
                "paymentOnly",
                "matched",
            ]
        )
        #expect(store.state.committedFilterSelection.isActive == false)
        #expect(store.state.destination == nil)
    }

    /// 驗證三項篩選已是預設時按下清除，狀態與搜尋都保留，不改變篩選，清除後篩選仍為未啟用 (狀態與搜尋不算在內)
    @Test
    func clearFiltersTapped_三項已是預設_保留狀態與搜尋且不委派() async {
        // Given
        var state = OrderListFeatureTestSupport.makeClearFiltersState()
        state.selectedDatePeriod = .all
        state.selectedCategories = []
        state.selectedPaymentMethod = nil
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.clearFiltersTapped))

        // Then
        #expect(store.state.selectedStatus == .status(.purchased))
        #expect(store.state.searchText == "Alice")
        #expect(store.state.committedFilterSelection.isActive == false)
    }

    /// 驗證類別變更後清除類別，清單顯示全部訂單，不委派任何請求
    @Test
    func clearFiltersTapped_類別變更後清除_顯示全部訂單且不委派() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "A", date: TestDependencies.fixedNow, categories: ["beauty"]),
            LedgerOrder.fixture(id: "B", date: TestDependencies.fixedNow, categories: ["books"]),
        ])
        state.selectedCategories = ["beauty"]
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.clearFiltersTapped)) {
            $0.selectedCategories = []
        }

        // Then
        #expect(store.state.filteredOrders.map(\.id) == ["A", "B"])
    }

    /// 驗證清除後仍沒有訂單符合狀態與搜尋時，篩選結果為空，狀態與搜尋保留，不委派任何請求
    @Test
    func clearFiltersTapped_清除後仍沒有相符訂單_保留狀態與搜尋且不委派() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            LedgerOrder.fixture(
                id: "wrongStatus",
                customer: LedgerCustomer(name: "Alice", initials: "AL", tier: .regular),
                status: .quoting,
                date: TestDependencies.fixedNow,
                categories: ["beauty"],
                paymentMethod: "現金"
            ),
            LedgerOrder.fixture(
                id: "wrongCustomer",
                customer: LedgerCustomer(name: "Bob", initials: "BO", tier: .regular),
                status: .purchased,
                date: TestDependencies.fixedNow,
                categories: ["beauty"],
                paymentMethod: "現金"
            ),
        ])
        state.selectedStatus = .status(.purchased)
        state.searchText = "Alice"
        state.selectedDatePeriod = .thisMonth
        state.selectedCategories = ["beauty"]
        state.selectedPaymentMethod = "現金"
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.clearFiltersTapped)) {
            $0.selectedDatePeriod = .all
            $0.selectedCategories = []
            $0.selectedPaymentMethod = nil
        }

        // Then
        #expect(store.state.selectedStatus == .status(.purchased))
        #expect(store.state.searchText == "Alice")
        #expect(store.state.filteredOrders.map(\.id) == [])
        #expect(store.state.committedFilterSelection.isActive == false)
    }

    /// 驗證已選類別從資料消失後，清除篩選會還原篩選條件並顯示剩餘訂單，不委派任何請求
    ///
    /// - Throws: 類別消失的前置條件不符時由 `#require` 丟出
    @Test
    func clearFiltersTapped_已選類別從資料消失_清空篩選並還原剩餘訂單() async throws {
        // Given
        let orders = Shared<[LedgerOrder]>(value: [
            LedgerOrder.fixture(
                id: "removed",
                date: TestDependencies.fixedNow,
                categories: ["beauty"]
            ),
        ])
        var state = OrderListFeature.State(orders: SharedReader(orders))
        state.$lookupCatalog = SharedReader(value: LookupCatalog())
        state.dateContext = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.selectedCategories = ["beauty"]
        orders.withLock {
            $0 = [LedgerOrder.fixture(id: "remaining", date: TestDependencies.fixedNow)]
        }
        try #require(state.availableCategories == [])
        try #require(state.selectedCategories == ["beauty"])
        try #require(state.filteredOrders == [])
        try #require(state.committedFilterSelection.isActive == true)
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.clearFiltersTapped)) {
            $0.selectedCategories = []
        }

        // Then
        #expect(store.state.availableCategories == [])
        #expect(store.state.filteredOrders.map(\.id) == ["remaining"])
        #expect(store.state.hasCategoryFilter == false)
        #expect(store.state.committedFilterSelection.isActive == false)
    }
}
