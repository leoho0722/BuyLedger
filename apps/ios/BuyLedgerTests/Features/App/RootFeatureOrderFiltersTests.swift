//
//  RootFeatureOrderFiltersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 `TestStore` 驗證客戶頁與分析頁開啟訂單時來源狀態與篩選的更新
@MainActor
struct RootFeatureOrderFiltersTests {

    /// 驗證客戶頁點選不同客戶時保留來源頁，沿用搜尋並清空不符的詳情路徑
    ///
    /// - Throws: 找不到來源路徑識別碼時由 `#require` 丟出
    @Test
    func more_客戶頁點選不同客戶_沿用搜尋並清空不命中路徑() async throws {
        // Given
        let sourceOrders = [
            RootFeatureTestSupport.makeTestOrder(
                id: "CUSTOMER-1",
                categories: ["snacks"],
                customerName: "Alice"
            ),
            RootFeatureTestSupport.makeTestOrder(
                id: "CUSTOMER-2",
                categories: ["snacks"],
                customerName: "Bob"
            ),
        ]
        let state = RootFeatureTestSupport.makeIsolatedRootState {
            var initial = RootFeature.State()
            initial.orders.$orders.withLock {
                $0 = sourceOrders
            }
            initial.more.$orders.withLock {
                $0 = sourceOrders
            }
            initial.orders.list.selectedCategories = ["snacks", "books"]
            initial.orders.detail.showDetail(orderID: "CUSTOMER-2")
            initial.more.path.append(
                .customers(
                    CustomersFeature.State(
                        orders: SharedReader(initial.more.$orders),
                        loadState: SharedReader(initial.more.$ordersLoadState)
                    )
                )
            )
            return initial
        }
        let sourcePathID = try #require(state.more.path.ids.first)

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .more(
                .path(
                    .element(id: sourcePathID, action: .customers(.view(.customerTapped("Alice"))))
                )
            )
        )

