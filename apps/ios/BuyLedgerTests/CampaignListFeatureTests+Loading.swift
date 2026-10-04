//
//  CampaignListFeatureTests+Loading.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignListFeatureTests {

    /// 首次載入被取消後，列表再次出現會重新讀取並結束載入狀態
    ///
    /// - Throws: 第一次讀取未開始時拋出測試錯誤
    /// - Note: 前置任務用來建立等待中的讀取 effect，再模擬畫面離開與再次出現
    @Test
    func view_首次載入取消後再次出現_重新載入兩筆開團() async throws(any Error) {
        // Given
        let campaigns = [
            Campaign.fixture(
                id: "C1",
                name: "第一團",
                closeDate: nil,
                status: .ongoing
            ),
            Campaign.fixture(
                id: "C2",
                name: "第二團",
                closeDate: nil,
                status: .ongoing
            ),
        ]
        let clock = TestClock()
        let calls = LockIsolated(0)
        let fetchCampaigns: CampaignService.FetchCampaigns = {
            @Dependency(\.continuousClock) var clock
            let call = calls.withValue {
                $0 += 1
                return $0
            }
            if call == 1 {
                do {
                    try await clock.sleep(for: .seconds(60))
                } catch {
                    throw .fetchFailed(underlying: error as NSError)
                }
            }
            return campaigns
        }
        let store = TestStore(initialState: Self.makeState()) {
            CampaignListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.continuousClock = clock
            $0.campaignService.fetchCampaigns = fetchCampaigns
        }
        let task = await store.send(.view(.task)) {
            $0.dateContext = CampaignDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.isLoading = true
        }
        await clock.advance()
        try #require(calls.value == 1)

        // When
        await task.cancel()
        await store.send(.view(.task))

        // Then
        await store.receive(\.campaignsResponse) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.$campaigns.withLock {
                $0 = campaigns
            }
        }
        await store.finish()
        #expect(calls.value == 2)
    }

    /// 載入沒有結單日的開團時維持進行中，也不寫回
    @Test
    func task_開團沒有結束日期_維持進行中狀態() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .ongoing
        )
        let store = TestStore(initialState: Self.makeState()) {
            CampaignListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                [campaign]
            }
        }

        // When
        await store.send(.view(.task)) {
            $0.dateContext = CampaignDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.isLoading = true
        }

        // Then
        await store.receive(\.campaignsResponse.success) {
            $0.hasLoaded = true
            $0.isLoading = false
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
        }
    }

    /// 結單日當天即使現在時間已晚於結單時間，載入後仍維持進行中，也不寫回
    @Test
    func task_今天為開團結束日期_仍維持進行中() async {
        // Given
        let closeDate = Date(timeIntervalSince1970: 1_777_539_600)
        let campaign = Campaign.fixture(
            id: "today",
            name: "今天團",
            closeDate: closeDate,
            status: .ongoing
        )
        let now = Date(timeIntervalSince1970: 1_777_561_200)
        let store = TestStore(initialState: Self.makeState()) {
            CampaignListFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                [campaign]
            }
        }

        // When
        await store.send(.view(.task)) {
            $0.dateContext = CampaignDateContext(now: now, calendar: TestDependencies.fixedCalendar)
            $0.isLoading = true
        }

        // Then
        await store.receive(\.campaignsResponse.success) {
            $0.hasLoaded = true
            $0.isLoading = false
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
        }
    }

    /// 注入不同時區後，結單日期仍以當地日曆判斷為今天
    ///
    /// - Parameter timeZoneIdentifier: 用來判斷當地日期的時區
    /// - Throws: 時區識別碼或日曆日期無法建立時拋出測試錯誤
    @Test(arguments: ["UTC", "Asia/Taipei", "America/Los_Angeles"])
    func task_注入時區後結束日為今天_維持進行中(timeZoneIdentifier: String) async throws(any Error) {
        // Given
        let timeZone = try #require(TimeZone(identifier: timeZoneIdentifier))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: TestDependencies.fixedNow)
        let closeDate = try #require(calendar.date(byAdding: .hour, value: 9, to: today))
        let now = try #require(calendar.date(byAdding: .hour, value: 15, to: today))
        let campaign = Campaign.fixture(
            id: "tz",
            name: "跨時區團",
            closeDate: closeDate,
            status: .ongoing
        )

        let store = TestStore(initialState: Self.makeState()) {
            CampaignListFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.calendar = calendar
            $0.campaignService.fetchCampaigns = {
                [campaign]
            }
        }

        // When
        await store.send(.view(.task)) {
            $0.dateContext = CampaignDateContext(now: now, calendar: calendar)
            $0.isLoading = true
        }

        // Then
        await store.receive(\.campaignsResponse.success) {
            $0.hasLoaded = true
            $0.isLoading = false
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
        }
    }
}
