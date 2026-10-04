//
//  RootFeatureTests+OrderFilters.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 客戶深連結清除殘留類別篩選，避免舊條件讓訂單消失
    @Test
    func more_客戶頁點選客戶_清空堆疊並清除殘留類別篩選() async {
        // Given
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleOrders
        state.orders.selectedCategory = "精品"
        state.more.path.append(
            .customers(CustomersFeature.State(orders: SharedReader(state.more.$orders)))
        )

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .more(.path(.element(id: 0, action: .customers(.view(.customerTapped("Alice"))))))
        )

        // Then
        await store.receive(\.more.path[id: 0].customers.delegate.customerSelected, "Alice") {
            $0.more.path.removeAll()
        }
        await store.receive(\.more.delegate.customerSelected, "Alice") {
            $0.selectedTab = .orders
            $0.orders.searchText = "Alice"
            $0.orders.selectedCategory = nil
        }
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.searchText == "Alice")
        #expect(store.state.orders.selectedCategory == nil)
    }

    /// 從分析頁點類別時，切到訂單頁、重設狀態日期與搜尋篩選，只套用該類別
    @Test
    func insights_點選分類且有殘留其他篩選_重設篩選並套用分類() async {
        // Given
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleOrders
        state.orders.selectedStatus = .status(.delivered)
        state.orders.selectedDatePeriod = .thisMonth
        state.orders.searchText = "stale query"
        state.orders.selectedOrderID = "BL-2604-016"

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.insights(.delegate(.categoryTapped("美妝")))) {
            $0.selectedTab = .orders
            $0.orders.selectedStatus = .all
            $0.orders.selectedDatePeriod = .all
            $0.orders.searchText = ""
            $0.orders.selectedCategory = "美妝"
            $0.orders.selectedOrderID = "BL-2604-018"
        }

        // Then
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.selectedStatus == .all)
        #expect(store.state.orders.selectedDatePeriod == .all)
        #expect(store.state.orders.searchText == "")
        #expect(store.state.orders.selectedCategory == "美妝")
        #expect(store.state.orders.selectedOrderID == "BL-2604-018")
    }

    /// 類別深連結只比對訂單的類別欄位，不把客戶名稱中的字眼當成類別
    @Test
    func insights_點選分類_依分類欄位而非搜尋文字篩選() async {
        // Given
        let realBeauty1 = Self.makeTestOrder(
            id: "TEST-BEAUTY-1",
            category: "美妝",
            customerName: "林書宇"
        )
        let falsePositive = Self.makeTestOrder(
            id: "TEST-FALSE-1",
            category: "服飾",
            customerName: "美妝小編"
        )
        let realBeauty2 = Self.makeTestOrder(
            id: "TEST-BEAUTY-2",
            category: "美妝",
            customerName: "Carol"
        )
        var state = RootFeature.State()
        state.orders.orders = [realBeauty1, falsePositive, realBeauty2]

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.insights(.delegate(.categoryTapped("美妝")))) {
            $0.selectedTab = .orders
            $0.orders.selectedCategory = "美妝"
            $0.orders.selectedOrderID = "TEST-BEAUTY-1"
        }

        // Then
        let filteredIDs = store.state.orders
            .filteredOrders(
                referenceDate: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            .map(\.id)
        #expect(filteredIDs == ["TEST-BEAUTY-1", "TEST-BEAUTY-2"])
    }

    /// 客戶頁載入時，要求訂單功能檢查是否需要載入資料
    @Test
    func more_客戶頁要求載入訂單_送出訂單載入() async {
        // Given
        var state = RootFeature.State()
        // 已載入時 `orders.task` 不再讀資料，本測試只驗轉送
        state.orders.hasLoaded = true
        state.more.path.append(
            .customers(CustomersFeature.State(orders: SharedReader(state.more.$orders)))
        )

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.more(.path(.element(id: 0, action: .customers(.view(.task))))))

        // Then
        await store.receive(\.more.path[id: 0].customers.delegate.ordersLoadRequested)
        await store.receive(\.more.delegate.ordersLoadRequested)
        await store.receive(\.orders.task)
    }

    /// 從「更多」裡的客戶頁點選客戶，先清空更多路徑再切到訂單分頁並以客戶名搜尋
    @Test
    func more_客戶頁點選客戶_切換分頁前清空堆疊() async {
        // Given
        var state = RootFeature.State()
        state.selectedTab = .more
        state.more.path.append(
            .customers(CustomersFeature.State(orders: SharedReader(state.more.$orders)))
        )

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .more(.path(.element(id: 0, action: .customers(.view(.customerTapped("Alice"))))))
        )

        // Then
        await store.receive(\.more.path[id: 0].customers.delegate.customerSelected, "Alice") {
            $0.more.path.removeAll()
        }
        await store.receive(\.more.delegate.customerSelected, "Alice") {
            $0.selectedTab = .orders
            $0.orders.searchText = "Alice"
            $0.orders.selectedStatus = .all
            $0.orders.selectedDatePeriod = .all
        }
        #expect(store.state.more.path.isEmpty)
        #expect(store.state.selectedTab == .orders)
    }
}
