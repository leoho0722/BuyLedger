//
//  OrderListFeatureTests+Presentation.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 識別值只包含符合篩選的訂單，並保留來源順序
    @Test
    func listSnapshot_類別篩選_保留相符訂單的來源順序() {
        // Given
        var state = Self.makeState(orders: [
            OrdersFeatureTests.makeOrder(id: "C", category: "美妝"),
            OrdersFeatureTests.makeOrder(id: "A", category: "食品"),
            OrdersFeatureTests.makeOrder(id: "B", category: "美妝"),
        ])
        state.selectedCategories = ["美妝"]

        // When
        let ids = state.listSnapshot().ids

        // Then
        #expect(ids == ["C", "B"])
    }

    /// 尚未記錄日期時不列出訂單識別值
    @Test
    func listSnapshot_尚無日期脈絡_回傳空識別值() {
        // Given
        var state = Self.makeState(orders: [OrdersFeatureTests.makeOrder(id: "A", categories: [])])
        state.dateContext = nil

        // When
        let ids = state.listSnapshot().ids

        // Then
        #expect(ids == [])
    }

    /// 篩選結果為空時，即使仍有舊勾選也不視為全選
    @Test
    func listSnapshot_篩選無結果_回傳否() {
        // Given
        var state = Self.makeState(orders: [OrdersFeatureTests.makeOrder(id: "A", categories: [])])
        state.selectedCategories = ["不存在"]
        state.selectedOrderIDs = ["A"]

        // When
        let isAllSelected = state.listSnapshot().isAllSelected

        // Then
        #expect(isAllSelected == false)
    }

    /// 清單沒有任何訂單時不視為全選
    @Test
    func listSnapshot_清單為空_回傳否() {
        // Given
        let state = Self.makeState()

        // When
        let isAllSelected = state.listSnapshot().isAllSelected

        // Then
        #expect(isAllSelected == false)
    }

    /// 只勾選部分篩選結果時不視為全選
    @Test
    func listSnapshot_僅勾選部分結果_回傳否() {
        // Given
        var state = Self.makeState(orders: [
            OrdersFeatureTests.makeOrder(id: "A", categories: []),
            OrdersFeatureTests.makeOrder(id: "B", categories: []),
        ])
        state.selectedOrderIDs = ["A"]

        // When
        let isAllSelected = state.listSnapshot().isAllSelected

        // Then
        #expect(isAllSelected == false)
    }

    /// 勾選所有篩選結果時視為全選，不要求勾選篩選外的訂單
    @Test
    func listSnapshot_勾選全部相符結果_回傳是() {
        // Given
        var state = Self.makeState(orders: [
            OrdersFeatureTests.makeOrder(id: "A", category: "美妝"),
            OrdersFeatureTests.makeOrder(id: "B", category: "美妝"),
            OrdersFeatureTests.makeOrder(id: "C", category: "食品"),
        ])
        state.selectedCategories = ["美妝"]
        state.selectedOrderIDs = ["A", "B"]

        // When
        let isAllSelected = state.listSnapshot().isAllSelected

        // Then
        #expect(isAllSelected == true)
    }

    /// 勾選集合多出其他識別值時，完整勾選的篩選結果仍視為全選
    @Test
    func listSnapshot_另含篩選外勾選_回傳是() {
        // Given
        var state = Self.makeState(orders: [OrdersFeatureTests.makeOrder(id: "A", categories: [])])
        state.selectedOrderIDs = ["A", "不存在"]

        // When
        let isAllSelected = state.listSnapshot().isAllSelected

        // Then
        #expect(isAllSelected == true)
    }
}
