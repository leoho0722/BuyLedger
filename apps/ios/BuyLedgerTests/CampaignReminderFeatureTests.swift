//
//  CampaignReminderFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證開團提醒流程的連結載入、建立與移除；重建順序與失敗分流在各 `+` 檔
@MainActor
struct CampaignReminderFeatureTests {

    // MARK: - Properties

    /// 測試共用的開團識別值
    static let campaignID = "C1"

    /// 提醒事件的全天日期 (2026-04-20 00:00 UTC)
    static let eventDate = Date(timeIntervalSince1970: 1_776_643_200)

    /// 重建前的提醒時間 (2026-04-20 09:00 UTC)
    static let oldTimestamp = Date(timeIntervalSince1970: 1_776_675_600)

    /// 建立或重建後的提醒時間 (2026-04-20 18:00 UTC)
    static let newTimestamp = Date(timeIntervalSince1970: 1_776_708_000)

    /// 重建前開團連結的舊事件
    static let oldLink = CampaignReminderLink(
        eventIdentifier: "EVT-old",
        reminderTimestamp: oldTimestamp
    )

    /// 建立或重建後開團連結的新事件
    static let newLink = CampaignReminderLink(
        eventIdentifier: "EVT-new",
        reminderTimestamp: newTimestamp
    )

    /// 尚未載入時讀取全部連結，存入共用連結並標記已載入
    @Test
    func linksRequested_尚未載入_載入並保存連結() async {
        // Given
        let loadedLinks = [Self.campaignID: Self.oldLink]
        let store = Self.makeStore(links: Shared(value: [:])) {
            $0.campaignReminderService.fetchLinks = {
                loadedLinks
            }
        }

        // When
        await store.send(.linksRequested)

        // Then
        await store.receive(\.linksResponse.success, loadedLinks) {
            $0.hasLoadedLinks = true
            $0.$links.withLock {
                $0 = loadedLinks
            }
        }
        #expect(store.state.links == loadedLinks)
    }

    /// 已成功載入過就不重複讀取
    @Test
    func linksRequested_已載入過_不重複讀取() async {
        // Given
        let fetchCount = LockIsolated(0)
        let store = Self.makeStore(links: Shared(value: [:]), hasLoadedLinks: true) {
            $0.campaignReminderService.fetchLinks = {
                fetchCount.withValue {
                    $0 += 1
                }
                return [:]
            }
        }

        // When
        await store.send(.linksRequested)

        // Then
        #expect(fetchCount.value == 0)
        #expect(store.state.hasLoadedLinks)
    }

    /// 載入失敗時連結維持空，不回報任何提示，也不標記已載入
    @Test
    func linksRequested_載入失敗_連結維持空且不回報() async {
        // Given
        let failingFetchLinks: CampaignReminderService.FetchLinks = {
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = Self.makeStore(links: Shared(value: [:])) {
            $0.campaignReminderService.fetchLinks = failingFetchLinks
        }

        // When
        await store.send(.linksRequested)

        // Then
        await store.receive(\.linksResponse.failure)
        #expect(store.state.links.isEmpty)
        #expect(store.state.hasLoadedLinks == false)
    }

    /// 建立提醒時依請求的標題、日期與提示位移建立全天事件，並保存連結
    @Test
    func reconcileRequested_建立提醒_以指定日期與提示位移建立事件並保存連結() async {
        // Given
        let operations = LockIsolated<[String]>([])
        let addedReminders = LockIsolated<[RecordedReminder]>([])
        let savedLinks = LockIsolated<[SavedLink]>([])
        let expectedReminder = RecordedReminder(
            title: "「新團」訂購提醒",
            eventDate: Self.eventDate,
            alarmOffset: 64_800
        )
        let store = Self.makeStore(links: Shared(value: [:])) {
            $0.calendarReminderService.requestAccess = {
                operations.withValue {
                    $0.append("requestAccess")
                }
                return .granted
            }
            $0.calendarReminderService.addReminder = { title, date, offset in
                operations.withValue {
                    $0.append("addReminder")
                }
                addedReminders.withValue {
                    $0.append(RecordedReminder(title: title, eventDate: date, alarmOffset: offset))
                }
                return "EVT-new"
            }
            $0.campaignReminderService.saveLink = { campaignID, link in
                operations.withValue {
                    $0.append("saveLink")
                }
                savedLinks.withValue {
                    $0.append(SavedLink(campaignID: campaignID, link: link))
                }
            }
        }

        // When
        await store.send(.reconcileRequested(Self.makeRequest(.create, title: "「新團」訂購提醒")))

        // Then
        await store.receive(\.createResponse) {
            $0.$links.withLock {
                $0[Self.campaignID] = Self.newLink
            }
        }
        #expect(operations.value == ["requestAccess", "addReminder", "saveLink"])
        #expect(addedReminders.value == [expectedReminder])
        #expect(savedLinks.value == [SavedLink(campaignID: Self.campaignID, link: Self.newLink)])
    }

    /// 清除提醒意圖時先移除行事曆事件再清除連結，且不請求行事曆權限
    @Test
    func reconcileRequested_移除提醒_移除事件與連結且不請求權限() async {
        // Given
        let operations = LockIsolated<[String]>([])
        let accessRequestCount = LockIsolated(0)
        let store = Self.makeStore(links: Shared(value: [Self.campaignID: Self.oldLink])) {
            $0.calendarReminderService.requestAccess = {
                accessRequestCount.withValue {
                    $0 += 1
                }
                return .denied
            }
            $0.calendarReminderService.removeReminder = { eventIdentifier in
                operations.withValue {
                    $0.append("removeReminder:\(eventIdentifier)")
                }
            }
            $0.campaignReminderService.removeLink = { campaignID in
                operations.withValue {
                    $0.append("removeLink:\(campaignID)")
                }
            }
        }

        // When
        await store.send(.reconcileRequested(Self.makeRequest(.remove(eventIdentifier: "EVT-old"))))

        // Then
        await store.receive(\.linkRemovalResponse) {
            $0.$links.withLock {
                $0[Self.campaignID] = nil
            }
        }
        #expect(operations.value == ["removeReminder:EVT-old", "removeLink:C1"])
        #expect(accessRequestCount.value == 0)
    }
}
