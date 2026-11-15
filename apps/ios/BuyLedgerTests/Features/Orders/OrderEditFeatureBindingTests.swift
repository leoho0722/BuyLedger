//
//  OrderEditFeatureBindingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，以 `TestStore` 送出畫面實際送出的 binding action，確認表單輸入寫回草稿
@MainActor
struct OrderEditFeatureBindingTests {

    /// 驗證表單輸入顧客名稱時，畫面送出整份草稿的 binding action，草稿的 `customerName` 更新為新值
    ///
    /// - Note: 畫面綁定 `$store.draft.customerName`，巢狀欄位送出的是整個 `draft`
    @Test
    func binding_顧客名稱改變_同步更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        var editedDraft = initial.draft
        editedDraft.customerName = "新客戶"
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(\.binding.draft, editedDraft) {
            $0.draft.customerName = "新客戶"
        }

        // Then
        #expect(store.state.draft.customerName == "新客戶")
    }

    /// 驗證表單切換訂單狀態時，畫面送出整份草稿的 binding action，草稿的 `status` 更新為新狀態
    ///
    /// - Note: 畫面綁定 `$store.draft.status`，巢狀欄位送出的是整個 `draft`
    @Test
    func binding_訂單狀態改變_同步更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        var editedDraft = initial.draft
        editedDraft.status = .delivered
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(\.binding.draft, editedDraft) {
            $0.draft.status = .delivered
        }

        // Then
        #expect(store.state.draft.status == .delivered)
    }

    /// 驗證折抵初始為 0 時，表單輸入實收金額 12,345，畫面送出 `chargedAmount` 自己的 binding action，
    /// 草稿的 `chargedAmount` 更新為 12,345，折抵維持 0
    ///
    /// - Note: 畫面綁定 `$store.chargedAmount`，這是可寫的 computed property，送出自己的 key path
    @Test
    func binding_實收金額改變_同步更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(\.binding.chargedAmount, 12_345) {
            $0.draft.chargedAmount = 12_345
        }

        // Then
        #expect(store.state.draft.chargedAmount == 12_345)
        #expect(store.state.draft.cardlessDeductionAmount == 0)
    }

    /// 驗證商品成本、運費與手續費率等成本欄位經表單輸入時，畫面送出整份草稿的 binding action，
    /// 草稿中對應欄位更新為輸入的值，其他欄位維持原值
    ///
    /// - Parameter field: 要更新的訂單草稿欄位
    /// - Note: 畫面綁定 `$store.draft.<欄位>`，巢狀欄位送出的是整個 `draft`
    @Test(arguments: CostField.allCases)
    func binding_成本欄位改變_同步更新草稿(field: CostField) async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        var editedDraft = initial.draft
        editedDraft[keyPath: field.keyPath] = field.value
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(\.binding.draft, editedDraft) {
            $0.draft[keyPath: field.keyPath] = field.value
        }

        // Then
        #expect(store.state.draft[keyPath: field.keyPath] == field.value)
    }
}

// MARK: - Nested Types

extension OrderEditFeatureBindingTests {

    /// `binding_成本欄位改變_同步更新草稿(field:)` 逐一代入的草稿金額與費率欄位
    enum CostField: CaseIterable, Sendable {

        /// 商品成本
        case itemCost

        /// 外國國內運費
        case foreignDomesticShipping

        /// 國內運費
        case domesticShipping

        /// 國際運費
        case internationalShipping

        /// 刷卡手續費率
        case cardFeeRate

        /// 平台手續費率
        case platformFeeRate

        /// 金流手續費率
        case paymentFeeRate

        /// 草稿中對應欄位的可寫 key path，供組出輸入後的草稿與讀回結果時使用
        var keyPath: WritableKeyPath<OrderDraft, Decimal> {
            switch self {
            case .itemCost:
                \.itemCost

            case .foreignDomesticShipping:
                \.foreignDomesticShipping

            case .domesticShipping:
                \.domesticShipping

            case .internationalShipping:
                \.internationalShipping

            case .cardFeeRate:
                \.cardFeeRate

            case .platformFeeRate:
                \.platformFeeRate

            case .paymentFeeRate:
                \.paymentFeeRate
            }
        }

        /// 各欄位用於測試的固定值
        var value: Decimal {
            switch self {
            case .itemCost:
                5_000

            case .foreignDomesticShipping:
                40

            case .domesticShipping:
                80

            case .internationalShipping:
                320

            case .cardFeeRate:
                0.015

            case .platformFeeRate:
                0.03

            case .paymentFeeRate:
                0.02
            }
        }
    }
}
