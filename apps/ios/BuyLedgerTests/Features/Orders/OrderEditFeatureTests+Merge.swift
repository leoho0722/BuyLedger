//
//  OrderEditFeatureTests+Merge.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrderEditFeatureTests {

    /// 只有帶合併來源編號的草稿或合併產生的訂單才算合併情境
    ///
    /// - Parameters:
    ///   - scenario: 要建立的訂單起始情境
    ///   - isMergeContext: 預期是否為合併情境
    /// - Throws: 找不到合併產生的樣本訂單時由 `#require` 丟出
    @Test(arguments: [
        (scenario: EditScenario.newOrder, isMergeContext: false),
        (scenario: EditScenario.existingOrder, isMergeContext: false),
        (scenario: EditScenario.mergeDraft, isMergeContext: true),
        (scenario: EditScenario.mergedResult, isMergeContext: true),
    ])
    func isMergeContext_各訂單情境_依合併來源判定(scenario: EditScenario, isMergeContext: Bool) throws {
        // Given
        let state = try Self.makeState(for: scenario)

        // When
        let isActualMergeContext = state.isMergeContext

        // Then
        #expect(isActualMergeContext == isMergeContext)
    }

    /// 合併草稿、合併結果與已合併舊單的金額與費率欄位都可透過 `binding` 更新
    ///
    /// - Parameter testCase: 要驗證的合併訂單情境、欄位與值
    /// - Throws: 找不到指定合併訂單樣本時由 `#require` 丟出
    /// - Note: 目前 reducer 未針對合併單分流
    /// - Note: 此測試守住合併單欄位仍可編輯
    @Test(arguments: [
        MergeEditCase(scenario: .mergeDraft, field: .chargedAmount, value: Decimal(9_999)),
        MergeEditCase(scenario: .mergeDraft, field: .itemCost, value: Decimal(1_234)),
        MergeEditCase(scenario: .mergedResult, field: .cardFeeRate, value: Decimal(0.02)),
        MergeEditCase(scenario: .mergedAway, field: .chargedAmount, value: Decimal(777)),
    ])
    func binding_合併訂單編輯金額與費率欄位_允許更新(testCase: MergeEditCase) throws {
        // Given
        let initial = try Self.makeState(for: testCase.scenario)
        let store = Store(initialState: initial) {
            OrderEditFeature()
        }
        @Bindable var bindable = store

        // When
        switch testCase.field {
        case .chargedAmount:
            $bindable.chargedAmount.wrappedValue = testCase.value

        case .itemCost:
            $bindable.draft.itemCost.wrappedValue = testCase.value

        case .cardFeeRate:
            $bindable.draft.cardFeeRate.wrappedValue = testCase.value
        }

        // Then
        #expect(store.state[keyPath: testCase.field.keyPath] == testCase.value)
    }

    /// 一般訂單的狀態選單不含「已合併」
    ///
    /// - Note: 「已合併」只能由合併流程寫入
    @Test
    func availableStatuses_一般既有訂單_不提供已合併() {
        // Given
        let state = OrderEditFeature.State(
            original: LedgerOrder.sampleOrders[0],
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )

        // When
        let statuses = state.availableStatuses

        // Then
        #expect(!statuses.contains(.merged))
    }

    /// 已合併舊單保留「已合併」，也能改回其他狀態
    @Test
    func availableStatuses_已合併舊單_保留已合併並可改回其他狀態() {
        // Given
        let state = OrderEditFeature.State(
            original: Self.mergedAwayOrder,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )

        // When
        let statuses = state.availableStatuses

        // Then
        #expect(statuses.contains(.merged))
        #expect(statuses.contains(.purchased))
    }
}
