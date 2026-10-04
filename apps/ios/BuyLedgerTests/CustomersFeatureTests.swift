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

/// 驗證客戶彙總與客戶頁交給更多頁的委派
@MainActor
struct CustomersFeatureTests {

    /// 驗證客戶狀態依訂單彙總並按累計消費排序
    @Test
    func customers_多筆訂單_依消費彙總並排序() {
        // Given
        // 日期皆為 2026 年 3 月指定日期的 UTC 零時
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

    /// 驗證畫面出現時委派訂單載入
    @Test
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

    /// 驗證客戶點選轉為 `customerSelected` delegate
    @Test
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
