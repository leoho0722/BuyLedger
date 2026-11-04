//
//  PaymentMethodEditFormFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/2.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `PaymentMethodEditFormFeature` 的單元測試，涵蓋草稿與旗標的綁定、變更判斷、可提交判斷與送出結果
@MainActor
struct PaymentMethodEditFormFeatureTests {

    /// 驗證付款方式表單開啟時，草稿名稱與三個旗標等於開啟時的原值
    @Test
    func init_沿用原名稱與旗標_草稿等於開啟時的值() {
        // Given
        let flags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: true
        )
        let state = PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: flags)

        // When
        let draftName = state.draftName

        // Then
        #expect(draftName == "信用卡")
        #expect(state.isDraftCardless == true)
        #expect(state.isDraftBankTransfer == false)
        #expect(state.isDraftCashOnDelivery == true)
    }

    /// 驗證草稿名稱經 `BindingAction` 寫入時，`State` 的草稿更新為新值
    @Test
    func binding_草稿名稱改為新值_寫入草稿() async {
        // Given
        let store = TestStore(
            initialState: PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: .none)
        ) {
            PaymentMethodEditFormFeature()
        }

        // When
        await store.send(.binding(.set(\.draftName, "新卡"))) {
            $0.draftName = "新卡"
        }

        // Then
        #expect(store.state.draftName == "新卡")
    }

    /// 驗證分類旗標經 `BindingAction` 寫入時，`State` 的旗標更新為新值
    @Test
    func binding_切換貨到付款旗標_寫入旗標() async {
        // Given
        let store = TestStore(
            initialState: PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: .none)
        ) {
            PaymentMethodEditFormFeature()
        }

        // When
        await store.send(.binding(.set(\.isDraftCashOnDelivery, true))) {
            $0.isDraftCashOnDelivery = true
        }

        // Then
        #expect(store.state.isDraftCashOnDelivery == true)
    }

    /// 驗證經畫面的 `@Bindable` 綁定切換旗標時，Store 的旗標同步更新
    @Test
    func binding_經畫面綁定路徑切換旗標_更新旗標() {
        // Given
        let store = Store(
            initialState: PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: .none)
        ) {
            PaymentMethodEditFormFeature()
        }
        @Bindable var bindable = store

        // When
        $bindable.isDraftCashOnDelivery.wrappedValue = true

        // Then
        #expect(store.isDraftCashOnDelivery == true)
    }

    /// 驗證草稿與旗標皆未修改時，不算已變更
    @Test
    func isDirty_未修改_不算變更() {
        // Given
        let flags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        let state = PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: flags)

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == false)
    }

    /// 驗證只切換分類旗標時，判定為已變更
    @Test
    func isDirty_只切換分類旗標_算變更() {
        // Given
        var state = PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: .none)
        state.isDraftBankTransfer = true

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == true)
    }

    /// 驗證名稱前後多出空白時仍算已變更，與付款方式表單比對未修剪名稱的規則一致
    @Test
    func isDirty_名稱首尾多空白_仍算變更() {
        // Given
        var state = PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: .none)
        state.draftName = "信用卡 "

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == true)
    }

    /// 驗證草稿名稱只有空白時不可提交
    @Test
    func canSubmit_名稱只有空白_不可提交() {
        // Given
        var state = PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: .none)
        state.draftName = "  "

        // When
        let canSubmit = state.canSubmit

        // Then
        #expect(canSubmit == false)
    }

    /// 驗證送出時名稱使用去除空白後的值，旗標使用動作攜帶的草稿旗標
    @Test
    func saveButtonTapped_送出修剪名稱與草稿旗標() async {
        // Given
        let store = TestStore(
            initialState: PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: .none)
        ) {
            PaymentMethodEditFormFeature()
        }
        let codFlags = PaymentMethodFlags(
            isCardless: false,
            isBankTransfer: false,
            isCashOnDelivery: true
        )

        // When
        await store.send(.view(.saveButtonTapped(name: " 新卡 ", flags: codFlags)))

        // Then
        await store.receive(\.delegate, .saved(originalName: "信用卡", newName: "新卡", flags: codFlags))
    }

    /// 驗證有未儲存變更時按下取消，只呈現捨棄確認，表單不關閉
    @Test
    func cancelButtonTapped_有未儲存變更_顯示捨棄確認且不關閉() async {
        // Given
        var initial = PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: .none)
        initial.draftName = "新卡"
        let dismissCallCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            PaymentMethodEditFormFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {
                dismissCallCount.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.view(.cancelButtonTapped)) {
            $0.isDiscardConfirmationPresented = true
        }

        // Then
        await store.finish()
        #expect(dismissCallCount.value == 0)
    }

    /// 驗證沒有未儲存變更時按下取消，reducer 直接關閉表單
    @Test
    func cancelButtonTapped_無未儲存變更_關閉表單() async {
        // Given
        let dismissCallCount = LockIsolated(0)
        let store = TestStore(
            initialState: PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: .none)
        ) {
            PaymentMethodEditFormFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {
                dismissCallCount.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.view(.cancelButtonTapped))

        // Then
        await store.finish()
        #expect(dismissCallCount.value == 1)
    }

    /// 驗證在捨棄確認中選擇捨棄變更，reducer 關閉表單且只呼叫一次 dismiss
    @Test
    func discardChangesButtonTapped_確認捨棄_關閉表單() async {
        // Given
        var initial = PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: .none)
        initial.draftName = "新卡"
        initial.isDiscardConfirmationPresented = true
        let dismissCallCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            PaymentMethodEditFormFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {
                dismissCallCount.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.view(.discardChangesButtonTapped))

        // Then
        await store.finish()
        #expect(dismissCallCount.value == 1)
    }

    /// 驗證確認框開啟且草稿與旗標有變更時，經綁定把確認框設為關閉 (繼續編輯)，草稿與旗標保留且表單不關閉
    @Test
    func binding_確認框開啟時設為關閉_草稿與旗標保留且表單不關閉() async {
        // Given
        var initial = PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: .none)
        initial.draftName = "新卡"
        initial.isDraftCashOnDelivery = true
        initial.isDiscardConfirmationPresented = true
        let dismissCallCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            PaymentMethodEditFormFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {
                dismissCallCount.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.binding(.set(\.isDiscardConfirmationPresented, false))) {
            $0.isDiscardConfirmationPresented = false
        }

        // Then
        await store.finish()
        #expect(store.state.isDiscardConfirmationPresented == false)
        #expect(store.state.draftName == "新卡")
        #expect(store.state.isDraftCashOnDelivery == true)
        #expect(dismissCallCount.value == 0)
    }
}
