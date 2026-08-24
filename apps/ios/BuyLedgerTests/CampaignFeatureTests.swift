//
//  CampaignFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import BuyLedger

/// 驗證開團功能
@MainActor
struct CampaignFeatureTests {
    
    // MARK: - Tests
    
    @Test func taskLoadsCampaignsWithoutTransitionWhenNoCloseDate() async {
        let campaign = makeCampaign(
            id: "C1", 
            name: "團", 
            status: .ongoing, 
            closeDate: nil
        )
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
        // 4/20 已過期應轉 closed，5/10 未到仍為 ongoing
        let pastDue = makeCampaign(
            id: "past", 
            name: "過期團", 
            status: .ongoing, 
            closeDate: day(month: 4, day: 20)
        )
        let future = makeCampaign(
            id: "future", 
            name: "未到團", 
            status: .ongoing, 
            closeDate: day(month: 5, day: 10)
        )
        
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
    
    @Test func closeDateTodayStaysOngoingUntilTheFollowingDay() async {
        // 結單日為今天；即使現在時間較晚，仍應保持進行中。
        let closeDate = day(month: 4, day: 30).addingTimeInterval(9 * 3600)
        let campaign = makeCampaign(
            id: "today", 
            name: "今天團", 
            status: .ongoing, 
            closeDate: closeDate
        )
        let nowBox = MutableDateBox(value: day(month: 4, day: 30).addingTimeInterval(15 * 3600))
        
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = DateGenerator { nowBox.value }
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].fetchCampaigns = { [campaign] }
            $0[CampaignRepository.self].saveCampaign = { _ in }
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
        // 先載入開團，再載入提醒連結
        await store.receive(\.reminderLinksLoaded)
        #expect(store.state.campaigns.first?.status == .ongoing, "結單日等於今天時，當天應維持進行中")
        
        // 結單日為今天的開團仍可歸屬訂單。
        var ordersState = OrdersFeature.State()
        ordersState.campaigns = store.state.campaigns
        #expect(
            ordersState.ongoingCampaigns.contains(campaign.name),
            "結單日等於今天的開團應仍出現在訂單編輯的可歸屬清單中"
        )
        
