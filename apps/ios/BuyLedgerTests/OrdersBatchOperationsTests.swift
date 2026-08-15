//
//  OrdersBatchOperationsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/2.
//

import Foundation
import Testing
@testable import BuyLedger

/// 直接測試批次狀態操作
struct OrdersBatchOperationsTests {
    
    // MARK: - Tests
    
    @Test func selectionModeToggledEntersSelectionMode() {
        var state = OrdersFeature.State()
        OrdersBatchOperations.selectionModeToggled(state: &state)
        #expect(state.isSelecting == true)
    }
    
    @Test func selectionModeToggledExitingClearsSelection() {
        var state = OrdersFeature.State()
        state.isSelecting = true
        state.selectedOrderIDs = ["A", "B"]
        
        OrdersBatchOperations.selectionModeToggled(state: &state)
        
        #expect(state.isSelecting == false)
        #expect(state.selectedOrderIDs.isEmpty)
    }
    
    @Test func orderSelectionToggledAddsThenRemoves() {
        var state = OrdersFeature.State()
        
        OrdersBatchOperations.orderSelectionToggled("A", state: &state)
        #expect(state.selectedOrderIDs == ["A"])
        
        OrdersBatchOperations.orderSelectionToggled("A", state: &state)
        #expect(state.selectedOrderIDs.isEmpty)
    }
    
    @Test func selectAllTappedSelectsAllFilteredOrders() {
        var state = OrdersFeature.State()
        state.orders = [
            makeOrder(id: "A", status: .quoting), makeOrder(id: "B", status: .delivered),
        ]
        state.selectedStatus = .status(.quoting)
        
        OrdersBatchOperations.selectAllTapped(
            state: &state, referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar)
        
        #expect(state.selectedOrderIDs == ["A"])
    }
    
    @Test func clearSelectionTappedEmptiesSelection() {
        var state = OrdersFeature.State()
        state.selectedOrderIDs = ["A", "B"]
        
        OrdersBatchOperations.clearSelectionTapped(state: &state)
        
        #expect(state.selectedOrderIDs.isEmpty)
    }
    
    /// 目標狀態為已合併時整條不做任何狀態變更 (含不退出多選)
    @Test func batchStatusChangedToMergedMakesNoChange() {
        var state = OrdersFeature.State()
        state.orders = [makeOrder(id: "A", status: .quoting)]
        state.isSelecting = true
        state.selectedOrderIDs = ["A"]
        
        let changed = OrdersBatchOperations.batchStatusChanged(.merged, state: &state)
        
        #expect(changed == nil)
        #expect(state.isSelecting == true)
        #expect(state.selectedOrderIDs == ["A"])
        #expect(state.orders[0].status == .quoting)
    }
    
    /// 只更新已選且狀態不同的訂單
    @Test func batchStatusChangedSkipsOrdersAlreadyAtTargetStatusAndUnselectedOrders() {
        var state = OrdersFeature.State()
        state.orders = [
            makeOrder(id: "A", status: .quoting),
            makeOrder(id: "B", status: .delivered),
            makeOrder(id: "C", status: .quoting),
        ]
        // B 已達目標狀態，C 未選取；兩者都不應更新。
        state.selectedOrderIDs = ["A", "B"]
        
        let changed = OrdersBatchOperations.batchStatusChanged(.delivered, state: &state)
        
        #expect(changed?.map(\.id) == ["A"])
    }
    
    /// 無論是否有訂單實際變更，皆退出多選並清空選取
    @Test func batchStatusChangedAlwaysExitsSelectionModeRegardlessOfChange() {
        var state = OrdersFeature.State()
        state.orders = [makeOrder(id: "A", status: .delivered)]
        state.isSelecting = true
        state.selectedOrderIDs = ["A"]
        
        // 目標狀態與現況相同：無訂單實際變更
        let changed = OrdersBatchOperations.batchStatusChanged(.delivered, state: &state)
        
        #expect(changed == nil)
        #expect(state.isSelecting == false)
        #expect(state.selectedOrderIDs.isEmpty)
    }
    
    @Test func batchStatusChangePersistedAppliesChangedOrdersByID() {
        var state = OrdersFeature.State()
        state.orders = [makeOrder(id: "A", status: .quoting), makeOrder(id: "B", status: .quoting)]
        
        OrdersBatchOperations.batchStatusChangePersisted(
            [makeOrder(id: "A", status: .delivered)], state: &state)
        
        #expect(state.orders[0].status == .delivered)
        #expect(state.orders[1].status == .quoting)
    }
}

// MARK: - Private Method

private extension OrdersBatchOperationsTests {
    
    /// 建立僅供批次測試使用的最小訂單；非相關欄位以零值/佔位填入
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - status: 訂單狀態
    /// - Returns: 建立的測試訂單
    func makeOrder(id: String, status: OrderStatus) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶\(id)", initials: "XX", tier: .new),
            status: status,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [LedgerOrderItem(id: UUID(), name: "商品", quantity: 1, unitPrice: 100)],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "來源",
            categories: ["類別"],
            paymentMethod: "付款",
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
