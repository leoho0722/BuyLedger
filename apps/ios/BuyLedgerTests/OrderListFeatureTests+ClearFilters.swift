//
//  OrderListFeatureTests+ClearFilters.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 規格的清除只重設三項，保留 purchased 與 Alice，重選後僅委派一次
    ///
    /// - Throws: 前置篩選結果不符預期時由驗證前置條件丟出
    @Test
    func clearFiltersTapped_狀態搜尋與三項篩選並用_重設三項並重選一次() async throws {
        // Given
        let state = Self.makeClearFiltersState()
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

    /// 預設三項時不重選第二筆，不委派，狀態與搜尋不影響停用條件
    @Test
    func clearFiltersTapped_三項已是預設_保留選取且不委派() async {
        // Given
        var state = Self.makeClearFiltersState()
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

    /// 有篩選變更但首筆識別值相同時仍沿用選取委派一次
    @Test
    func clearFiltersTapped_類別變更但首筆相同_仍委派一次選取() async {
        // Given
        var state = Self.makeState(orders: [
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

    /// 清除後仍沒有符合狀態與搜尋的訂單時，清空詳情選取並委派 nil
    @Test
    func clearFiltersTapped_清除後仍沒有相符訂單_清空選取並委派() async {
        // Given
        var state = Self.makeState()
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
        #expect(store.state.filteredOrders == [])
        #expect(store.state.committedFilterSelection.isActive == false)
    }

    /// 已選 beauty 從資料與主檔消失後，清除仍可還原沒有類別的剩餘訂單
    ///
    /// - Throws: 類別消失前置條件不符時由驗證前置條件丟出
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
