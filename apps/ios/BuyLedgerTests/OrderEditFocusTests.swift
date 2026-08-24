//
//  OrderEditFocusTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/20.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

/// 訂單編輯表單的焦點管理
@MainActor
struct OrderEditFocusTests {
    
    // MARK: - Tests
    
    @Test func openingABlankOrderFocusesTheFirstField() async {
        let store = Self.makeStore(original: nil)
        
        await store.send(.task) {
            $0.focusedField = .customerName
        }
    }
    
    /// 編輯既有訂單不搶焦點，讓使用者自行決定要改哪一欄
    @Test func openingAnExistingOrderDoesNotStealFocus() async {
        let store = Self.makeStore(original: Self.existingOrder)
        
        await store.send(.task)
        
        #expect(store.state.focusedField == nil)
    }
    
    @Test func cancellingAnUntouchedFormClearsFocus() async {
        let store = Self.makeStore(original: nil)
        await store.send(.task) {
            $0.focusedField = .customerName
        }
        
        await store.send(.cancelTapped) {
            $0.focusedField = nil
        }
    }
    
    @Test func savingClearsFocus() async {
        let store = Self.makeStore(original: nil)
        await store.send(.task) {
            $0.focusedField = .customerName
        }
        
        await store.send(.saveTapped) {
            $0.focusedField = nil
        }
    }
    
    /// 重開表單不沿用上次焦點——狀態隨草稿一起重建
    @Test func reopeningStartsFromACleanFocusState() {
        let state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        
        #expect(state.focusedField == nil)
    }
}

// MARK: - Private Method

private extension OrderEditFocusTests {
    
    /// 建立一個注入固定時間的編輯表單 store
    /// - Parameter original: 要編輯的原始訂單；新增訂單時為 `nil`
    /// - Returns: 已建立的 OrderEditFeature 測試 store
    static func makeStore(original: LedgerOrder?) -> TestStoreOf<OrderEditFeature> {
        let store = TestStore(
            initialState: OrderEditFeature.State(
                original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        // 主檔效果並行且順序不固定，本測試只驗證焦點
        store.exhaustivity = .off
        return store
    }
    
    /// 供「編輯既有訂單」情境使用的訂單
    static let existingOrder = LedgerOrder(
        id: "EXISTING",
        customer: LedgerCustomer(name: "小美", initials: "XM", tier: .regular),
        status: .delivered,
        currency: .twd,
        date: TestDependencies.fixedNow,
        items: [LedgerOrderItem(name: "示範商品", quantity: 1, unitPrice: 100)],
        itemCost: 100,
        domesticShipping: 0,
        internationalShipping: 0,
        foreignDomesticShipping: 0,
        cardFeeRate: 0,
        platformFeeRate: 0,
        paymentFeeRate: 0,
        chargedAmount: 1_000,
        cardlessDeductionAmount: 0,
        cardlessSupplementAmount: 0,
        orderSource: "蝦皮",
        categories: ["美妝"],
        paymentMethod: "信用卡",
        notes: "",
        reconciliationStatus: "",
        campaignNames: [],
        paymentReceiptStatus: .pending,
        isCashOnDelivery: false,
        photos: [],
        mergedSourceIDs: []
    )
}
