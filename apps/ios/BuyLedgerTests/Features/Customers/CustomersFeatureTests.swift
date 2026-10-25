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

/// `CustomersFeature` 的單元測試，涵蓋客戶彙總、強調區塊，以及客戶頁送給更多頁的載入與點選事件
struct CustomersFeatureTests {

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
        let state = CustomersFeature.State(orders: SharedReader(value: orders))

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
        let state = CustomersFeature.State(orders: SharedReader(value: []))

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
        let state = CustomersFeature.State(orders: SharedReader(value: orders))

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
        let state = CustomersFeature.State(orders: SharedReader(value: orders))

        // When
        let topCustomers = state.topCustomers

        // Then
        #expect(topCustomers.map(\.rank) == [1, 2])
        #expect(topCustomers.map(\.customer.name) == ["Bob", "Amy"])
    }

    /// 驗證客戶頁出現時，向更多頁送出訂單載入請求
    @Test
    @MainActor
    func task_客戶頁出現_委派訂單載入() async {
        // Given
        let initial = CustomersFeature.State(orders: SharedReader(value: []))
        let store = TestStore(initialState: initial) {
            CustomersFeature()
        }

        // When
        await store.send(.view(.task))

        // Then
        await store.receive(\.delegate.ordersLoadRequested)
    }

    /// 驗證點選客戶時，向更多頁送出 `customerSelected`，帶出被點選的客戶名稱
    @Test
    @MainActor
    func customerTapped_點選客戶_委派選取名稱() async {
        // Given
        let initial = CustomersFeature.State(orders: SharedReader(value: []))
        let store = TestStore(initialState: initial) {
            CustomersFeature()
        }

        // When
        await store.send(.view(.customerTapped("Alice")))

        // Then
        await store.receive(\.delegate.customerSelected, "Alice")
    }
}
