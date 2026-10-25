//
//  OrderListFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

/// 提供訂單清單測試共用的固定日期狀態與清除篩選資料
enum OrderListFeatureTestSupport {}

// MARK: - Internal Method

extension OrderListFeatureTestSupport {

    /// 建立固定日期與唯讀訂單的清單，不讀取系統時間
    ///
    /// - Parameter orders: 初始訂單
    /// - Returns: 清單測試的初始狀態
    static func makeState(orders: [LedgerOrder] = []) -> OrderListFeature.State {
        let sharedOrders = Shared<[LedgerOrder]>(value: [])
        sharedOrders.withLock {
            $0 = orders
        }
        var state = OrderListFeature.State(orders: SharedReader(sharedOrders))
        state.dateContext = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        return state
    }

    /// 建立含 `purchased` 狀態、Alice 搜尋與三項篩選的清單狀態，並附上各自不相符的反例訂單
    ///
    /// - Returns: 套用狀態、搜尋與三項篩選後的清單狀態，只剩 selected 一筆
    static func makeClearFiltersState() -> OrderListFeature.State {
        let alice = LedgerCustomer(name: "Alice", initials: "AL", tier: .regular)
        let bob = LedgerCustomer(name: "Bob", initials: "BO", tier: .regular)
        let now = TestDependencies.fixedNow
        let previousMonth = now.addingTimeInterval(-3_456_000)
        var state = OrderListFeatureTestSupport.makeState(orders: [
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
