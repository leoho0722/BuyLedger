//
//  CampaignReminderFailureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/07/20.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

/// 行事曆提醒的失敗路徑分流
@MainActor
struct CampaignReminderFailureTests {

    // MARK: - Tests

    /// 驗證行事曆提醒失敗在此情境下的狀態與訊息
    @Test func accessNotGrantedRoutesToThePermissionPath() async {
        // Given

        let store = Self.makeStore {
            $0[CalendarReminderClient.self].requestAccess = { .denied }
        }

        // When

        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }
        // Then

        await store.receive(\.campaignSaved) {
            $0.campaigns = [Self.newCampaign]
        }
        await store.receive(\.reminderAccessDenied) {
            $0.noticeAlert = Self.accessDeniedAlert()
        }

        #expect(store.state.noticeAlert != nil)
        #expect(store.state.reminderLinks[Self.campaignID] == nil)
    }

    /// 驗證行事曆提醒失敗在此情境下的狀態與訊息
    @Test func restrictedAccessRoutesToItsOwnMessageWithoutASettingsButton() async {
        // Given

        // 裝置政策限制與使用者拒絕不同；前者無法由使用者自行開啟。
        // 訊息與按鈕都不得指向設定，故與 denied 情境走不同 action、不同文案
        let store = Self.makeStore {
            $0[CalendarReminderClient.self].requestAccess = { .restricted }
        }

        // When

        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }
        // Then

        await store.receive(\.campaignSaved) {
            $0.campaigns = [Self.newCampaign]
        }
        await store.receive(\.reminderAccessRestricted) {
            $0.noticeAlert = AlertState {
                TextState("無法使用行事曆")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                TextState("這台裝置的行事曆存取受政策限制，暫時無法新增或移除訂購提醒。")
            }
        }

        #expect(store.state.reminderLinks[Self.campaignID] == nil)
    }

    /// 驗證行事曆提醒失敗在此情境下的狀態與訊息
    @Test func eventSaveFailureRoutesToTheCreationFailurePath() async {
        // Given

        let store = Self.makeStore {
            $0[CalendarReminderClient.self].requestAccess = { .granted }
            $0[CalendarReminderClient.self].addReminder = {
                (_: String, _: Date, _: TimeInterval)
                    async throws(CalendarReminderError) -> String in
                throw CalendarReminderError.system(
                    underlying: TestDependencies.makeUnderlyingError(message: "boom")
                )
            }
        }

        // When

        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }
        // Then

        await store.receive(\.campaignSaved) {
            $0.campaigns = [Self.newCampaign]
        }
        await store.receive(\.reminderCreationFailed) {
            $0.noticeAlert = Self.creationFailedAlert()
        }

        #expect(store.state.noticeAlert != nil)
        #expect(store.state.reminderLinks[Self.campaignID] == nil)
    }

    /// 驗證行事曆提醒失敗在此情境下的狀態與訊息
    @Test func missingEventIdentifierRoutesToTheCreationFailurePath() async {
        // Given

        let store = Self.makeStore {
            $0[CalendarReminderClient.self].requestAccess = { .granted }
            $0[CalendarReminderClient.self].addReminder = {
                (_: String, _: Date, _: TimeInterval)
                    async throws(CalendarReminderError) -> String in
                throw CalendarReminderError.eventIdentifierMissing
            }
        }

        // When

        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }
        // Then

        await store.receive(\.campaignSaved) {
            $0.campaigns = [Self.newCampaign]
        }
        await store.receive(\.reminderCreationFailed) {
            $0.noticeAlert = Self.creationFailedAlert()
        }

        #expect(store.state.noticeAlert != nil)
        #expect(store.state.reminderLinks[Self.campaignID] == nil)
    }

    /// 驗證行事曆提醒失敗在此情境下的狀態與訊息
    @Test func missingWritableCalendarRoutesToItsOwnMessage() async {
        // Given

        // 權限已授予但沒有可寫入行事曆，應顯示專用訊息。
        let store = Self.makeStore {
            $0[CalendarReminderClient.self].requestAccess = { .granted }
            $0[CalendarReminderClient.self].addReminder = {
                (_: String, _: Date, _: TimeInterval)
                    async throws(CalendarReminderError) -> String in
                throw CalendarReminderError.noWritableCalendar
            }
        }

        // When

        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }
        // Then

        await store.receive(\.campaignSaved) {
            $0.campaigns = [Self.newCampaign]
        }
        await store.receive(\.reminderCalendarUnavailable) {
            $0.noticeAlert = AlertState {
                TextState("找不到可寫入的行事曆")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                TextState("找不到可寫入的行事曆，請新增或啟用一個可寫入的行事曆後再試。")
            }
        }

        #expect(store.state.reminderLinks[Self.campaignID] == nil)
    }

    /// 驗證行事曆提醒失敗在此情境下的狀態與訊息
    @Test func linkPersistenceFailureRoutesToTheCreationFailurePath() async {
        // Given

        let store = Self.makeStore {
            $0[CalendarReminderClient.self].requestAccess = { .granted }
            $0[CalendarReminderClient.self].addReminder = { _, _, _ in "EVT-new" }
            $0[CampaignReminderRepository.self].saveLink = {
                (_: String, _: CampaignReminderLink) async throws(PersistenceError) in
                throw PersistenceError.saveFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "boom")
                )
            }
        }

        // When

        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }
        // Then

        await store.receive(\.campaignSaved) {
            $0.campaigns = [Self.newCampaign]
        }
        await store.receive(\.reminderCreationFailed) {
            $0.noticeAlert = Self.creationFailedAlert()
        }

        #expect(store.state.noticeAlert != nil)
        // 事件建立成功但連結寫入失敗時不得留下部分寫入的連結
        #expect(store.state.reminderLinks[Self.campaignID] == nil)
    }

    /// 權限提示的「前往設定」以注入的相依開啟系統設定
    @Test func openSettingsButtonInvokesTheInjectedDependency() async {
        // Given

        let opened = LockIsolated(false)
        let store = Self.makeStore {
            $0[CalendarReminderClient.self].requestAccess = { .denied }
            $0[OpenSettingsClient.self].open = { opened.setValue(true) }
        }

        // When

        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }
        // Then

        await store.receive(\.campaignSaved) {
            $0.campaigns = [Self.newCampaign]
        }
        await store.receive(\.reminderAccessDenied) {
            $0.noticeAlert = Self.accessDeniedAlert()
        }
        // 純 AlertState 的 `.ifLet` 收到 `.presented` 動作會隱含自動清空該呈現
        await store.send(.noticeAlert(.presented(.openSettings))) {
            $0.noticeAlert = nil
        }
        await store.finish()

        #expect(opened.value)
    }

    /// 移除不存在的事件不應報錯
    @Test func removingAnAbsentEventRemainsANoOp() async {
        // Given：提醒連結指向已不存在的行事曆事件
        let removeCallCount = LockIsolated(0)
        let campaign = Campaign(
            id: Self.campaignID,
            name: "四月團",
            openDate: TestDependencies.fixedNow,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        var editState = CampaignEditFeature.State(
            original: campaign,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: false,
            reminderTimestamp: TestDependencies.fixedNow
        )
        editState.draft.name = campaign.name
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.reminderLinks[Self.campaignID] = CampaignReminderLink(
            eventIdentifier: "EVT-gone",
            reminderTimestamp: TestDependencies.fixedNow
        )
        initial.editCampaign = editState
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { _ in }
            $0[CalendarReminderClient.self].removeReminder = {
                (_: String) async throws(CalendarReminderError) in
                removeCallCount.withValue { $0 += 1 }
                throw CalendarReminderError.system(
                    underlying: TestDependencies.makeUnderlyingError(message: "boom")
                )
            }
            $0[CampaignReminderRepository.self].removeLink = { _ in }
        }

        // When
        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }
        await store.receive(\.campaignSaved)
        await store.receive(\.reminderStored) {
            $0.reminderLinks[Self.campaignID] = nil
        }
        await store.finish()

        // Then
        #expect(removeCallCount.value == 1)
        #expect(store.state.reminderLinks[Self.campaignID] == nil)
        #expect(store.state.noticeAlert == nil)
    }

    // MARK: - Rebuild Tests

    /// 驗證行事曆提醒失敗在此情境下的狀態與訊息
    @Test func rebuildKeepsTheOldEventWhenTheNewOneFailsToBeCreated() async {
        // Given

        // 建立新事件失敗時，保留舊連結且不移除舊事件。
        let removeCallCount = LockIsolated(0)
        let store = Self.makeRebuildStore {
            $0[CalendarReminderClient.self].requestAccess = { .granted }
            $0[CalendarReminderClient.self].addReminder = {
                (_: String, _: Date, _: TimeInterval)
                    async throws(CalendarReminderError) -> String in
                throw CalendarReminderError.system(
                    underlying: TestDependencies.makeUnderlyingError(message: "boom")
                )
            }
            $0[CalendarReminderClient.self].removeReminder = { _ in
                removeCallCount.withValue { $0 += 1 }
            }
        }

        // When

        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }
        // Then

        await store.receive(\.campaignSaved) {
            $0.campaigns = [Self.rebuildCampaign]
        }
        await store.receive(\.reminderCreationFailed) {
            $0.noticeAlert = AlertState {
                TextState("無法建立訂購提醒")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                TextState("訂購提醒建立失敗，請稍後再試。")
            }
        }

        #expect(removeCallCount.value == 0, "新事件建立失敗時不應呼叫移除舊事件")
        #expect(
            store.state.reminderLinks[Self.rebuildCampaignID] == CampaignReminderLink(
                eventIdentifier: Self.oldEventIdentifier,
                reminderTimestamp: Self.oldTimestamp
            ),
            "連結應仍指向舊事件，不能變成 nil 或指向不存在的新事件"
        )
    }

    /// 驗證行事曆提醒失敗在此情境下的狀態與訊息
    @Test func rebuildRemovesTheOldEventOnlyAfterTheNewOneIsCreated() async {
        // Given

        let removeCallCount = LockIsolated(0)
        let removedIdentifier = LockIsolated<String?>(nil)
        let store = Self.makeRebuildStore {
            $0[CalendarReminderClient.self].requestAccess = { .granted }
            $0[CalendarReminderClient.self].addReminder = { _, _, _ in "EVT-new" }
            $0[CampaignReminderRepository.self].saveLink = { _, _ in }
            $0[CalendarReminderClient.self].removeReminder = { identifier in
                removeCallCount.withValue { $0 += 1 }
                removedIdentifier.setValue(identifier)
            }
        }

        // When

        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }
        // Then

        await store.receive(\.campaignSaved) {
            $0.campaigns = [Self.rebuildCampaign]
        }
        await store.receive(\.reminderStored) {
            $0.reminderLinks[Self.rebuildCampaignID] = CampaignReminderLink(
                eventIdentifier: "EVT-new", reminderTimestamp: Self.newTimestamp)
        }

        #expect(removeCallCount.value == 1, "新事件建立成功後應移除舊事件，且只呼叫一次")
        #expect(removedIdentifier.value == Self.oldEventIdentifier, "移除的必須是舊事件識別碼")
    }

    /// 驗證行事曆提醒失敗在此情境下的狀態與訊息
    @Test func rebuildReportsFailureWhenTheOldEventCannotBeRemoved() async {
        // Given

        // 新事件建立後才移除舊事件；移除失敗要回報。
        // 移除失敗不回滾新連結，仍須顯示錯誤。
        // 依行事曆整合規則驗證提醒失敗
        let store = Self.makeRebuildStore {
            $0[CalendarReminderClient.self].requestAccess = { .granted }
            $0[CalendarReminderClient.self].addReminder = { _, _, _ in "EVT-new" }
            $0[CampaignReminderRepository.self].saveLink = { _, _ in }
            $0[CalendarReminderClient.self].removeReminder = {
                (_: String) async throws(CalendarReminderError) in
                throw CalendarReminderError.system(
                    underlying: TestDependencies.makeUnderlyingError(message: "boom")
                )
            }
        }
        // When

        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }
        // Then

        await store.receive(\.campaignSaved) {
            $0.campaigns = [Self.rebuildCampaign]
        }
        await store.receive(\.reminderStored) {
            $0.reminderLinks[Self.rebuildCampaignID] = CampaignReminderLink(
                eventIdentifier: "EVT-new",
                reminderTimestamp: Self.newTimestamp
            )
        }
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = AlertState {
                TextState("操作失敗")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                TextState("提醒已更新，但舊的行事曆事件移除失敗，請自行到行事曆刪除。")
            }
        }

        #expect(
            store.state.reminderLinks[Self.rebuildCampaignID] == CampaignReminderLink(
                eventIdentifier: "EVT-new",
                reminderTimestamp: Self.newTimestamp
            ),
            "連結應指向新建立的事件，不因舊事件移除失敗而回滾或變成 nil"
        )
    }
}

