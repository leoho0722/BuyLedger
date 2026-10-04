//
//  RootFeatureTests+Sidebar.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 選取智慧分組後切到訂單頁，套用狀態並選取第一筆符合的訂單
    ///
    /// - Parameters:
    ///   - status: 智慧分組代表的訂單狀態
    ///   - expectedOrderID: 預期選取的第一筆訂單識別值
    @Test(arguments: [
        (status: OrderStatus.shipping, expectedOrderID: "BL-2604-018"),
        (status: OrderStatus.purchased, expectedOrderID: "BL-2604-017"),
    ])
    func smartGroupSelected_選取智慧分組_切至訂單並選取第一筆符合訂單(
        status: OrderStatus,
        expectedOrderID: String
    ) async {
        // Given
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleOrders

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.smartGroupSelected(status))) {
            $0.selectedTab = .orders
            $0.orders.selectedStatus = .status(status)
            $0.orders.selectedOrderID = expectedOrderID
        }

        // Then
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.selectedStatus == .status(status))
        #expect(store.state.orders.selectedOrderID == expectedOrderID)
    }

    /// iPad 側邊欄切換分頁前清空「更多」路徑
    @Test
    func sidebarTabSelected_更多路徑非空_清空路徑並切換分頁() async {
        // Given
        var state = Self.makeIsolatedRootState {
            var initial = RootFeature.State()
            initial.more.path.append(
                .lookupManagement(LookupManagementFeature.State(kind: .category))
            )
            return initial
        }
        state.selectedTab = .more

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.view(.sidebarTabSelected(.orders))) {
            $0.more.path.removeAll()
            $0.selectedTab = .orders
        }

        // Then
        #expect(store.state.more.path.isEmpty)
        #expect(store.state.selectedTab == .orders)
    }

    /// iPad 側邊欄選取目前分頁時不清空「更多」路徑
    @Test
    func sidebarTabSelected_選取目前分頁_不清空更多路徑() async {
        // Given
        var state = Self.makeIsolatedRootState {
            var initial = RootFeature.State()
            initial.more.path.append(
                .lookupManagement(LookupManagementFeature.State(kind: .category))
            )
            return initial
        }
        state.selectedTab = .more

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.view(.sidebarTabSelected(.more)))

        // Then
        #expect(store.state.more.path.count == 1)
        #expect(store.state.selectedTab == .more)
    }

    /// iPad 側邊欄的智慧分組切到訂單頁前清空「更多」路徑
    @Test
    func smartGroupSelected_從更多頁選取智慧分組_清空更多路徑() async {
        // Given
        var state = Self.makeIsolatedRootState {
            var initial = RootFeature.State()
            initial.more.path.append(
                .lookupManagement(LookupManagementFeature.State(kind: .category))
            )
            return initial
        }
        state.selectedTab = .more

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.smartGroupSelected(.shipping))) {
            $0.more.path.removeAll()
            $0.selectedTab = .orders
            $0.orders.selectedStatus = .status(.shipping)
        }

        // Then
        #expect(store.state.more.path.isEmpty)
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.selectedStatus == .status(.shipping))
    }

    /// 智慧分組只切換狀態篩選，不覆寫既有日期區間與類別
    @Test
    func smartGroupSelected_已有日期與類別篩選_只切換狀態篩選() async {
        // Given
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleOrders
        state.orders.selectedStatus = .status(.delivered)
        state.orders.selectedDatePeriod = .thisMonth
        state.orders.selectedCategory = "美妝"
        state.orders.selectedOrderID = "BL-2604-016"

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.smartGroupSelected(.shipping))) {
            $0.selectedTab = .orders
            $0.orders.selectedStatus = .status(.shipping)
            $0.orders.selectedOrderID = "BL-2604-018"
        }

        // Then
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.selectedStatus == .status(.shipping))
        #expect(store.state.orders.selectedDatePeriod == .thisMonth)
        #expect(store.state.orders.selectedCategory == "美妝")
    }
}
