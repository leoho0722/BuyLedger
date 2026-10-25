//
//  CampaignEditFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/19.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `CampaignEditFeature` 的單元測試，涵蓋草稿的未儲存變更、名稱檢查、送出與捨棄流程
struct CampaignEditFeatureTests {

    /// 驗證新增與編輯表單改了名稱後出現未儲存變更，改回原名後未儲存變更消失
    ///
    /// - Parameter hasOriginal: 是否以既有開團建立表單
    /// - Throws: 初始或修改後的草稿未符合前置條件時丟出測試錯誤
    @Test(arguments: [false, true])
    func isDirty_名稱修改後還原_恢復初始草稿(hasOriginal: Bool) throws {
        // Given
        var state = CampaignEditFeatureTestSupport.makeState(
            original: hasOriginal ? CampaignEditFeatureTestSupport.original : nil
        )
        try #require(state.isDirty == false)
        state.draft.name = "四月團"
        try #require(state.isDirty)

        // When
        state.draft.name = hasOriginal ? "三月團" : ""

        // Then
        #expect(state.isDirty == false)
    }

    /// 驗證七個草稿欄位中任一欄改變時，表單都標記為有未儲存變更
    ///
    /// - Parameter field: 要獨立修改的草稿欄位
    @Test(arguments: DraftField.allCases)
    func isDirty_單一草稿欄位變更_標記未儲存變更(field: DraftField) {
        // Given
        var state = CampaignEditFeatureTestSupport.makeState()

        // When
        switch field {
        case .name:
            state.draft.name = "四月團"

        case .openDate:
            state.draft.openDate = Date(timeIntervalSince1970: 3_600)

        case .closeDate:
            state.draft.closeDate = Date(timeIntervalSince1970: 3_600)

        case .status:
            state.draft.status = .closed

        case .notes:
            state.draft.notes = "orders.detail.label.notes"

        case .wantsReminder:
            state.draft.wantsReminder = true

        case .reminderTimestamp:
            state.draft.reminderTimestamp = Date(timeIntervalSince1970: 3_600)
        }

        // Then
        #expect(state.isDirty)
    }

    /// 驗證草稿有變更時按下取消，只呈現捨棄確認，不關閉表單
    @Test
    @MainActor
    func cancelButtonTapped_草稿有變更_呈現捨棄確認() async {
        // Given
        var initial = CampaignEditFeatureTestSupport.makeState()
        initial.draft.name = "四月團"
        let store = TestStore(initialState: initial) {
            CampaignEditFeature()
        }

        // When
        await store.send(.view(.cancelButtonTapped)) {
            $0.discardConfirmation = Self.discardAlert
        }

        // Then
        #expect(store.state.discardConfirmation == Self.discardAlert)
    }

    /// 驗證確認捨棄後關閉表單，捨棄確認的呈現狀態由 `ifLet` 自動清空
    @Test
    @MainActor
    func discardConfirmation_確認捨棄_關閉表單並清除確認() async {
        // Given
        var initial = CampaignEditFeatureTestSupport.makeState()
        initial.draft.name = "四月團"
        initial.discardConfirmation = Self.discardAlert
        let dismissCalls = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            CampaignEditFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {
                dismissCalls.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.discardConfirmation(.presented(.discard))) {
            $0.discardConfirmation = nil
        }

        // Then
        await store.finish()
        #expect(dismissCalls.value == 1)
        #expect(store.state.discardConfirmation == nil)
    }

