//
//  OrderEditFeatureTests+Items.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderEditFeatureTests {

    /// 新增商品列時，既有商品資料會保留並追加空白列
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

    /// 刪除指定位置的商品列後，其餘商品維持原順序
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
