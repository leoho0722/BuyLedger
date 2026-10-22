//
//  CampaignFeatureTests+FailureTimingFollowUp.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 開團改名存檔失敗在表單關閉中到達，表單關好後呈現存檔失敗提示
    ///
    /// - Note: 對應規格範例「rename with a failing save」
    /// - Note: 提示文案 `campaigns.general.message.campaignSavedTry` 的正體中文為「開團儲存失敗，請稍後再試。」
    @Test
    func formSheetDismissed_存檔失敗在表單關閉中到達_關好後呈現存檔失敗提示() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "三月日本團",
            closeDate: nil,
            status: .ongoing
        )
        let timestamp = Date(timeIntervalSince1970: 1_776_675_600)
        var editState = CampaignEditFeature.State(
            original: campaign,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            isReminderWanted: false,
            reminderTimestamp: timestamp
        )
        editState.draft.name = "三月日本團 (補)"
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.presentation.destination = .edit(editState)
        let saveFailureNotice: CampaignPresentationFeature.Destination.State = .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("orders.list.label.operationFailed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState("campaigns.general.message.campaignSavedTry")
            }
        )
        let failingRename: CampaignService.RenameCampaign = { _, _ throws(PersistenceError) in
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.renameCampaign = failingRename
        }
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveButtonTapped))))))
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested)
        await store.receive(\.presentation.delegate.saveRequested) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.failure)
        await store.receive(\.writes.delegate.failed)
        await store.receive(\.presentation.noticeRequested, saveFailureNotice) {
            $0.presentation.queue.pendingNotice = saveFailureNotice
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = saveFailureNotice
        }

        // Then
        #expect(store.state.presentation.destination == saveFailureNotice)
        #expect(store.state.campaigns == [campaign])
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
                TextState("orders.list.label.operationFailed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState("campaigns.general.message.campaignStatusUpdated")
            }
        )
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.showDetail(campaignID: "C1")
        let detailID = try #require(initial.path.ids.first)
        initial.presentation.destination = .edit(Self.makeEditState())
        let failingSave: CampaignService.SaveCampaign = { _ throws(PersistenceError) in
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
