//
//  OrdersFilterOperationsSearchTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Testing

@testable import BuyLedger

/// `OrdersFilterOperations` 的單元測試，直接呼叫搜尋方法，斷言搜尋文字的變化
struct OrdersFilterOperationsSearchTests {

    /// 驗證輸入搜尋文字「B」時，搜尋文字更新為 B
    @Test
    func searchTextChanged_輸入搜尋文字B_更新搜尋文字() {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFilterOperationsTestSupport.makeOrder(id: "A"),
            OrdersFilterOperationsTestSupport.makeOrder(id: "B"),
        ])

        // When
        OrdersFilterOperations.searchTextChanged("B", state: &state)

        // Then
        #expect(state.searchText == "B")
    }
}
