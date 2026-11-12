//
//  CustomersFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/12.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CustomersFeature` 的單元測試，涵蓋客戶彙總、載入畫面狀態，以及送給更多頁的載入與點選事件
@MainActor
struct CustomersFeatureTests {

    // MARK: - Properties

    /// 規格四列訂單載入狀態、訂單資料與預期畫面內容
    ///
    /// - Note: `nonisolated` 讓 `@Test(arguments:)` 在進入主執行緒隔離前讀取案例
    nonisolated private static let screenStateScenarios: [ScreenStateScenario] = [
        ScreenStateScenario(loadState: .loaded, orders: [], expectedScreenState: .empty),
        ScreenStateScenario(
            loadState: .loaded,
            orders: [
                LedgerOrder.fixture(
                    id: "AMY-1",
                    customer: LedgerCustomer(name: "Amy", initials: "AM", tier: .regular),
                    date: TestDependencies.fixedNow,
                    chargedAmount: 300
                ),
            ],
            expectedScreenState: .customers
        ),
        ScreenStateScenario(loadState: .loading, orders: [], expectedScreenState: .loading),
        ScreenStateScenario(
            loadState: .failed("orders.general.message.ordersLoadedTry"),
            orders: [],
            expectedScreenState: .failed("orders.general.message.ordersLoadedTry")
        ),
    ]

    /// 驗證客戶名單依訂單彙總，並依累計消費由高到低排序，筆數與最近訂單日期各自計算
    ///
    /// - Note: 日期皆為 2026 年 3 月指定日期的 UTC 零時
    @Test
    func customers_多筆訂單_依消費彙總並排序() {
        // Given
        let orders = [
            LedgerOrder.fixture(
                id: "1",
                customer: LedgerCustomer(name: "Amy", initials: "AM", tier: .regular),
                date: Date(timeIntervalSince1970: 1772323200),
                chargedAmount: 300
            ),
            LedgerOrder.fixture(
                id: "2",
                customer: LedgerCustomer(name: "Amy", initials: "AM", tier: .regular),
                date: Date(timeIntervalSince1970: 1772668800),
                chargedAmount: 200
            ),
            LedgerOrder.fixture(
                id: "3",
                customer: LedgerCustomer(name: "Bob", initials: "BO", tier: .regular),
                date: Date(timeIntervalSince1970: 1772409600),
                chargedAmount: 400
            ),
            LedgerOrder.fixture(
                id: "4",
                customer: LedgerCustomer(name: "Cara", initials: "CA", tier: .regular),
                date: Date(timeIntervalSince1970: 1772496000),
                chargedAmount: 100
            ),
        ]
        let state = CustomersFeature.State(
            orders: SharedReader(value: orders),
            loadState: SharedReader(value: .loaded)
        )

        // When
        let customers = state.customers

        // Then
        #expect(customers.map(\.name) == ["Amy", "Bob", "Cara"])

        let amy = customers.first { $0.name == "Amy" }
        #expect(amy?.orderCount == 2)
        #expect(amy?.totalSpent == 500)
        #expect(amy?.lastOrderDate == Date(timeIntervalSince1970: 1772668800))

        let bob = customers.first { $0.name == "Bob" }
        #expect(bob?.orderCount == 1)
        #expect(bob?.totalSpent == 400)
        #expect(bob?.lastOrderDate == Date(timeIntervalSince1970: 1772409600))

        let cara = customers.first { $0.name == "Cara" }
        #expect(cara?.orderCount == 1)
        #expect(cara?.totalSpent == 100)
        #expect(cara?.lastOrderDate == Date(timeIntervalSince1970: 1772496000))
    }

    /// 驗證沒有訂單時客戶名單為空
    @Test
    func customers_沒有訂單_回傳空名單() {
        // Given
        let state = CustomersFeature.State(
            orders: SharedReader(value: []),
            loadState: SharedReader(value: .loaded)
        )

        // When
        let customers = state.customers

        // Then
        #expect(customers.isEmpty)
    }

    /// 驗證客戶超過三位時，強調區塊只取消費前三名，並依序標示第一到第三名
    @Test
    func topCustomers_多於三位客戶_取前三並依序標示名次() {
        // Given
        let orders = [
            LedgerOrder.fixture(
                id: "1",
                customer: LedgerCustomer(name: "Amy", initials: "AM", tier: .regular),
                date: Date(timeIntervalSince1970: 1772323200),
                chargedAmount: 500
            ),
            LedgerOrder.fixture(
                id: "2",
                customer: LedgerCustomer(name: "Bob", initials: "BO", tier: .regular),
                date: Date(timeIntervalSince1970: 1772323200),
                chargedAmount: 400
            ),
            LedgerOrder.fixture(
                id: "3",
                customer: LedgerCustomer(name: "Cara", initials: "CA", tier: .regular),
                date: Date(timeIntervalSince1970: 1772323200),
                chargedAmount: 300
            ),
            LedgerOrder.fixture(
                id: "4",
                customer: LedgerCustomer(name: "Dan", initials: "DA", tier: .regular),
                date: Date(timeIntervalSince1970: 1772323200),
                chargedAmount: 100
            ),
        ]
        let state = CustomersFeature.State(
            orders: SharedReader(value: orders),
            loadState: SharedReader(value: .loaded)
        )

        // When
        let topCustomers = state.topCustomers

        // Then
        #expect(topCustomers.map(\.rank) == [1, 2, 3])
        #expect(topCustomers.map(\.customer.name) == ["Amy", "Bob", "Cara"])
    }