        // 推進到隔日後重新評估，應轉為已收單。
        nowBox.value = day(month: 5, day: 1).addingTimeInterval(1 * 3600)
        await store.send(.campaignsLoaded([campaign])) {
            $0.campaigns[0].status = .closed
        }
        #expect(store.state.campaigns.first?.status == .closed, "隔日起結單日已過的開團應轉為已收單")
    }
    
    @Test(
        arguments: [
            TimeZone(identifier: "UTC")!,
            TimeZone(identifier: "Asia/Taipei")!,
            TimeZone(identifier: "America/Los_Angeles")!,
        ]
    )
    func closeDateTodayStaysOngoingRegardlessOfInjectedTimeZone(timeZone: TimeZone) async {
        // 使用注入的時區判定日期，不讀系統時區；三個時區都應得到相同結果。
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: TestDependencies.fixedNow)
        let closeDate = calendar.date(byAdding: .hour, value: 9, to: today)!
        let nowBox = MutableDateBox(value: calendar.date(byAdding: .hour, value: 15, to: today)!)
        let campaign = makeCampaign(
            id: "tz", 
            name: "跨時區團", 
            status: .ongoing, 
            closeDate: closeDate
        )
        
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = DateGenerator { nowBox.value }
            $0.calendar = calendar
            $0[CampaignRepository.self].fetchCampaigns = { [campaign] }
            $0[CampaignRepository.self].saveCampaign = { _ in }
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
        // 先載入開團，再載入提醒連結
        await store.receive(\.reminderLinksLoaded)
        #expect(
            store.state.campaigns.first?.status == .ongoing,
            "\(timeZone.identifier)：結單日等於當地今天時應維持進行中"
        )
        
        let nextDay = calendar.date(byAdding: .day, value: 1, to: today)!
        nowBox.value = calendar.date(byAdding: .hour, value: 1, to: nextDay)!
        await store.send(.campaignsLoaded([campaign])) {
            $0.campaigns[0].status = .closed
        }
        #expect(
            store.state.campaigns.first?.status == .closed,
            "\(timeZone.identifier)：隔日 (該時區) 起應轉為已收單"
        )
    }
    
    @Test func statusChangedUpdatesCampaign() async {
        let campaign = makeCampaign(
            id: "C1", 
            name: "團", 
            status: .ongoing, 
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { _ in }
        }
        
        // 寫入成功後才套用新的開團狀態。
        await store.send(.statusChanged("C1", .closed))
        await store.receive(\.campaignStatusSaved) {
            $0.campaigns[0].status = .closed
        }
    }
    
    @Test func settleTappedRecordsSettledDateWithoutChangingStatus() async {
        let campaign = makeCampaign(
            id: "C1", 
            name: "團", 
            status: .closed, 
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { _ in }
        }
        
        // 結團是不可逆轉換，先確認、確認後才寫入結算日期
        await store.send(.settleTapped("C1")) {
            $0.settleConfirmation = AlertState {
                TextState("結團結算")
            } actions: {
                ButtonState(action: .confirmSettle("C1")) {
                    TextState("結團")
                }
                ButtonState(role: .cancel) {
                    TextState("取消")
                }
            } message: {
                TextState("結算「團」後就無法再改回進行中。確定要結團嗎？")
            }
        }
        #expect(store.state.settleConfirmation != nil)
        #expect(store.state.campaigns[0].settledDate == nil, "確認前不應寫入結算日期")
        
        await store.send(.settleConfirmation(.presented(.confirmSettle("C1")))) {
            $0.settleConfirmation = nil
        }
        await store.receive(\.settleConfirmed)
        // settleConfirmed 送出寫入 effect，寫入成功後 campaignSettled 才套用結算日期
        await store.receive(\.campaignSettled) {
            $0.campaigns[0].settledDate = TestDependencies.fixedNow
        }
        
        #expect(store.state.campaigns[0].settledDate == TestDependencies.fixedNow)
        #expect(store.state.campaigns[0].status == .closed, "結團不應改變狀態")
    }
    
    @Test func deleteConfirmationRemovesCampaign() async {
        let campaign = makeCampaign(
            id: "C1", 
            name: "團", 
            status: .ongoing, 
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].removeCampaign = { _, _ in nil }
        }
        await store.send(.deleteCampaignTapped("C1")) {
            $0.deletionConfirmation = AlertState {
                TextState("刪除開團")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete("C1")) {
                    TextState("刪除")
                }
                ButtonState(role: .cancel) {
                    TextState("取消")
                }
            } message: {
                TextState("刪除「團」後無法復原。歸屬此開團的訂單會保留，但會變回未歸團。")
            }
        }
        #expect(store.state.deletionConfirmation != nil)
        
        await store.send(.deletionConfirmation(.presented(.confirmDelete("C1")))) {
            $0.deletionConfirmation = nil
        }
        await store.receive(\.campaignDeleteRequested)
        await store.receive(\.campaignDeleted) {
            $0.campaigns = []
            $0.reminderLinks = [:]
            $0.selectedCampaignID = nil
        }
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
        // 以完整狀態比較驗證表單已呈現且為新開團
        await store.send(.newCampaignTapped) {
            $0.editCampaign = CampaignEditFeature.State(
                id: UUID(0),
                currentDate: TestDependencies.fixedNow,
                reminderTimestamp: TestDependencies.fixedCalendar.date(
                    bySettingHour: 9,
                    minute: 0,
                    second: 0,
                    of: TestDependencies.fixedCalendar.startOfDay(for: TestDependencies.fixedNow)
                ) ?? TestDependencies.fixedNow
            )
        }
        #expect(store.state.editCampaign != nil)
        #expect(store.state.editCampaign?.original == nil)
        #expect(store.state.editCampaign?.draft.status == .ongoing)
    }
    
    // MARK: - Name Uniqueness Tests
    
    @Test func savingDuplicateNameIsRejectedBeforeAnyWrite() async {
        let existing = makeCampaign(
            id: "C1",
            name: "母親節團",
            status: .ongoing,
            closeDate: nil
        )
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            // 開啟提醒；若守門失效應觸發行事曆呼叫。
            wantsReminder: true,
            reminderTimestamp: TestDependencies.fixedNow
        )
        // 前後空白不應影響比對：trim 後與既有開團同名
        editState.draft.name = "  母親節團  "
        var initial = CampaignFeature.State()
        initial.campaigns = [existing]
        initial.editCampaign = editState
        
        let saveCount = SaveCallCountBox()
        let requestAccessCount = SaveCallCountBox()
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
            $0[CampaignRepository.self].saveCampaign = { _ in saveCount.value += 1 }
            $0[CalendarReminderClient.self].requestAccess = {
                requestAccessCount.value += 1
                return .granted
            }
        }
        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign?.nameConflictMessage = "已有其他開團使用這個名稱，請改用不同名稱。"
        }
        await store.finish()
        
        #expect(store.state.campaigns.count == 1, "重複名稱應被拒絕，不應新增第二筆")
        #expect(store.state.editCampaign != nil, "拒絕儲存時表單應維持呈現，而非被關閉")
        #expect(store.state.editCampaign?.nameConflictMessage != nil, "表單應持有可呈現的重複名稱原因")
        #expect(saveCount.value == 0, "拒絕時不應進入任何持久層寫入呼叫")
        #expect(requestAccessCount.value == 0, "拒絕時不應進入任何行事曆相依呼叫")
    }
    
    @Test func editingCampaignKeepingOwnNameSavesSuccessfully() async {
        let existing = makeCampaign(
            id: "C1",
            name: "四月團",
            status: .ongoing,
            closeDate: nil
        )
        let editState = CampaignEditFeature.State(
            original: existing,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [existing]
        initial.editCampaign = editState
        
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { _ in }
        }
        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }
        // 沒有結單日的舊開團，草稿會以目前日期填入
        await store.receive(\.campaignSaved) {
            $0.campaigns[0] = Campaign(
                id: "C1",
                name: "四月團",
                openDate: existing.openDate,
                closeDate: TestDependencies.fixedNow,
                status: .ongoing,
                settledDate: nil,
                notes: ""
            )
        }
        
        #expect(store.state.editCampaign == nil, "維持原名儲存應成功並關閉表單")
        #expect(store.state.campaigns.first?.name == "四月團")
    }
    
    @Test func preExistingDuplicateNamesRemainSavableWithoutRename() async {
        // 既有同名開團可維持原名，新建或改名時才檢查重複
        let campaignA = makeCampaign(
            id: "A",
            name: "重複團",
            status: .ongoing,
            closeDate: nil
        )
        let campaignB = makeCampaign(
            id: "B",
            name: "重複團",
            status: .ongoing,
            closeDate: nil
        )
        let editState = CampaignEditFeature.State(
            original: campaignA,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaignA, campaignB]
        initial.editCampaign = editState
        
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { _ in }
        }
        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }
        // 沒有結單日的舊開團，草稿會以目前日期填入
        await store.receive(\.campaignSaved) {
            $0.campaigns[0] = Campaign(
                id: "A",
                name: "重複團",
                openDate: campaignA.openDate,
                closeDate: TestDependencies.fixedNow,
                status: .ongoing,
                settledDate: nil,
                notes: ""
            )
        }
        
        #expect(store.state.editCampaign == nil, "既有重名資料在不改名時應可正常儲存")
        #expect(store.state.campaigns.count == 2)
        #expect(store.state.campaigns.filter { $0.name == "重複團" }.count == 2, "既有重名不做自動清理")
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
        
        await store.send(.binding(.set(\.draft.wantsReminder, true))) {
            $0.draft.wantsReminder = true
        }
        await store.send(.binding(.set(\.draft.wantsReminder, false))) {
            $0.draft.wantsReminder = false
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
        
        await store.send(.binding(.set(\.draft.reminderTimestamp, picked))) {
            $0.draft.reminderTimestamp = picked
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
            $0[CalendarReminderClient.self].requestAccess = { .denied }
        }
        // 儲存後依序收到 campaignSaved 與 reminderAccessDenied
        store.exhaustivity = .off
        await store.send(.editCampaign(.presented(.saveTapped)))
        await store.receive(\.campaignSaved)
        await store.receive(\.reminderAccessDenied)
        // 新開團尚無 selectedCampaignID (未進入詳情)，通知掛列表插槽
        #expect(store.state.noticeAlert != nil)
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
        editState.draft.name = "新團"
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
            $0[CalendarReminderClient.self].requestAccess = { .granted }
            $0[CalendarReminderClient.self].addReminder = { _, date, offset in
                eventDateBox.value = date
                offsetBox.value = offset
                return "EVT-new"
            }
            $0[CampaignReminderRepository.self].saveLink = { _, _ in }
        }
        // 儲存同時啟動子表單 dismiss、`campaignSaved` 與提醒建立／連結寫入效果。
        // 完成順序不固定，因此關閉窮舉。
        store.exhaustivity = .off
        await store.send(.editCampaign(.presented(.saveTapped)))
        await store.receive(\.reminderStored)
        await store.skipReceivedActions(strict: false)
        #expect(
            store.state.reminderLinks[newID.uuidString] == CampaignReminderLink(
                eventIdentifier: "EVT-new", 
                reminderTimestamp: chosen
            )
        )
        // 全天事件日期＝時間戳當天起始 (4/20 00:00)、提示位移＝18:00
        #expect(eventDateBox.value == day(month: 4, day: 20))
        #expect(offsetBox.value == TimeInterval(18 * 60 * 60))
    }
    
    @Test func saveRemovesReminderWhenIntentClearedOnExistingCampaign() async {
        let campaign = makeCampaign(
            id: "C1",
            name: "四月團",
            status: .ongoing,
            closeDate: nil
        )
        var editState = CampaignEditFeature.State(
            original: campaign,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: false,
            reminderTimestamp: day(month: 4, day: 20).addingTimeInterval(9 * 3600)
        )
        editState.draft.name = campaign.name
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.reminderLinks = [
            "C1": CampaignReminderLink(
                eventIdentifier: "EVT-1",
                reminderTimestamp: day(month: 4, day: 20).addingTimeInterval(9 * 3600)
            )
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
        // 儲存與提醒移除同時進行，完成順序不固定。
        store.exhaustivity = .off
        await store.send(.editCampaign(.presented(.saveTapped)))
        await store.receive(\.reminderStored)
        await store.skipReceivedActions(strict: false)
        #expect(store.state.reminderLinks["C1"] == nil)
    }
    
    @Test func saveRebuildsReminderWhenNameChangedOnExistingCampaign() async {
        let campaign = makeCampaign(
            id: "C1", 
            name: "舊團名", 
            status: .ongoing, 
            closeDate: nil
        )
        let timestamp = day(month: 4, day: 20).addingTimeInterval(9 * 3600)
        var editState = CampaignEditFeature.State(
            original: campaign,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: true,
            reminderTimestamp: timestamp
        )
        editState.draft.name = "新團名"
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.reminderLinks = [
            "C1": CampaignReminderLink(
                eventIdentifier: "EVT-old", 
                reminderTimestamp: timestamp
            )
        ]
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
            $0[CalendarReminderClient.self].requestAccess = { .granted }
            $0[CalendarReminderClient.self].addReminder = { _, _, _ in "EVT-new" }
            $0[CampaignReminderRepository.self].saveLink = { _, _ in }
        }
        // 改名會重建提醒；完成順序不固定，只驗證結果。
        store.exhaustivity = .off
        await store.send(.editCampaign(.presented(.saveTapped)))
        await store.receive(\.reminderStored)
        await store.skipReceivedActions(strict: false)
        #expect(
            store.state.reminderLinks["C1"] == CampaignReminderLink(
                eventIdentifier: "EVT-new", 
                reminderTimestamp: timestamp
            )
        )
        #expect(removedOldIdentifier.value == "EVT-old")
    }
    
    @Test func saveRebuildsReminderWhenTimestampChanged() async {
        // 提醒時間變更後應重建提醒。
        let campaign = makeCampaign(
            id: "C1", name: "四月團", status: .ongoing, closeDate: day(month: 4, day: 20))
        let oldTimestamp = day(month: 4, day: 20).addingTimeInterval(9 * 3600)
        let newTimestamp = day(month: 4, day: 26).addingTimeInterval(18 * 3600)
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
            "C1": CampaignReminderLink(
                eventIdentifier: "EVT-old", 
                reminderTimestamp: oldTimestamp
            )
        ]
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
            $0[CalendarReminderClient.self].requestAccess = { .granted }
            $0[CalendarReminderClient.self].addReminder = { _, date, offset in
                eventDateBox.value = date
                offsetBox.value = offset
                return "EVT-new"
            }
            $0[CampaignReminderRepository.self].saveLink = { _, _ in }
        }
        // 時間戳變更會重建提醒；完成順序不固定，只驗證結果。
        store.exhaustivity = .off
        await store.send(.editCampaign(.presented(.saveTapped)))
        await store.receive(\.reminderStored)
        await store.skipReceivedActions(strict: false)
        #expect(
            store.state.reminderLinks["C1"] == CampaignReminderLink(
                eventIdentifier: "EVT-new",
                reminderTimestamp: newTimestamp
            )
        )
        #expect(removedOldIdentifier.value == "EVT-old")
        #expect(eventDateBox.value == day(month: 4, day: 26))
        #expect(offsetBox.value == TimeInterval(18 * 60 * 60))
    }
    
    // MARK: - Write Failure Visibility Tests
    
    @Test func saveFailureDoesNotInsertCampaign() async {
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        editState.draft.name = "新團"
        var initial = CampaignFeature.State()
        initial.editCampaign = editState
        
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
            $0[CampaignRepository.self].saveCampaign = { (_: Campaign) async throws(PersistenceError) in
                throw PersistenceError.saveFailed(message: "boom")
            }
        }
        
        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("開團儲存失敗，請稍後再試。")
        }
        
        #expect(store.state.campaigns.isEmpty, "寫入失敗不應插入開團")
    }
    
    @Test func statusChangeFailureKeepsPreviousStatus() async {
        let campaign = makeCampaign(
            id: "C1", 
            name: "團", 
            status: .ongoing, 
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { (_: Campaign) async throws(PersistenceError) in
                throw PersistenceError.saveFailed(message: "boom")
            }
        }
        
        await store.send(.statusChanged("C1", .closed))
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("開團狀態更新失敗，請稍後再試。")
        }
        
        #expect(store.state.campaigns[0].status == .ongoing, "寫入失敗應維持先前狀態")
    }
    
    @Test func settleFailureKeepsCampaignUnsettled() async {
        let campaign = makeCampaign(
            id: "C1", 
            name: "團", 
            status: .closed, 
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { (_: Campaign) async throws(PersistenceError) in
                throw PersistenceError.saveFailed(message: "boom")
            }
        }
        
        await store.send(.settleTapped("C1")) {
            $0.settleConfirmation = Self.settleAlert(id: "C1", name: "團")
        }
        await store.send(.settleConfirmation(.presented(.confirmSettle("C1")))) {
            $0.settleConfirmation = nil
        }
        await store.receive(\.settleConfirmed)
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("結團失敗，請稍後再試。")
        }
        
        #expect(store.state.campaigns[0].settledDate == nil, "寫入失敗不應寫入結算日期")
        #expect(store.state.campaigns[0].status == .closed)
    }
    
    @Test func deleteFailureKeepsCampaignVisible() async {
        let campaign = makeCampaign(
            id: "C1", 
            name: "團", 
            status: .ongoing, 
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].removeCampaign = { (_: String, _: String) async throws(PersistenceError) -> String? in
                throw PersistenceError.saveFailed(message: "boom")
            }
        }
        
        await store.send(.deleteCampaignTapped("C1")) {
            $0.deletionConfirmation = Self.deletionAlert(id: "C1", name: "團")
        }
        await store.send(.deletionConfirmation(.presented(.confirmDelete("C1")))) {
            $0.deletionConfirmation = nil
        }
        await store.receive(\.campaignDeleteRequested)
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("開團刪除失敗，請稍後再試。")
        }
        
        #expect(
            store.state.campaigns.count == 1,
            "刪除失敗應保持開團可見 (destructive-action-safeguard 的 Failed deletion leaves the item visible)"
        )
    }
    
    // MARK: - Delete Cascade Tests
    
    @Test func deleteClearsReminderLinkAndRemovesCalendarEvent() async {
        let campaign = makeCampaign(
            id: "C1", 
            name: "團", 
            status: .ongoing, 
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.reminderLinks = [
            "C1": CampaignReminderLink(
                eventIdentifier: "EVT-1", 
                reminderTimestamp: TestDependencies.fixedNow
            )
        ]
        
        let removedIdentifier = CampaignTestCaptureBox()
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].removeCampaign = { _, _ in "EVT-1" }
            $0[CalendarReminderClient.self].removeReminder = { identifier in
                removedIdentifier.value = identifier
            }
        }
        
        await store.send(.deleteCampaignTapped("C1")) {
            $0.deletionConfirmation = Self.deletionAlert(id: "C1", name: "團")
        }
        await store.send(.deletionConfirmation(.presented(.confirmDelete("C1")))) {
            $0.deletionConfirmation = nil
        }
        await store.receive(\.campaignDeleteRequested)
        await store.receive(\.campaignDeleted) {
            $0.campaigns = []
            $0.reminderLinks = [:]
        }
        
        #expect(removedIdentifier.value == "EVT-1", "刪除應以連結記錄的事件識別碼呼叫一次 removeReminder")
    }
    
    @Test func calendarRemovalFailureDoesNotResurrectTheDeletedCampaign() async {
        // 行事曆移除失敗不回滾開團，但仍須顯示錯誤。
        let campaign = makeCampaign(
            id: "C1", 
            name: "團", 
            status: .ongoing, 
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].removeCampaign = { _, _ in "EVT-1" }
            $0[CalendarReminderClient.self].removeReminder = { (_: String) async throws(CalendarReminderError) in
                throw CalendarReminderError.system(message: "boom")
            }
        }
        
        await store.send(.deleteCampaignTapped("C1")) {
            $0.deletionConfirmation = Self.deletionAlert(id: "C1", name: "團")
        }
        await store.send(.deletionConfirmation(.presented(.confirmDelete("C1")))) {
            $0.deletionConfirmation = nil
        }
        await store.receive(\.campaignDeleteRequested)
        await store.receive(\.campaignDeleted) {
            $0.campaigns = []
        }
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("開團已刪除，但行事曆上的提醒事件移除失敗，請自行到行事曆刪除。")
        }
        
        #expect(store.state.campaigns.isEmpty, "本機刪除已生效，不因行事曆失敗而復原")
    }
    
    // MARK: - Notice Alert Slot Tests
    
    @Test func noticeAlertGoesToListSlotWhenNoCampaignIsSelected() async {
        let campaign = makeCampaign(
            id: "C1", 
            name: "團", 
            status: .ongoing, 
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.selectedCampaignID = nil
        
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { (_: Campaign) async throws(PersistenceError) in
                throw PersistenceError.saveFailed(message: "boom")
            }
        }
        
        await store.send(.statusChanged("C1", .closed))
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("開團狀態更新失敗，請稍後再試。")
        }
    }
    
    @Test func noticeAlertGoesToDetailSlotWhenACampaignIsSelected() async {
        let campaign = makeCampaign(
            id: "C1", 
            name: "團", 
            status: .ongoing, 
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.selectedCampaignID = "C1"
        
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { (_: Campaign) async throws(PersistenceError) in
                throw PersistenceError.saveFailed(message: "boom")
            }
        }
        
        await store.send(.statusChanged("C1", .closed))
        await store.receive(\.campaignWriteFailed) {
            $0.detailNoticeAlert = Self.failureAlert("開團狀態更新失敗，請稍後再試。")
        }
    }
    
    // MARK: - Reload Consistency Tests
    
    /// 儲存失敗後重新載入，確認畫面與資料庫一致
    /// - Throws: 測試資料建立或功能驗證失敗時拋出錯誤
    @Test func presentedCampaignsMatchReloadAfterFailedSave() async throws(any Error) {
        let existing = makeCampaign(
            id: "C1", 
            name: "既有團", 
            status: .ongoing, 
            closeDate: nil
        )
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        editState.draft.name = "新團"
        var initial = CampaignFeature.State()
        initial.campaigns = [existing]
        initial.editCampaign = editState
        
        let repository = try await Self.makeReloadConsistencyRepository(seeding: [existing])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
            $0[CampaignRepository.self] = repository
        }
        
        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("開團儲存失敗，請稍後再試。")
        }
        let presented = store.state.campaigns
        
        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.campaignsLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.campaigns = presented
        }
        await store.receive(\.reminderLinksLoaded)
        
        #expect(store.state.campaigns == presented, "重新從唯讀 store 載入的結果應與失敗當下呈現的一致")
    }
    
    @Test func presentedCampaignsMatchReloadAfterFailedStatusChange() async throws(any Error) {
        let campaign = makeCampaign(
            id: "C1", 
            name: "團", 
            status: .ongoing, 
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        
        let repository = try await Self.makeReloadConsistencyRepository(seeding: [campaign])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self] = repository
        }
        
        await store.send(.statusChanged("C1", .closed))
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("開團狀態更新失敗，請稍後再試。")
        }
        let presented = store.state.campaigns
        
        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.campaignsLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.campaigns = presented
        }
        await store.receive(\.reminderLinksLoaded)
        
        #expect(store.state.campaigns == presented)
    }
    
    @Test func presentedCampaignsMatchReloadAfterFailedSettle() async throws(any Error) {
        let campaign = makeCampaign(
            id: "C1", 
            name: "團", 
            status: .closed, 
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        
        let repository = try await Self.makeReloadConsistencyRepository(seeding: [campaign])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self] = repository
        }
        
        await store.send(.settleTapped("C1")) {
            $0.settleConfirmation = Self.settleAlert(id: "C1", name: "團")
        }
        await store.send(.settleConfirmation(.presented(.confirmSettle("C1")))) {
            $0.settleConfirmation = nil
        }
        await store.receive(\.settleConfirmed)
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("結團失敗，請稍後再試。")
        }
        let presented = store.state.campaigns
        
        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.campaignsLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.campaigns = presented
        }
        await store.receive(\.reminderLinksLoaded)
        
        #expect(store.state.campaigns == presented)
    }
    
    @Test func presentedCampaignsMatchReloadAfterFailedListDelete() async throws(any Error) {
        let campaign = makeCampaign(
            id: "C1", 
            name: "團", 
            status: .ongoing, 
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        
        let repository = try await Self.makeReloadConsistencyRepository(seeding: [campaign])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self] = repository
        }
        
        await store.send(.deleteCampaignTapped("C1")) {
            $0.deletionConfirmation = Self.deletionAlert(id: "C1", name: "團")
        }
        await store.send(.deletionConfirmation(.presented(.confirmDelete("C1")))) {
            $0.deletionConfirmation = nil
        }
        await store.receive(\.campaignDeleteRequested)
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("開團刪除失敗，請稍後再試。")
        }
        let presented = store.state.campaigns
        
        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.campaignsLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.campaigns = presented
        }
        await store.receive(\.reminderLinksLoaded)
        
        #expect(store.state.campaigns == presented)
    }
    
    @Test func presentedCampaignsMatchReloadAfterFailedDetailDelete() async throws(any Error) {
        let campaign = makeCampaign(
            id: "C1", 
            name: "團", 
            status: .ongoing, 
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.selectedCampaignID = "C1"
        
        let repository = try await Self.makeReloadConsistencyRepository(seeding: [campaign])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self] = repository
        }
        
        await store.send(.detailDeleteCampaignTapped("C1")) {
            $0.detailDeletionConfirmation = Self.deletionAlert(id: "C1", name: "團")
        }
        await store.send(.detailDeletionConfirmation(.presented(.confirmDelete("C1")))) {
            $0.detailDeletionConfirmation = nil
        }
        await store.receive(\.campaignDeleteRequested)
        await store.receive(\.campaignWriteFailed) {
            $0.detailNoticeAlert = Self.failureAlert("開團刪除失敗，請稍後再試。")
        }
        let presented = store.state.campaigns
        
        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.campaignsLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.campaigns = presented
        }
        await store.receive(\.reminderLinksLoaded)
        
        #expect(store.state.campaigns == presented)
    }
    
    /// 收款狀態切換只送出 delegate，不直接修改 `State.orders`
    @Test func receiptStatusToggleEmitsDelegateWithoutMutatingState() async {
        let order = makeCampaignOrder(
            id: "O1", 
            campaign: "四月團"
        )
        var state = CampaignFeature.State()
        state.orders = [order]
        
        let store = TestStore(initialState: state) {
            CampaignFeature()
        }
        
        await store.send(.receiptStatusToggled("O1", .received))
        await store.receive(\.delegate.receiptStatusToggled)
        
        // 測試期間不直接改寫 `State.orders`，由 RootFeature 同步投影。
        #expect(store.state.orders == [order])
    }
    
    /// 開團摘要衍生自 `State.orders` 投影
    @Test func ordersProjectionDrivesCampaignSummary() {
        var state = CampaignFeature.State()
        state.orders = [
            makeCampaignOrder(
                id: "O1", 
                campaign: "四月團", 
                chargedAmount: 500
            )
        ]
        
        let summaryBeforeSync = CampaignSummary(campaignName: "四月團", orders: state.orders)
        #expect(summaryBeforeSync.orderCount == 1)
        #expect(summaryBeforeSync.receivables == 500)
        
        // 模擬投影更新：新訂單併入同一份 State.orders，而不是另建區域陣列
        state.orders.append(
            makeCampaignOrder(
                id: "O2", 
                campaign: "四月團", 
                chargedAmount: 300
            )
        )
        
        let summaryAfterSync = CampaignSummary(campaignName: "四月團", orders: state.orders)
        #expect(summaryAfterSync.orderCount == 2)
        #expect(summaryAfterSync.receivables == 800)
        #expect(summaryBeforeSync != summaryAfterSync)
    }
}

