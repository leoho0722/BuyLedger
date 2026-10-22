//
//  OrderListFeatureTests+Snapshot.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 快照的訂單與識別值保留篩選順序，全選只取決於篩選結果
    ///
    /// - Parameters:
    ///   - selectedIDs: 已勾選的訂單識別值
    ///   - isAllSelected: 預期是否已全選
    @Test(arguments: [
        (Set<String>(), false),
        (Set<String>(["C"]), false),
        (Set<String>(["C", "B"]), true),
        (Set<String>(["C", "B", "outside"]), true),
    ])
    func listSnapshot_各種勾選集合_保留篩選內容順序與全選狀態(selectedIDs: Set<String>, isAllSelected: Bool) {
        // Given
        let first = LedgerOrder.fixture(id: "C", categories: ["美妝"])
        let excluded = LedgerOrder.fixture(id: "A", categories: ["食品"])
        let second = LedgerOrder.fixture(id: "B", categories: ["美妝"])
        var state = Self.makeState(orders: [first, excluded, second])
        state.selectedCategories = ["美妝"]
        state.selectedOrderIDs = selectedIDs

        // When
        let snapshot = state.listSnapshot()

        // Then
        #expect(snapshot.orders == [first, second])
        #expect(snapshot.ids == ["C", "B"])
        #expect(snapshot.isAllSelected == isAllSelected)
    }

    /// 篩選更新後重新取得快照，不改動先前取得的值
    @Test
    func listSnapshot_取得後篩選改變_保留舊快照並回傳新結果() {
        // Given
        let beauty = LedgerOrder.fixture(id: "C", categories: ["美妝"])
        let food = LedgerOrder.fixture(id: "A", categories: ["食品"])
        var state = Self.makeState(orders: [beauty, food])
        state.selectedCategories = ["美妝"]
        state.selectedOrderIDs = ["C"]
        let original = state.listSnapshot()

        // When
        state.selectedCategories = ["食品"]
        let updated = state.listSnapshot()

        // Then
        #expect(original.orders == [beauty])
        #expect(original.ids == ["C"])
        #expect(original.isAllSelected == true)
        #expect(updated.orders == [food])
        #expect(updated.ids == ["A"])
        #expect(updated.isAllSelected == false)
    }
}
