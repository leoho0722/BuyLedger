//
//  OrderEditFeatureTests+Deduction.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrderEditFeatureTests {

    /// 合併預填折抵以收款金額為上限，整理後的草稿仍是未修改的初始值
    ///
    /// - Parameters:
    ///   - chargedAmount: 預填收款金額
    ///   - deduction: 預填折抵金額
    ///   - expectedDeduction: 夾限後的折抵金額
    ///   - isCapped: 是否應顯示折抵已夾限的提示
    @Test(arguments: [
        (Decimal(500), Decimal(1_000), Decimal(500), true),
        (Decimal(500), Decimal(500), Decimal(500), false),
        (Decimal(-20), Decimal(100), Decimal(0), true),
    ])
    func init_合併預填折抵超額或等於收款_依上限夾限且不視為修改(
        chargedAmount: Decimal,
        deduction: Decimal,
        expectedDeduction: Decimal,
        isCapped: Bool
    ) {
        // Given
        var draft = OrderDraft(original: nil, currentDate: TestDependencies.fixedNow)
        draft.chargedAmount = chargedAmount
        draft.cardlessDeductionAmount = deduction

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
        #expect(state.draft.cardlessDeductionAmount == expectedDeduction)
        #expect(state.isCardlessDeductionCapped == isCapped)
        #expect(state.initialDraft.cardlessDeductionAmount == expectedDeduction)
        #expect(!state.isDirty)
        #expect(state.isMergeContext)
    }

    /// 折抵超過實收金額時，金額夾到上限並標示已修正
    @Test
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

    /// 已夾限後輸入未超額折抵時，保留輸入並清除提示
    @Test
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

    /// 實收金額降到折抵以下時，折抵會同步夾到新的上限
    @Test
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

    /// 修改其他草稿欄位時，保留折抵金額與既有夾限提示
    @Test
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

    /// 開啟折抵超過實付金額的既有訂單時，折抵降到上限並標示修正，但不算未儲存變更
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
