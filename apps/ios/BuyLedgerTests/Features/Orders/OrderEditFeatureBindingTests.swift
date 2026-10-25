//
//  OrderEditFeatureBindingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，以 `Store` 搭配 `@Bindable` 確認畫面實際的綁定路徑能寫回草稿
@MainActor
struct OrderEditFeatureBindingTests {

    /// 驗證表單輸入顧客名稱後，草稿的 `customerName` 同步成新值
    ///
    /// - Note: 此測試守住 `BindingReducer()` 的 `binding` 接線
    @Test
    func binding_顧客名稱改變_同步更新草稿() {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = Store(initialState: initial) {
            OrderEditFeature()
        }
        @Bindable var bindable = store

        // When
        $bindable.draft.customerName.wrappedValue = "新客戶"

        // Then
        #expect(store.state.draft.customerName == "新客戶")
    }

    /// 驗證表單選取商品類別後，草稿的 `categories` 同步成選取的清單
    ///
    /// - Note: 此測試守住 `BindingReducer()` 的 `binding` 接線
    @Test
    func binding_分類選取改變_同步更新草稿() {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = Store(initialState: initial) {
            OrderEditFeature()
        }
        @Bindable var bindable = store

        // When
        $bindable.draft.categories.wrappedValue = ["美妝"]

        // Then
        #expect(store.state.draft.categories == ["美妝"])
    }

    /// 驗證表單切換訂單狀態後，草稿的 `status` 同步成新狀態
    ///
    /// - Note: 此測試守住 `BindingReducer()` 的 `binding` 接線
    @Test
    func binding_訂單狀態改變_同步更新草稿() {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = Store(initialState: initial) {
            OrderEditFeature()
        }
        @Bindable var bindable = store

        // When
        $bindable.draft.status.wrappedValue = .delivered

        // Then
        #expect(store.state.draft.status == .delivered)
    }

    /// 驗證表單切換幣別後，草稿的 `currency` 同步成新幣別
    ///
    /// - Note: 此測試守住 `BindingReducer()` 的 `binding` 接線
    @Test
    func binding_訂單幣別改變_同步更新草稿() {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = Store(initialState: initial) {
            OrderEditFeature()
        }
        @Bindable var bindable = store

        // When
        $bindable.draft.currency.wrappedValue = .jpy

        // Then
        #expect(store.state.draft.currency == .jpy)
    }

    /// 驗證折抵初始為 0 時，經表單綁定輸入實收金額 12,345，草稿的 `chargedAmount` 同步為 12,345
    ///
    /// - Note: 夾限行為由 `binding_實收金額降到折抵以下_折抵夾到新上限` 覆蓋
    @Test
    func binding_實收金額改變_同步更新草稿() {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = Store(initialState: initial) {
            OrderEditFeature()
        }
        @Bindable var bindable = store

        // When
        $bindable.chargedAmount.wrappedValue = 12_345

        // Then
        #expect(store.state.draft.chargedAmount == 12_345)
    }

    /// 驗證商品成本、運費與手續費率等成本欄位經綁定寫入後，草稿中對應欄位保留寫入的值
    ///
    /// - Parameter field: 要更新的訂單草稿欄位
    /// - Note: 此測試守住 `BindingReducer()` 的 `binding` 接線
    @Test(arguments: CostField.allCases)
    func binding_成本欄位改變_同步更新草稿(field: CostField) {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = Store(initialState: initial) {
            OrderEditFeature()
        }
        @Bindable var bindable = store

        // When
        $bindable.draft[dynamicMember: field.keyPath].wrappedValue = field.value

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

        /// 國內運費
        case domesticShipping

        /// 國際運費
        case internationalShipping

        /// 刷卡手續費率
        case cardFeeRate

        /// 平台手續費率
        case platformFeeRate

        /// 草稿中對應欄位的可寫 key path，供綁定寫入與讀回結果時使用
        var keyPath: WritableKeyPath<OrderDraft, Decimal> {
            switch self {
            case .itemCost:
                \.itemCost

            case .domesticShipping:
                \.domesticShipping

            case .internationalShipping:
                \.internationalShipping

            case .cardFeeRate:
                \.cardFeeRate

            case .platformFeeRate:
                \.platformFeeRate
            }
        }

        /// 各欄位用於測試的固定值
        var value: Decimal {
            switch self {
            case .itemCost:
                5_000

            case .domesticShipping:
                80

            case .internationalShipping:
                320

            case .cardFeeRate:
                0.015

            case .platformFeeRate:
                0.03
            }
        }
    }
}
