//
//  CampaignFeaturePresentationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `CampaignFeature` 的單元測試，涵蓋表單關閉、捨棄確認與提醒失敗時通知的呈現時機與文案
@MainActor
struct CampaignFeaturePresentationTests {

    /// 驗證取消沒有變更的表單後，`destination` 清空並標記 `isFormClosing`，原先暫存的開團狀態自動更新失敗提示保留而不顯示
    @Test
    func presentation_取消無變更的表單_進入關閉中且暫存通知不提前呈現() async {
        // Given
        let pendingNotice = CampaignFeatureTestSupport.failureAlert(
            "campaigns.general.message.automaticallyUpdatingCampaign"
        )
        var initial = CampaignFeature.State()
        initial.presentation.destination = .edit(CampaignFeatureTestSupport.makeEditState())
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

    /// 驗證確認捨棄未儲存的變更時，表單進入關閉中，暫存的通知保留、不提前呈現
    @Test
    func presentation_確認捨棄變更_進入關閉中且暫存通知不提前呈現() async {
        // Given
        var editState = CampaignFeatureTestSupport.makeEditState()
        editState.draft.name = "團"
        editState.discardConfirmation = CampaignFeatureTestSupport.discardAlert
        let pendingNotice = CampaignFeatureTestSupport.failureAlert(
            "campaigns.general.message.campaignSettledTry"
        )
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

    /// 驗證捨棄確認選繼續編輯時，表單維持開啟、不進入關閉中，暫存的通知保留
    @Test
    func presentation_選繼續編輯_表單維持開啟且暫存通知保留() async {
        // Given
        var editState = CampaignFeatureTestSupport.makeEditState()
        editState.draft.name = "團"
        editState.discardConfirmation = CampaignFeatureTestSupport.discardAlert
        let pendingNotice = CampaignFeatureTestSupport.failureAlert(
            "campaigns.general.message.campaignSettledTry"
        )
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

    /// 驗證關閉已顯示的通知後，目的地清空，且不進入表單關閉中、暫存通知也為空
    @Test
    func presentation_提示關閉後_目的地為空() async {
        // Given
        var initial = CampaignFeature.State()
        initial.presentation.destination = CampaignFeatureTestSupport.failureAlert(
            "campaigns.general.message.campaignDeletedTry"
        )
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.presentation(.destination(.dismiss))) {
            $0.presentation.destination = nil
        }

        // Then
        #expect(store.state.presentation.destination == nil)
        #expect(store.state.presentation.queue.isFormClosing == false)
        #expect(store.state.presentation.queue.pendingNotice == nil)
    }

    /// 驗證提醒流程在沒有表單開啟時回報失敗，直接呈現對應標題、訊息與按鈕的通知
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

    /// 驗證表單開啟中收到提醒失敗時，通知暫存、表單維持開啟，不取代使用者正在編輯的表單
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

    /// 驗證點選權限提示的「前往設定」時，以注入的 `openSettingsService` 開啟系統設定，並關閉提示
    ///
    /// - Note: 純 `AlertState` 的 `.ifLet` 收到 `.presented` 動作會隱含自動清空該呈現
    @Test
    func presentation_點選開啟設定_開啟系統設定() async {
        // Given
        let hasOpenedSettings = LockIsolated(false)
        var initial = CampaignFeature.State()
        initial.presentation.destination = CampaignFeatureTestSupport.accessDeniedAlert
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

// MARK: - Private Method

private extension CampaignFeaturePresentationTests {

    /// 依失敗種類組出預期的通知，文案鍵以字面值寫出，不取自被測程式
    ///
    /// - Parameter failure: 提醒流程的失敗種類
    /// - Returns: 對應文案的通知狀態
    static func reminderFailureAlert(
        for failure: CampaignReminderFeature.Failure
    ) -> CampaignPresentationFeature.Destination.State {
        switch failure {
        case .accessDenied:
            return CampaignFeatureTestSupport.accessDeniedAlert

        case .accessRestricted:
            return CampaignFeatureTestSupport.titledAlert(
                "campaigns.general.label.calendarUnavailable",
                message: "campaigns.general.message.calendarAccessRestricted"
            )

        case .creationFailed:
            return CampaignFeatureTestSupport.titledAlert(
                "campaigns.general.label.unableCreateReminder",
                message: "campaigns.general.message.reminderCreatedPlease"
            )

        case .calendarUnavailable:
            return CampaignFeatureTestSupport.titledAlert(
                "campaigns.reminder.label.writableCalendarFound",
                message: "campaigns.general.message.writableCalendarFound"
            )

        case .linkRemovalFailed:
            return CampaignFeatureTestSupport.failureAlert(
                "campaigns.general.message.removingReminderLink"
            )

        case .oldEventRemovalFailed:
            return CampaignFeatureTestSupport.failureAlert(
                "campaigns.general.message.reminderUpdatedBut"
            )

        case .eventRemovalAfterDeleteFailed:
            return CampaignFeatureTestSupport.failureAlert(
                "campaigns.general.message.campaignDeletedBut"
            )
        }
    }
}
