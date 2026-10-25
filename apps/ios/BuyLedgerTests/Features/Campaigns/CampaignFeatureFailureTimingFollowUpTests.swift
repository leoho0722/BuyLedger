//
//  CampaignFeatureFailureTimingFollowUpTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignFeature` 的單元測試，涵蓋寫入失敗在表單開啟或關閉中到達時的提示時機
@MainActor
struct CampaignFeatureFailureTimingFollowUpTests {

    /// 驗證改名存檔失敗時，表單先關閉，存檔失敗提示先暫存、不立即呈現，開團維持原名
    ///
    /// - Note: 對應規格範例「rename with a failing save」
    @Test
    func presentation_改名存檔失敗_表單先關閉並暫存存檔失敗提示() async {
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

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveButtonTapped))))))

        // Then
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
        #expect(store.state.presentation.destination == nil)
        #expect(store.state.campaigns == [campaign])
    }

    /// 驗證表單正在關閉、存檔失敗提示已暫存時，表單關好後才呈現該提示，並清除暫存
    ///
    /// - Note: 對應規格範例「rename with a failing save」
    /// - Note: 提示文案 `campaigns.general.message.campaignSavedTry` 的正體中文為「開團儲存失敗，請稍後再試。」
    @Test
    func formSheetDismissed_存檔失敗在表單關閉中到達_關好後呈現存檔失敗提示() async {
        // Given
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
        var initial = CampaignFeature.State()
        initial.presentation.queue.isFormClosing = true
        initial.presentation.queue.pendingNotice = saveFailureNotice
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = saveFailureNotice
        }

        // Then
        #expect(store.state.presentation.destination == saveFailureNotice)
    }

    /// 驗證表單開啟中，詳情頁變更開團狀態失敗時，失敗提示暫存、表單維持開啟，開團狀態不變
    ///
    /// - Throws: 詳情沒有推入堆疊時由 `try #require` 丟出
    @Test
    func path_表單開啟中詳情狀態變更失敗_暫存通知且表單維持開啟() async throws {
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
        let editState = CampaignFeatureTestSupport.makeEditState()
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.showDetail(campaignID: "C1")
        let detailID = try #require(initial.path.ids.first)
        initial.presentation.destination = .edit(editState)
        let failingSave: CampaignService.SaveCampaign = { _ throws(PersistenceError) in
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.campaignService.saveCampaign = failingSave
        }

        // When
        await store.send(
            .path(.element(id: detailID, action: .detail(.view(.statusChanged(.closed)))))
        )

        // Then
        await store.receive(\.path[id: detailID].detail.delegate.requested)
        await store.receive(\.writes.statusChangeRequested)
        await store.receive(\.writes.statusResponse.failure)
        await store.receive(\.writes.delegate.failed)
        await store.receive(\.presentation.noticeRequested, expectedNotice) {
            $0.presentation.queue.pendingNotice = expectedNotice
        }
        #expect(store.state.presentation.destination == .edit(editState))
        #expect(store.state.campaigns == [campaign])
    }

    /// 驗證表單正在關閉、狀態變更失敗的提示已暫存時，表單關好後才呈現該提示，並清除暫存
    @Test
    func formSheetDismissed_關閉中已暫存詳情狀態失敗提示_表單關好後呈現() async {
        // Given
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
        initial.presentation.queue.isFormClosing = true
        initial.presentation.queue.pendingNotice = expectedNotice
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = expectedNotice
        }

        // Then
        #expect(store.state.presentation.destination == expectedNotice)
    }
}
