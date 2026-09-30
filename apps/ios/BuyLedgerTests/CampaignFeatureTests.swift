//
//  CampaignFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import SwiftData
import SwiftUI
import Testing

@testable import BuyLedger

/// 以 `TestStore` 逐步驗證 `CampaignFeature` 的狀態轉換與副作用
@MainActor
struct CampaignFeatureTests {

    // MARK: - Tests

    /// 載入沒有結單日的開團時維持進行中，也不寫回
    @Test
    func task_開團沒有結束日期_維持進行中狀態() async {
        // Given
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
            $0.campaignService.fetchCampaigns = {
                [campaign]
            }
            $0.campaignReminderService.fetchLinks = {
                [:]
            }
        }

        // When
        await store.send(.task) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.campaignsLoaded) {
            $0.hasLoaded = true
            $0.isLoading = false
            $0.campaigns = [campaign]
        }
        await store.receive(\.reminderLinksLoaded)
    }

    /// 已過結單日的開團自動改為已結束並寫回，未到期的維持進行中
    @Test
    func task_目前日期晚於結束日期_自動轉為已結束() async {
        // Given
        // 4/20 已過結單日要轉為已結束，5/10 還沒到維持進行中
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

        let savedCampaigns = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                [pastDue, future]
            }
            $0.campaignService.saveCampaign = { campaign in
                savedCampaigns.withValue {
                    $0.append(campaign)
                }
            }
            $0.campaignReminderService.fetchLinks = {
                [:]
            }
        }

        var transitioned = pastDue
        transitioned.status = .closed

        // When
        await store.send(.task) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.campaignsLoaded) {
            $0.hasLoaded = true
            $0.isLoading = false
            $0.campaigns = [transitioned, future]
        }
        await store.receive(\.reminderLinksLoaded)
        await store.finish()
        #expect(savedCampaigns.value == [transitioned])
    }

    /// 結單日當天即使現在時間已晚於結單時間，載入後仍維持進行中，也不寫回
    @Test
    func task_今天為開團結束日期_仍維持進行中() async {
        // Given
        // 結單日為今天；即使現在時間較晚，仍應保持進行中
        let closeDate = day(month: 4, day: 30).addingTimeInterval(9 * 3600)
        let campaign = makeCampaign(
            id: "today",
            name: "今天團",
            status: .ongoing,
            closeDate: closeDate
        )
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(day(month: 4, day: 30).addingTimeInterval(15 * 3600))
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                [campaign]
            }
            $0.campaignReminderService.fetchLinks = {
                [:]
            }
        }

        // When
        await store.send(.task) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.campaignsLoaded) {
            $0.hasLoaded = true
            $0.isLoading = false
            $0.campaigns = [campaign]
        }
        await store.receive(\.reminderLinksLoaded)
    }

    /// 隔日收到載入結果時，已過結單日的開團改為已結束並寫回
    @Test
    func campaignsLoaded_隔日已超過結束日期_自動轉為已結束() async {
        // Given
        let closeDate = day(month: 4, day: 30).addingTimeInterval(9 * 3600)
        let campaign = makeCampaign(
            id: "next-day",
            name: "隔日團",
            status: .ongoing,
            closeDate: closeDate
        )
        var closedCampaign = campaign
        closedCampaign.status = .closed
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(day(month: 5, day: 1).addingTimeInterval(1 * 3600))
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = { savedCampaign in
                savedCampaigns.withValue {
                    $0.append(savedCampaign)
                }
            }
        }

        // When
        await store.send(.campaignsLoaded([campaign])) {
            $0.hasLoaded = true
            $0.campaigns = [closedCampaign]
        }

        // Then
        await store.finish()
        #expect(store.state.campaigns == [closedCampaign])
        #expect(savedCampaigns.value == [closedCampaign])
    }

    /// 注入不同時區後，結單日期仍以當地日曆判斷為今天
    ///
    /// - Parameter timeZoneIdentifier: 用來判斷當地日期的時區
    /// - Throws: 時區識別碼或日曆日期無法建立時拋出測試錯誤
    @Test(arguments: ["UTC", "Asia/Taipei", "America/Los_Angeles"])
    func task_注入時區後結束日為今天_維持進行中(timeZoneIdentifier: String) async throws(any Error) {
        // Given
        // 使用注入的時區判定日期，不讀系統時區
        let timeZone = try #require(TimeZone(identifier: timeZoneIdentifier))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: TestDependencies.fixedNow)
        let closeDate = try #require(calendar.date(byAdding: .hour, value: 9, to: today))
        let now = try #require(calendar.date(byAdding: .hour, value: 15, to: today))
        let campaign = makeCampaign(
            id: "tz",
            name: "跨時區團",
            status: .ongoing,
            closeDate: closeDate
        )

        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.calendar = calendar
            $0.campaignService.fetchCampaigns = {
                [campaign]
            }
            $0.campaignReminderService.fetchLinks = {
                [:]
            }
        }

        // When
        await store.send(.task) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.campaignsLoaded) {
            $0.hasLoaded = true
            $0.isLoading = false
            $0.campaigns = [campaign]
        }
        await store.receive(\.reminderLinksLoaded)
    }

    /// 在注入時區的隔日載入已過結束日期的開團時自動結束
    ///
    /// - Parameter timeZoneIdentifier: 用來判斷當地日期的時區
    /// - Throws: 時區識別碼或日曆日期無法建立時拋出測試錯誤
    @Test(arguments: ["UTC", "Asia/Taipei", "America/Los_Angeles"])
    func campaignsLoaded_注入時區後已過結束日期_自動轉為已結束(timeZoneIdentifier: String) async throws(any Error) {
        // Given
        let timeZone = try #require(TimeZone(identifier: timeZoneIdentifier))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: TestDependencies.fixedNow)
        let closeDate = try #require(calendar.date(byAdding: .hour, value: 9, to: today))
        let nextDay = try #require(calendar.date(byAdding: .day, value: 1, to: today))
        let now = try #require(calendar.date(byAdding: .hour, value: 1, to: nextDay))
        let campaign = makeCampaign(
            id: "tz-next-day",
            name: "跨時區隔日團",
            status: .ongoing,
            closeDate: closeDate
        )
        var closedCampaign = campaign
        closedCampaign.status = .closed
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.calendar = calendar
            $0.campaignService.saveCampaign = { savedCampaign in
                savedCampaigns.withValue {
                    $0.append(savedCampaign)
                }
            }
        }

        // When
        await store.send(.campaignsLoaded([campaign])) {
            $0.hasLoaded = true
            $0.campaigns = [closedCampaign]
        }

        // Then
        await store.finish()
        #expect(store.state.campaigns == [closedCampaign])
        #expect(savedCampaigns.value == [closedCampaign])
    }

    /// 切換開團狀態先寫入，成功後才更新清單
    @Test
    func statusChanged_更新開團狀態_寫入後更新清單狀態() async {
        // Given
        let campaign = makeCampaign(
            id: "C1",
            name: "團",
            status: .ongoing,
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]

        let savedCampaigns = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.campaignService.saveCampaign = { savedCampaign in
                savedCampaigns.withValue {
                    $0.append(savedCampaign)
                }
            }
        }

        // When
        await store.send(.statusChanged("C1", .closed))

        // Then
        await store.receive(\.campaignStatusSaved) {
            $0.campaigns[0].status = .closed
        }
        await store.finish()
        var expectedCampaign = campaign
        expectedCampaign.status = .closed
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 未結算的開團按下結團時，先呈現點明無法改回的確認對話框，不直接寫入
    @Test
    func settleTapped_未結算開團_呈現結團確認() async {
        // Given
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
        }

        // When
        await store.send(.settleTapped("C1")) {
            $0.settleConfirmation = Self.settleAlert(id: "C1", name: "團")
        }

        // Then
        #expect(store.state.settleConfirmation == Self.settleAlert(id: "C1", name: "團"))
    }

    /// 確認結團後先寫入結算日期，寫入成功才套用到清單，開團狀態維持不變
    @Test
    func settleConfirmation_確認結算開團_記錄結算日期且不改狀態() async {
        // Given
        let campaign = makeCampaign(
            id: "C1",
            name: "團",
            status: .closed,
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.settleConfirmation = Self.settleAlert(id: "C1", name: "團")

        let savedCampaigns = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.campaignService.saveCampaign = { savedCampaign in
                savedCampaigns.withValue {
                    $0.append(savedCampaign)
                }
            }
        }

        // When
        await store.send(.settleConfirmation(.presented(.confirmSettle("C1")))) {
            $0.settleConfirmation = nil
        }

        // Then
        await store.receive(\.settleConfirmed)
        // settleConfirmed 送出寫入 effect，寫入成功後 campaignSettled 才套用結算日期
        await store.receive(\.campaignSettled) {
            $0.campaigns[0].settledDate = TestDependencies.fixedNow
        }
        #expect(store.state.campaigns[0].status == .closed, "結團不應改變狀態")
        await store.finish()
        var expectedCampaign = campaign
        expectedCampaign.settledDate = TestDependencies.fixedNow
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 點選刪除開團時，呈現包含資料影響說明的確認對話框
    @Test
    func deleteCampaignTapped_清單中的開團_呈現刪除確認() async {
        // Given
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
        }

        // When
        await store.send(.deleteCampaignTapped("C1")) {
            $0.deletionConfirmation = Self.deletionAlert(id: "C1", name: "團")
        }

        // Then
        #expect(store.state.deletionConfirmation == Self.deletionAlert(id: "C1", name: "團"))
    }

    /// 確認刪除後刪除開團並從清單移除
    @Test
    func deletionConfirmation_確認刪除開團_從清單移除() async {
        // Given
        let campaign = makeCampaign(
            id: "C1",
            name: "團",
            status: .ongoing,
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.deletionConfirmation = Self.deletionAlert(id: "C1", name: "團")

        let removedCampaignIDs = LockIsolated<[String]>([])
        let removedCampaignNames = LockIsolated<[String]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.campaignService.removeCampaign = { id, name in
                removedCampaignIDs.withValue {
                    $0.append(id)
                }
                removedCampaignNames.withValue {
                    $0.append(name)
                }
                return nil
            }
        }

        // When
        await store.send(.deletionConfirmation(.presented(.confirmDelete("C1")))) {
            $0.deletionConfirmation = nil
        }

        // Then
        await store.receive(\.campaignDeleteRequested)
        await store.receive(\.campaignDeleted) {
            $0.campaigns = []
        }
        await store.finish()
        #expect(removedCampaignIDs.value == ["C1"])
        #expect(removedCampaignNames.value == ["團"])
    }

    /// 切換只看未收款時，篩選旗標改成新值，不觸發任何後續動作
    ///
    /// - Parameter isEnabled: 篩選開關的新狀態
    @Test(arguments: [true, false])
    func unpaidOnlyToggled_切換篩選開關_更新只看未收款篩選(isEnabled: Bool) async {
        // Given
        var initial = CampaignFeature.State()
        initial.showsUnpaidOnly = !isEnabled
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.unpaidOnlyToggled(isEnabled)) {
            $0.showsUnpaidOnly = isEnabled
        }

        // Then
        #expect(store.state.showsUnpaidOnly == isEnabled)
    }

    /// 按下新增開團時開啟空白表單，提醒預設當天上午 9 點
    @Test
    func newCampaignTapped_點選新增開團_呈現空白表單() async {
        // Given
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
        }

        // When
        await store.send(.newCampaignTapped) {
            $0.editCampaign = CampaignEditFeature.State(
                id: UUID(0),
                currentDate: TestDependencies.fixedNow,
                reminderTimestamp: day(month: 4, day: 30).addingTimeInterval(9 * 3600)
            )
        }

        // Then
        #expect(
            store.state.editCampaign?.draft.reminderTimestamp
                == day(month: 4, day: 30).addingTimeInterval(9 * 3600)
        )
    }

    /// 新名稱去掉前後空白後與既有開團相同時顯示重名原因，不寫入也不要求行事曆權限
    ///
    /// - Note: `testValue` 的 `campaignService.saveCampaign` 與
    ///   `calendarReminderService.requestAccess` 都是 `unimplemented`；重名時誤寫入或要求
    ///   行事曆權限會使測試失敗
    @Test
    func editCampaign_新增名稱與既有開團重複_拒絕寫入() async {
        // Given
        let existing = makeCampaign(
            id: "C1",
            name: "母親節團",
            status: .ongoing,
            closeDate: nil
        )
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            // 開啟提醒；若守門失效應觸發行事曆呼叫
            wantsReminder: true,
            reminderTimestamp: TestDependencies.fixedNow
        )
        // 前後空白不應影響比對：去掉前後空白後與既有開團同名
        editState.draft.name = "  母親節團  "
        var initial = CampaignFeature.State()
        initial.campaigns = [existing]
        initial.editCampaign = editState

        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign?.nameConflictMessage = "已有其他開團使用這個名稱，請改用不同名稱。"
        }

        // Then
        #expect(store.state.editCampaign?.nameConflictMessage == "已有其他開團使用這個名稱，請改用不同名稱。")
    }

    /// 編輯既有開團沒改名時直接儲存並關閉表單
    @Test
    func editCampaign_編輯時保留原開團名稱_成功儲存() async {
        // Given
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

        // 沒有結單日的舊開團，儲存草稿會以目前日期填入
        let expectedCampaign = Campaign(
            id: "C1",
            name: "四月團",
            openDate: existing.openDate,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = { campaign in
                savedCampaigns.withValue {
                    $0.append(campaign)
                }
            }
        }

        // When
        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }

        // Then
        await store.receive(\.campaignSaved) {
            $0.campaigns[0] = expectedCampaign
        }
        await store.finish()
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 資料原本就有同名開團時，沒改名仍可儲存且不清理重名
    @Test
    func editCampaign_既有資料已有同名開團_未改名仍可儲存() async {
        // Given
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

        // 沒有結單日的舊開團，儲存草稿會以目前日期填入
        let expectedCampaign = Campaign(
            id: "A",
            name: "重複團",
            openDate: campaignA.openDate,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = { campaign in
                savedCampaigns.withValue {
                    $0.append(campaign)
                }
            }
        }

        // When
        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }

        // Then
        await store.receive(\.campaignSaved) {
            $0.campaigns[0] = expectedCampaign
        }
        await store.finish()
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 切換是否提醒時，草稿的提醒開關跟著改變
    ///
    /// - Parameter wantsReminder: 草稿是否要建立提醒
    /// - Note: 此測試守住 `BindingReducer()` 的 binding 接線
    @Test(arguments: [true, false])
    func binding_切換提醒意圖_更新草稿提醒開關(wantsReminder: Bool) async {
        // Given
        let store = TestStore(
            initialState: CampaignEditFeature.State(
                id: UUID(0),
                currentDate: TestDependencies.fixedNow,
                wantsReminder: !wantsReminder,
                reminderTimestamp: day(month: 4, day: 20).addingTimeInterval(9 * 3600)
            )
        ) {
            CampaignEditFeature()
        }

        // When
        await store.send(.binding(.set(\.draft.wantsReminder, wantsReminder))) {
            $0.draft.wantsReminder = wantsReminder
        }

        // Then
        #expect(store.state.draft.wantsReminder == wantsReminder)
    }

    /// 修改提醒時間時，草稿的提醒時間跟著改變
    ///
    /// - Note: 此測試守住 `BindingReducer()` 的 binding 接線
    @Test
    func binding_修改提醒時間_更新草稿提醒時間() async {
        // Given
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

        // When
        await store.send(.binding(.set(\.draft.reminderTimestamp, picked))) {
            $0.draft.reminderTimestamp = picked
        }

        // Then
        #expect(store.state.draft.reminderTimestamp == picked)
    }

    /// 提醒連結載入完成時整份存進畫面狀態
    @Test
    func reminderLinksLoaded_載入提醒連結_保存連結清單() async {
        // Given
        let link = CampaignReminderLink(
            eventIdentifier: "EVT-1",
            reminderTimestamp: day(month: 4, day: 20).addingTimeInterval(9 * 3600)
        )
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        }

        // When
        await store.send(.reminderLinksLoaded(["C1": link])) {
            $0.reminderLinks = ["C1": link]
        }

        // Then
        #expect(store.state.reminderLinks == ["C1": link])
    }

    /// 行事曆權限被拒時開團照常儲存，顯示前往設定的提示，不存連結
    @Test
    func editCampaign_行事曆權限遭拒_顯示提示且不保存連結() async {
        // Given
        let newID = UUID(2)
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: true,
            reminderTimestamp: day(month: 4, day: 20).addingTimeInterval(9 * 3600)
        )
        editState.draft.name = "新團"
        var initial = CampaignFeature.State()
        initial.editCampaign = editState

        let expectedCampaign = Campaign(
            id: newID.uuidString,
            name: "新團",
            openDate: TestDependencies.fixedNow,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(newID)
            $0.campaignService.saveCampaign = { campaign in
                savedCampaigns.withValue {
                    $0.append(campaign)
                }
            }
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
            $0.campaigns = [expectedCampaign]
        }
        await store.receive(\.reminderAccessDenied) {
            $0.noticeAlert = AlertState {
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
        #expect(store.state.reminderLinks[newID.uuidString] == nil)
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 新增開團並開啟提醒時，依所選日期建全天事件、依所選時間設提示並存連結
    @Test
    func editCampaign_新增開團並啟用提醒_以指定時間建立提醒() async {
        // Given
        let newID = UUID(1)
        // 使用者在彈出式選單選 4/20 18:00
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

        let expectedCampaign = Campaign(
            id: newID.uuidString,
            name: "新團",
            openDate: TestDependencies.fixedNow,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let expectedLink = CampaignReminderLink(
            eventIdentifier: "EVT-new",
            reminderTimestamp: chosen
        )
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let savedLinkIDs = LockIsolated<[String]>([])
        let savedLinks = LockIsolated<[CampaignReminderLink]>([])
        let savedReminderTitles = LockIsolated<[String]>([])
        let savedAlarmOffsets = LockIsolated<[TimeInterval]>([])
        let savedEventDates = LockIsolated<[Date]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(newID)
            $0.campaignService.saveCampaign = { campaign in
                savedCampaigns.withValue {
                    $0.append(campaign)
                }
            }
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = { title, date, offset in
                savedReminderTitles.withValue {
                    $0.append(title)
                }
                savedEventDates.withValue {
                    $0.append(date)
                }
                savedAlarmOffsets.withValue {
                    $0.append(offset)
                }
                return "EVT-new"
            }
            $0.campaignReminderService.saveLink = { campaignID, link in
                savedLinkIDs.withValue {
                    $0.append(campaignID)
                }
                savedLinks.withValue {
                    $0.append(link)
                }
            }
        }

        // When
        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }

        // Then
        await store.receive(\.campaignSaved) {
            $0.campaigns = [expectedCampaign]
        }
        await store.receive(\.reminderStored) {
            $0.reminderLinks[newID.uuidString] = expectedLink
        }
        await store.finish()
        #expect(savedReminderTitles.value == ["「新團」訂購提醒"])
        #expect(savedEventDates.value == [day(month: 4, day: 20)])
        #expect(savedAlarmOffsets.value == [18 * 60 * 60])
        #expect(savedCampaigns.value == [expectedCampaign])
        #expect(savedLinkIDs.value == [newID.uuidString])
        #expect(savedLinks.value == [expectedLink])
    }

    /// 編輯時關掉提醒會刪除行事曆事件與連結
    @Test
    func editCampaign_既有開團清除提醒意圖_移除提醒() async {
        // Given
        let campaign = makeCampaign(
            id: "C1",
            name: "四月團",
            status: .ongoing,
            closeDate: nil
        )
        let editState = CampaignEditFeature.State(
            original: campaign,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: false,
            reminderTimestamp: day(month: 4, day: 20).addingTimeInterval(9 * 3600)
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.reminderLinks = [
            "C1": CampaignReminderLink(
                eventIdentifier: "EVT-1",
                reminderTimestamp: day(month: 4, day: 20).addingTimeInterval(9 * 3600)
            ),
        ]
        initial.editCampaign = editState

        let expectedCampaign = Campaign(
            id: "C1",
            name: "四月團",
            openDate: campaign.openDate,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let removedLinkIDs = LockIsolated<[String]>([])
        let removedEventIDs = LockIsolated<[String]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = { savedCampaign in
                savedCampaigns.withValue {
                    $0.append(savedCampaign)
                }
            }
            $0.calendarReminderService.removeReminder = { eventID in
                removedEventIDs.withValue {
                    $0.append(eventID)
                }
            }
            $0.campaignReminderService.removeLink = { campaignID in
                removedLinkIDs.withValue {
                    $0.append(campaignID)
                }
            }
        }

        // When
        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }

        // Then
        await store.receive(\.campaignSaved) {
            $0.campaigns[0] = expectedCampaign
        }
        await store.receive(\.reminderStored) {
            $0.reminderLinks["C1"] = nil
        }
        await store.finish()
        #expect(savedCampaigns.value == [expectedCampaign])
        #expect(removedLinkIDs.value == ["C1"])
        #expect(removedEventIDs.value == ["EVT-1"])
    }

    /// 改名時訂單跟著改名，並以新名稱建立新提醒、移除舊提醒
    ///
    /// - Note: 建新後才刪舊的順序由 `CampaignReminderFailureTests` 的
    ///   `editCampaign_建立新事件成功_之後才移除舊事件()` 守住
    @Test
    func editCampaign_既有開團名稱變更_重建提醒() async {
        // Given
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
            "C1": CampaignReminderLink(eventIdentifier: "EVT-old", reminderTimestamp: timestamp),
        ]
        initial.editCampaign = editState

        let expectedCampaign = Campaign(
            id: "C1",
            name: "新團名",
            openDate: campaign.openDate,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let expectedLink = CampaignReminderLink(
            eventIdentifier: "EVT-new",
            reminderTimestamp: timestamp
        )
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let savedLinkIDs = LockIsolated<[String]>([])
        let savedLinks = LockIsolated<[CampaignReminderLink]>([])
        let removedOldIdentifiers = LockIsolated<[String]>([])
        let renamedFromCampaignNames = LockIsolated<[String]>([])
        let renamedToCampaignNames = LockIsolated<[String]>([])
        let savedReminderTitles = LockIsolated<[String]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = { savedCampaign in
                savedCampaigns.withValue {
                    $0.append(savedCampaign)
                }
            }
            $0.orderService.renameOrderCampaign = { oldName, newName in
                renamedFromCampaignNames.withValue {
                    $0.append(oldName)
                }
                renamedToCampaignNames.withValue {
                    $0.append(newName)
                }
            }
            $0.calendarReminderService.removeReminder = { identifier in
                removedOldIdentifiers.withValue {
                    $0.append(identifier)
                }
            }
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = { title, _, _ in
                savedReminderTitles.withValue {
                    $0.append(title)
                }
                return "EVT-new"
            }
            $0.campaignReminderService.saveLink = { campaignID, link in
                savedLinkIDs.withValue {
                    $0.append(campaignID)
                }
                savedLinks.withValue {
                    $0.append(link)
                }
            }
        }

        // When
        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }

        // Then
        await store.receive(\.campaignSaved) {
            $0.campaigns[0] = expectedCampaign
        }
        await store.receive(\.campaignRenamed)
        await store.receive(\.reminderStored) {
            $0.reminderLinks["C1"] = expectedLink
        }
        await store.finish()
        #expect(removedOldIdentifiers.value == ["EVT-old"])
        #expect(renamedFromCampaignNames.value == ["舊團名"])
        #expect(renamedToCampaignNames.value == ["新團名"])
        #expect(savedReminderTitles.value == ["「新團名」訂購提醒"])
        #expect(savedCampaigns.value == [expectedCampaign])
        #expect(savedLinkIDs.value == ["C1"])
        #expect(savedLinks.value == [expectedLink])
    }

    /// 改提醒時間時以新時間建立新提醒、移除舊提醒
    ///
    /// - Note: 建新後才刪舊的順序由 `CampaignReminderFailureTests` 的
    ///   `editCampaign_建立新事件成功_之後才移除舊事件()` 守住
    @Test
    func editCampaign_提醒時間變更_重建提醒() async {
        // Given
        let campaign = makeCampaign(
            id: "C1",
            name: "四月團",
            status: .ongoing,
            closeDate: day(month: 4, day: 20)
        )
        let oldTimestamp = day(month: 4, day: 20).addingTimeInterval(9 * 3600)
        let newTimestamp = day(month: 4, day: 26).addingTimeInterval(18 * 3600)
        let editState = CampaignEditFeature.State(
            original: campaign,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: true,
            reminderTimestamp: newTimestamp
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.reminderLinks = [
            "C1": CampaignReminderLink(eventIdentifier: "EVT-old", reminderTimestamp: oldTimestamp),
        ]
        initial.editCampaign = editState

        let expectedCampaign = Campaign(
            id: "C1",
            name: "四月團",
            openDate: campaign.openDate,
            closeDate: day(month: 4, day: 20),
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let expectedLink = CampaignReminderLink(
            eventIdentifier: "EVT-new",
            reminderTimestamp: newTimestamp
        )
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let savedLinkIDs = LockIsolated<[String]>([])
        let savedLinks = LockIsolated<[CampaignReminderLink]>([])
        let savedReminderTitles = LockIsolated<[String]>([])
        let removedOldIdentifiers = LockIsolated<[String]>([])
        let savedAlarmOffsets = LockIsolated<[TimeInterval]>([])
        let savedEventDates = LockIsolated<[Date]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = { savedCampaign in
                savedCampaigns.withValue {
                    $0.append(savedCampaign)
                }
            }
            $0.calendarReminderService.removeReminder = { identifier in
                removedOldIdentifiers.withValue {
                    $0.append(identifier)
                }
            }
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = { title, date, offset in
                savedReminderTitles.withValue {
                    $0.append(title)
                }
                savedEventDates.withValue {
                    $0.append(date)
                }
                savedAlarmOffsets.withValue {
                    $0.append(offset)
                }
                return "EVT-new"
            }
            $0.campaignReminderService.saveLink = { campaignID, link in
                savedLinkIDs.withValue {
                    $0.append(campaignID)
                }
                savedLinks.withValue {
                    $0.append(link)
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
            $0.reminderLinks["C1"] = expectedLink
        }
        await store.finish()
        #expect(removedOldIdentifiers.value == ["EVT-old"])
        #expect(savedEventDates.value == [day(month: 4, day: 26)])
        #expect(savedAlarmOffsets.value == [18 * 60 * 60])
        #expect(savedReminderTitles.value == ["「四月團」訂購提醒"])
        #expect(savedCampaigns.value == [expectedCampaign])
        #expect(savedLinkIDs.value == ["C1"])
        #expect(savedLinks.value == [expectedLink])
    }

    /// 新增開團儲存失敗時表單照樣關閉、清單不新增，並跳出儲存失敗提示
    @Test
    func editCampaign_儲存開團失敗_不加入清單() async {
        // Given
        let newID = UUID(1)
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        editState.draft.name = "新團"
        var initial = CampaignFeature.State()
        initial.editCampaign = editState

        let expectedCampaign = Campaign(
            id: newID.uuidString,
            name: "新團",
            openDate: TestDependencies.fixedNow,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let failingSave: CampaignService.SaveCampaign = { campaign in
            savedCampaigns.withValue {
                $0.append(campaign)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(newID)
            $0.campaignService.saveCampaign = failingSave
        }

        // When
        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }

        // Then
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("開團儲存失敗，請稍後再試。")
        }
        #expect(store.state.campaigns.isEmpty, "寫入失敗不應插入開團")
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 改開團狀態寫入失敗時清單維持原狀態，並跳出更新失敗提示
    @Test
    func statusChanged_更新開團狀態失敗_保留原狀態() async {
        // Given
        let campaign = makeCampaign(
            id: "C1",
            name: "團",
            status: .ongoing,
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]

        var expectedCampaign = campaign
        expectedCampaign.status = .closed
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let failingSave: CampaignService.SaveCampaign = { savedCampaign in
            savedCampaigns.withValue {
                $0.append(savedCampaign)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.campaignService.saveCampaign = failingSave
        }

        // When
        await store.send(.statusChanged("C1", .closed))

        // Then
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("開團狀態更新失敗，請稍後再試。")
        }
        #expect(store.state.campaigns == [campaign], "寫入失敗應維持先前開團資料")
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 確認結團後寫入失敗，開團不記錄結算日期，並跳出結團失敗提示
    @Test
    func settleConfirmation_確認結團且寫入失敗_維持未結算狀態() async {
        // Given
        let campaign = makeCampaign(
            id: "C1",
            name: "團",
            status: .closed,
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.settleConfirmation = Self.settleAlert(id: "C1", name: "團")

        var expectedCampaign = campaign
        expectedCampaign.settledDate = TestDependencies.fixedNow
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let failingSave: CampaignService.SaveCampaign = { savedCampaign in
            savedCampaigns.withValue {
                $0.append(savedCampaign)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.campaignService.saveCampaign = failingSave
        }

        // When
        await store.send(.settleConfirmation(.presented(.confirmSettle("C1")))) {
            $0.settleConfirmation = nil
        }

        // Then
        await store.receive(\.settleConfirmed)
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("結團失敗，請稍後再試。")
        }
        #expect(store.state.campaigns == [campaign], "寫入失敗不應套用結算資料")
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 確認刪除後寫入失敗，開團仍留在清單，並跳出刪除失敗提示
    @Test
    func deletionConfirmation_刪除寫入失敗_保留清單項目() async {
        // Given
        let campaign = makeCampaign(
            id: "C1",
            name: "團",
            status: .ongoing,
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.deletionConfirmation = Self.deletionAlert(id: "C1", name: "團")

        let removedCampaignIDs = LockIsolated<[String]>([])
        let removedCampaignNames = LockIsolated<[String]>([])
        let failingRemove: CampaignService.RemoveCampaign = { id, name in
            removedCampaignIDs.withValue {
                $0.append(id)
            }
            removedCampaignNames.withValue {
                $0.append(name)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.campaignService.removeCampaign = failingRemove
        }

        // When
        await store.send(.deletionConfirmation(.presented(.confirmDelete("C1")))) {
            $0.deletionConfirmation = nil
        }

        // Then
        await store.receive(\.campaignDeleteRequested)
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("開團刪除失敗，請稍後再試。")
        }
        #expect(store.state.campaigns == [campaign])
        #expect(removedCampaignIDs.value == ["C1"])
        #expect(removedCampaignNames.value == ["團"])
    }

    /// 刪除有提醒的開團時連結一起清掉，並以連結記錄的事件識別碼移除行事曆事件一次
    @Test
    func deletionConfirmation_刪除含提醒開團_移除連結與行事曆事件() async {
        // Given
        let campaign = makeCampaign(
            id: "C1",
            name: "團",
            status: .ongoing,
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.deletionConfirmation = Self.deletionAlert(id: "C1", name: "團")
        initial.reminderLinks = [
            "C1": CampaignReminderLink(
                eventIdentifier: "EVT-1",
                reminderTimestamp: TestDependencies.fixedNow
            ),
        ]

        let removedCampaignIDs = LockIsolated<[String]>([])
        let removedCampaignNames = LockIsolated<[String]>([])
        let removedEventIdentifiers = LockIsolated<[String]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.campaignService.removeCampaign = { id, name in
                removedCampaignIDs.withValue {
                    $0.append(id)
                }
                removedCampaignNames.withValue {
                    $0.append(name)
                }
                return "EVT-1"
            }
            $0.calendarReminderService.removeReminder = { identifier in
                removedEventIdentifiers.withValue {
                    $0.append(identifier)
                }
            }
        }

        // When
        await store.send(.deletionConfirmation(.presented(.confirmDelete("C1")))) {
            $0.deletionConfirmation = nil
        }

        // Then
        await store.receive(\.campaignDeleteRequested)
        await store.receive(\.campaignDeleted) {
            $0.campaigns = []
            $0.reminderLinks["C1"] = nil
        }
        await store.finish()
        #expect(removedCampaignIDs.value == ["C1"])
        #expect(removedCampaignNames.value == ["團"])
        #expect(removedEventIdentifiers.value == ["EVT-1"], "刪除應以連結記錄的事件識別碼呼叫一次 removeReminder")
    }

    /// 開團已刪除但行事曆事件移除失敗時，開團不回到清單，並提示使用者自行到行事曆刪除
    @Test
    func deletionConfirmation_移除行事曆事件失敗_不還原已刪開團() async {
        // Given
        let campaign = makeCampaign(
            id: "C1",
            name: "團",
            status: .ongoing,
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.deletionConfirmation = Self.deletionAlert(id: "C1", name: "團")
        initial.reminderLinks = [
            "C1": CampaignReminderLink(
                eventIdentifier: "EVT-1",
                reminderTimestamp: TestDependencies.fixedNow
            ),
        ]

        let removedCampaignIDs = LockIsolated<[String]>([])
        let removedCampaignNames = LockIsolated<[String]>([])
        let removedEventIdentifiers = LockIsolated<[String]>([])
        let failingRemoveReminder: CalendarReminderService.RemoveReminder = { identifier in
            removedEventIdentifiers.withValue {
                $0.append(identifier)
            }
            throw .system(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.campaignService.removeCampaign = { id, name in
                removedCampaignIDs.withValue {
                    $0.append(id)
                }
                removedCampaignNames.withValue {
                    $0.append(name)
                }
                return "EVT-1"
            }
            $0.calendarReminderService.removeReminder = failingRemoveReminder
        }

        // When
        await store.send(.deletionConfirmation(.presented(.confirmDelete("C1")))) {
            $0.deletionConfirmation = nil
        }

        // Then
        await store.receive(\.campaignDeleteRequested)
        await store.receive(\.campaignDeleted) {
            $0.campaigns = []
            $0.reminderLinks["C1"] = nil
        }
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("開團已刪除，但行事曆上的提醒事件移除失敗，請自行到行事曆刪除。")
        }
        #expect(removedCampaignIDs.value == ["C1"])
        #expect(removedCampaignNames.value == ["團"])
        #expect(removedEventIdentifiers.value == ["EVT-1"])
    }

    /// 沒有打開開團明細時，寫入失敗提示顯示在列表層
    @Test
    func statusChanged_未選取開團且列表操作失敗_呈現列表通知() async {
        // Given
        let campaign = makeCampaign(
            id: "C1",
            name: "團",
            status: .ongoing,
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]

        let failingSave: CampaignService.SaveCampaign = { _ in
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.campaignService.saveCampaign = failingSave
        }

        // When
        await store.send(.statusChanged("C1", .closed))

        // Then
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("開團狀態更新失敗，請稍後再試。")
        }
    }

    /// 正在看開團明細時，寫入失敗提示顯示在明細層
    @Test
    func statusChanged_已選取開團且明細操作失敗_呈現明細通知() async {
        // Given
        let campaign = makeCampaign(
            id: "C1",
            name: "團",
            status: .ongoing,
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.selectedCampaignID = "C1"

        let failingSave: CampaignService.SaveCampaign = { _ in
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.campaignService.saveCampaign = failingSave
        }

        // When
        await store.send(.statusChanged("C1", .closed))

        // Then
        await store.receive(\.campaignWriteFailed) {
            $0.detailNoticeAlert = Self.failureAlert("開團狀態更新失敗，請稍後再試。")
        }
    }

    /// 儲存失敗後重新載入，畫面仍呈現唯讀資料庫中的開團
    ///
    /// - Throws: 建立暫存目錄或 SwiftData 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
    @Test
    func task_開團儲存失敗後重新載入_呈現清單一致() async throws(any Error) {
        // Given
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
        let fixture = try await Self.makeReloadConsistencyDatabase(seeding: [existing])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let store = Self.makeReloadConsistencyStore(
            initialState: initial,
            database: fixture.database,
            write: .create
        )

        await store.send(.editCampaign(.presented(.saveTapped))) {
            $0.editCampaign = nil
        }
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("開團儲存失敗，請稍後再試。")
        }

        // When
        await store.send(.task) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.campaignsLoaded) {
            $0.hasLoaded = true
            $0.isLoading = false
            $0.campaigns = [existing]
        }
        await store.receive(\.reminderLinksLoaded)
    }

    /// 開團狀態寫入失敗後重新載入，畫面仍呈現唯讀資料庫中的開團
    ///
    /// - Throws: 建立暫存目錄或 SwiftData 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
    @Test
    func task_開團狀態寫入失敗後重新載入_呈現清單一致() async throws(any Error) {
        // Given
        let campaign = makeCampaign(
            id: "C1",
            name: "團",
            status: .ongoing,
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        let fixture = try await Self.makeReloadConsistencyDatabase(seeding: [campaign])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let store = Self.makeReloadConsistencyStore(
            initialState: initial,
            database: fixture.database,
            write: .save
        )

        await store.send(.statusChanged("C1", .closed))
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("開團狀態更新失敗，請稍後再試。")
        }

        // When
        await store.send(.task) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.campaignsLoaded) {
            $0.hasLoaded = true
            $0.isLoading = false
            $0.campaigns = [campaign]
        }
        await store.receive(\.reminderLinksLoaded)
    }

    /// 開團結算失敗後重新載入，畫面仍呈現唯讀資料庫中的開團
    ///
    /// - Throws: 建立暫存目錄或 SwiftData 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
    @Test
    func task_開團結算失敗後重新載入_呈現清單一致() async throws(any Error) {
        // Given
        let campaign = makeCampaign(
            id: "C1",
            name: "團",
            status: .closed,
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.settleConfirmation = Self.settleAlert(id: "C1", name: "團")
        let fixture = try await Self.makeReloadConsistencyDatabase(seeding: [campaign])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let store = Self.makeReloadConsistencyStore(
            initialState: initial,
            database: fixture.database,
            write: .save
        )

        await store.send(.settleConfirmation(.presented(.confirmSettle("C1")))) {
            $0.settleConfirmation = nil
        }
        await store.receive(\.settleConfirmed)
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("結團失敗，請稍後再試。")
        }

        // When
        await store.send(.task) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.campaignsLoaded) {
            $0.hasLoaded = true
            $0.isLoading = false
            $0.campaigns = [campaign]
        }
        await store.receive(\.reminderLinksLoaded)
    }

    /// 開團列表刪除失敗後重新載入，畫面仍呈現唯讀資料庫中的開團
    ///
    /// - Throws: 建立暫存目錄或 SwiftData 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
    @Test
    func task_開團列表刪除失敗後重新載入_呈現清單一致() async throws(any Error) {
        // Given
        let campaign = makeCampaign(
            id: "C1",
            name: "團",
            status: .ongoing,
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.deletionConfirmation = Self.deletionAlert(id: "C1", name: "團")
        let fixture = try await Self.makeReloadConsistencyDatabase(seeding: [campaign])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let store = Self.makeReloadConsistencyStore(
            initialState: initial,
            database: fixture.database,
            write: .remove
        )

        await store.send(.deletionConfirmation(.presented(.confirmDelete("C1")))) {
            $0.deletionConfirmation = nil
        }
        await store.receive(\.campaignDeleteRequested)
        await store.receive(\.campaignWriteFailed) {
            $0.noticeAlert = Self.failureAlert("開團刪除失敗，請稍後再試。")
        }

        // When
        await store.send(.task) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.campaignsLoaded) {
            $0.hasLoaded = true
            $0.isLoading = false
            $0.campaigns = [campaign]
        }
        await store.receive(\.reminderLinksLoaded)
    }

    /// 明細刪除失敗後重新載入，畫面仍呈現唯讀資料庫中的開團
    ///
    /// - Throws: 建立暫存目錄或 SwiftData 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
    @Test
    func task_明細刪除失敗後重新載入_呈現清單一致() async throws(any Error) {
        // Given
        let campaign = makeCampaign(
            id: "C1",
            name: "團",
            status: .ongoing,
            closeDate: nil
        )
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]
        initial.selectedCampaignID = "C1"
        initial.detailDeletionConfirmation = Self.deletionAlert(id: "C1", name: "團")
        let fixture = try await Self.makeReloadConsistencyDatabase(seeding: [campaign])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let store = Self.makeReloadConsistencyStore(
            initialState: initial,
            database: fixture.database,
            write: .remove
        )

        await store.send(.detailDeletionConfirmation(.presented(.confirmDelete("C1")))) {
            $0.detailDeletionConfirmation = nil
        }
        await store.receive(\.campaignDeleteRequested)
        await store.receive(\.campaignWriteFailed) {
            $0.detailNoticeAlert = Self.failureAlert("開團刪除失敗，請稍後再試。")
        }

        // When
        await store.send(.task) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.campaignsLoaded) {
            $0.hasLoaded = true
            $0.isLoading = false
            $0.campaigns = [campaign]
        }
        await store.receive(\.reminderLinksLoaded)
    }

    /// 收款狀態切換只送出 `delegate`，不直接修改 `State.orders`
    @Test
    func receiptStatusToggled_切換收款狀態_送出委派且不改本地狀態() async {
        // Given
        let order = LedgerOrder.fixture(id: "O1", campaignNames: ["四月團"])
        var initial = CampaignFeature.State()
        initial.orders = [order]

        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.receiptStatusToggled("O1", .received))

        // Then
        await store.receive(\.delegate.receiptStatusToggled)
        #expect(store.state.orders == [order])
    }
}

// MARK: - Nested Types

private extension CampaignFeatureTests {

    /// 指定重新載入前要觸發的失敗寫入操作
    enum ReloadConsistencyWrite: Sendable {

        /// 新增開團
        case create

        /// 寫入既有開團
        case save

        /// 移除既有開團
        case remove
    }
}

// MARK: - Private Method

private extension CampaignFeatureTests {

    /// 建立結團確認對話框
    ///
    /// - Parameters:
    ///   - id: 要結團的開團識別碼
    ///   - name: 要結團的開團名稱
    /// - Returns: 結團提示狀態
    static func settleAlert(
        id: Campaign.ID,
        name: String
    ) -> AlertState<CampaignFeature.Action.SettleAlert> {
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

    /// 建立刪除確認對話框
    ///
    /// - Parameters:
    ///   - id: 要刪除的開團識別碼
    ///   - name: 要刪除的開團名稱
    /// - Returns: 刪除提示狀態
    static func deletionAlert(
        id: Campaign.ID,
        name: String
    ) -> AlertState<CampaignFeature.Action.Alert> {
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

    /// 建立寫入失敗提示
    ///
    /// - Parameter message: 要顯示的錯誤訊息
    /// - Returns: 錯誤提示狀態
    static func failureAlert(
        _ message: LocalizedStringKey
    ) -> AlertState<CampaignFeature.Action.NoticeAlert> {
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

    /// 建立含初始開團的 V17 唯讀資料庫
    ///
    /// - Parameter initialCampaigns: 要寫入資料庫的開團清單
    /// - Returns: 只能讀取的資料庫與專屬暫存目錄
    /// - Throws: 建立暫存目錄或 SwiftData 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
    static func makeReloadConsistencyDatabase(
        seeding initialCampaigns: [Campaign]
    ) async throws(any Error) -> (database: BuyLedgerDatabase, directoryURL: URL) {
        let directoryURL = FileManager.default.temporaryDirectory
            .appending(
                path: "BuyLedgerCampaignReloadTest-\(UUID().uuidString)",
                directoryHint: .isDirectory
            )
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        var isDirectoryTransferred = false
        defer {
            if !isDirectoryTransferred {
                BuyLedgerDatabaseTests.removeTemporaryDirectory(at: directoryURL)
            }
        }
        let storeURL = directoryURL.appending(
            path: "CampaignReload.store",
            directoryHint: .notDirectory
        )
        let schema = Schema(versionedSchema: BuyLedgerSchemaV17.self)
        let writableConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let writableContainer = try TestContainerCreationLock.withLock {
            try ModelContainer(
                for: schema,
                migrationPlan: BuyLedgerMigrationPlan.self,
                configurations: writableConfiguration
            )
        }
        let writableDatabase = BuyLedgerDatabase(
            modelContainer: writableContainer,
            storeLocation: .directory(directoryURL)
        )
        let campaignService = CampaignServiceTests.makeService(database: writableDatabase)
        for campaign in initialCampaigns {
            try await campaignService.saveCampaign(campaign)
        }

        let readOnlyConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: false,
            cloudKitDatabase: .none
        )
        let readOnlyContainer = try TestContainerCreationLock.withLock {
            try ModelContainer(
                for: schema,
                migrationPlan: BuyLedgerMigrationPlan.self,
                configurations: readOnlyConfiguration
            )
        }
        let database = BuyLedgerDatabase(
            modelContainer: readOnlyContainer,
            storeLocation: .directory(directoryURL)
        )
        isDirectoryTransferred = true
        return (database, directoryURL)
    }

    /// 建立只注入重新載入與指定失敗寫入的 `CampaignFeature` `TestStore`
    ///
    /// - Parameters:
    ///   - initialState: 測試開始時的 feature 狀態
    ///   - database: 重新載入與失敗寫入使用的唯讀資料庫
    ///   - write: 要注入的寫入操作
    /// - Returns: 使用唯讀資料庫依賴的 `TestStore`
    static func makeReloadConsistencyStore(
        initialState: CampaignFeature.State,
        database: any BuyLedgerDatabaseProtocol,
        write: ReloadConsistencyWrite
    ) -> TestStoreOf<CampaignFeature> {
        let campaignService = CampaignServiceTests.makeService(database: database)
        let reminderService = CampaignReminderServiceTests.makeService(database: database)

        return TestStore(initialState: initialState) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = campaignService.fetchCampaigns
            $0.campaignReminderService.fetchLinks = reminderService.fetchLinks
            switch write {
            case .create:
                $0.uuid = .incrementing
                $0.campaignService.saveCampaign = campaignService.saveCampaign

            case .save:
                $0.campaignService.saveCampaign = campaignService.saveCampaign

            case .remove:
                $0.campaignService.removeCampaign = campaignService.removeCampaign
            }
        }
    }

    /// 建立測試用開團
    ///
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

    /// 建立 2026 年指定月日的固定時間 (UTC)
    ///
    /// - Parameters:
    ///   - month: 月份
    ///   - day: 幾號
    /// - Returns: 指定日期
    func day(month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = .gmt
        components.year = 2026
        components.month = month
        components.day = day
        return components.date ?? Date(timeIntervalSince1970: 0)
    }
}