// MARK: - Private Method

private extension CampaignReminderFailureTests {

    /// 測試共用的開團識別值
    static let campaignID = "11111111-1111-1111-1111-111111111111"

    /// 重建情境測試共用的開團識別值 (既有開團，而非新開團)
    static let rebuildCampaignID = "C1"

    /// 重建情境測試共用的舊事件識別碼
    static let oldEventIdentifier = "EVT-old"

    /// 重建情境測試共用的舊提醒時間戳
    static let oldTimestamp = TestDependencies.fixedNow.addingTimeInterval(9 * 3600)

    /// 重建測試使用的新提醒時間
    static let newTimestamp = TestDependencies.fixedNow.addingTimeInterval(18 * 3600)

    /// 建立一個「儲存新開團並要求建立提醒」的 store
    ///
    /// - Parameter dependencies: 要注入的依賴修改
    /// - Returns: 已建立的 CampaignFeature 測試 store
    static func makeStore(
        _ dependencies: @escaping (inout DependencyValues) -> Void
    ) -> TestStoreOf<CampaignFeature> {
        let newID = UUID(uuidString: campaignID)!
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: true,
            reminderTimestamp: TestDependencies.fixedNow.addingTimeInterval(18 * 3600)
        )
        editState.draft.name = "新團"
        var initial = CampaignFeature.State()
        initial.editCampaign = editState

        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(newID)
            $0[CampaignRepository.self].saveCampaign = { _ in }
            dependencies(&$0)
        }
        return store
    }

    /// 建立含提醒連結與新時間的開團 store
    ///
    /// - Parameter dependencies: 要注入的依賴修改
    /// - Returns: 已建立的 CampaignFeature 測試 store
    static func makeRebuildStore(
        _ dependencies: @escaping (inout DependencyValues) -> Void
    ) -> TestStoreOf<CampaignFeature> {
        let campaign = Campaign(
            id: rebuildCampaignID,
            name: "四月團",
            openDate: TestDependencies.fixedNow,
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        var editState = CampaignEditFeature.State(
            original: campaign,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: true,
            reminderTimestamp: newTimestamp
        )
        editState.draft.name = campaign.name
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.reminderLinks = [
            rebuildCampaignID: CampaignReminderLink(
                eventIdentifier: oldEventIdentifier,
                reminderTimestamp: oldTimestamp
            )
        ]
        initial.editCampaign = editState

        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { _ in }
            dependencies(&$0)
        }
        return store
    }

    /// ``makeStore(_:)`` 儲存後預期的開團值
    static var newCampaign: Campaign {
        Campaign(
            id: campaignID,
            name: "新團",
            openDate: TestDependencies.fixedNow,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
    }

    /// 儲存後預期的開團值
    static var rebuildCampaign: Campaign {
        Campaign(
            id: rebuildCampaignID,
            name: "四月團",
            openDate: TestDependencies.fixedNow,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
    }

    /// 權限被拒時的 alert
    ///
    /// - Returns: 行事曆存取被拒時顯示的 alert
    static func accessDeniedAlert() -> AlertState<CampaignFeature.Action.NoticeAlert> {
        AlertState {
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
    }

    /// 建立失敗時的 alert
    ///
    /// - Returns: 訂購提醒建立失敗時使用的 alert
    static func creationFailedAlert() -> AlertState<CampaignFeature.Action.NoticeAlert> {
        AlertState {
            TextState("無法建立訂購提醒")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("知道了")
            }
        } message: {
            TextState("訂購提醒建立失敗，請稍後再試。")
        }
    }
}
