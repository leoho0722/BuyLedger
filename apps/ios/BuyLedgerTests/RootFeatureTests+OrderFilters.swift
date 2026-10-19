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

    /// 從客戶頁點選客戶時，清除殘留的類別篩選，避免舊條件讓訂單消失
    @Test
    func more_客戶頁點選客戶_清空堆疊並清除殘留類別篩選() async {
        // Given
        var state = RootFeature.State()
        state.orders.$orders.withLock {
            $0 = LedgerOrder.sampleOrders
        }
        state.orders.list.selectedCategories = ["snacks", "books"]
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
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.orders.list.searchText = "Alice"
            $0.orders.list.selectedCategories = []
        }
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.list.searchText == "Alice")
        #expect(store.state.orders.list.selectedCategories == [])
    }

    /// 從分析頁點選類別時，切到訂單頁並清除狀態、日期區間與搜尋文字，只套用該類別
    @Test
    func insights_點選分類且有殘留其他篩選_重設篩選並套用分類() async {
        // Given
        var state = RootFeature.State()
        state.orders.$orders.withLock {
            $0 = LedgerOrder.sampleOrders
        }
        state.orders.list.selectedStatus = .status(.delivered)
        state.orders.list.selectedDatePeriod = .thisMonth
        state.orders.list.selectedCategories = ["snacks", "books"]
        state.orders.list.searchText = "stale query"
        state.orders.list.selectedOrderID = "BL-2604-016"

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.insights(.delegate(.categoryTapped("美妝")))) {
            $0.selectedTab = .orders
            $0.orders.list.selectedStatus = .all
            $0.orders.list.selectedDatePeriod = .all
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.orders.list.searchText = ""
            $0.orders.list.selectedCategories = ["美妝"]
            $0.orders.list.selectedOrderID = "BL-2604-018"
            $0.orders.detail.regularDetail = OrderDetailFeature.State(
                orderID: "BL-2604-018",
                orders: SharedReader($0.orders.$orders)
            )
        }

        // Then
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.list.selectedStatus == .all)
        #expect(store.state.orders.list.selectedDatePeriod == .all)
        #expect(store.state.orders.list.searchText == "")
        #expect(store.state.orders.list.selectedCategories == ["美妝"])
        #expect(store.state.orders.list.selectedOrderID == "BL-2604-018")
    }

    /// 從分析頁點選類別時只比對訂單的類別欄位，客戶名稱含有同樣的字不會被算進來
    @Test
    func insights_點選分類_依分類欄位而非搜尋文字篩選() async {
        // Given
        let realBeauty1 = Self.makeTestOrder(
            id: "O1",
            categories: ["beauty"],
            customerName: "Alice"
        )
        let falsePositive = Self.makeTestOrder(
            id: "O2",
            categories: ["snacks"],
            customerName: "Beauty Bob"
        )
        let realBeauty2 = Self.makeTestOrder(
            id: "O3",
            categories: ["beauty", "snacks"],
            customerName: "Carol"
        )
        let state = RootFeature.State()
        state.orders.$orders.withLock {
            $0 = [realBeauty1, falsePositive, realBeauty2]
        }

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.insights(.delegate(.categoryTapped("beauty")))) {
            $0.selectedTab = .orders
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.orders.list.selectedCategories = ["beauty"]
            $0.orders.list.selectedOrderID = "O1"
            $0.orders.detail.regularDetail = OrderDetailFeature.State(
                orderID: "O1",
                orders: SharedReader($0.orders.$orders)
            )
        }

        // Then
        let filteredIDs = store.state.orders.list.filteredOrders.map(\.id)
        #expect(filteredIDs == ["O1", "O3"])
    }

    /// 客戶頁開始載入時，要求訂單功能檢查是否需要重新讀取資料
    ///
    /// - Note: 訂單已載入時，`orders.rootRequest(.load)` 不再讀取資料，本測試只驗證轉送
    @Test
    func more_客戶頁要求載入訂單_送出訂單載入() async {
        // Given
        var state = RootFeature.State()
        state.orders.load.$hasLoaded.withLock {
            $0 = true
        }
        state.more.catalog.hasLoaded = true
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
        await store.send(.more(.path(.element(id: 0, action: .customers(.view(.task))))))

        // Then
        await store.receive(\.more.path[id: 0].customers.delegate.ordersLoadRequested)
        await store.receive(\.more.delegate.ordersLoadRequested)
        await store.receive(\.more.catalogLoadRequested)
        await store.receive(\.more.catalog.loadRequested)
        await store.receive(\.more.catalog.delegate.loadFinished)
        await store.receive(\.more.delegate.catalogLoadFinished)
        await store.receive(\.orders.rootRequest.load)
        await store.receive(\.orders.load.loadRequested)
    }

    /// 在「更多」的客戶頁點選客戶，先清空「更多」的頁面，再切到訂單分頁並以客戶名稱搜尋
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
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.orders.list.searchText = "Alice"
            $0.orders.list.selectedStatus = .all
            $0.orders.list.selectedDatePeriod = .all
        }
        #expect(store.state.more.path.isEmpty)
        #expect(store.state.selectedTab == .orders)
    }
}
