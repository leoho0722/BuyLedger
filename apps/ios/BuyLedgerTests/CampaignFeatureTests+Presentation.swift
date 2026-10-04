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
    func destination_取消無變更的表單_進入關閉中且暫存通知不提前呈現() async {
        // Given
        let pendingNotice = Self.failureAlert("開團狀態自動更新失敗，請稍後再試。")
        var initial = CampaignFeature.State()
        initial.destination = .edit(Self.makeEditState())
        initial.presentationQueue.pendingNotice = pendingNotice
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.destination(.presented(.edit(.view(.cancelButtonTapped)))))

        // Then
        await store.receive(\.destination.dismiss) {
            $0.destination = nil
            $0.presentationQueue.isFormClosing = true
        }
        #expect(store.state.destination == nil)
        #expect(store.state.presentationQueue.pendingNotice == pendingNotice)
    }

    /// 確認捨棄未儲存變更時進入關閉中，暫存的通知不會在表單關好前提早呈現
    @Test
    func destination_確認捨棄變更_進入關閉中且暫存通知不提前呈現() async {
        // Given
        var editState = Self.makeEditState()
        editState.draft.name = "團"
        editState.discardConfirmation = Self.discardAlert
        let pendingNotice = Self.failureAlert("結團失敗，請稍後再試。")
        var initial = CampaignFeature.State()
        initial.destination = .edit(editState)
        initial.presentationQueue.pendingNotice = pendingNotice
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(
            .destination(.presented(.edit(.discardConfirmation(.presented(.discard)))))
        ) {
            $0.destination?.modify(\.edit) {
                $0.discardConfirmation = nil
            }
        }

        // Then
        await store.receive(\.destination.dismiss) {
            $0.destination = nil
            $0.presentationQueue.isFormClosing = true
        }
        #expect(store.state.destination == nil)
        #expect(store.state.presentationQueue.pendingNotice == pendingNotice)
    }

    /// 捨棄確認選「繼續編輯」時表單維持開啟，暫存的通知保留到表單真正關閉
    @Test
    func destination_選繼續編輯_表單維持開啟且暫存通知保留() async {
        // Given
        var editState = Self.makeEditState()
        editState.draft.name = "團"
        editState.discardConfirmation = Self.discardAlert
        let pendingNotice = Self.failureAlert("結團失敗，請稍後再試。")
        var initial = CampaignFeature.State()
        initial.destination = .edit(editState)
        initial.presentationQueue.pendingNotice = pendingNotice
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.destination(.presented(.edit(.discardConfirmation(.dismiss))))) {
            $0.destination?.modify(\.edit) {
                $0.discardConfirmation = nil
            }
        }

        // Then
        #expect(store.state.destination?.edit?.draft.name == "團")
        #expect(store.state.presentationQueue.isFormClosing == false)
        #expect(store.state.presentationQueue.pendingNotice == pendingNotice)
    }

    /// 開啟中到達的通知，在使用者選繼續編輯後再取消並確認捨棄，表單關閉時才進入關閉中
    @Test
    func destination_開啟中到達後選繼續編輯再捨棄_關閉後才輪到暫存通知() async {
        // Given
        var editState = Self.makeEditState()
        editState.draft.name = "團"
        let pendingNotice = Self.failureAlert("結團失敗，請稍後再試。")
        var initial = CampaignFeature.State()
        initial.destination = .edit(editState)
        initial.presentationQueue.pendingNotice = pendingNotice
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }
        await store.send(.destination(.presented(.edit(.view(.cancelButtonTapped))))) {
            $0.destination?.modify(\.edit) {
                $0.discardConfirmation = Self.discardAlert
            }
        }
        await store.send(.destination(.presented(.edit(.discardConfirmation(.dismiss))))) {
            $0.destination?.modify(\.edit) {
                $0.discardConfirmation = nil
            }
        }
        await store.send(.destination(.presented(.edit(.view(.cancelButtonTapped))))) {
            $0.destination?.modify(\.edit) {
                $0.discardConfirmation = Self.discardAlert
            }
        }

        // When
        await store.send(
            .destination(.presented(.edit(.discardConfirmation(.presented(.discard)))))
        ) {
            $0.destination?.modify(\.edit) {
                $0.discardConfirmation = nil
            }
        }

        // Then
        await store.receive(\.destination.dismiss) {
            $0.destination = nil
            $0.presentationQueue.isFormClosing = true
        }
        #expect(store.state.presentationQueue.pendingNotice == pendingNotice)
    }

    /// 通知的按鈕按下後目的地清空，不留下已顯示的通知
    @Test
    func destination_提示關閉後_目的地為空() async {
        // Given
        var initial = CampaignFeature.State()
        initial.destination = Self.failureAlert("開團刪除失敗，請稍後再試。")
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.destination(.dismiss)) {
            $0.destination = nil
        }

        // Then
        #expect(store.state.destination == nil)
        #expect(store.state.presentationQueue == CampaignPresentationQueue())
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
        await store.send(.reminder(.delegate(.failed(failure)))) {
            $0.destination = Self.reminderFailureAlert(for: failure)
        }

        // Then
        #expect(store.state.destination == Self.reminderFailureAlert(for: failure))
        #expect(store.state.presentationQueue.pendingNotice == nil)
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
        initial.destination = .edit(editState)
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.reminder(.delegate(.failed(.creationFailed)))) {
            $0.presentationQueue.pendingNotice = Self.reminderFailureAlert(for: .creationFailed)
        }

        // Then
        let expectedNotice = Self.reminderFailureAlert(for: .creationFailed)
        #expect(store.state.destination == .edit(editState))
        #expect(store.state.presentationQueue.pendingNotice == expectedNotice)
    }

    /// 權限提示的「前往設定」以注入的相依開啟系統設定
    @Test
    func destination_點選開啟設定_開啟系統設定() async {
        // Given
        let hasOpenedSettings = LockIsolated(false)
        var initial = CampaignFeature.State()
        initial.destination = Self.accessDeniedAlert
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.openSettingsService.open = {
                hasOpenedSettings.setValue(true)
            }
        }

        // When
        // 純 `AlertState` 的 `.ifLet` 收到 `.presented` 動作會隱含自動清空該呈現
        await store.send(.destination(.presented(.alert(.openSettings)))) {
            $0.destination = nil
        }

        // Then
        await store.finish()
        #expect(hasOpenedSettings.value)
        #expect(store.state.destination == nil)
    }
}
