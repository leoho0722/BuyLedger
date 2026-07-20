//
//  OrdersSearchCancellationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/20.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

/// 系統搜尋列取消後的過濾狀態
///
/// 系統搜尋呈現在取消時會把文字清空，功能狀態必須跟著回到未過濾，
/// 否則使用者會停留在已過濾結果卻看不到搜尋列
@MainActor
struct OrdersSearchCancellationTests {

    // MARK: - Tests

    @Test func cancellingSearchClearsTheQueryAndRestoresTheFullList() async {
        var initial = OrdersFeature.State()
        initial.orders = Self.orders
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        store.exhaustivity = .off

        await store.send(.searchTextChanged("小美"))
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        #expect(filtered.map(\.id) == ["A"])

        // 取消搜尋等同把文字清空
        await store.send(.searchTextChanged(""))

        #expect(store.state.searchText.isEmpty)
        let restored = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        #expect(restored.map(\.id) == Self.orders.map(\.id))
    }

    /// 取消搜尋只解除查詢，其他篩選條件維持不變
    @Test func cancellingSearchDoesNotClearTheOtherFilters() async {
        var initial = OrdersFeature.State()
        initial.orders = Self.orders
        initial.selectedCategory = "美妝"
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        store.exhaustivity = .off

        await store.send(.searchTextChanged("小美"))
        await store.send(.searchTextChanged(""))

        #expect(store.state.selectedCategory == "美妝")
        let restored = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        #expect(restored.map(\.id) == ["A", "B"])
    }
}

// MARK: - Private Method

private extension OrdersSearchCancellationTests {

    /// 測試用訂單：兩筆美妝、一筆零食，客戶名稱各異
    static let orders: [LedgerOrder] = [
        makeOrder(id: "A", customer: "小美", category: "美妝"),
        makeOrder(id: "B", customer: "阿明", category: "美妝"),
        makeOrder(id: "C", customer: "阿華", category: "零食"),
    ]

    static func makeOrder(id: String, customer: String, category: String) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: customer, initials: "XX", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [LedgerOrderItem(name: "示範商品", quantity: 1, unitPrice: 100)],
            itemCost: 100,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 1_000,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "蝦皮",
            categories: [category],
            paymentMethod: "信用卡",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}
