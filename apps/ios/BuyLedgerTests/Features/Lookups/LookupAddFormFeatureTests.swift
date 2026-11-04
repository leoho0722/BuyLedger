//
//  LookupAddFormFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/2.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `LookupAddFormFeature` 的單元測試，涵蓋名稱型與付款方式型表單的草稿綁定、變更判斷、可提交判斷與送出結果
@MainActor
struct LookupAddFormFeatureTests {

    /// 驗證新增表單開啟時，名稱草稿為空白、各旗標與焦點皆為關閉
    @Test
    func init_名稱型表單_草稿與旗標為預設值() {
        // Given
        let state = LookupAddFormFeature.State(hasClassification: false)

        // When
        let draftName = state.draftName

        // Then
        #expect(draftName == "")
        #expect(state.isDraftCardless == false)
        #expect(state.isDraftBankTransfer == false)
        #expect(state.isDraftCashOnDelivery == false)
        #expect(state.isNameFieldFocused == false)
        #expect(state.isDiscardConfirmationPresented == false)
    }

    /// 驗證草稿名稱經 `BindingAction` 寫入時，`State` 的草稿更新為新值
    @Test
    func binding_草稿名稱改為新值_寫入草稿() async {
        // Given
        let store = TestStore(
            initialState: LookupAddFormFeature.State(hasClassification: false)
        ) {
            LookupAddFormFeature()
        }

        // When
        await store.send(.binding(.set(\.draftName, "手工藝品"))) {
            $0.draftName = "手工藝品"
        }

        // Then
        #expect(store.state.draftName == "手工藝品")
    }

    /// 驗證付款方式型表單的銀行匯款旗標經綁定寫入時，`State` 記錄為開啟
    @Test
    func binding_切換銀行匯款旗標_寫入旗標() async {
        // Given
        let store = TestStore(
            initialState: LookupAddFormFeature.State(hasClassification: true)
        ) {
            LookupAddFormFeature()
        }

        // When
        await store.send(.binding(.set(\.isDraftBankTransfer, true))) {
            $0.isDraftBankTransfer = true
        }

        // Then
        #expect(store.state.isDraftBankTransfer == true)
    }

    /// 驗證經畫面的 `@Bindable` 綁定修改草稿時，Store 的草稿同步更新
    @Test
    func binding_經畫面綁定路徑修改草稿_更新草稿() {
        // Given
        let store = Store(
            initialState: LookupAddFormFeature.State(hasClassification: true)
        ) {
            LookupAddFormFeature()
        }
        @Bindable var bindable = store

        // When
        $bindable.draftName.wrappedValue = "匯款"

        // Then
        #expect(store.draftName == "匯款")
    }

    /// 驗證名稱型表單只有前後空白時，去除空白後與初始的空白名稱相同，不算已變更
    @Test
    func isDirty_名稱型首尾空白_不算變更() {
        // Given
        var state = LookupAddFormFeature.State(hasClassification: false)
        state.draftName = "  "

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == false)
    }

    /// 驗證付款方式型表單只有空白名稱時仍算已變更，與付款方式表單比對未修剪名稱的規則一致
    @Test
    func isDirty_付款方式型只有空白名稱_算變更() {
        // Given
        var state = LookupAddFormFeature.State(hasClassification: true)
        state.draftName = "  "

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == true)
    }

    /// 驗證付款方式型表單只切換分類旗標時，判定為已變更
    @Test
    func isDirty_付款方式型只切換旗標_算變更() {
        // Given
        var state = LookupAddFormFeature.State(hasClassification: true)
        state.isDraftCashOnDelivery = true

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == true)
    }

    /// 驗證名稱型表單的草稿只有空白時不可提交
    @Test
    func canSubmit_名稱型名稱只有空白_不可提交() {
        // Given
        var state = LookupAddFormFeature.State(hasClassification: false)
        state.draftName = " "

        // When
        let canSubmit = state.canSubmit

        // Then
        #expect(canSubmit == false)
    }

    /// 驗證付款方式型表單的草稿只有空白時不可提交
    @Test
    func canSubmit_付款方式型名稱只有空白_不可提交() {
        // Given
        var state = LookupAddFormFeature.State(hasClassification: true)
        state.draftName = " "

        // When
        let canSubmit = state.canSubmit

        // Then
        #expect(canSubmit == false)
    }

    /// 驗證名稱型表單送出時忽略動作攜帶的旗標，結果不含分類旗標
    @Test
    func saveButtonTapped_名稱型_忽略送出的旗標_送出無旗標() async {
        // Given
        let store = TestStore(
            initialState: LookupAddFormFeature.State(hasClassification: false)
        ) {
            LookupAddFormFeature()
        }
        let cardlessFlags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: false
        )

        // When
        await store.send(.view(.saveButtonTapped(name: "手工藝品", flags: cardlessFlags)))

        // Then
        await store.receive(\.delegate, .saved(name: "手工藝品", flags: .none))
    }

    /// 驗證付款方式型表單送出時使用去除空白後的名稱與動作攜帶的旗標
    @Test
    func saveButtonTapped_付款方式型_送出修剪名稱與旗標() async {
        // Given
        let store = TestStore(
            initialState: LookupAddFormFeature.State(hasClassification: true)
        ) {
            LookupAddFormFeature()
        }
        let bankFlags = PaymentMethodFlags(
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        )

        // When
        await store.send(.view(.saveButtonTapped(name: " 匯款 ", flags: bankFlags)))

        // Then
        await store.receive(\.delegate, .saved(name: "匯款", flags: bankFlags))
    }

    /// 驗證名稱型表單有草稿時按下取消，只呈現捨棄確認，表單不關閉
    @Test
    func cancelButtonTapped_名稱型有草稿_顯示捨棄確認且不關閉() async {
        // Given
        var initial = LookupAddFormFeature.State(hasClassification: false)
        initial.draftName = "手工藝品"
        let dismissCallCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            LookupAddFormFeature()
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

    /// 驗證付款方式型表單只切換分類旗標時按下取消，仍視為有未儲存變更，只呈現捨棄確認
    @Test
    func cancelButtonTapped_付款方式型只切換旗標_顯示捨棄確認且不關閉() async {
        // Given
        var initial = LookupAddFormFeature.State(hasClassification: true)
        initial.isDraftCashOnDelivery = true
        let dismissCallCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            LookupAddFormFeature()
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
            initialState: LookupAddFormFeature.State(hasClassification: false)
        ) {
            LookupAddFormFeature()
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
        var initial = LookupAddFormFeature.State(hasClassification: false)
        initial.draftName = "手工藝品"
        initial.isDiscardConfirmationPresented = true
        let dismissCallCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            LookupAddFormFeature()
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

    /// 驗證付款方式型確認框開啟且草稿與旗標有變更時，經綁定把確認框設為關閉 (繼續編輯)，草稿與旗標保留且表單不關閉
    @Test
    func binding_確認框開啟時設為關閉_草稿與旗標保留且表單不關閉() async {
        // Given
        var initial = LookupAddFormFeature.State(hasClassification: true)
        initial.draftName = "匯款"
        initial.isDraftBankTransfer = true
        initial.isDiscardConfirmationPresented = true
        let dismissCallCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            LookupAddFormFeature()
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
        #expect(store.state.draftName == "匯款")
        #expect(store.state.isDraftBankTransfer == true)
        #expect(dismissCallCount.value == 0)
    }
}
