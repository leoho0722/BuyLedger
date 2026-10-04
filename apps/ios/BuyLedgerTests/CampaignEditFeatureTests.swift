//
//  CampaignEditFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/19.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證開團表單的草稿、驗證、送出與捨棄流程
@MainActor
struct CampaignEditFeatureTests {

    /// 新增與編輯表單在名稱修改後出現未儲存變更，改回原名後不再有未儲存變更
    ///
    /// - Parameter hasOriginal: 是否以既有開團建立表單
    /// - Throws: 初始或修改後的草稿未符合前置條件時拋出測試錯誤
    @Test(arguments: [false, true])
    func isDirty_名稱修改後還原_恢復初始草稿(hasOriginal: Bool) throws(any Error) {
        // Given
        var state = Self.makeState(original: hasOriginal ? Self.original : nil)
        try #require(state.isDirty == false)
        state.draft.name = "四月團"
        try #require(state.isDirty)

        // When
        state.draft.name = hasOriginal ? "三月團" : ""

        // Then
        #expect(state.isDirty == false)
    }

    /// 七個草稿欄位任一欄改變都應標記未儲存變更
    ///
    /// - Parameter field: 要獨立修改的草稿欄位
    @Test(arguments: DraftField.allCases)
    func isDirty_單一草稿欄位變更_標記未儲存變更(field: DraftField) {
        // Given
        var state = Self.makeState()

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
            state.draft.notes = "備註"

        case .wantsReminder:
            state.draft.wantsReminder = true

        case .reminderTimestamp:
            state.draft.reminderTimestamp = Date(timeIntervalSince1970: 3_600)
        }

