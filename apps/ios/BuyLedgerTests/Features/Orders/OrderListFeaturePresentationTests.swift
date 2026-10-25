//
//  OrderListFeaturePresentationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，涵蓋清單快照的識別值、日期脈絡與全選判定
struct OrderListFeaturePresentationTests {

    /// 驗證類別篩選後，清單快照的識別值只含符合的訂單，並依來源順序排列
    @Test
    func listSnapshot_類別篩選_保留相符訂單的來源順序() {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "C", category: "美妝"),
            OrdersFeatureTestSupport.makeOrder(id: "A", category: "食品"),
            OrdersFeatureTestSupport.makeOrder(id: "B", category: "美妝"),
        ])
        state.selectedCategories = ["美妝"]

        // When
        let ids = state.listSnapshot().ids

        // Then
        #expect(ids == ["C", "B"])
    }

    /// 驗證尚未記錄日期脈絡時，清單快照的識別值為空，即使訂單本身存在
    @Test
    func listSnapshot_尚無日期脈絡_回傳空識別值() {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "A", categories: []),
        ])
        state.dateContext = nil

        // When
        let ids = state.listSnapshot().ids

        // Then
        #expect(ids == [])
    }

    /// 驗證篩選結果為空時，即使選取集合仍含 A，全選判定為否
    @Test
    func listSnapshot_篩選無結果_回傳否() {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "A", categories: []),
        ])
        state.selectedCategories = ["不存在"]
        state.selectedOrderIDs = ["A"]

        // When
        let isAllSelected = state.listSnapshot().isAllSelected

        // Then
        #expect(isAllSelected == false)
    }

    /// 驗證清單沒有任何訂單時，全選判定為否
    @Test
    func listSnapshot_清單為空_回傳否() {
        // Given
        let state = OrderListFeatureTestSupport.makeState()

        // When
        let isAllSelected = state.listSnapshot().isAllSelected

        // Then
        #expect(isAllSelected == false)
    }

    /// 驗證只勾選部分訂單時，全選判定為否
    @Test
    func listSnapshot_僅勾選部分結果_回傳否() {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "A", categories: []),
            OrdersFeatureTestSupport.makeOrder(id: "B", categories: []),
        ])
        state.selectedOrderIDs = ["A"]

        // When
        let isAllSelected = state.listSnapshot().isAllSelected

        // Then
        #expect(isAllSelected == false)
    }

    /// 驗證勾選了所有符合篩選的訂單時，全選判定為是，篩選外的訂單不需要勾選
    @Test
    func listSnapshot_勾選全部相符結果_回傳是() {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "A", category: "美妝"),
            OrdersFeatureTestSupport.makeOrder(id: "B", category: "美妝"),
            OrdersFeatureTestSupport.makeOrder(id: "C", category: "食品"),
        ])
        state.selectedCategories = ["美妝"]
        state.selectedOrderIDs = ["A", "B"]

        // When
        let isAllSelected = state.listSnapshot().isAllSelected

        // Then
        #expect(isAllSelected == true)
    }

    /// 驗證選取集合含有不存在的識別值時，只要篩選結果都已勾選，全選判定仍為是
    @Test
    func listSnapshot_另含篩選外勾選_回傳是() {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "A", categories: []),
        ])
        state.selectedOrderIDs = ["A", "不存在"]

        // When
        let isAllSelected = state.listSnapshot().isAllSelected

        // Then
        #expect(isAllSelected == true)
    }
}