// MARK: - Helper Method

private extension CampaignFeatureTests {
    
    /// 建立供 `orders` 投影測試使用的最小訂單
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - campaign: 開團名稱
    ///   - chargedAmount: 客戶實付金額
    /// - Returns: 建立的訂單
    func makeCampaignOrder(
        id: String,
        campaign: String,
        chargedAmount: Decimal = 100
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [LedgerOrderItem(name: "item", quantity: 1, unitPrice: 0)],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: chargedAmount,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: [],
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [campaign],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
    
    /// 建立測試用開團
    /// - Parameters:
    ///   - id: 開團識別值
    ///   - name: 開團名稱
    ///   - status: 開團狀態
    ///   - closeDate: 結單日期
    /// - Returns: 建立的開團
    func makeCampaign(
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
    /// - Parameters:
    ///   - month: 月份
    ///   - day: 日期
    /// - Returns: 指定日期
    func day(month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = 2026
        components.month = month
        components.day = day
        return components.date ?? Date(timeIntervalSince1970: 0)
    }
    
    /// 建立含初始開團的唯讀 ``CampaignRepository``
    /// - Parameter initialCampaigns: 初始開團清單
    /// - Returns: CampaignRepository
    /// - Throws: 測試資料庫建立或資料寫入失敗時拋出錯誤
    static func makeReloadConsistencyRepository(seeding initialCampaigns: [Campaign]) async throws(any Error) -> CampaignRepository {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BuyLedgerCampaignReloadTest-\(UUID().uuidString).store")
        let schema = Schema(versionedSchema: BuyLedgerSchemaV16.self)
        let writableConfiguration = ModelConfiguration(
            schema: schema, 
            url: storeURL, 
            cloudKitDatabase: .none
        )
        let writableContainer = try ModelContainer(
            for: schema,
            migrationPlan: BuyLedgerMigrationPlan.self,
            configurations: writableConfiguration
        )
        let seedPersistence = CampaignPersistence(modelContainer: writableContainer)
        for campaign in initialCampaigns {
            try await seedPersistence.upsert(campaign)
        }
        
        let readOnlyConfiguration = ModelConfiguration(
            schema: schema, 
            url: storeURL, 
            allowsSave: false, 
            cloudKitDatabase: .none
        )
        let readOnlyContainer = try ModelContainer(
            for: schema,
            migrationPlan: BuyLedgerMigrationPlan.self,
            configurations: readOnlyConfiguration
        )
        return CampaignRepository.live(container: readOnlyContainer)
    }
    
    /// 建立寫入失敗提示
    /// - Parameter message: 要顯示的錯誤訊息
    /// - Returns: 錯誤提示狀態
    static func failureAlert(_ message: LocalizedStringKey) -> AlertState<CampaignFeature.Action.NoticeAlert> {
        AlertState {
            TextState("操作失敗")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("知道了")
            }
        } message: {
            TextState(message)
        }
    }
    
    /// 建立刪除確認對話框
    /// - Parameters:
    ///   - id: 要刪除的開團識別碼
    ///   - name: 要刪除的開團名稱
    /// - Returns: 刪除提示狀態
    static func deletionAlert(id: Campaign.ID, name: String) -> AlertState<CampaignFeature.Action.Alert> {
        AlertState {
            TextState("刪除開團")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDelete(id)) {
                TextState("刪除")
            }
            ButtonState(role: .cancel) {
                TextState("取消")
            }
        } message: {
            TextState("刪除「\(name)」後無法復原。歸屬此開團的訂單會保留，但會變回未歸團。")
        }
    }
    
