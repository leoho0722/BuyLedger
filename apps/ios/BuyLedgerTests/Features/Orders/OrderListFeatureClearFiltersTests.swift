//
//  OrderListFeatureClearFiltersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，以 TestStore 逐步驗證清除篩選的重設與重選行為
@MainActor
struct OrderListFeatureClearFiltersTests {

    /// 驗證狀態、搜尋與三項篩選同時生效時，清除只重設日期、類別與付款方式，`purchased` 狀態與 Alice 搜尋保留，重選後只通知一次選取變更
    ///
    /// - Throws: 前置篩選結果不符預期時由 `#require` 丟出
    @Test
    func clearFiltersTapped_狀態搜尋與三項篩選並用_重設三項並重選一次() async throws {
        // Given
        let state = OrderListFeatureTestSupport.makeClearFiltersState()
        try #require(state.filteredOrders.map(\.id) == ["selected"])
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
            $0.selectedOrderID = "restored"
        }

        // Then
        await store.receive(\.delegate.selectionChanged, "restored")
        #expect(store.state.selectedStatus == .status(.purchased))
        #expect(store.state.searchText == "Alice")
        #expect(
            store.state.filteredOrders.map(\.id) == [
                "restored",
                "dateOnly",
                "categoryOnly",
                "paymentOnly",
                "selected",
            ]
        )
        #expect(store.state.committedFilterSelection.isActive == false)
        #expect(store.state.destination == nil)
    }

    /// 驗證三項篩選已是預設時按下清除，選取、狀態與搜尋都保留，不重選也不通知清單，清除後篩選仍為未啟用 (狀態與搜尋不算在內)
    @Test
    func clearFiltersTapped_三項已是預設_保留選取且不委派() async {
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
        #expect(store.state.selectedOrderID == "selected")
        #expect(store.state.selectedStatus == .status(.purchased))
        #expect(store.state.searchText == "Alice")
        #expect(store.state.committedFilterSelection.isActive == false)
    }

    /// 驗證清除類別後，即使第一筆仍是 A，清單仍通知一次選取變更，選取的 A 不變
    @Test
    func clearFiltersTapped_類別變更但首筆相同_仍委派一次選取() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "A", date: TestDependencies.fixedNow, categories: ["beauty"]),
            LedgerOrder.fixture(id: "B", date: TestDependencies.fixedNow, categories: ["books"]),
        ])
        state.selectedCategories = ["beauty"]
        state.selectedOrderID = "A"
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
        await store.receive(\.delegate.selectionChanged, "A")
        #expect(store.state.selectedOrderID == "A")
        #expect(store.state.filteredOrders.map(\.id) == ["A", "B"])
    }

    /// 驗證清除後仍沒有訂單符合狀態與搜尋時，選取清為 `nil` 並通知清單，狀態與搜尋保留
    @Test
    func clearFiltersTapped_清除後仍沒有相符訂單_清空選取並委派() async {
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
        state.selectedOrderID = "removed"
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
            $0.selectedOrderID = nil
        }

        // Then
        await store.receive(\.delegate.selectionChanged, nil)
        #expect(store.state.selectedStatus == .status(.purchased))
        #expect(store.state.searchText == "Alice")
        #expect(store.state.filteredOrders.map(\.id) == [])
        #expect(store.state.committedFilterSelection.isActive == false)
    }

    /// 驗證已選的 beauty 從訂單與主檔都消失後，清除篩選會清空已選類別，並把剩餘的 remaining 訂單重新選為第一筆
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
        state.selectedOrderID = "removed"
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
            $0.selectedOrderID = "remaining"
        }

        // Then
        await store.receive(\.delegate.selectionChanged, "remaining")
        #expect(store.state.availableCategories == [])
        #expect(store.state.filteredOrders.map(\.id) == ["remaining"])
        #expect(store.state.hasCategoryFilter == false)
        #expect(store.state.committedFilterSelection.isActive == false)
    }
}
