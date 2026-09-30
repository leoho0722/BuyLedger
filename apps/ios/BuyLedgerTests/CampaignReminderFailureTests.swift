//
//  CampaignReminderFailureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/20.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 行事曆提醒的失敗路徑分流
@MainActor
struct CampaignReminderFailureTests {

    // MARK: - Properties

    /// 測試共用的開團識別值
    private static let campaignID = "11111111-1111-1111-1111-111111111111"

    /// 新開團情境使用的 UUID 字面值
    private static let newCampaignUUID = UUID(
        uuid: (
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11,
            0x11
        )
    )

    /// 重建情境測試共用的開團識別值 (既有開團，而非新開團)
    private static let rebuildCampaignID = "C1"

    /// 重建情境測試共用的舊事件識別碼
    private static let oldEventIdentifier = "EVT-old"

    /// 重建情境測試共用的舊提醒時間戳
    private static let oldTimestamp = TestDependencies.fixedNow.addingTimeInterval(9 * 3600)

    /// 新開團與重建情境共用的新提醒時間
    private static let newTimestamp = TestDependencies.fixedNow.addingTimeInterval(18 * 3600)

    // MARK: - Tests

    /// 行事曆權限遭拒時保存開團並提供前往系統設定的提示
    @Test
    func editCampaign_行事曆權限未授予_顯示前往設定提示() async {
        // Given
        let store = Self.makeStore {
            $0.calendarReminderService.requestAccess = {
                .denied
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
        await store.receive(\.reminderAccessDenied) {
            $0.noticeAlert = Self.accessDeniedAlert
        }
        #expect(store.state.reminderLinks[Self.campaignID] == nil)
    }

    /// 裝置政策限制行事曆時顯示專屬說明且不提供設定按鈕
    @Test
    func editCampaign_權限受限制_顯示專屬說明且不提供設定按鈕() async {
        // Given
        // 裝置政策限制無法由使用者自行開啟，提示不提供設定按鈕
        let store = Self.makeStore {
            $0.calendarReminderService.requestAccess = {
                .restricted
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

    /// 行事曆事件建立失敗時保存開團並呈現建立失敗提示
    @Test
    func editCampaign_儲存行事曆事件失敗_回報建立失敗() async {
        // Given
        let failingAddReminder: CalendarReminderService.AddReminder = { _, _, _ in
            throw .system(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = Self.makeStore {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = failingAddReminder
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
            $0.noticeAlert = Self.creationFailedAlert
        }
        #expect(store.state.reminderLinks[Self.campaignID] == nil)
    }

    /// 行事曆存檔後沒有給事件識別碼就無法記錄連結，視同建立失敗；開團仍保存
    @Test
    func editCampaign_建立事件未提供識別碼_回報建立失敗() async {
        // Given
        let failingAddReminder: CalendarReminderService.AddReminder = { _, _, _ in
            throw .eventIdentifierMissing
        }
        let store = Self.makeStore {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = failingAddReminder
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
            $0.noticeAlert = Self.creationFailedAlert
        }
        #expect(store.state.reminderLinks[Self.campaignID] == nil)
    }

    /// 沒有可寫入行事曆時呈現專屬提示且不建立連結
    @Test
    func editCampaign_沒有可寫入行事曆_顯示專屬說明() async {
        // Given
        let failingAddReminder: CalendarReminderService.AddReminder = { _, _, _ in
            throw .noWritableCalendar
        }
        let store = Self.makeStore {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = failingAddReminder
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

    /// 提醒連結持久化失敗時保留開團且不留下部分連結
    @Test
    func editCampaign_保存提醒連結失敗_回報建立失敗() async {
        // Given
        let expectedLink = CampaignReminderLink(
            eventIdentifier: "EVT-new",
            reminderTimestamp: Self.newTimestamp
        )
        let savedCampaignIDs = LockIsolated<[String]>([])
        let savedLinks = LockIsolated<[CampaignReminderLink]>([])
        let failingSaveLink: CampaignReminderService.SaveLink = { campaignID, link in
            savedCampaignIDs.withValue {
                $0.append(campaignID)
            }
            savedLinks.withValue {
                $0.append(link)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = Self.makeStore {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = { _, _, _ in
                "EVT-new"
            }
            $0.campaignReminderService.saveLink = failingSaveLink
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
            $0.noticeAlert = Self.creationFailedAlert
        }
        // 事件建立成功但連結寫入失敗時不得留下部分寫入的連結
        #expect(store.state.reminderLinks[Self.campaignID] == nil)
        #expect(savedCampaignIDs.value == [Self.campaignID])
        #expect(savedLinks.value == [expectedLink])
    }

    /// 權限提示的「前往設定」以注入的相依開啟系統設定
    @Test
    func noticeAlert_點選開啟設定_開啟系統設定() async {
        // Given
        let hasOpenedSettings = LockIsolated(false)
        var initial = CampaignFeature.State()
        initial.noticeAlert = Self.accessDeniedAlert
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.openSettingsService.open = {
                hasOpenedSettings.setValue(true)
            }
        }

        // When
        // 純 AlertState 的 `.ifLet` 收到 `.presented` 動作會隱含自動清空該呈現
        await store.send(.noticeAlert(.presented(.openSettings))) {
            $0.noticeAlert = nil
        }

        // Then
        await store.finish()
        #expect(hasOpenedSettings.value)
    }

    /// 使用者關掉提醒時，行事曆事件可能已被手動刪除而移除失敗；仍清除本機連結，也不跳錯誤打擾使用者
    @Test
    func editCampaign_關閉提醒且移除事件失敗_不顯示錯誤並清除連結() async {
        // Given
        let removedIdentifiers = LockIsolated<[String]>([])
        let removedCampaignIDs = LockIsolated<[String]>([])
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
        let failingRemoveReminder: CalendarReminderService.RemoveReminder = { identifier in
            removedIdentifiers.withValue {
                $0.append(identifier)
            }
            throw .system(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = { _ in
            }
            $0.calendarReminderService.removeReminder = failingRemoveReminder
            $0.campaignReminderService.removeLink = { campaignID in
                removedCampaignIDs.withValue {
                    $0.append(campaignID)
                }
            }
        }

        // When
        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }

        // Then
        await store.receive(\.campaignSaved)
        await store.receive(\.reminderStored) {
            $0.reminderLinks[Self.campaignID] = nil
        }
        await store.finish()
        #expect(removedIdentifiers.value == ["EVT-gone"])
        #expect(removedCampaignIDs.value == [Self.campaignID])
        #expect(store.state.reminderLinks[Self.campaignID] == nil)
        #expect(store.state.noticeAlert == nil)
    }

    /// 重建提醒的新事件建立失敗時保留舊連結
    ///
    /// - Note: `testValue` 的 `calendarReminderService.removeReminder` 是 `unimplemented`；
    ///   新事件建立失敗後誤刪舊事件會使測試失敗
    @Test
    func editCampaign_重建新事件失敗_保留舊事件() async {
        // Given
        let failingAddReminder: CalendarReminderService.AddReminder = { _, _, _ in
            throw .system(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = Self.makeRebuildStore {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = failingAddReminder
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
            $0.noticeAlert = Self.creationFailedAlert
        }
        #expect(
            store.state.reminderLinks[Self.rebuildCampaignID] == CampaignReminderLink(
                eventIdentifier: Self.oldEventIdentifier,
                reminderTimestamp: Self.oldTimestamp
            ),
            "連結應仍指向舊事件，不能變成 nil 或指向不存在的新事件"
        )
    }

    /// 新事件與提醒連結保存完成後才移除舊事件
    @Test
    func editCampaign_建立新事件成功_之後才移除舊事件() async {
        // Given
        let expectedLink = CampaignReminderLink(
            eventIdentifier: "EVT-new",
            reminderTimestamp: Self.newTimestamp
        )
        let operations = LockIsolated<[String]>([])
        let savedCampaignIDs = LockIsolated<[String]>([])
        let savedLinks = LockIsolated<[CampaignReminderLink]>([])
        let store = Self.makeRebuildStore {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = { _, _, _ in
                operations.withValue {
                    $0.append("add")
                }
                return "EVT-new"
            }
            $0.campaignReminderService.saveLink = { campaignID, link in
                operations.withValue {
                    $0.append("saveLink")
                }
                savedCampaignIDs.withValue {
                    $0.append(campaignID)
                }
                savedLinks.withValue {
                    $0.append(link)
                }
            }
            $0.calendarReminderService.removeReminder = { identifier in
                operations.withValue {
                    $0.append("remove:\(identifier)")
                }
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
            $0.reminderLinks[Self.rebuildCampaignID] = expectedLink
        }
        await store.finish()
        #expect(operations.value == ["add", "saveLink", "remove:\(Self.oldEventIdentifier)"])
        #expect(savedCampaignIDs.value == [Self.rebuildCampaignID])
        #expect(savedLinks.value == [expectedLink])
    }

    /// 移除舊事件失敗時保留新連結，並提示使用者自行到行事曆刪除舊事件
    @Test
    func editCampaign_移除舊事件失敗_回報舊事件移除失敗() async {
        // Given
        let expectedLink = CampaignReminderLink(
            eventIdentifier: "EVT-new",
            reminderTimestamp: Self.newTimestamp
        )
        let operations = LockIsolated<[String]>([])
        let savedCampaignIDs = LockIsolated<[String]>([])
        let savedLinks = LockIsolated<[CampaignReminderLink]>([])
        let failingRemoveReminder: CalendarReminderService.RemoveReminder = { identifier in
            operations.withValue {
                $0.append("remove:\(identifier)")
            }
            throw .system(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = Self.makeRebuildStore {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = { _, _, _ in
                operations.withValue {
                    $0.append("add")
                }
                return "EVT-new"
            }
            $0.campaignReminderService.saveLink = { campaignID, link in
                operations.withValue {
                    $0.append("saveLink")
                }
                savedCampaignIDs.withValue {
                    $0.append(campaignID)
                }
                savedLinks.withValue {
                    $0.append(link)
                }
            }
            $0.calendarReminderService.removeReminder = failingRemoveReminder
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
            $0.reminderLinks[Self.rebuildCampaignID] = expectedLink
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
            store.state.reminderLinks[Self.rebuildCampaignID] == expectedLink,
            "連結應指向新建立的事件，不因舊事件移除失敗而回滾或變成 nil"
        )
        #expect(operations.value == ["add", "saveLink", "remove:\(Self.oldEventIdentifier)"])
        #expect(savedCampaignIDs.value == [Self.rebuildCampaignID])
        #expect(savedLinks.value == [expectedLink])
    }
}

// MARK: - Private Method

private extension CampaignReminderFailureTests {

    /// 新開團成功儲存後的預期內容
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

    /// ``makeRebuildStore(_:)`` 儲存後預期的開團值
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

    /// 使用者拒絕行事曆權限時可前往系統設定的提示
    static var accessDeniedAlert: AlertState<CampaignFeature.Action.NoticeAlert> {
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

    /// 建立行事曆提醒失敗時顯示的提示
    static var creationFailedAlert: AlertState<CampaignFeature.Action.NoticeAlert> {
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

    /// 建立新開團並要求建立提醒的測試 store
    ///
    /// - Parameter dependencies: 要覆寫的測試依賴
    /// - Returns: 已使用固定日期與識別值的 `CampaignFeature` 測試 store
    static func makeStore(
        _ dependencies: @escaping (inout DependencyValues) -> Void
    ) -> TestStoreOf<CampaignFeature> {
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: true,
            reminderTimestamp: Self.newTimestamp
        )
        editState.draft.name = "新團"
        var initial = CampaignFeature.State()
        initial.editCampaign = editState

        return TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(newCampaignUUID)
            $0.campaignService.saveCampaign = { _ in
            }
            dependencies(&$0)
        }
    }

    /// 建立含舊提醒連結與新提醒時間的開團測試 store
    ///
    /// - Parameter dependencies: 要覆寫的測試依賴
    /// - Returns: 已載入舊開團與提醒連結的 `CampaignFeature` 測試 store
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
            ),
        ]
        initial.editCampaign = editState

        return TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = { _ in
            }
            dependencies(&$0)
        }
    }
}
