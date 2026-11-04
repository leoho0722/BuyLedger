//
//  RootFeatureDetailNavigationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 `TestStore` 驗證詳情已顯示訂單時，從分析頁開啟類別深連結的導覽行為
@MainActor
struct RootFeatureDetailNavigationTests {

    /// 驗證分析頁點選類別時，切到訂單分頁並清空不符類別的 A 詳情路徑，不改開 B
    ///
    /// - Throws: 初始詳情不是訂單 A 時由 `try #require` 丟出
    @Test
    func insights_詳情已有訂單時開類別深連結_清空path而不改開其他訂單() async throws {
        // Given
        var initial = RootFeatureTestSupport.makeIsolatedRootState()
        initial.orders.$orders.withLock {
            $0 = [
                LedgerOrder.fixture(id: "A", categories: ["服飾"]),
                LedgerOrder.fixture(id: "B", categories: ["美妝"]),
            ]
        }
        initial.orders.detail.showDetail(orderID: "A")
        try #require(initial.orders.detail.path.last?.detail?.orderID == "A")
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.insights(.delegate(.categoryTapped("美妝")))) {
            $0.selectedTab = .orders
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.orders.list.selectedCategories = ["美妝"]
            $0.orders.detail.path.removeAll()
        }

        // Then
        #expect(store.state.orders.detail.path.isEmpty)
    }

    /// 驗證分析類別仍命中目前推入的詳情時，保留詳情路徑元素識別值
    ///
    /// - Throws: 初始詳情路徑不符時由 `#require` 丟出
    @Test
    func insights_類別導覽命中目前詳情_保留path識別值() async throws {
        // Given
        var initial = RootFeatureTestSupport.makeIsolatedRootState()
        initial.orders.$orders.withLock {
            $0 = [
                LedgerOrder.fixture(id: "B", categories: ["美妝"]),
                LedgerOrder.fixture(id: "A", categories: ["美妝"]),
            ]
        }
        initial.orders.detail.showDetail(orderID: "A")
        let initialOrderPathIDs = Array(initial.orders.detail.path.ids)
        try #require(initialOrderPathIDs.count == 1)
        try #require(initial.orders.detail.path.first?.detail?.orderID == "A")
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.insights(.delegate(.categoryTapped("美妝")))) {
            $0.selectedTab = .orders
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.orders.list.selectedCategories = ["美妝"]
        }

        // Then
        #expect(store.state.orders.detail.path.last?.detail?.orderID == "A")
        #expect(store.state.orders.list.filteredOrders.map(\.id) == ["B", "A"])
        #expect(Array(store.state.orders.detail.path.ids) == initialOrderPathIDs)
        #expect(store.state.orders.detail.path.first?.detail?.orderID == "A")
    }

    /// 驗證分析類別排除仍存在的推入詳情時，清空詳情路徑，列出剩餘訂單
    ///
    /// - Throws: 初始詳情路徑不符時由 `#require` 丟出
    @Test
    func insights_類別導覽排除仍存在詳情_清空path() async throws {
        // Given
        var initial = RootFeatureTestSupport.makeIsolatedRootState()
        initial.orders.$orders.withLock {
            $0 = [
                LedgerOrder.fixture(id: "A", categories: ["服飾"]),
                LedgerOrder.fixture(id: "B", categories: ["美妝"]),
            ]
        }
        initial.orders.detail.showDetail(orderID: "A")
        let initialOrderPathIDs = Array(initial.orders.detail.path.ids)
        try #require(initialOrderPathIDs.count == 1)
        try #require(initial.orders.detail.path.first?.detail?.orderID == "A")
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.insights(.delegate(.categoryTapped("美妝")))) {
            $0.selectedTab = .orders
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.orders.list.selectedCategories = ["美妝"]
            $0.orders.detail.path.removeAll()
        }

        // Then
        #expect(store.state.orders.list.filteredOrders.map(\.id) == ["B"])
        #expect(store.state.orders.detail.path.isEmpty)
    }
}
