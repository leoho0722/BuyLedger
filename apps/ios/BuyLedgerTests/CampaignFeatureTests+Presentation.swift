//
//  CampaignFeatureTests+Presentation.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 取消沒有變更的表單時進入關閉中，暫存的通知不會在表單關好前提早呈現
    @Test
    func presentation_取消無變更的表單_進入關閉中且暫存通知不提前呈現() async {
        // Given
        let pendingNotice = Self.failureAlert("開團狀態自動更新失敗，請稍後再試。")
        var initial = CampaignFeature.State()
        initial.presentation.destination = .edit(Self.makeEditState())
        initial.presentation.queue.pendingNotice = pendingNotice
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.cancelButtonTapped))))))

        // Then
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        #expect(store.state.presentation.destination == nil)
        #expect(store.state.presentation.queue.pendingNotice == pendingNotice)
    }

    /// 確認捨棄未儲存變更時進入關閉中，暫存的通知不會在表單關好前提早呈現
    @Test
    func presentation_確認捨棄變更_進入關閉中且暫存通知不提前呈現() async {
        // Given
        var editState = Self.makeEditState()
        editState.draft.name = "團"
        editState.discardConfirmation = Self.discardAlert
        let pendingNotice = Self.failureAlert("結團失敗，請稍後再試。")
        var initial = CampaignFeature.State()
        initial.presentation.destination = .edit(editState)
        initial.presentation.queue.pendingNotice = pendingNotice
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(
            .presentation(
                .destination(.presented(.edit(.discardConfirmation(.presented(.discard)))))
            )
        ) {
            $0.presentation.destination?.modify(\.edit) {
                $0.discardConfirmation = nil
            }
        }

        // Then
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        #expect(store.state.presentation.destination == nil)
        #expect(store.state.presentation.queue.pendingNotice == pendingNotice)
    }

    /// 捨棄確認選「繼續編輯」時表單維持開啟，暫存的通知保留到表單真正關閉
    @Test
    func presentation_選繼續編輯_表單維持開啟且暫存通知保留() async {
        // Given
        var editState = Self.makeEditState()
        editState.draft.name = "團"
        editState.discardConfirmation = Self.discardAlert
        let pendingNotice = Self.failureAlert("結團失敗，請稍後再試。")
        var initial = CampaignFeature.State()
        initial.presentation.destination = .edit(editState)
        initial.presentation.queue.pendingNotice = pendingNotice
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(
            .presentation(.destination(.presented(.edit(.discardConfirmation(.dismiss)))))
        ) {
            $0.presentation.destination?.modify(\.edit) {
                $0.discardConfirmation = nil
            }
        }

        // Then
        #expect(store.state.presentation.destination?.edit?.draft.name == "團")
        #expect(store.state.presentation.queue.isFormClosing == false)
        #expect(store.state.presentation.queue.pendingNotice == pendingNotice)
    }

    /// 通知的按鈕按下後目的地清空，不留下已顯示的通知
    @Test
    func presentation_提示關閉後_目的地為空() async {
        // Given
        var initial = CampaignFeature.State()
        initial.presentation.destination = Self.failureAlert("開團刪除失敗，請稍後再試。")
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.presentation(.destination(.dismiss))) {
            $0.presentation.destination = nil
        }

        // Then
        #expect(store.state.presentation.destination == nil)
        #expect(store.state.presentation.queue == CampaignPresentationQueue())
    }

    /// 提醒子 Feature 在沒有表單開啟時回報失敗，直接呈現對應標題、訊息與按鈕的通知
    ///
    /// - Parameter failure: 提醒流程回報的失敗種類
    @Test(arguments: [
        CampaignReminderFeature.Failure.accessDenied,
        .accessRestricted,
        .creationFailed,
        .calendarUnavailable,
        .linkRemovalFailed,
        .oldEventRemovalFailed,
        .eventRemovalAfterDeleteFailed,
    ])
    func reminder_子層回報失敗_直接呈現對應文案的通知(failure: CampaignReminderFeature.Failure) async {
        // Given
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        }

        // When
        await store.send(.reminder(.delegate(.failed(failure))))

        // Then
        await store.receive(
            \.presentation.noticeRequested,
            Self.reminderFailureAlert(for: failure)
        ) {
            $0.presentation.destination = Self.reminderFailureAlert(for: failure)
        }
        #expect(store.state.presentation.destination == Self.reminderFailureAlert(for: failure))
        #expect(store.state.presentation.queue.pendingNotice == nil)
    }

    /// 表單開啟中收到提醒失敗時暫存通知，不取代使用者正在編輯的表單
    @Test
    func reminder_表單開啟中子層回報失敗_暫存通知且表單維持開啟() async {
        // Given
        let editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        var initial = CampaignFeature.State()
        initial.presentation.destination = .edit(editState)
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.reminder(.delegate(.failed(.creationFailed))))

        // Then
        let expectedNotice = Self.reminderFailureAlert(for: .creationFailed)
        await store.receive(\.presentation.noticeRequested, expectedNotice) {
            $0.presentation.queue.pendingNotice = expectedNotice
        }
        #expect(store.state.presentation.destination == .edit(editState))
        #expect(store.state.presentation.queue.pendingNotice == expectedNotice)
    }

    /// 權限提示的「前往設定」以注入的相依開啟系統設定
    ///
    /// - Note: 純 `AlertState` 的 `.ifLet` 收到 `.presented` 動作會隱含自動清空該呈現
    @Test
    func presentation_點選開啟設定_開啟系統設定() async {
        // Given
        let hasOpenedSettings = LockIsolated(false)
        var initial = CampaignFeature.State()
        initial.presentation.destination = Self.accessDeniedAlert
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.openSettingsService.open = {
                hasOpenedSettings.setValue(true)
            }
        }

        // When
        await store.send(.presentation(.destination(.presented(.alert(.openSettings))))) {
            $0.presentation.destination = nil
        }

        // Then
        await store.finish()
        #expect(hasOpenedSettings.value)
        #expect(store.state.presentation.destination == nil)
    }
}
