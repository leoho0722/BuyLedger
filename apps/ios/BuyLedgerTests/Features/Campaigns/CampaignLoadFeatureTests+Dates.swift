//
//  CampaignLoadFeatureTests+Dates.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignLoadFeatureTests {

    /// 載入沒有結單日的開團時維持進行中，也不寫回
    @Test
    func loadRequested_開團沒有結束日期_維持進行中狀態() async {
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
        let store = TestStore(initialState: Self.makeState()) {
            CampaignLoadFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                [campaign]
            }
        }

        // When
        await store.send(.loadRequested) {
            $0.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.campaignsResponse.success) {
            $0.$hasLoaded.withLock {
                $0 = true
            }
            $0.$isLoading.withLock {
                $0 = false
            }
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
        }
    }

    /// 結單日當天即使現在時間已晚於結單時間，載入後仍維持進行中，也不寫回
    @Test
    func loadRequested_今天為開團結束日期_仍維持進行中() async {
        // Given
        let closeDate = Date(timeIntervalSince1970: 1_777_539_600)
        let campaign = Campaign(
            id: "today",
            name: "今天團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: closeDate,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let now = Date(timeIntervalSince1970: 1_777_561_200)
        let store = TestStore(initialState: Self.makeState()) {
            CampaignLoadFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                [campaign]
            }
        }

        // When
        await store.send(.loadRequested) {
            $0.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.campaignsResponse.success) {
            $0.$hasLoaded.withLock {
                $0 = true
            }
            $0.$isLoading.withLock {
                $0 = false
            }
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
    func loadRequested_注入時區後結束日為今天_維持進行中(timeZoneIdentifier: String) async throws {
        // Given
        let timeZone = try #require(TimeZone(identifier: timeZoneIdentifier))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: TestDependencies.fixedNow)
        let closeDate = try #require(calendar.date(byAdding: .hour, value: 9, to: today))
        let now = try #require(calendar.date(byAdding: .hour, value: 15, to: today))
        let campaign = Campaign(
            id: "tz",
            name: "跨時區團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: closeDate,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )

        let store = TestStore(initialState: Self.makeState()) {
            CampaignLoadFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.calendar = calendar
            $0.campaignService.fetchCampaigns = {
                [campaign]
            }
        }

        // When
        await store.send(.loadRequested) {
            $0.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.campaignsResponse.success) {
            $0.$hasLoaded.withLock {
                $0 = true
            }
            $0.$isLoading.withLock {
                $0 = false
            }
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
        }
    }
}
