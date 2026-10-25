//
//  OrderEditFeatureDeductionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，涵蓋無卡折抵金額以實收金額為上限的夾限、標示與清除
struct OrderEditFeatureDeductionTests {

    /// 驗證合併預填的折抵超過實收金額時夾到實收金額並標示，等於實收金額時不標示，實收為負時夾到 0，且都不算修改
    ///
    /// - Parameter testCase: 測試輸入與字面值預期結果
    @Test(arguments: [
        CardlessDeductionCapCase(
            chargedAmount: 500,
            deduction: 1_000,
            expectedDeduction: 500,
            isCapped: true
        ),
        CardlessDeductionCapCase(
            chargedAmount: 500,
            deduction: 500,
            expectedDeduction: 500,
            isCapped: false
        ),
        CardlessDeductionCapCase(
            chargedAmount: -20,
            deduction: 100,
            expectedDeduction: 0,
            isCapped: true
        ),
    ])
    func init_合併預填折抵超額或等於收款_依上限夾限且不視為修改(testCase: CardlessDeductionCapCase) {
        // Given
        var draft = OrderDraft(original: nil, currentDate: TestDependencies.fixedNow)
        draft.chargedAmount = testCase.chargedAmount
        draft.cardlessDeductionAmount = testCase.deduction

        // When
        let state = OrderEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            prefill: OrderEditFeature.State.Prefill(
                draft: draft,
                mergeSourceIDs: ["PRIMARY", "SECONDARY"],
                keptPhotos: []
            )
        )

        // Then
        #expect(state.draft.cardlessDeductionAmount == testCase.expectedDeduction)
        #expect(state.isCardlessDeductionCapped == testCase.isCapped)
        #expect(state.initialDraft.cardlessDeductionAmount == testCase.expectedDeduction)
        #expect(!state.isDirty)
        #expect(state.isMergeContext)
    }

    /// 驗證折抵經綁定寫入超過實收金額的值時，草稿與畫面讀取的折抵都夾到實收金額，並標示已夾限
    @Test
    @MainActor
    func binding_無卡折抵超過實收金額_夾到上限並標示() {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.chargedAmount = 1_000
        let store = Store(initialState: initial) {
            OrderEditFeature()
        }
        @Bindable var bindable = store

        // When
        $bindable.cardlessDeductionAmount.wrappedValue = 1_500

        // Then
        #expect(store.state.draft.cardlessDeductionAmount == 1_000)
        #expect(store.cardlessDeductionAmount == 1_000)
        #expect(store.state.isCardlessDeductionCapped)
    }

    /// 驗證已夾限後綁定寫入未超過實收金額的折抵時，保留新輸入的金額並清除已夾限的提示
    @Test
    @MainActor
    func binding_已夾限後輸入未超額折抵_保留輸入並清除標示() {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.chargedAmount = 1_000
        initial.draft.cardlessDeductionAmount = 1_000
        initial.isCardlessDeductionCapped = true
        let store = Store(initialState: initial) {
            OrderEditFeature()
        }
        @Bindable var bindable = store

        // When
        $bindable.cardlessDeductionAmount.wrappedValue = 300

        // Then
        #expect(store.state.isCardlessDeductionCapped == false)
        #expect(store.state.draft.cardlessDeductionAmount == 300)
    }

    /// 驗證實收金額經綁定改到低於目前折抵時，折抵同步夾到新的實收金額並標示已夾限
    @Test
    @MainActor
    func binding_實收金額降到折抵以下_折抵夾到新上限() {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.chargedAmount = 1_000
        initial.draft.cardlessDeductionAmount = 800
        let store = Store(initialState: initial) {
            OrderEditFeature()
        }
        @Bindable var bindable = store

        // When
        $bindable.chargedAmount.wrappedValue = 300

        // Then
        #expect(store.state.draft.chargedAmount == 300)
        #expect(store.chargedAmount == 300)
        #expect(store.state.draft.cardlessDeductionAmount == 300)
        #expect(store.state.isCardlessDeductionCapped)
    }

    /// 驗證經畫面綁定修改備註時，不重新夾限，折抵金額與既有的夾限提示都保留
    @Test
    @MainActor
    func binding_經畫面綁定修改備註_不觸發折抵夾限() {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.chargedAmount = 1_000
        initial.draft.cardlessDeductionAmount = 1_000
        initial.isCardlessDeductionCapped = true
        let store = Store(initialState: initial) {
            OrderEditFeature()
        }
        @Bindable var bindable = store

        // When
        $bindable.draft.notes.wrappedValue = "已聯絡客戶"

        // Then
        #expect(store.draft.notes == "已聯絡客戶")
        #expect(store.draft.chargedAmount == 1_000)
        #expect(store.draft.cardlessDeductionAmount == 1_000)
        #expect(store.isCardlessDeductionCapped)
    }

    /// 驗證開啟折抵超過實收金額的既有訂單時，折抵降到實收金額並標示已夾限，初始化的修正不算未儲存變更
    @Test
    func init_既有訂單折抵超過上限_修正並標示原因() {
        // Given
        let overCapOrder = LedgerOrder(
            id: "BL-OVERCAP-001",
            customer: LedgerCustomer(name: "既有超額折抵", initials: "OC", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 1_000,
            cardlessDeductionAmount: 1_500,
            cardlessSupplementAmount: 0,
            orderSource: "測試來源",
            categories: ["測試"],
            paymentMethod: "無卡存款",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        // When
        let state = OrderEditFeature.State(
            original: overCapOrder,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        let deduction = state.draft.cardlessDeductionAmount
        let isCapped = state.isCardlessDeductionCapped
        let isDirty = state.isDirty

        // Then
        #expect(deduction == 1_000)
        #expect(isCapped)
        // 初始化時先修正既有資料，避免尚未編輯就被視為未儲存
        #expect(isDirty == false)
    }
}

// MARK: - Nested Types

extension OrderEditFeatureDeductionTests {

    /// 合併預填折抵的上限與提示案例
    struct CardlessDeductionCapCase: Sendable {

        /// 預填實收金額
        let chargedAmount: Decimal

        /// 預填折抵金額
        let deduction: Decimal

        /// 夾限後的折抵金額
        let expectedDeduction: Decimal

        /// 是否應顯示折抵已夾限的提示
        let isCapped: Bool
    }
}
