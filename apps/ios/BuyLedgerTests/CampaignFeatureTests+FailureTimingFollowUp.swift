//
//  CampaignFeatureTests+FailureTimingFollowUp.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 儲存成功但改名與提醒都失敗時，表單關好後只呈現最後一則 (提醒權限被拒)
    @Test
    func formSheetDismissed_儲存成功但改名與提醒都失敗_只呈現最後一則() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "舊團名",
            closeDate: nil,
            status: .ongoing
        )
        let timestamp = Date(timeIntervalSince1970: 1_776_675_600)
        var editState = CampaignEditFeature.State(
            original: campaign,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: true,
            reminderTimestamp: timestamp
        )
        editState.draft.name = "新團名"
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.$reminderLinks.withLock {
            $0 = [
                "C1": CampaignReminderLink(
                    eventIdentifier: "EVT-old",
                    reminderTimestamp: timestamp
                ),
            ]
        }
        initial.presentation.destination = .edit(editState)
        let expectedCampaign = Campaign(
            id: "C1",
            name: "新團名",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: Date(timeIntervalSince1970: 1_777_507_200),
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let renameFailureNotice: CampaignPresentationFeature.Destination.State = .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("操作失敗")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                TextState("開團已儲存，但歸屬訂單的開團名稱更新失敗，請稍後再試。")
            }
        )
        let accessDeniedNotice: CampaignPresentationFeature.Destination.State = .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("需要行事曆權限")
            } actions: {
                ButtonState(action: .openSettings) {
                    TextState("前往設定")
                }
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                TextState("請到「設定」開啟行事曆存取權限，才能新增或移除訂購提醒。")
            }
        )
        let failingRename: OrderService.RenameOrderCampaign = { _, _ in
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = { _ in
            }
            $0.orderService.renameOrderCampaign = failingRename
            $0.calendarReminderService.requestAccess = {
                .denied
            }
        }
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveButtonTapped))))))
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$campaigns.withLock {
                $0 = [expectedCampaign]
            }
        }
        await store.receive(\.presentation.delegate.saveRequested) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.success)
        await store.receive(\.writes.renameResponse)
        await store.receive(\.writes.delegate.failed)
        await store.receive(\.writes.delegate.saved)
        await store.receive(\.presentation.noticeRequested, renameFailureNotice) {
            $0.presentation.queue.pendingNotice = renameFailureNotice
        }
        await store.receive(\.reminder.reconcileRequested)
        await store.receive(\.reminder.createResponse)
        await store.receive(\.reminder.delegate.failed, .accessDenied)
        await store.receive(\.presentation.noticeRequested, accessDeniedNotice) {
            $0.presentation.queue.pendingNotice = accessDeniedNotice
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = accessDeniedNotice
        }

        // Then
        #expect(store.state.presentation.destination == accessDeniedNotice)
    }

    /// 詳情發起的狀態變更失敗在表單開啟中到達，表單取消並關好後才呈現
    ///
    /// - Throws: 詳情沒有推入堆疊時由 `try #require` 丟出
    @Test
    func formSheetDismissed_詳情狀態變更失敗在表單開啟中到達_表單關好後呈現() async throws {
        // Given
        let campaign = Campaign(
            id: "C1",
            name: "團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let expectedNotice: CampaignPresentationFeature.Destination.State = .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("操作失敗")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                TextState("開團狀態更新失敗，請稍後再試。")
            }
        )
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.showDetail(campaignID: "C1")
        let detailID = try #require(initial.path.ids.first)
        initial.presentation.destination = .edit(Self.makeEditState())
        let failingSave: CampaignService.SaveCampaign = { _ in
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.campaignService.saveCampaign = failingSave
        }
        await store.send(
            .path(.element(id: detailID, action: .detail(.view(.statusChanged(.closed)))))
        )
        await store.receive(\.path[id: detailID].detail.delegate.requested)
        await store.receive(\.writes.statusChangeRequested)
        await store.receive(\.writes.statusResponse.failure)
        await store.receive(\.writes.delegate.failed)
        await store.receive(\.presentation.noticeRequested, expectedNotice) {
            $0.presentation.queue.pendingNotice = expectedNotice
        }
        await store.send(.presentation(.destination(.presented(.edit(.view(.cancelButtonTapped))))))
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = expectedNotice
        }

        // Then
        #expect(store.state.presentation.destination == expectedNotice)
        #expect(store.state.campaigns == [campaign])
    }
}
