//
//  OrderEditFeatureMergeTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，涵蓋合併判定、合併訂單的金額與費率編輯，以及可選狀態
struct OrderEditFeatureMergeTests {

    /// 驗證帶有合併來源編號的草稿與合併產生的訂單判定為合併情境，新訂單與一般既有訂單則否
    ///
    /// - Parameter testCase: 測試輸入與字面值預期結果
    /// - Throws: 找不到合併產生的樣本訂單時由 `#require` 丟出
    @Test(arguments: [
        MergeContextCase(scenario: .newOrder, isMergeContext: false),
        MergeContextCase(scenario: .existingOrder, isMergeContext: false),
        MergeContextCase(scenario: .mergeDraft, isMergeContext: true),
        MergeContextCase(scenario: .mergedResult, isMergeContext: true),
    ])
    func isMergeContext_各訂單情境_依合併來源判定(testCase: MergeContextCase) throws {
        // Given
        let state = try OrderEditFeatureTestSupport.makeState(for: testCase.scenario)

        // When
        let isActualMergeContext = state.isMergeContext

        // Then
        #expect(isActualMergeContext == testCase.isMergeContext)
    }

    /// 驗證合併草稿、合併結果與已合併舊單的金額與費率欄位，經綁定寫入新值後都會更新
    ///
    /// - Parameter testCase: 要驗證的合併訂單情境、欄位與值
    /// - Throws: 找不到合併產生的樣本訂單時由 `#require` 丟出
    /// - Note: 目前 reducer 未針對合併單分流
    /// - Note: 此測試守住合併單欄位仍可編輯
    @Test(arguments: [
        MergeEditCase(scenario: .mergeDraft, field: .chargedAmount, value: Decimal(9_999)),
        MergeEditCase(scenario: .mergeDraft, field: .itemCost, value: Decimal(1_234)),
        MergeEditCase(scenario: .mergedResult, field: .cardFeeRate, value: Decimal(0.02)),
        MergeEditCase(scenario: .mergedAway, field: .chargedAmount, value: Decimal(777)),
    ])
    @MainActor
    func binding_合併訂單編輯金額與費率欄位_允許更新(testCase: MergeEditCase) throws {
        // Given
        let initial = try OrderEditFeatureTestSupport.makeState(for: testCase.scenario)
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

    /// 驗證一般既有訂單的狀態選單不提供「已合併」
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

    /// 驗證已合併舊單的狀態選單保留「已合併」，同時提供 `.purchased` 等其他狀態
    @Test
    func availableStatuses_已合併舊單_保留已合併並可改回其他狀態() {
        // Given
        let state = OrderEditFeature.State(
            original: OrderEditFeatureTestSupport.mergedAwayOrder,
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

// MARK: - Nested Types

extension OrderEditFeatureMergeTests {

    /// 訂單起始情境與合併判定預期
    struct MergeContextCase: Sendable {

        /// 要建立的訂單起始情境
        let scenario: OrderEditFeatureTestSupport.EditScenario

        /// 預期是否為合併情境
        let isMergeContext: Bool
    }

    /// 合併情境的 `binding` 測試使用的金額或費率欄位
    enum MergeEditField: CaseIterable, Sendable {

        /// 實收金額
        case chargedAmount

        /// 商品成本
        case itemCost

        /// 刷卡手續費率
        case cardFeeRate

        /// 結果斷言使用的草稿欄位路徑
        var keyPath: WritableKeyPath<OrderEditFeature.State, Decimal> & Sendable {
            switch self {
            case .chargedAmount:
                \.draft.chargedAmount

            case .itemCost:
                \.draft.itemCost

            case .cardFeeRate:
                \.draft.cardFeeRate
            }
        }
    }

    /// 合併訂單的 `binding` 測試使用的情境、欄位與要寫入的值
    struct MergeEditCase: Sendable {

        /// 要建立的訂單起始情境
        let scenario: OrderEditFeatureTestSupport.EditScenario

        /// 要更新的金額或費率欄位
        let field: MergeEditField

        /// 要寫入欄位的值
        let value: Decimal
    }
}
