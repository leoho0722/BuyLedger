//
//  CampaignFeatureTests+FailureTiming.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 儲存新開團失敗時表單先關閉，失敗提示等表單關好才出現，清單沒有該開團
    ///
    /// - Note: 規格範例：寫入失敗時，新增表單內容為「失敗開團」，按下儲存
    @Test
    func formSheetDismissed_儲存失敗後表單關好_呈現失敗提示() async {
        // Given
        var editState = Self.makeEditState()
        editState.draft.name = "失敗開團"
        var initial = CampaignFeature.State()
        initial.destination = .edit(editState)
        let savedCampaignNames = LockIsolated<[String]>([])
        let failingSave: CampaignService.SaveCampaign = { campaign in
            savedCampaignNames.withValue {
                $0.append(campaign.name)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(1))
            $0.campaignService.saveCampaign = failingSave
        }
        await store.send(.destination(.presented(.edit(.view(.saveButtonTapped)))))
        await store.receive(\.destination.presented.edit.delegate.saveRequested) {
            $0.destination = nil
            $0.presentationQueue.isFormClosing = true
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.failure)
        await store.receive(\.writes.delegate.failed) {
            $0.presentationQueue.pendingNotice = Self.failureAlert("開團儲存失敗，請稍後再試。")
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentationQueue.isFormClosing = false
            $0.presentationQueue.pendingNotice = nil
            $0.destination = Self.failureAlert("開團儲存失敗，請稍後再試。")
        }

        // Then
        #expect(store.state.destination == Self.failureAlert("開團儲存失敗，請稍後再試。"))
        #expect(store.state.campaigns.isEmpty)
        #expect(savedCampaignNames.value == ["失敗開團"])
    }

    /// 新增表單開啟中結單日自動轉狀態失敗，使用者取消表單後才出現失敗提示
    ///
    /// - Note: 規格範例：新增表單開啟中自動轉狀態失敗，之後對沒有變更的表單按取消
    @Test
    func formSheetDismissed_表單開啟中自動轉狀態失敗後取消_表單關好才呈現通知() async {
        // Given
        let overdue = Campaign.fixture(
            id: "C1",
            name: "過期團",
            closeDate: Date(timeIntervalSince1970: 1_777_539_600),
            status: .ongoing
        )
        var closed = overdue
        closed.status = .closed
        var initial = CampaignFeature.State()
        initial.destination = .edit(Self.makeEditState())
        let failingSave: CampaignService.SaveCampaign = { _ in
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(Date(timeIntervalSince1970: 1_777_597_200))
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = failingSave
        }
        await store.send(.list(.campaignsResponse(.success([overdue])))) {
            $0.list.hasLoaded = true
            $0.$campaigns.withLock {
                $0 = [closed]
            }
        }
        await store.receive(\.list.autoCloseResponse)
        await store.receive(\.list.delegate.autoCloseFailed) {
            $0.presentationQueue.pendingNotice = Self.failureAlert("開團狀態自動更新失敗，請稍後再試。")
        }
        await store.send(.destination(.presented(.edit(.view(.cancelButtonTapped)))))
        await store.receive(\.destination.dismiss) {
            $0.destination = nil
            $0.presentationQueue.isFormClosing = true
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentationQueue.isFormClosing = false
            $0.presentationQueue.pendingNotice = nil
            $0.destination = Self.failureAlert("開團狀態自動更新失敗，請稍後再試。")
        }

        // Then
        #expect(store.state.destination == Self.failureAlert("開團狀態自動更新失敗，請稍後再試。"))
        #expect(store.state.presentationQueue == CampaignPresentationQueue())
    }

    /// 表單關閉中連續到達兩則失敗，表單關好後只呈現後一則
    @Test
    func formSheetDismissed_關閉中連續兩則失敗_只呈現後一則() async {
        // Given
        var initial = CampaignFeature.State()
        initial.presentationQueue.isFormClosing = true
        initial.presentationQueue.pendingNotice = Self.failureAlert("開團儲存失敗，請稍後再試。")
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }
        await store.send(.writes(.delegate(.failed(.settle)))) {
            $0.presentationQueue.pendingNotice = Self.failureAlert("結團失敗，請稍後再試。")
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentationQueue.isFormClosing = false
            $0.presentationQueue.pendingNotice = nil
            $0.destination = Self.failureAlert("結團失敗，請稍後再試。")
        }

        // Then
        #expect(store.state.destination == Self.failureAlert("結團失敗，請稍後再試。"))
        #expect(store.state.presentationQueue.pendingNotice == nil)
    }

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
        initial.destination = .edit(editState)
        let expectedCampaign = Campaign(
            id: "C1",
            name: "新團名",
            openDate: campaign.openDate,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let renameFailureNotice = Self.failureAlert("開團已儲存，但歸屬訂單的開團名稱更新失敗，請稍後再試。")
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
        await store.send(.destination(.presented(.edit(.view(.saveButtonTapped)))))
        await store.receive(\.destination.presented.edit.delegate.saveRequested) {
            $0.destination = nil
            $0.presentationQueue.isFormClosing = true
            $0.$campaigns.withLock {
                $0 = [expectedCampaign]
            }
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.success)
        await store.receive(\.writes.renameResponse)
        await store.receive(\.writes.delegate.failed) {
            $0.presentationQueue.pendingNotice = renameFailureNotice
        }
        await store.receive(\.writes.delegate.saved)
        await store.receive(\.reminder.reconcileRequested)
        await store.receive(\.reminder.createResponse)
        await store.receive(\.reminder.delegate.failed, .accessDenied) {
            $0.presentationQueue.pendingNotice = Self.accessDeniedAlert
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentationQueue.isFormClosing = false
            $0.presentationQueue.pendingNotice = nil
            $0.destination = Self.accessDeniedAlert
        }

        // Then
        #expect(store.state.destination == Self.accessDeniedAlert)
    }

    /// 詳情發起的狀態變更失敗在表單開啟中到達，表單取消並關好後才呈現
    ///
    /// - Throws: 詳情沒有推入堆疊時由 `try #require` 丟出
    @Test
    func formSheetDismissed_詳情狀態變更失敗在表單開啟中到達_表單關好後呈現() async throws(any Error) {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .ongoing
        )
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.showDetail(campaignID: "C1")
        let detailID = try #require(initial.path.ids.first)
        initial.destination = .edit(Self.makeEditState())
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
        await store.receive(\.writes.delegate.failed) {
            $0.presentationQueue.pendingNotice = Self.failureAlert("開團狀態更新失敗，請稍後再試。")
        }
        await store.send(.destination(.presented(.edit(.view(.cancelButtonTapped)))))
        await store.receive(\.destination.dismiss) {
            $0.destination = nil
            $0.presentationQueue.isFormClosing = true
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentationQueue.isFormClosing = false
            $0.presentationQueue.pendingNotice = nil
            $0.destination = Self.failureAlert("開團狀態更新失敗，請稍後再試。")
        }

        // Then
        #expect(store.state.destination == Self.failureAlert("開團狀態更新失敗，請稍後再試。"))
        #expect(store.state.campaigns == [campaign])
    }
}
