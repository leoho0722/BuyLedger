//
//  CampaignLoadFeatureTests+AutoClose.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignLoadFeatureTests {

    /// 已過結單日的開團自動改為已結束並寫回，未到期的維持進行中
    @Test
    func loadRequested_目前日期晚於結束日期_自動轉為已結束() async {
        // Given
        let pastDue = Campaign.fixture(
            id: "past",
            name: "過期團",
            closeDate: Date(timeIntervalSince1970: 1_776_643_200),
            status: .ongoing
        )
        let future = Campaign(
            id: "future",
            name: "未到團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: Date(timeIntervalSince1970: 1_778_371_200),
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )

        let savedCampaigns = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: Self.makeState()) {
            CampaignLoadFeature()
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
        }

        let transitioned = Campaign(
            id: "past",
            name: "過期團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: Date(timeIntervalSince1970: 1_776_643_200),
            status: .closed,
            settledDate: nil,
            notes: ""
        )

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
                $0 = [transitioned, future]
            }
        }
        await store.receive(\.autoCloseResponse)
        await store.finish()
        #expect(savedCampaigns.value == [transitioned])
    }

    /// 隔日收到載入結果時，已過結單日的開團改為已結束並寫回
    @Test
    func campaignsResponse_隔日已超過結束日期_自動轉為已結束() async {
        // Given
        let closeDate = Date(timeIntervalSince1970: 1_777_539_600)
        let campaign = Campaign(
            id: "next-day",
            name: "隔日團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: closeDate,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let closedCampaign = Campaign(
            id: "next-day",
            name: "隔日團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: closeDate,
            status: .closed,
            settledDate: nil,
            notes: ""
        )
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: Self.makeState()) {
            CampaignLoadFeature()
        } withDependencies: {
            $0.date = .constant(Date(timeIntervalSince1970: 1_777_597_200))
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = { savedCampaign in
                savedCampaigns.withValue {
                    $0.append(savedCampaign)
                }
            }
        }

        // When
        await store.send(.campaignsResponse(.success([campaign]))) {
            $0.$hasLoaded.withLock {
                $0 = true
            }
            $0.$campaigns.withLock {
                $0 = [closedCampaign]
            }
        }

        // Then
        await store.receive(\.autoCloseResponse)
        await store.finish()
        #expect(store.state.campaigns == [closedCampaign])
        #expect(savedCampaigns.value == [closedCampaign])
    }

    /// 在注入時區的隔日載入已過結束日期的開團時自動結束
    ///
    /// - Parameter timeZoneIdentifier: 用來判斷當地日期的時區
    /// - Throws: 時區識別碼或日曆日期無法建立時拋出測試錯誤
    @Test(arguments: ["UTC", "Asia/Taipei", "America/Los_Angeles"])
    func campaignsResponse_注入時區後已過結束日期_自動轉為已結束(timeZoneIdentifier: String) async throws {
        // Given
        let timeZone = try #require(TimeZone(identifier: timeZoneIdentifier))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: TestDependencies.fixedNow)
        let closeDate = try #require(calendar.date(byAdding: .hour, value: 9, to: today))
        let nextDay = try #require(calendar.date(byAdding: .day, value: 1, to: today))
        let now = try #require(calendar.date(byAdding: .hour, value: 1, to: nextDay))
        let campaign = Campaign(
            id: "tz-next-day",
            name: "跨時區隔日團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: closeDate,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let closedCampaign = Campaign(
            id: "tz-next-day",
            name: "跨時區隔日團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: closeDate,
            status: .closed,
            settledDate: nil,
            notes: ""
        )
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: Self.makeState()) {
            CampaignLoadFeature()
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
        await store.send(.campaignsResponse(.success([campaign]))) {
            $0.$hasLoaded.withLock {
                $0 = true
            }
            $0.$campaigns.withLock {
                $0 = [closedCampaign]
            }
        }

        // Then
        await store.receive(\.autoCloseResponse)
        await store.finish()
        #expect(store.state.campaigns == [closedCampaign])
        #expect(savedCampaigns.value == [closedCampaign])
    }

    /// 自動結束的持久化失敗仍保留先更新的狀態，並請父層呈現通知
    @Test
    func campaignsResponse_自動結束寫入失敗_保留已結束狀態並委派失敗() async {
        // Given
        let overdue = Campaign.fixture(
            id: "C1",
            name: "過期團",
            closeDate: Date(timeIntervalSince1970: 1_776_643_200),
            status: .ongoing
        )
        let closed = Campaign(
            id: "C1",
            name: "過期團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: Date(timeIntervalSince1970: 1_776_643_200),
            status: .closed,
            settledDate: nil,
            notes: ""
        )
        let saves = LockIsolated<[Campaign]>([])
        let failingSave: CampaignService.SaveCampaign = { campaign in
            saves.withValue {
                $0.append(campaign)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: Self.makeState()) {
            CampaignLoadFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = failingSave
        }

        // When
        await store.send(.campaignsResponse(.success([overdue]))) {
            $0.$hasLoaded.withLock {
                $0 = true
            }
            $0.$campaigns.withLock {
                $0 = [closed]
            }
        }

        // Then
        await store.receive(\.autoCloseResponse)
        await store.receive(\.delegate.autoCloseFailed)
        #expect(store.state.campaigns == [closed])
        #expect(saves.value == [closed])
    }
}
