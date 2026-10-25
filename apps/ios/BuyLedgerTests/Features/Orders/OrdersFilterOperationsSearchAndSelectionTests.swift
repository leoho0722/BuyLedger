//
//  OrdersFilterOperationsSearchAndSelectionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Testing

@testable import BuyLedger

/// `OrdersFilterOperations` 的單元測試，直接呼叫搜尋與選取方法，斷言搜尋文字與選取識別值的變化
struct OrdersFilterOperationsSearchAndSelectionTests {

    /// 驗證輸入搜尋文字「B」時，搜尋文字更新，選取改為第一筆相符的 B
    @Test
    func searchTextChanged_輸入搜尋_重選第一筆相符訂單() {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFilterOperationsTestSupport.makeOrder(id: "A"),
            OrdersFilterOperationsTestSupport.makeOrder(id: "B"),
        ])

        // When
        OrdersFilterOperations.searchTextChanged("B", state: &state)

        // Then
        #expect(state.searchText == "B")
        #expect(state.selectedOrderID == "B")
    }

    /// 驗證目前沒有選取時選取 A，選取識別值由 `nil` 改為 A
    @Test
    func orderSelected_選取訂單_設定選取識別值() {
        // Given
        var state = OrderListFeatureTestSupport.makeState()

        // When
        OrdersFilterOperations.orderSelected("A", state: &state)

        // Then
        #expect(state.selectedOrderID == "A")
    }

    /// 驗證已選取 A 時傳入 `nil` 清空選取，選取識別值由 A 改為 `nil`
    @Test
    func orderSelected_已有選取_清除選取識別值() {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedOrderID = "A"

        // When
        OrdersFilterOperations.orderSelected(nil, state: &state)

        // Then
        #expect(state.selectedOrderID == nil)
    }
}
