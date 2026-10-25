//
//  OrderListFeatureSnapshotTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，涵蓋清單快照的順序、全選判定與取得後不受篩選變更影響 (非影像快照)
struct OrderListFeatureSnapshotTests {

    /// 驗證各種勾選集合下，快照的訂單與識別值依來源順序保留篩選結果，全選只看篩選結果是否都已勾選
    ///
    /// - Parameter testCase: 已勾選的識別值集合與預期的全選狀態
    @Test(arguments: [
        SelectionCase(selectedIDs: [], isAllSelected: false),
        SelectionCase(selectedIDs: ["C"], isAllSelected: false),
        SelectionCase(selectedIDs: ["C", "B"], isAllSelected: true),
        SelectionCase(selectedIDs: ["C", "B", "outside"], isAllSelected: true),
    ])
    func listSnapshot_各種勾選集合_保留篩選內容順序與全選狀態(testCase: SelectionCase) {
        // Given
        let first = LedgerOrder.fixture(id: "C", categories: ["美妝"])
        let excluded = LedgerOrder.fixture(id: "A", categories: ["食品"])
        let second = LedgerOrder.fixture(id: "B", categories: ["美妝"])
        var state = OrderListFeatureTestSupport.makeState(orders: [first, excluded, second])
        state.selectedCategories = ["美妝"]
        state.selectedOrderIDs = testCase.selectedIDs

        // When
        let snapshot = state.listSnapshot()

        // Then
        #expect(snapshot.orders == [first, second])
        #expect(snapshot.ids == ["C", "B"])
        #expect(snapshot.isAllSelected == testCase.isAllSelected)
    }

    /// 驗證篩選改變後重新取得的快照回傳新結果，先前取得的快照內容與全選狀態都不變
    @Test
    func listSnapshot_取得後篩選改變_保留舊快照並回傳新結果() {
        // Given
        let beauty = LedgerOrder.fixture(id: "C", categories: ["美妝"])
        let food = LedgerOrder.fixture(id: "A", categories: ["食品"])
        var state = OrderListFeatureTestSupport.makeState(orders: [beauty, food])
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

// MARK: - Nested Types

extension OrderListFeatureSnapshotTests {

    /// 清單快照的測試案例，含已勾選的識別值集合與預期的全選判定
    struct SelectionCase: Sendable {

        /// 已勾選的訂單識別值
        let selectedIDs: Set<String>

        /// 預期是否已全選
        let isAllSelected: Bool
    }
}
