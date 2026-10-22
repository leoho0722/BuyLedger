//
//  OrdersFilterOperationsTests+SearchAndSelection.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Testing

@testable import BuyLedger

extension OrdersFilterOperationsTests {

    /// 驗證輸入搜尋時重選第一筆相符訂單
    @Test
    func searchTextChanged_輸入搜尋_重選第一筆相符訂單() {
        // Given
        var state = OrderListFeatureTests.makeState(orders: [
            makeOrder(id: "A"),
            makeOrder(id: "B"),
        ])

        // When
        OrdersFilterOperations.searchTextChanged("B", state: &state)

        // Then
        #expect(state.searchText == "B")
        #expect(state.selectedOrderID == "B")
    }

    /// 驗證選取訂單時設定選取識別值
    @Test
    func orderSelected_選取訂單_設定選取識別值() {
        // Given
        var state = OrderListFeatureTests.makeState()

        // When
        OrdersFilterOperations.orderSelected("A", state: &state)

        // Then
        #expect(state.selectedOrderID == "A")
    }

    /// 驗證已有選取時清空選取會移除選取識別值
    @Test
    func orderSelected_已有選取_清除選取識別值() {
        // Given
        var state = OrderListFeatureTests.makeState()
        state.selectedOrderID = "A"

        // When
        OrdersFilterOperations.orderSelected(nil, state: &state)

        // Then
        #expect(state.selectedOrderID == nil)
    }
}