    /// 建立結團確認對話框
    /// - Parameters:
    ///   - id: 要結團的開團識別碼
    ///   - name: 要結團的開團名稱
    /// - Returns: 結團提示狀態
    static func settleAlert(id: Campaign.ID, name: String) -> AlertState<CampaignFeature.Action.SettleAlert> {
        AlertState {
            TextState("結團結算")
        } actions: {
            ButtonState(action: .confirmSettle(id)) {
                TextState("結團")
            }
            ButtonState(role: .cancel) {
                TextState("取消")
            }
        } message: {
            TextState("結算「\(name)」後就無法再改回進行中。確定要結團嗎？")
        }
    }
}

/// 捕捉 fake client 的字串參數
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

/// 可在測試期間修改的現在時間
private final class MutableDateBox: @unchecked Sendable {
    
    // MARK: - Data Properties
    
    /// 目前要回傳的「現在」時間
    var value: Date
    
    // MARK: - Init
    
    init(value: Date) {
        self.value = value
    }
}

/// 計算 fake repository 的 saveCampaign 呼叫次數
private final class SaveCallCountBox: @unchecked Sendable {
    
    // MARK: - Data Properties
    
    /// 呼叫次數
    var value = 0
}

/// 捕捉 fake client 的字串參數
private final class CampaignTestCaptureBox: @unchecked Sendable {
    
    // MARK: - Data Properties
    
    /// 由 fake closure 寫入、供測試讀取的值
    var value: String?
}