        // Then
        await store.receive(
            \.more.path[id: sourcePathID].customers.delegate.customerSelected,
            "Alice"
        )
        await store.receive(\.more.delegate.customerSelected, "Alice") {
            $0.selectedTab = .orders
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.orders.list.searchText = "Alice"
            $0.orders.list.selectedCategories = []
            $0.orders.detail.path.removeAll()
        }
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.list.searchText == "Alice")
        #expect(store.state.orders.list.selectedCategories == [])
        #expect(Array(store.state.more.path.ids) == [sourcePathID])
        #expect(store.state.more.path[id: sourcePathID, case: \.customers]?.orders == sourceOrders)
    }

    /// 驗證客戶搜尋命中目前與更前面的訂單時，保留詳情路徑與其詳情
    ///
    /// - Throws: 找不到來源路徑識別碼時由 `#require` 丟出
    @Test
    func more_客戶搜尋仍命中非首筆_保留原詳情路徑() async throws {
        // Given
        let sourceOrders = [
            RootFeatureTestSupport.makeTestOrder(
                id: "CUSTOMER-0",
                categories: ["snacks"],
                customerName: "Alice"
            ),
            RootFeatureTestSupport.makeTestOrder(
                id: "CUSTOMER-1",
                categories: ["snacks"],
                customerName: "Alice"
            ),
        ]
        let state = RootFeatureTestSupport.makeIsolatedRootState {
            var initial = RootFeature.State()
            initial.orders.$orders.withLock {
                $0 = sourceOrders
            }
            initial.more.$orders.withLock {
                $0 = sourceOrders
            }
            initial.orders.detail.showDetail(orderID: "CUSTOMER-1")
            initial.more.path.append(
                .customers(
                    CustomersFeature.State(
                        orders: SharedReader(initial.more.$orders),
                        loadState: SharedReader(initial.more.$ordersLoadState)
                    )
                )
            )
            return initial
        }
        let sourcePathID = try #require(state.more.path.ids.first)

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .more(
                .path(
                    .element(id: sourcePathID, action: .customers(.view(.customerTapped("Alice"))))
                )
            )
        )

        // Then
        await store.receive(
            \.more.path[id: sourcePathID].customers.delegate.customerSelected,
            "Alice"
        )
        await store.receive(\.more.delegate.customerSelected, "Alice") {
            $0.selectedTab = .orders
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.orders.list.searchText = "Alice"
        }
        #expect(store.state.orders.detail.path.count == 1)
        #expect(store.state.orders.detail.path.last?.detail?.orderID == "CUSTOMER-1")
        #expect(Array(store.state.more.path.ids) == [sourcePathID])
        #expect(store.state.more.path[id: sourcePathID, case: \.customers]?.orders == sourceOrders)
    }

    /// 驗證客戶搜尋仍命中目前推入的詳情時，保留詳情路徑元素識別值
    ///
    /// - Throws: 找不到來源或訂單路徑識別碼時由 `#require` 丟出
    @Test
    func more_客戶導覽命中目前詳情_保留path識別值() async throws {
        // Given
        let sourceOrders = [
            RootFeatureTestSupport.makeTestOrder(
                id: "CUSTOMER-0",
                categories: ["snacks"],
                customerName: "Alice"
            ),
            RootFeatureTestSupport.makeTestOrder(
                id: "CUSTOMER-1",
                categories: ["snacks"],
                customerName: "Alice"
            ),
        ]
        let state = RootFeatureTestSupport.makeIsolatedRootState {
            var initial = RootFeature.State()
            initial.selectedTab = .more
            initial.orders.$orders.withLock {
                $0 = sourceOrders
            }
            initial.more.$orders.withLock {
                $0 = sourceOrders
            }
            initial.orders.list.selectedCategories = ["snacks"]
            initial.orders.detail.showDetail(orderID: "CUSTOMER-1")
            initial.more.path.append(
                .customers(
                    CustomersFeature.State(
                        orders: SharedReader(initial.more.$orders),
                        loadState: SharedReader(initial.more.$ordersLoadState)
                    )
                )
            )
            return initial
        }
        let sourcePathID = try #require(state.more.path.ids.first)
        let initialOrderPathIDs = Array(state.orders.detail.path.ids)
        try #require(initialOrderPathIDs.count == 1)
        try #require(state.orders.detail.path.first?.detail?.orderID == "CUSTOMER-1")

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .more(
                .path(
                    .element(id: sourcePathID, action: .customers(.view(.customerTapped("Alice"))))
                )
            )
        )

        // Then
        await store.receive(
            \.more.path[id: sourcePathID].customers.delegate.customerSelected,
            "Alice"
        )
        await store.receive(\.more.delegate.customerSelected, "Alice") {
            $0.selectedTab = .orders
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.orders.list.searchText = "Alice"
            $0.orders.list.selectedCategories = []
        }

        #expect(store.state.orders.detail.path.last?.detail?.orderID == "CUSTOMER-1")
        #expect(store.state.orders.list.filteredOrders.map(\.id) == ["CUSTOMER-0", "CUSTOMER-1"])
        #expect(Array(store.state.orders.detail.path.ids) == initialOrderPathIDs)
        #expect(store.state.orders.detail.path.first?.detail?.orderID == "CUSTOMER-1")
        #expect(Array(store.state.more.path.ids) == [sourcePathID])
    }

    /// 驗證客戶搜尋排除仍存在的推入詳情時，清空詳情路徑
    ///
    /// - Throws: 找不到來源或訂單路徑識別碼時由 `#require` 丟出
    @Test
    func more_客戶導覽排除仍存在詳情_清空path() async throws {
        // Given
        let sourceOrders = [
            RootFeatureTestSupport.makeTestOrder(
                id: "CUSTOMER-1",
                categories: ["snacks"],
                customerName: "Alice"
            ),
            RootFeatureTestSupport.makeTestOrder(
                id: "CUSTOMER-2",
                categories: ["snacks"],
                customerName: "Bob"
            ),
        ]
        let state = RootFeatureTestSupport.makeIsolatedRootState {
            var initial = RootFeature.State()
            initial.selectedTab = .more
            initial.orders.$orders.withLock {
                $0 = sourceOrders
            }
            initial.more.$orders.withLock {
                $0 = sourceOrders
            }
            initial.orders.list.selectedCategories = ["snacks"]
            initial.orders.detail.showDetail(orderID: "CUSTOMER-2")
            initial.more.path.append(
                .customers(
                    CustomersFeature.State(
                        orders: SharedReader(initial.more.$orders),
                        loadState: SharedReader(initial.more.$ordersLoadState)
                    )
                )
            )
            return initial
        }
        let sourcePathID = try #require(state.more.path.ids.first)
        let initialOrderPathIDs = Array(state.orders.detail.path.ids)
        try #require(initialOrderPathIDs.count == 1)
        try #require(state.orders.detail.path.first?.detail?.orderID == "CUSTOMER-2")

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .more(
                .path(
                    .element(id: sourcePathID, action: .customers(.view(.customerTapped("Alice"))))
                )
            )
        )

        // Then
        await store.receive(
            \.more.path[id: sourcePathID].customers.delegate.customerSelected,
            "Alice"
        )
        await store.receive(\.more.delegate.customerSelected, "Alice") {
            $0.selectedTab = .orders
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.orders.list.searchText = "Alice"
            $0.orders.list.selectedCategories = []
            $0.orders.detail.path.removeAll()
        }

        #expect(store.state.orders.list.searchText == "Alice")
        #expect(store.state.orders.list.filteredOrders.map(\.id) == ["CUSTOMER-1"])
        #expect(store.state.orders.detail.path.isEmpty)
        #expect(Array(store.state.more.path.ids) == [sourcePathID])
    }

    /// 驗證分析頁點選類別時，重設其他篩選並保留仍符合類別的詳情路徑
    @Test
    func insights_點選分類且有殘留其他篩選_重設篩選並保留符合路徑() async {
        // Given
        var state = RootFeature.State()
        state.orders.$orders.withLock {
            $0 = LedgerOrder.sampleOrders
        }
        state.orders.list.selectedStatus = .status(.delivered)
        state.orders.list.selectedDatePeriod = .thisMonth
        state.orders.list.selectedCategories = ["snacks", "books"]
        state.orders.list.searchText = "stale query"
        state.orders.detail.showDetail(orderID: "BL-2604-016")

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
        }

        // Then
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.list.selectedStatus == .all)
        #expect(store.state.orders.list.selectedDatePeriod == .all)
        #expect(store.state.orders.list.searchText == "")
        #expect(store.state.orders.list.selectedCategories == ["美妝"])
        #expect(store.state.orders.detail.path.last?.detail?.orderID == "BL-2604-016")
    }

    /// 驗證分析頁點選類別時只比對訂單類別，只列出符合的訂單，不自動開啟詳情
    @Test
    func insights_點選分類_只篩分類且不自動開啟詳情() async {
        // Given
        let realBeauty1 = RootFeatureTestSupport.makeTestOrder(
            id: "O1",
            categories: ["beauty"],
            customerName: "Alice"
        )
        let falsePositive = RootFeatureTestSupport.makeTestOrder(
            id: "O2",
            categories: ["snacks"],
            customerName: "Beauty Bob"
        )
        let realBeauty2 = RootFeatureTestSupport.makeTestOrder(
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
        }

        // Then
        let filteredIDs = store.state.orders.list.filteredOrders.map(\.id)
        #expect(filteredIDs == ["O1", "O3"])
        #expect(store.state.orders.detail.path.isEmpty)
    }

    /// 驗證客戶頁開始載入時，送出訂單載入請求，由訂單判斷是否需要重新讀取資料
    ///
    /// - Note: 訂單已載入時，`orders.rootRequest(.load)` 不再讀取資料，本測試只驗證請求已送出
    @Test
    func more_客戶頁要求載入訂單_送出訂單載入() async {
        // Given
        var state = RootFeature.State()
        state.orders.load.$hasLoaded.withLock {
            $0 = true
        }
        state.more.catalog.hasLoaded = true
        state.more.path.append(
            .customers(
                CustomersFeature.State(
                    orders: SharedReader(state.more.$orders),
                    loadState: SharedReader(state.more.$ordersLoadState)
                )
            )
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

    /// 驗證在「更多」的客戶頁點選客戶時，來源頁保留、訂單搜尋條件更新，且不自動開啟訂單詳情
    ///
    /// - Throws: 找不到來源路徑識別碼時由 `#require` 丟出
    @Test
    func more_客戶頁點選客戶_無詳情路徑且不自動開啟詳情() async throws {
        // Given
        let sourceOrders = [
            RootFeatureTestSupport.makeTestOrder(
                id: "CUSTOMER-2",
                categories: [],
                customerName: "Alice"
            ),
        ]
        let state = RootFeatureTestSupport.makeIsolatedRootState {
            var initial = RootFeature.State()
            initial.selectedTab = .more
            initial.orders.list.selectedStatus = .status(.delivered)
            initial.orders.list.selectedDatePeriod = .thisMonth
            initial.orders.list.searchText = "stale query"
            initial.orders.$orders.withLock {
                $0 = sourceOrders
            }
            initial.more.$orders.withLock {
                $0 = sourceOrders
            }
            initial.more.path.append(
                .customers(
                    CustomersFeature.State(
                        orders: SharedReader(initial.more.$orders),
                        loadState: SharedReader(initial.more.$ordersLoadState)
                    )
                )
            )
            return initial
        }
        let sourcePathID = try #require(state.more.path.ids.first)

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .more(
                .path(
                    .element(id: sourcePathID, action: .customers(.view(.customerTapped("Alice"))))
                )
            )
        )

        // Then
        await store.receive(
            \.more.path[id: sourcePathID].customers.delegate.customerSelected,
            "Alice"
        )
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
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.detail.path.isEmpty)
        #expect(Array(store.state.more.path.ids) == [sourcePathID])
        #expect(store.state.more.path[id: sourcePathID, case: \.customers]?.orders == sourceOrders)
    }
}