        // Then
        #expect(state.isDirty)
    }

    /// 有變更時取消只呈現捨棄確認，不直接關閉表單
    @Test
    func cancelButtonTapped_草稿有變更_呈現捨棄確認() async {
        // Given
        var initial = Self.makeState()
        initial.draft.name = "四月團"
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
        await store.send(.view(.cancelButtonTapped)) {
            $0.discardConfirmation = Self.discardAlert
        }

        // Then
        #expect(store.state.discardConfirmation == Self.discardAlert)
        #expect(dismissCalls.value == 0)
    }

    /// 確認捨棄後關閉表單，呈現狀態由 `ifLet` 清除
    @Test
    func discardConfirmation_確認捨棄_關閉表單並清除確認() async {
        // Given
        var initial = Self.makeState()
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

    /// 未修改的草稿取消時直接關閉，不呈現捨棄確認
    @Test
    func cancelButtonTapped_草稿未變更_直接關閉表單() async {
        // Given
        let dismissCalls = LockIsolated(0)
        let store = TestStore(initialState: Self.makeState()) {
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

    /// 名稱欄位的綁定屬性變更時更新草稿並清除父層寫回的重名原因
    @Test
    func binding_修改名稱_清除過期重名訊息() async {
        // Given
        var initial = Self.makeState()
        initial.nameConflictMessage = "已有其他開團使用這個名稱，請改用不同名稱。"
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

    /// 切換提醒意圖時透過 `BindingReducer` 更新草稿開關
    ///
    /// - Parameter wantsReminder: 使用者選定的提醒意圖
    @Test(arguments: [true, false])
    func binding_切換提醒意圖_更新草稿提醒開關(wantsReminder: Bool) async {
        // Given
        var initial = Self.makeState()
        initial.draft.wantsReminder = !wantsReminder
        let store = TestStore(initialState: initial) {
            CampaignEditFeature()
        }

        // When
        await store.send(.binding(.set(\.draft.wantsReminder, wantsReminder))) {
            $0.draft.wantsReminder = wantsReminder
        }

        // Then
        #expect(store.state.draft.wantsReminder == wantsReminder)
    }

    /// 修改提醒時間時透過 `BindingReducer` 更新草稿時間戳
    @Test
    func binding_修改提醒時間_更新草稿提醒時間() async {
        // Given
        let picked = Date(timeIntervalSince1970: 3_600)
        let store = TestStore(initialState: Self.makeState()) {
            CampaignEditFeature()
        }

        // When
        await store.send(.binding(.set(\.draft.reminderTimestamp, picked))) {
            $0.draft.reminderTimestamp = Date(timeIntervalSince1970: 3_600)
        }

        // Then
        #expect(store.state.draft.reminderTimestamp == Date(timeIntervalSince1970: 3_600))
    }

    /// 名稱為空或只有空白時不送出儲存請求，也不關閉表單
    ///
    /// - Parameter name: 空字串或只有空白與換行的名稱
    @Test(arguments: ["", " \n\t "])
    func saveButtonTapped_名稱只有空白_不送出儲存請求(name: String) async {
        // Given
        var initial = Self.makeState()
        initial.draft.name = name
        let store = TestStore(initialState: initial) {
            CampaignEditFeature()
        }

        // When
        await store.send(.view(.saveButtonTapped))

        // Then
        await store.finish()
        #expect(store.state == initial)
        #expect(store.state.canSave == false)
    }

    /// 有效名稱送出去空白名稱、原開團與完整草稿，子層維持開啟
    ///
    /// - Parameter hasOriginal: 儲存請求是否包含原開團
    @Test(arguments: [false, true])
    func saveButtonTapped_名稱有效_送出完整請求且不關閉(hasOriginal: Bool) async {
        // Given
        let original = hasOriginal ? Self.original : nil
        var initial = Self.makeState(original: original)
        initial.draft.name = " \n四月團\t "
        initial.draft.openDate = Date(timeIntervalSince1970: 3_600)
        initial.draft.closeDate = Date(timeIntervalSince1970: 10_800)
        initial.draft.status = .closed
        initial.draft.notes = " 備註 "
        initial.draft.wantsReminder = true
        initial.draft.reminderTimestamp = Date(timeIntervalSince1970: 7_200)
        var expectedDraft = CampaignDraft(
            original: nil,
            currentDate: Date(timeIntervalSince1970: 3_600),
            wantsReminder: true,
            reminderTimestamp: Date(timeIntervalSince1970: 7_200)
        )
        expectedDraft.name = " \n四月團\t "
        expectedDraft.openDate = Date(timeIntervalSince1970: 3_600)
        expectedDraft.closeDate = Date(timeIntervalSince1970: 10_800)
        expectedDraft.status = .closed
        expectedDraft.notes = " 備註 "
        let expected = CampaignEditFeature.SaveRequest(
            original: original,
            name: "四月團",
            draft: expectedDraft
        )
        let store = TestStore(initialState: initial) {
            CampaignEditFeature()
        }

        // When
        await store.send(.view(.saveButtonTapped))

        // Then
        await store.receive(\.delegate.saveRequested, expected)
        #expect(store.state == initial)
        #expect(store.state.canSave)
    }
}

// MARK: - Nested Types

extension CampaignEditFeatureTests {

    /// 逐一驗證未儲存變更的草稿欄位
    enum DraftField: CaseIterable, Sendable {

        /// 開團名稱
        case name

        /// 開團日期
        case openDate

        /// 結單日期
        case closeDate

        /// 開團狀態
        case status

        /// 備註
        case notes

        /// 提醒意圖
        case wantsReminder

        /// 提醒時間
        case reminderTimestamp
    }
}

// MARK: - Private Method

private extension CampaignEditFeatureTests {

    /// 固定內容的原開團，供編輯與請求內容斷言使用
    static var original: Campaign {
        Campaign.fixture(
            id: "C1",
            name: "三月團",
            openDate: Date(timeIntervalSince1970: 0),
            status: .ongoing,
            notes: ""
        )
    }

    /// 捨棄確認的獨立預期文案與按鈕
    static var discardAlert: AlertState<CampaignEditFeature.Action.DiscardAlert> {
        AlertState {
            TextState("捨棄變更")
        } actions: {
            ButtonState(role: .destructive, action: .discard) {
                TextState("捨棄變更")
            }
            ButtonState(role: .cancel) {
                TextState("繼續編輯")
            }
        } message: {
            TextState("這個開團有尚未儲存的變更，離開後將不會保留。")
        }
    }

    /// 建立固定識別值與時間的表單狀態
    ///
    /// - Parameter original: 原開團；沒有時建立新增表單
    /// - Returns: 尚未修改的表單狀態
    static func makeState(original: Campaign? = nil) -> CampaignEditFeature.State {
        CampaignEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: Date(timeIntervalSince1970: 0),
            reminderTimestamp: Date(timeIntervalSince1970: 0)
        )
    }
}
