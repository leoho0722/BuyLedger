//
//  OrderEditFeatureTests+Binding.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrderEditFeatureTests {

    /// 在表單輸入顧客名稱時，草稿的顧客名稱跟著更新
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

    /// 在表單選擇商品類別時，草稿的類別跟著更新
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

    /// 在表單切換訂單狀態時，草稿的狀態跟著更新
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

    /// 在表單切換幣別時，草稿的幣別跟著更新
    ///
    /// - Note: 此測試守住 `BindingReducer()` 的 `binding` 接線
    @Test
    func binding_來源幣別改變_同步更新草稿() {
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

    /// 折抵為 0 時輸入實收金額，草稿金額跟著更新，不觸發折抵夾限
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

    /// 金額或費率欄位透過 `binding` 寫入後，草稿保留指定值
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
