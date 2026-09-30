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

/// 驗證客戶彙總
@MainActor
struct CustomersFeatureTests {

    // MARK: - Tests

    /// 驗證客戶狀態依訂單彙總並按累計消費排序
    @Test func aggregatesOrdersByCustomerRankedBySpendDescending() {
        // Given
        let orders = [
            LedgerOrder.fixture(
                id: "1",
                customer: LedgerCustomer(name: "Amy", initials: "AM", tier: .regular),
                date: date(2026, 3, 1),
                chargedAmount: 300
            ),
            LedgerOrder.fixture(
                id: "2",
                customer: LedgerCustomer(name: "Amy", initials: "AM", tier: .regular),
                date: date(2026, 3, 5),
                chargedAmount: 200
            ),
            LedgerOrder.fixture(
                id: "3",
                customer: LedgerCustomer(name: "Bob", initials: "BO", tier: .regular),
                date: date(2026, 3, 2),
                chargedAmount: 400
            ),
            LedgerOrder.fixture(
                id: "4",
                customer: LedgerCustomer(name: "Cara", initials: "CA", tier: .regular),
                date: date(2026, 3, 3),
                chargedAmount: 100
            )
        ]
        let state = CustomersFeature.State(orders: orders)

        // When
        let customers = state.customers

        // Then
        #expect(customers.map(\.name) == ["Amy", "Bob", "Cara"])

        let amy = customers.first { $0.name == "Amy" }
        #expect(amy?.orderCount == 2)
        #expect(amy?.totalSpent == 500)
        #expect(amy?.lastOrderDate == date(2026, 3, 5))

        let bob = customers.first { $0.name == "Bob" }
        #expect(bob?.orderCount == 1)
        #expect(bob?.totalSpent == 400)
        #expect(bob?.lastOrderDate == date(2026, 3, 2))

        let cara = customers.first { $0.name == "Cara" }
        #expect(cara?.orderCount == 1)
        #expect(cara?.totalSpent == 100)
        #expect(cara?.lastOrderDate == date(2026, 3, 3))
    }

    /// 驗證沒有訂單時客戶名單為空
    @Test func emptyOrdersYieldsEmptyCustomerList() {
        // Given
        let state = CustomersFeature.State(orders: [])

        // When
        let customers = state.customers

        // Then
        #expect(customers.isEmpty)
    }

    /// 驗證畫面出現時委派訂單載入
    @Test func taskDelegatesOrdersLoadRequest() async {
        // Given
        let store = TestStore(initialState: CustomersFeature.State()) {
            CustomersFeature()
        }

        // When
        await store.send(.view(.task))

        // Then
        await store.receive(\.delegate.ordersLoadRequested)
    }

    /// 驗證客戶點選轉為 customerSelected delegate
    @Test func customerTappedSendsSelectedDelegate() async {
        // Given
        let store = TestStore(initialState: CustomersFeature.State()) {
            CustomersFeature()
        }

        // When
        await store.send(.view(.customerTapped("Alice")))

        // Then
        await store.receive(\.delegate.customerSelected, "Alice")
    }
}

// MARK: - Private Method

private extension CustomersFeatureTests {

    /// 以固定 gregorian/UTC 曆建立指定年月日的日期，確保跨機器一致
    ///
    /// - Parameters:
    ///   - year: 西元年
    ///   - month: 月份
    ///   - day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
    func date(
        _ year: Int,
        _ month: Int,
        _ day: Int
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        guard let date = calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day
            )
        ) else {
            preconditionFailure("測試日期建立失敗")
        }
        return date
    }
}
