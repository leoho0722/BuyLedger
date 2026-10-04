//
//  CampaignReminderFeatureTests+Failures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignReminderFeatureTests {

    /// 行事曆權限遭拒時回報權限被拒，不建立事件與連結
    ///
    /// - Note: 未覆寫的 `addReminder` 與 `saveLink` 是 `unimplemented`；被呼叫會使測試失敗
    @Test
    func reconcileRequested_行事曆權限遭拒_回報權限被拒() async {
        // Given
        let store = Self.makeStore(links: Shared(value: [:])) {
            $0.calendarReminderService.requestAccess = {
                .denied
            }
        }

        // When
        await store.send(.reconcileRequested(Self.makeRequest(.create)))

        // Then
        await store.receive(\.createResponse)
        await store.receive(\.delegate.failed, .accessDenied)
        #expect(store.state.links[Self.campaignID] == nil)
    }

    /// 裝置政策限制行事曆時回報受限，與權限被拒分開，不建立事件與連結
    ///
    /// - Note: 未覆寫的 `addReminder` 與 `saveLink` 是 `unimplemented`；被呼叫會使測試失敗
    @Test
    func reconcileRequested_行事曆權限受限制_回報權限受限() async {
        // Given
        let store = Self.makeStore(links: Shared(value: [:])) {
            $0.calendarReminderService.requestAccess = {
                .restricted
            }
        }

        // When
        await store.send(.reconcileRequested(Self.makeRequest(.create)))

        // Then
        await store.receive(\.createResponse)
        await store.receive(\.delegate.failed, .accessRestricted)
        #expect(store.state.links[Self.campaignID] == nil)
    }

    /// 沒有可寫入的行事曆時回報行事曆無法使用，不是權限問題，也不寫入連結
    ///
    /// - Note: 未覆寫的 `saveLink` 是 `unimplemented`；被呼叫會使測試失敗
    @Test
    func reconcileRequested_沒有可寫入行事曆_回報行事曆無法使用() async {
        // Given
        let failingAddReminder: CalendarReminderService.AddReminder = { _, _, _ in
            throw .noWritableCalendar
        }
        let store = Self.makeStore(links: Shared(value: [:])) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = failingAddReminder
        }

        // When
        await store.send(.reconcileRequested(Self.makeRequest(.create)))

        // Then
        await store.receive(\.createResponse)
        await store.receive(\.delegate.failed, .calendarUnavailable)
        #expect(store.state.links[Self.campaignID] == nil)
    }

    /// 事件寫入行事曆失敗時回報建立失敗，不寫入連結
    ///
    /// - Note: 未覆寫的 `saveLink` 是 `unimplemented`；被呼叫會使測試失敗
    @Test
    func reconcileRequested_儲存行事曆事件失敗_回報建立失敗() async {
        // Given
        let failingAddReminder: CalendarReminderService.AddReminder = { _, _, _ in
            throw .system(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = Self.makeStore(links: Shared(value: [:])) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = failingAddReminder
        }

        // When
        await store.send(.reconcileRequested(Self.makeRequest(.create)))

        // Then
        await store.receive(\.createResponse)
        await store.receive(\.delegate.failed, .creationFailed)
        #expect(store.state.links[Self.campaignID] == nil)
    }

    /// 行事曆存檔後沒有給事件識別碼就無法記錄連結，視同建立失敗
    ///
    /// - Note: 未覆寫的 `saveLink` 是 `unimplemented`；被呼叫會使測試失敗
    @Test
    func reconcileRequested_建立事件未提供識別碼_回報建立失敗() async {
        // Given
        let failingAddReminder: CalendarReminderService.AddReminder = { _, _, _ in
            throw .eventIdentifierMissing
        }
        let store = Self.makeStore(links: Shared(value: [:])) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = failingAddReminder
        }

        // When
        await store.send(.reconcileRequested(Self.makeRequest(.create)))

        // Then
        await store.receive(\.createResponse)
        await store.receive(\.delegate.failed, .creationFailed)
        #expect(store.state.links[Self.campaignID] == nil)
    }

    /// 事件建立成功但連結寫入失敗時回報建立失敗，共用連結不留下部分寫入
    @Test
    func reconcileRequested_保存提醒連結失敗_回報建立失敗() async {
        // Given
        let savedLinks = LockIsolated<[SavedLink]>([])
        let failingSaveLink: CampaignReminderService.SaveLink = { campaignID, link in
            savedLinks.withValue {
                $0.append(SavedLink(campaignID: campaignID, link: link))
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = Self.makeStore(links: Shared(value: [:])) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = { _, _, _ in
                "EVT-new"
            }
            $0.campaignReminderService.saveLink = failingSaveLink
        }

        // When
        await store.send(.reconcileRequested(Self.makeRequest(.create)))

        // Then
        await store.receive(\.createResponse)
        await store.receive(\.delegate.failed, .creationFailed)
        #expect(store.state.links[Self.campaignID] == nil)
        #expect(savedLinks.value == [SavedLink(campaignID: Self.campaignID, link: Self.newLink)])
    }

    /// 新事件建立失敗時連結維持指向舊事件，也不移除舊事件
    ///
    /// - Note: 未覆寫的 `removeReminder` 與 `saveLink` 是 `unimplemented`；誤刪舊事件或寫入連結會使測試失敗
    @Test
    func reconcileRequested_重建新事件失敗_保留舊連結且不移除舊事件() async {
        // Given
        let failingAddReminder: CalendarReminderService.AddReminder = { _, _, _ in
            throw .system(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = Self.makeStore(links: Shared(value: [Self.campaignID: Self.oldLink])) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = failingAddReminder
        }
        let request = Self.makeRequest(.rebuild(oldEventIdentifier: "EVT-old"))

        // When
        await store.send(.reconcileRequested(request))

        // Then
        await store.receive(\.createResponse)
        await store.receive(\.delegate.failed, .creationFailed)
        #expect(store.state.links[Self.campaignID] == Self.oldLink, "連結應仍指向舊事件")
    }

    /// 沒有可寫入的行事曆時保留舊事件並回報 (規格範例：行事曆拒絕新事件)
    ///
    /// - Note: 未覆寫的 `saveLink` 是 `unimplemented`；寫入連結會使測試失敗
    @Test
    func reconcileRequested_重建時無可寫入行事曆_連結仍指向舊事件且不移除() async {
        // Given
        let campaign = Campaign.fixture(id: Self.campaignID, name: "四月韓國團")
        let removedEventIdentifiers = LockIsolated<[String]>([])
        let failingAddReminder: CalendarReminderService.AddReminder = { _, _, _ in
            throw .noWritableCalendar
        }
        let oldLink = CampaignReminderLink(
            eventIdentifier: "E-OLD",
            reminderTimestamp: Self.oldTimestamp
        )
        let store = Self.makeStore(links: Shared(value: [Self.campaignID: oldLink])) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = failingAddReminder
            $0.calendarReminderService.removeReminder = { eventIdentifier in
                removedEventIdentifiers.withValue {
                    $0.append(eventIdentifier)
                }
            }
        }
        // 提醒由 2026-04-20 09:00 UTC 改為同日 18:00 UTC
        let request = CampaignReminderRequest.make(
            campaign: campaign,
            reconcile: .rebuild(oldEventIdentifier: "E-OLD"),
            timestamp: Date(timeIntervalSince1970: 1_776_708_000),
            calendar: TestDependencies.fixedCalendar
        )

        // When
        await store.send(.reconcileRequested(request))

        // Then
        await store.receive(\.createResponse)
        await store.receive(\.delegate.failed, .calendarUnavailable)
        #expect(store.state.links[Self.campaignID] == oldLink)
        #expect(removedEventIdentifiers.value.isEmpty)
    }
}
