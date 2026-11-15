//
//  LookupRenameFormFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/2.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `LookupRenameFormFeature` 的單元測試，涵蓋草稿與焦點的綁定、可提交判斷與送出結果
@MainActor
struct LookupRenameFormFeatureTests {

    /// 驗證改名表單輸入名稱時，畫面送出 `draftName` 自己的 binding action，`State` 的草稿更新為新值
    ///
    /// - Note: 畫面綁定 `$renameStore.draftName`
    @Test
    func binding_草稿名稱改為新值_寫入草稿() async {
        // Given
        let store = TestStore(
            initialState: LookupRenameFormFeature.State(originalName: "服飾")
        ) {
            LookupRenameFormFeature()
        }

        // When
        await store.send(\.binding.draftName, "美妝") {
            $0.draftName = "美妝"
        }

        // Then
        #expect(store.state.draftName == "美妝")
    }

    /// 驗證名稱欄位取得焦點時，畫面送出 `isNameFieldFocused` 自己的 binding action，`State` 記錄為聚焦
    ///
    /// - Note: 畫面綁定 `$renameStore.isNameFieldFocused`
    @Test
    func binding_名稱欄位取得焦點_寫入聚焦狀態() async {
        // Given
        let store = TestStore(
            initialState: LookupRenameFormFeature.State(originalName: "服飾")
        ) {
            LookupRenameFormFeature()
        }

        // When
        await store.send(\.binding.isNameFieldFocused, true) {
            $0.isNameFieldFocused = true
        }

        // Then
        #expect(store.state.isNameFieldFocused == true)
    }

    /// 驗證顯示捨棄確認彈窗時，畫面送出 `isDiscardConfirmationPresented` 自己的 binding action，
    /// `State` 記錄為顯示中
    ///
    /// - Note: 畫面綁定 `$renameStore.isDiscardConfirmationPresented`
    @Test
    func binding_顯示捨棄確認_寫入確認狀態() async {
        // Given
        let store = TestStore(
            initialState: LookupRenameFormFeature.State(originalName: "服飾")
        ) {
            LookupRenameFormFeature()
        }

        // When
        await store.send(\.binding.isDiscardConfirmationPresented, true) {
            $0.isDiscardConfirmationPresented = true
        }

        // Then
        #expect(store.state.isDiscardConfirmationPresented == true)
    }

    /// 驗證改名表單開啟時，草稿等於原名稱且焦點與捨棄確認皆為關閉
    @Test
    func init_建立改名表單_草稿等於原名稱() {
        // Given
        let state = LookupRenameFormFeature.State(originalName: "服飾")

        // When
        let draftName = state.draftName

        // Then
        #expect(draftName == "服飾")
        #expect(state.isNameFieldFocused == false)
        #expect(state.isDiscardConfirmationPresented == false)
    }

    /// 驗證草稿只在前後多出空白時，去除空白後與原名稱相同，不算已變更
    @Test
    func isDirty_首尾空白與原名稱相同_不算變更() {
        // Given
        var state = LookupRenameFormFeature.State(originalName: "服飾")
        state.draftName = " 服飾 "

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == false)
    }

    /// 驗證草稿改為不同名稱時，判定為已變更
    @Test
    func isDirty_輸入不同名稱_算變更() {
        // Given
        var state = LookupRenameFormFeature.State(originalName: "服飾")
        state.draftName = "美妝"

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == true)
    }

    /// 驗證草稿只有空白時不可提交
    @Test
    func canSubmit_名稱只有空白_不可提交() {
        // Given
        var state = LookupRenameFormFeature.State(originalName: "服飾")
        state.draftName = "   "

        // When
        let canSubmit = state.canSubmit

        // Then
        #expect(canSubmit == false)
    }

    /// 驗證草稿與原名稱相同時不可提交，即使前後有空白
    @Test
    func canSubmit_名稱與原名稱相同_不可提交() {
        // Given
        var state = LookupRenameFormFeature.State(originalName: "服飾")
        state.draftName = " 服飾 "

        // When
        let canSubmit = state.canSubmit

        // Then
        #expect(canSubmit == false)
    }

    /// 驗證草稿為不同的非空名稱時可以提交
    @Test
    func canSubmit_輸入新名稱_可提交() {
        // Given
        var state = LookupRenameFormFeature.State(originalName: "服飾")
        state.draftName = "美妝"

        // When
        let canSubmit = state.canSubmit

        // Then
        #expect(canSubmit == true)
    }

    /// 驗證送出的新名稱前後有空白時，改名結果使用去除空白後的名稱
    @Test
    func saveButtonTapped_新名稱前後有空白_送出修剪後的結果() async {
        // Given
        let store = TestStore(
            initialState: LookupRenameFormFeature.State(originalName: "服飾")
        ) {
            LookupRenameFormFeature()
        }

        // When
        await store.send(.view(.saveButtonTapped(name: " 美妝 ")))

        // Then
        await store.receive(\.delegate, .saved(oldName: "服飾", newName: "美妝"))
    }

    /// 驗證送出的名稱與原名稱相同時，不回傳改名結果
    @Test
    func saveButtonTapped_名稱與原名稱相同_不送出() async {
        // Given
        let store = TestStore(
            initialState: LookupRenameFormFeature.State(originalName: "服飾")
        ) {
            LookupRenameFormFeature()
        }

        // When
        await store.send(.view(.saveButtonTapped(name: "服飾")))

        // Then
        // 沒有 delegate，多出的改名結果會被 `TestStore` 列為未預期的 action
        await store.finish()
        #expect(store.state.draftName == "服飾")
    }

    /// 驗證有未儲存變更時按下取消，只呈現捨棄確認，表單不關閉
    @Test
    func cancelButtonTapped_有未儲存變更_顯示捨棄確認且不關閉() async {
        // Given
        var initial = LookupRenameFormFeature.State(originalName: "服飾")
        initial.draftName = "美妝"
        let dismissCallCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            LookupRenameFormFeature()
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
            initialState: LookupRenameFormFeature.State(originalName: "服飾")
        ) {
            LookupRenameFormFeature()
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
        var initial = LookupRenameFormFeature.State(originalName: "服飾")
        initial.draftName = "美妝"
        initial.isDiscardConfirmationPresented = true
        let dismissCallCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            LookupRenameFormFeature()
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

    /// 驗證確認框開啟且草稿有變更時，經綁定把確認框設為關閉 (繼續編輯)，草稿保留且表單不關閉
    @Test
    func binding_確認框開啟時設為關閉_草稿保留且表單不關閉() async {
        // Given
        var initial = LookupRenameFormFeature.State(originalName: "服飾")
        initial.draftName = "美妝"
        initial.isDiscardConfirmationPresented = true
        let dismissCallCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            LookupRenameFormFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {
                dismissCallCount.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(\.binding.isDiscardConfirmationPresented, false) {
            $0.isDiscardConfirmationPresented = false
        }

        // Then
        await store.finish()
        #expect(store.state.isDiscardConfirmationPresented == false)
        #expect(store.state.draftName == "美妝")
        #expect(dismissCallCount.value == 0)
    }
}
