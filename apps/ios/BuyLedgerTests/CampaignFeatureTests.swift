//
//  CampaignFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct CampaignFeatureTests {

    // MARK: - Tests

    @Test func taskLoadsCampaignsWithoutTransitionWhenNoCloseDate() async {
        let campaign = makeCampaign(id: "C1", name: "團", status: .ongoing, closeDate: nil)
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].fetchCampaigns = { [campaign] }
        }

        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.campaignsLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.campaigns = [campaign]
        }

        await store.receive(\.reminderLinksLoaded)
    }

    @Test func loadingAutoTransitionsOngoingPastCloseDateToClosed() async {
        // fixedNow = 2026-04-30。closeDate 4/20 已過 → 轉 closed；closeDate 5/10 未到 → 維持 ongoing
        let pastDue = makeCampaign(id: "past", name: "過期團", status: .ongoing, closeDate: day(month: 4, day: 20))
        let future = makeCampaign(id: "future", name: "未到團", status: .ongoing, closeDate: day(month: 5, day: 10))

        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].fetchCampaigns = { [pastDue, future] }
            $0[CampaignRepository.self].saveCampaign = { _ in }
        }

        var transitioned = pastDue
        transitioned.status = .closed

        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.campaignsLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.campaigns = [transitioned, future]
        }

        await store.receive(\.reminderLinksLoaded)
    }

    @Test func statusChangedUpdatesCampaign() async {
        let campaign = makeCampaign(id: "C1", name: "團", status: .ongoing, closeDate: nil)
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]

        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { _ in }
        }

        await store.send(.statusChanged("C1", .closed)) {
            $0.campaigns[0].status = .closed
        }
    }

    @Test func settleTappedRecordsSettledDateWithoutChangingStatus() async {
        let campaign = makeCampaign(id: "C1", name: "團", status: .closed, closeDate: nil)
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]

        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { _ in }
        }

        store.exhaustivity = .off

        // 結團是不可逆轉換，先確認、確認後才寫入結算日期
        await store.send(.settleTapped("C1"))
        #expect(store.state.settleConfirmation != nil)
        #expect(store.state.campaigns[0].settledDate == nil, "確認前不應寫入結算日期")

        await store.send(.settleConfirmation(.presented(.confirmSettle("C1"))))
        await store.receive(\.settleConfirmed)

        #expect(store.state.campaigns[0].settledDate == TestDependencies.fixedNow)
        #expect(store.state.campaigns[0].status == .closed, "結團不應改變狀態")
    }

    @Test func deleteConfirmationRemovesCampaign() async {
        let campaign = makeCampaign(id: "C1", name: "團", status: .ongoing, closeDate: nil)
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]

        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].removeCampaign = { _ in }
        }
        store.exhaustivity = .off

        await store.send(.deleteCampaignTapped("C1"))
        #expect(store.state.deletionConfirmation != nil)

        await store.send(.deletionConfirmation(.presented(.confirmDelete("C1"))))
        #expect(store.state.campaigns.isEmpty)
    }

    @Test func unpaidOnlyToggledUpdatesState() async {
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        }

        await store.send(.unpaidOnlyToggled(true)) {
            $0.showsUnpaidOnly = true
        }

        await store.send(.unpaidOnlyToggled(false)) {
            $0.showsUnpaidOnly = false
        }
    }

    @Test func newCampaignTappedPresentsEmptyEditForm() async {
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
        }
        // 以非窮舉模式驗證表單已呈現且為新開團 (不逐欄比對整個 CampaignEditFeature.State)
        store.exhaustivity = .off

        await store.send(.newCampaignTapped)
        #expect(store.state.editCampaign != nil)
        #expect(store.state.editCampaign?.original == nil)
        #expect(store.state.editCampaign?.draftStatus == .ongoing)
    }

    // MARK: - Reminder Tests

    @Test func reminderIntentToggledViaBinding() async {
        let store = TestStore(
            initialState: CampaignEditFeature.State(
                id: UUID(0),
                currentDate: TestDependencies.fixedNow,
                reminderTimestamp: day(month: 4, day: 20).addingTimeInterval(9 * 3600)
            )
        ) {
            CampaignEditFeature()
        }

        await store.send(\.binding.wantsReminder, true) {
            $0.wantsReminder = true
        }
        await store.send(\.binding.wantsReminder, false) {
            $0.wantsReminder = false
        }
    }

    @Test func reminderTimestampEditedViaBinding() async {
        let committed = day(month: 4, day: 20).addingTimeInterval(9 * 3600)
        let picked = day(month: 4, day: 26).addingTimeInterval(18 * 3600)
        let store = TestStore(
            initialState: CampaignEditFeature.State(
                id: UUID(0),
                currentDate: TestDependencies.fixedNow,
                wantsReminder: true,
                reminderTimestamp: committed
            )
        ) {
            CampaignEditFeature()
        }

        await store.send(\.binding.reminderTimestamp, picked) {
            $0.reminderTimestamp = picked
        }
    }

    @Test func reminderLinksLoadedStoresLinks() async {
        let link = CampaignReminderLink(
            eventIdentifier: "EVT-1",
            reminderTimestamp: day(month: 4, day: 20).addingTimeInterval(9 * 3600)
        )
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        }

        await store.send(.reminderLinksLoaded(["C1": link])) {
            $0.reminderLinks = ["C1": link]
        }
    }

    @Test func saveWithDeniedAccessShowsAlertAndStoresNoLink() async {
        let newID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: true,
            reminderTimestamp: day(month: 4, day: 20).addingTimeInterval(9 * 3600)
        )
        editState.draftName = "新團"
        var initial = CampaignFeature.State()
        initial.editCampaign = editState

        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(newID)
            $0[CampaignRepository.self].saveCampaign = { _ in }
            $0[CalendarReminderClient.self].requestAccess = { false }
        }
        store.exhaustivity = .off

        await store.send(.editCampaign(.presented(.saveTapped)))
        await store.receive(\.reminderAccessDenied)
        #expect(store.state.reminderAccessAlert != nil)
        #expect(store.state.reminderLinks[newID.uuidString] == nil)
    }

    @Test func saveCreatesReminderWithChosenTimestampOnNewCampaign() async {
        let newID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        // 使用者在 popup 選 4/20 18:00
        let chosen = day(month: 4, day: 20).addingTimeInterval(18 * 3600)
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: true,
            reminderTimestamp: chosen
        )
        editState.draftName = "新團"
        var initial = CampaignFeature.State()
        initial.editCampaign = editState

        let offsetBox = ReminderOffsetBox()
        let eventDateBox = ReminderDateBox()
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(newID)
            $0[CampaignRepository.self].saveCampaign = { _ in }
            $0[CalendarReminderClient.self].requestAccess = { true }
            $0[CalendarReminderClient.self].addReminder = { _, date, offset in
                eventDateBox.value = date
                offsetBox.value = offset
                return "EVT-new"
            }
            $0[CampaignReminderRepository.self].saveLink = { _, _, _ in }
        }
        store.exhaustivity = .off

        await store.send(.editCampaign(.presented(.saveTapped)))
        await store.receive(\.reminderStored)
        await store.skipReceivedActions(strict: false)
        #expect(store.state.reminderLinks[newID.uuidString] == CampaignReminderLink(eventIdentifier: "EVT-new", reminderTimestamp: chosen))
        // 全天事件日期＝時間戳當天起始 (4/20 00:00)、提示位移＝18:00
        #expect(eventDateBox.value == day(month: 4, day: 20))
        #expect(offsetBox.value == TimeInterval(18 * 60 * 60))
    }

    @Test func saveRemovesReminderWhenIntentClearedOnExistingCampaign() async {
        let campaign = makeCampaign(id: "C1", name: "四月團", status: .ongoing, closeDate: nil)
        var editState = CampaignEditFeature.State(
            original: campaign,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: false,
            reminderTimestamp: day(month: 4, day: 20).addingTimeInterval(9 * 3600)
        )
        editState.draftName = campaign.name
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.reminderLinks = [
            "C1": CampaignReminderLink(
                eventIdentifier: "EVT-1",
                reminderTimestamp: day(month: 4, day: 20).addingTimeInterval(9 * 3600)
            ),
        ]
        initial.editCampaign = editState

        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { _ in }
            $0[CalendarReminderClient.self].removeReminder = { _ in }
            $0[CampaignReminderRepository.self].removeLink = { _ in }
        }
        store.exhaustivity = .off

        await store.send(.editCampaign(.presented(.saveTapped)))
        await store.receive(\.reminderStored)
        await store.skipReceivedActions(strict: false)
        #expect(store.state.reminderLinks["C1"] == nil)
    }

    @Test func saveRebuildsReminderWhenNameChangedOnExistingCampaign() async {
        let campaign = makeCampaign(id: "C1", name: "舊團名", status: .ongoing, closeDate: nil)
        let timestamp = day(month: 4, day: 20).addingTimeInterval(9 * 3600)
        var editState = CampaignEditFeature.State(
            original: campaign,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: true,
            reminderTimestamp: timestamp
        )
        editState.draftName = "新團名"
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.reminderLinks = ["C1": CampaignReminderLink(eventIdentifier: "EVT-old", reminderTimestamp: timestamp)]
        initial.editCampaign = editState

        let removedOldIdentifier = ReminderCaptureBox()
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { _ in }
            $0[OrderRepository.self].renameOrderCampaign = { _, _ in }
            $0[CalendarReminderClient.self].removeReminder = { removedOldIdentifier.value = $0 }
            $0[CalendarReminderClient.self].requestAccess = { true }
            $0[CalendarReminderClient.self].addReminder = { _, _, _ in "EVT-new" }
            $0[CampaignReminderRepository.self].saveLink = { _, _, _ in }
        }
        store.exhaustivity = .off

        await store.send(.editCampaign(.presented(.saveTapped)))
        await store.receive(\.reminderStored)
        await store.skipReceivedActions(strict: false)
        #expect(store.state.reminderLinks["C1"] == CampaignReminderLink(eventIdentifier: "EVT-new", reminderTimestamp: timestamp))
        #expect(removedOldIdentifier.value == "EVT-old")
    }

    @Test func saveRebuildsReminderWhenTimestampChanged() async {
        // 名稱不變、把提醒時間戳從 4/20 09:00 改到 4/26 18:00：已新增提醒應重建到新時間戳
        let campaign = makeCampaign(id: "C1", name: "四月團", status: .ongoing, closeDate: day(month: 4, day: 20))
        let oldTimestamp = day(month: 4, day: 20).addingTimeInterval(9 * 3600)
        let newTimestamp = day(month: 4, day: 26).addingTimeInterval(18 * 3600)
        var editState = CampaignEditFeature.State(
            original: campaign,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: true,
            reminderTimestamp: newTimestamp
        )
        editState.draftName = campaign.name
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.reminderLinks = ["C1": CampaignReminderLink(eventIdentifier: "EVT-old", reminderTimestamp: oldTimestamp)]
        initial.editCampaign = editState

        let removedOldIdentifier = ReminderCaptureBox()
        let eventDateBox = ReminderDateBox()
        let offsetBox = ReminderOffsetBox()
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { _ in }
            $0[CalendarReminderClient.self].removeReminder = { removedOldIdentifier.value = $0 }
            $0[CalendarReminderClient.self].requestAccess = { true }
            $0[CalendarReminderClient.self].addReminder = { _, date, offset in
                eventDateBox.value = date
                offsetBox.value = offset
                return "EVT-new"
            }
            $0[CampaignReminderRepository.self].saveLink = { _, _, _ in }
        }
        store.exhaustivity = .off

        await store.send(.editCampaign(.presented(.saveTapped)))
        await store.receive(\.reminderStored)
        await store.skipReceivedActions(strict: false)
        #expect(store.state.reminderLinks["C1"] == CampaignReminderLink(eventIdentifier: "EVT-new", reminderTimestamp: newTimestamp))
        #expect(removedOldIdentifier.value == "EVT-old")
        #expect(eventDateBox.value == day(month: 4, day: 26))
        #expect(offsetBox.value == TimeInterval(18 * 60 * 60))
    }

    // MARK: - Helper

    /// 建立測試用開團
    private func makeCampaign(
        id: String,
        name: String,
        status: CampaignStatus,
        closeDate: Date?
    ) -> Campaign {
        Campaign(
            id: id,
            name: name,
            openDate: day(month: 4, day: 1),
            closeDate: closeDate,
            status: status,
            settledDate: nil,
            notes: ""
        )
    }

    /// 建立 2026 年指定月日的固定日期 (UTC)
    private func day(month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = 2026
        components.month = month
        components.day = day
        return components.date ?? Date(timeIntervalSince1970: 0)
    }
}

/// 捕捉 fake client 收到的字串參數；避免引入 `ConcurrencyExtras.LockIsolated` 在測試 target 中遭遇連結問題
private final class ReminderCaptureBox: @unchecked Sendable {

    // MARK: - Data Properties

    /// 由 fake closure 寫入、供測試讀取的值
    var value: String?
}

/// 捕捉 fake client 收到的日期參數；用途同 ``ReminderCaptureBox``
private final class ReminderDateBox: @unchecked Sendable {

    // MARK: - Data Properties

    /// 由 fake closure 寫入、供測試讀取的值
    var value: Date?
}

/// 捕捉 fake client 收到的提示位移參數；用途同 ``ReminderCaptureBox``
private final class ReminderOffsetBox: @unchecked Sendable {

    // MARK: - Data Properties

    /// 由 fake closure 寫入、供測試讀取的值
    var value: TimeInterval?
}
