//
//  OrderEditFeatureItemsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，以 TestStore 逐步驗證商品列的新增與刪除
@MainActor
struct OrderEditFeatureItemsTests {

    /// 驗證按下新增商品時，既有的商品列原樣保留，並在末尾追加一列空白商品列
    @Test
    func addItemTapped_新增訂單項目_追加空白列() async {
        // Given
        let existingItem = LedgerOrderItem(
            id: UUID(9),
            name: "既有商品",
            quantity: 2,
            unitPrice: 100
        )
        let blankItem = LedgerOrderItem(
            id: UUID(0),
            name: "",
            quantity: 1,
            unitPrice: 0
        )
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.items = [existingItem]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }

        // When
        await store.send(.view(.addItemTapped)) {
            $0.draft.items = [existingItem, blankItem]
        }

        // Then
        #expect(store.state.draft.items == [existingItem, blankItem])
    }

    /// 驗證刪除中間的商品列時，只移除該列，其餘商品維持原順序
    @Test
    func itemsDeleted_刪除指定索引_保留其他項目順序() async {
        // Given
        let itemA = LedgerOrderItem(
            id: UUID(0),
            name: "A",
            quantity: 1,
            unitPrice: 100
        )
        let itemB = LedgerOrderItem(
            id: UUID(1),
            name: "B",
            quantity: 2,
            unitPrice: 200
        )
        let itemC = LedgerOrderItem(
            id: UUID(2),
            name: "C",
            quantity: 3,
            unitPrice: 300
        )
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.items = [itemA, itemB, itemC]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.view(.itemsDeleted(IndexSet(integer: 1)))) {
            $0.draft.items = [itemA, itemC]
        }

        // Then
        #expect(store.state.draft.items == [itemA, itemC])
    }
}
