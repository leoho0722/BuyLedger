//
//  OrderListFeatureTests+ClearFilterFixtures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

// MARK: - Internal Method

extension OrderListFeatureTests {

    /// 規格的 purchased、Alice 與三項篩選，含各自不相符的反例訂單
    ///
    /// - Returns: 清除前只顯示 selected，清除後首筆為 restored 的固定日期清單
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static func makeClearFiltersState() -> OrderListFeature.State {
        let alice = LedgerCustomer(name: "Alice", initials: "AL", tier: .regular)
        let bob = LedgerCustomer(name: "Bob", initials: "BO", tier: .regular)
        let now = TestDependencies.fixedNow
        let previousMonth = now.addingTimeInterval(-3_456_000)
        var state = Self.makeState(orders: [
            LedgerOrder.fixture(
                id: "wrongCustomer",
                customer: bob,
                status: .purchased,
                date: now,
                categories: ["beauty"],
                paymentMethod: "現金"
            ),
            LedgerOrder.fixture(
                id: "wrongStatus",
                customer: alice,
                status: .quoting,
                date: now,
                categories: ["beauty"],
                paymentMethod: "現金"
            ),
            LedgerOrder.fixture(
                id: "restored",
                customer: alice,
                status: .purchased,
                date: previousMonth,
                categories: ["books"],
                paymentMethod: "信用卡"
            ),
            LedgerOrder.fixture(
                id: "dateOnly",
                customer: alice,
                status: .purchased,
                date: previousMonth,
                categories: ["beauty"],
                paymentMethod: "現金"
            ),
            LedgerOrder.fixture(
                id: "categoryOnly",
                customer: alice,
                status: .purchased,
                date: now,
                categories: ["books"],
                paymentMethod: "現金"
            ),
            LedgerOrder.fixture(
                id: "paymentOnly",
                customer: alice,
                status: .purchased,
                date: now,
                categories: ["beauty"],
                paymentMethod: "信用卡"
            ),
            LedgerOrder.fixture(
                id: "selected",
                customer: alice,
                status: .purchased,
                date: now,
                categories: ["beauty"],
                paymentMethod: "現金"
            ),
        ])
        state.selectedStatus = .status(.purchased)
        state.searchText = "Alice"
        state.selectedDatePeriod = .thisMonth
        state.selectedCategories = ["beauty"]
        state.selectedPaymentMethod = "現金"
        state.selectedOrderID = "selected"
        state.$lookupCatalog = SharedReader(value: LookupCatalog())
        return state
    }
}
