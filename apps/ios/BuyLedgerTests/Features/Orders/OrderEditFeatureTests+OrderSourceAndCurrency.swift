//
//  OrderEditFeatureTests+OrderSourceAndCurrency.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderEditFeatureTests {

    /// 尚未開啟選擇器時，點選訂單來源按鈕會推入訂單來源選擇器
    @Test
    func pickers_點選訂單來源按鈕時尚未開啟選擇器_推入訂單來源選擇器() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.pickers(.view(.orderSourcePickerTapped))) {
            $0.pickers.pickerRoute = .orderSource
        }

        // Then
        #expect(store.state.pickers.pickerRoute == .orderSource)
    }

    /// 尚未開啟選擇器時，點選幣別按鈕會推入幣別選擇器
    @Test
    func pickers_點選幣別按鈕時尚未開啟選擇器_推入幣別選擇器() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.pickers(.view(.currencyPickerTapped))) {
            $0.pickers.pickerRoute = .currency
        }

        // Then
        #expect(store.state.pickers.pickerRoute == .currency)
    }

    /// 草稿尚無訂單來源時，選取來源會寫入名稱
    @Test
    func pickers_選取訂單來源且草稿尚無來源_更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.pickers(.view(.orderSourceSelected("蝦皮"))))

        // Then
        await store.receive(\.pickers.delegate.orderSourceSelected, "蝦皮") {
            $0.draft.orderSource = "蝦皮"
        }
        #expect(store.state.draft.orderSource == "蝦皮")
    }

    /// 草稿使用預設台幣時，選取幣別會更新代碼
    @Test
    func pickers_選取幣別且草稿為預設台幣_更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.pickers(.view(.currencySelected("JPY"))))

        // Then
        await store.receive(\.pickers.delegate.currencySelected, "JPY") {
            $0.draft.currency = .jpy
        }
        #expect(store.state.draft.currency == .jpy)
    }
}