    /// 驗證客戶不足三位時，強調區塊只列出既有客戶，依消費排序並從第一名起算
    @Test
    func topCustomers_客戶不足三位_只列出既有客戶() {
        // Given
        let orders = [
            LedgerOrder.fixture(
                id: "1",
                customer: LedgerCustomer(name: "Amy", initials: "AM", tier: .regular),
                date: Date(timeIntervalSince1970: 1772323200),
                chargedAmount: 300
            ),
            LedgerOrder.fixture(
                id: "2",
                customer: LedgerCustomer(name: "Bob", initials: "BO", tier: .regular),
                date: Date(timeIntervalSince1970: 1772323200),
                chargedAmount: 400
            ),
        ]
        let state = CustomersFeature.State(
            orders: SharedReader(value: orders),
            loadState: SharedReader(value: .loaded)
        )

        // When
        let topCustomers = state.topCustomers

        // Then
        #expect(topCustomers.map(\.rank) == [1, 2])
        #expect(topCustomers.map(\.customer.name) == ["Bob", "Amy"])
    }

    /// 驗證客戶頁出現時，向更多頁送出訂單載入請求
    @Test
    func task_客戶頁出現_委派訂單載入() async {
        // Given
        let initial = CustomersFeature.State(
            orders: SharedReader(value: []),
            loadState: SharedReader(value: .loaded)
        )
        let store = TestStore(initialState: initial) {
            CustomersFeature()
        }

        // When
        await store.send(.view(.task))

        // Then
        await store.receive(\.delegate.ordersLoadRequested)
    }

    /// 驗證失敗畫面要求重試時，向更多頁送出訂單載入請求，保留原失敗狀態直到根功能同步新結果
    @Test
    func retryTapped_客戶頁載入失敗_委派訂單載入() async {
        // Given
        let initial = CustomersFeature.State(
            orders: SharedReader(value: []),
            loadState: SharedReader(value: .failed("orders.general.message.ordersLoadedTry"))
        )
        let store = TestStore(initialState: initial) {
            CustomersFeature()
        }

        // When
        await store.send(.view(.retryTapped))

        // Then
        await store.receive(\.delegate.ordersLoadRequested)
        await store.finish()
        #expect(store.state.screenState == .failed("orders.general.message.ordersLoadedTry"))
    }

    /// 驗證載入中與失敗時不顯示空名單，只有訂單載入完成後才依資料決定空名單或唯一的 Amy 客戶列
    ///
    /// - Parameter scenario: 規格四列中的訂單載入狀態、訂單資料與預期畫面內容
    @Test(arguments: Self.screenStateScenarios)
    func screenState_訂單載入狀態與資料四種組合_顯示對應內容(scenario: ScreenStateScenario) {
        // Given
        let state = CustomersFeature.State(
            orders: SharedReader(value: scenario.orders),
            loadState: SharedReader(value: scenario.loadState)
        )

        // When
        let screenState = state.screenState

        // Then
        #expect(screenState == scenario.expectedScreenState)
        if case .customers = scenario.expectedScreenState {
            #expect(state.customers.map(\.name) == ["Amy"])
            #expect(state.customers.map(\.totalSpent) == [300])
        }
    }

    /// 驗證點選客戶時，向更多頁送出 `customerSelected`，帶出被點選的客戶名稱
    @Test
    func customerTapped_點選客戶_委派選取名稱() async {
        // Given
        let initial = CustomersFeature.State(
            orders: SharedReader(value: []),
            loadState: SharedReader(value: .loaded)
        )
        let store = TestStore(initialState: initial) {
            CustomersFeature()
        }

        // When
        await store.send(.view(.customerTapped("Alice")))

        // Then
        await store.receive(\.delegate.customerSelected, "Alice")
    }
}

// MARK: - Nested Types

extension CustomersFeatureTests {

    /// 一列訂單載入狀態與客戶畫面預期，不包含由受測程式計算的值
    nonisolated struct ScreenStateScenario: Sendable {

        /// 根功能提供的訂單載入狀態
        let loadState: OrdersLoadState

        /// 客戶頁讀到的固定訂單資料
        let orders: [LedgerOrder]

        /// 規格明列的畫面內容種類
        let expectedScreenState: CustomersFeature.State.ScreenState
    }
}