    /// 驗證草稿未變更時按下取消，直接關閉表單，不呈現捨棄確認
    @Test
    @MainActor
    func cancelButtonTapped_草稿未變更_直接關閉表單() async {
        // Given
        let dismissCalls = LockIsolated(0)
        let store = TestStore(initialState: CampaignEditFeatureTestSupport.makeState()) {
            CampaignEditFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {
                dismissCalls.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.view(.cancelButtonTapped))

        // Then
        await store.finish()
        #expect(store.state.discardConfirmation == nil)
        #expect(dismissCalls.value == 1)
    }

    /// 驗證名稱欄位的綁定送出改名時，草稿名稱更新，並清除已過期的重名訊息
    @Test
    @MainActor
    func binding_修改名稱_清除過期重名訊息() async {
        // Given
        var initial = CampaignEditFeatureTestSupport.makeState()
        initial.nameConflictMessage = "campaigns.edit.message.anotherCampaignAlready"
        let store = TestStore(initialState: initial) {
            CampaignEditFeature()
        }

        // When
        await store.send(.binding(.set(\.draftName, "五月團"))) {
            $0.draft.name = "五月團"
            $0.nameConflictMessage = nil
        }

        // Then
        #expect(store.state.draft.name == "五月團")
        #expect(store.state.nameConflictMessage == nil)
    }

    /// 驗證切換提醒意圖時，經畫面的 `@Bindable` 綁定路徑更新草稿的提醒開關
    ///
    /// - Parameter isReminderWanted: 使用者選定的提醒意圖
    @Test(arguments: [true, false])
    @MainActor
    func binding_切換提醒意圖_更新草稿提醒開關(isReminderWanted: Bool) {
        // Given
        var initial = CampaignEditFeatureTestSupport.makeState()
        initial.draft.wantsReminder = !isReminderWanted
        let store = Store(initialState: initial) {
            CampaignEditFeature()
        }
        @Bindable var bindable = store

        // When
        $bindable.draft.wantsReminder.wrappedValue = isReminderWanted

        // Then
        #expect(store.draft.wantsReminder == isReminderWanted)
    }

    /// 驗證修改提醒時間時，經畫面的 `@Bindable` 綁定路徑更新草稿的提醒時間
    @Test
    @MainActor
    func binding_修改提醒時間_更新草稿提醒時間() {
        // Given
        let picked = Date(timeIntervalSince1970: 3_600)
        let store = Store(initialState: CampaignEditFeatureTestSupport.makeState()) {
            CampaignEditFeature()
        }
        @Bindable var bindable = store

        // When
        $bindable.draft.reminderTimestamp.wrappedValue = picked

        // Then
        #expect(store.draft.reminderTimestamp == Date(timeIntervalSince1970: 3_600))
    }

    /// 驗證名稱為空或只有空白時，按下儲存不送出儲存請求，表單狀態不變且不關閉
    ///
    /// - Parameter name: 空字串或只有空白與換行的名稱
    @Test(arguments: ["", " \n\t "])
    @MainActor
    func saveButtonTapped_名稱只有空白_不送出儲存請求(name: String) async {
        // Given
        var initial = CampaignEditFeatureTestSupport.makeState()
        initial.draft.name = name
        let store = TestStore(initialState: initial) {
            CampaignEditFeature()
        }

        // When
        await store.send(.view(.saveButtonTapped))

        // Then
        await store.finish()
        #expect(store.state == initial)
    }

    /// 驗證名稱有效時，儲存請求的名稱去除前後空白，連同原開團與完整草稿送出，表單保持開啟
    ///
    /// - Parameter hasOriginal: 儲存請求是否包含原開團
    @Test(arguments: [false, true])
    @MainActor
    func saveButtonTapped_名稱有效_送出完整請求且不關閉(hasOriginal: Bool) async {
        // Given
        let original = hasOriginal ? CampaignEditFeatureTestSupport.original : nil
        var initial = CampaignEditFeatureTestSupport.makeState(original: original)
        initial.draft.name = " \n四月團\t "
        initial.draft.openDate = Date(timeIntervalSince1970: 3_600)
        initial.draft.closeDate = Date(timeIntervalSince1970: 10_800)
        initial.draft.status = .closed
        initial.draft.notes = " 備註 "
        initial.draft.wantsReminder = true
        initial.draft.reminderTimestamp = Date(timeIntervalSince1970: 7_200)
        let expected = CampaignEditFeature.SaveRequest(
            original: original,
            name: "四月團",
            draft: initial.draft
        )
        let store = TestStore(initialState: initial) {
            CampaignEditFeature()
        }

        // When
        await store.send(.view(.saveButtonTapped))

        // Then
        await store.receive(\.delegate.saveRequested, expected)
        #expect(store.state == initial)
    }

    /// 驗證名稱去除頭尾空白後仍有文字時，表單可以送出
    @Test
    func canSave_名稱去空白後仍有文字_可送出() {
        // Given
        var state = CampaignEditFeatureTestSupport.makeState()
        state.draft.name = " \n四月團\t "

        // When
        let canSave = state.canSave

        // Then
        #expect(canSave)
    }

    /// 驗證名稱為空或只有空白與換行時，表單不可送出
    ///
    /// - Parameter name: 空字串或只有空白與換行的名稱
    @Test(arguments: ["", " \n\t "])
    func canSave_名稱只有空白_不可送出(name: String) {
        // Given
        var state = CampaignEditFeatureTestSupport.makeState()
        state.draft.name = name

        // When
        let canSave = state.canSave

        // Then
        #expect(canSave == false)
    }
}

// MARK: - Nested Types

extension CampaignEditFeatureTests {

    /// 未儲存變更測試用的草稿欄位，每個案例各改一個欄位
    enum DraftField: CaseIterable, Sendable {

        /// 草稿的開團名稱被修改
        case name

        /// 草稿的開團日期被修改
        case openDate

        /// 草稿的結單日期被修改
        case closeDate

        /// 草稿的開團狀態被修改
        case status

        /// 草稿的備註被修改
        case notes

        /// 草稿的提醒意圖被修改
        case wantsReminder

        /// 草稿的提醒時間被修改
        case reminderTimestamp
    }
}

// MARK: - Private Method

private extension CampaignEditFeatureTests {

    /// 捨棄確認的獨立預期文案與按鈕
    static var discardAlert: AlertState<CampaignEditFeature.Action.DiscardAlert> {
        AlertState {
            TextState("orders.list.label.discardChanges")
        } actions: {
            ButtonState(role: .destructive, action: .discard) {
                TextState("orders.list.label.discardChanges")
            }
            ButtonState(role: .cancel) {
                TextState("orders.list.label.keepEditing")
            }
        } message: {
            TextState("campaigns.edit.message.campaignHasUnsaved")
        }
    }
}
