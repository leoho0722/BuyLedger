//
//  CampaignReminderFeatureFailuresTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignReminderFeature` 的單元測試，涵蓋權限遭拒、行事曆無法使用與各類寫入失敗時的錯誤分流
@MainActor
struct CampaignReminderFeatureFailuresTests {

    /// 驗證行事曆權限遭拒時，回報權限被拒，不建立事件也不寫入連結
    ///
    /// - Note: 未覆寫的 `addReminder` 與 `saveReminderLink` 是 `unimplemented`；被呼叫會使測試失敗
    @Test
    func reconcileRequested_行事曆權限遭拒_回報權限被拒() async {
        // Given
        let store = CampaignReminderFeatureTestSupport.makeStore(links: Shared(value: [:])) {
            $0.calendarReminderService.requestAccess = {
                .denied
            }
        }

        // When
        await store.send(
            .reconcileRequested(CampaignReminderFeatureTestSupport.makeRequest(.create))
        )

        // Then
        await store.receive(\.createResponse)
        await store.receive(\.delegate.failed, .accessDenied)
        #expect(store.state.links[CampaignReminderFeatureTestSupport.campaignID] == nil)
    }

    /// 驗證行事曆受裝置政策限制時，回報權限受限而非權限被拒，不建立事件也不寫入連結
    ///
    /// - Note: 未覆寫的 `addReminder` 與 `saveReminderLink` 是 `unimplemented`；被呼叫會使測試失敗
    @Test
    func reconcileRequested_行事曆權限受限制_回報權限受限() async {
        // Given
        let store = CampaignReminderFeatureTestSupport.makeStore(links: Shared(value: [:])) {
            $0.calendarReminderService.requestAccess = {
                .restricted
            }
        }

        // When
        await store.send(
            .reconcileRequested(CampaignReminderFeatureTestSupport.makeRequest(.create))
        )

        // Then
        await store.receive(\.createResponse)
        await store.receive(\.delegate.failed, .accessRestricted)
        #expect(store.state.links[CampaignReminderFeatureTestSupport.campaignID] == nil)
    }

    /// 驗證權限已允許、但沒有可寫入的行事曆時，回報行事曆無法使用而非權限問題，也不寫入連結
    ///
    /// - Note: 未覆寫的 `saveReminderLink` 是 `unimplemented`；被呼叫會使測試失敗
    @Test
    func reconcileRequested_沒有可寫入行事曆_回報行事曆無法使用() async {
        // Given
        let failingAddReminder: CalendarReminderService.AddReminder = { _, _, _ throws(CalendarReminderError) in
            throw .noWritableCalendar
        }
        let store = CampaignReminderFeatureTestSupport.makeStore(links: Shared(value: [:])) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = failingAddReminder
        }

        // When
        await store.send(
            .reconcileRequested(CampaignReminderFeatureTestSupport.makeRequest(.create))
        )

        // Then
        await store.receive(\.createResponse)
        await store.receive(\.delegate.failed, .calendarUnavailable)
        #expect(store.state.links[CampaignReminderFeatureTestSupport.campaignID] == nil)
    }

    /// 驗證寫入行事曆事件失敗時，回報建立失敗，不寫入連結
    ///
    /// - Note: 未覆寫的 `saveReminderLink` 是 `unimplemented`；被呼叫會使測試失敗
    @Test
    func reconcileRequested_儲存行事曆事件失敗_回報建立失敗() async {
        // Given
        let failingAddReminder: CalendarReminderService.AddReminder = { _, _, _ throws(CalendarReminderError) in
            throw .system(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = CampaignReminderFeatureTestSupport.makeStore(links: Shared(value: [:])) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = failingAddReminder
        }

        // When
        await store.send(
            .reconcileRequested(CampaignReminderFeatureTestSupport.makeRequest(.create))
        )

        // Then
        await store.receive(\.createResponse)
        await store.receive(\.delegate.failed, .creationFailed)
        #expect(store.state.links[CampaignReminderFeatureTestSupport.campaignID] == nil)
    }

    /// 驗證新增事件後拿不到事件識別碼時，無法記錄連結，視同建立失敗
    ///
    /// - Note: 未覆寫的 `saveReminderLink` 是 `unimplemented`；被呼叫會使測試失敗
    @Test
    func reconcileRequested_建立事件未提供識別碼_回報建立失敗() async {
        // Given
        let failingAddReminder: CalendarReminderService.AddReminder = { _, _, _ throws(CalendarReminderError) in
            throw .eventIdentifierMissing
        }
        let store = CampaignReminderFeatureTestSupport.makeStore(links: Shared(value: [:])) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = failingAddReminder
        }

        // When
        await store.send(
            .reconcileRequested(CampaignReminderFeatureTestSupport.makeRequest(.create))
        )

        // Then
        await store.receive(\.createResponse)
        await store.receive(\.delegate.failed, .creationFailed)
        #expect(store.state.links[CampaignReminderFeatureTestSupport.campaignID] == nil)
    }

    /// 驗證事件建立成功但連結寫入失敗時，回報建立失敗，共用連結不留下部分寫入
    @Test
    func reconcileRequested_保存提醒連結失敗_回報建立失敗() async {
        // Given
        let savedLinks = LockIsolated<[CampaignReminderFeatureTestSupport.SavedLink]>([])
        let failingSaveLink: CampaignService.SaveReminderLink = { campaignID, link throws(PersistenceError) in
            savedLinks.withValue {
                $0.append(
                    CampaignReminderFeatureTestSupport.SavedLink(campaignID: campaignID, link: link)
                )
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = CampaignReminderFeatureTestSupport.makeStore(links: Shared(value: [:])) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = { _, _, _ in
                "EVT-new"
            }
            $0.campaignService.saveReminderLink = failingSaveLink
        }

        // When
        await store.send(
            .reconcileRequested(CampaignReminderFeatureTestSupport.makeRequest(.create))
        )

        // Then
        await store.receive(\.createResponse)
        await store.receive(\.delegate.failed, .creationFailed)
        #expect(store.state.links[CampaignReminderFeatureTestSupport.campaignID] == nil)
        #expect(
            savedLinks.value == [
                CampaignReminderFeatureTestSupport.SavedLink(
                    campaignID: CampaignReminderFeatureTestSupport.campaignID,
                    link: CampaignReminderFeatureTestSupport.newLink
                ),
            ]
        )
    }

    /// 驗證重建時新事件建立失敗，連結維持指向舊事件，舊事件也不移除
    ///
    /// - Note: 未覆寫的 `removeReminder` 與 `saveReminderLink` 是 `unimplemented`；誤刪舊事件或寫入連結會使測試失敗
    @Test
    func reconcileRequested_重建新事件失敗_保留舊連結且不移除舊事件() async {
        // Given
        let failingAddReminder: CalendarReminderService.AddReminder = { _, _, _ throws(CalendarReminderError) in
            throw .system(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = CampaignReminderFeatureTestSupport.makeStore(
            links: Shared(value: [
                CampaignReminderFeatureTestSupport.campaignID:
                    CampaignReminderFeatureTestSupport.oldLink,
            ])
        ) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = failingAddReminder
        }
        let request = CampaignReminderFeatureTestSupport.makeRequest(
            .rebuild(oldEventIdentifier: "EVT-old")
        )

        // When
        await store.send(.reconcileRequested(request))

        // Then
        await store.receive(\.createResponse)
        await store.receive(\.delegate.failed, .creationFailed)
        #expect(
            store.state.links[CampaignReminderFeatureTestSupport.campaignID]
                == CampaignReminderFeatureTestSupport.oldLink,
            "連結應仍指向舊事件"
        )
    }

    /// 驗證重建時沒有可寫入的行事曆，連結仍指向舊事件、舊事件不移除，並回報行事曆無法使用
    ///
    /// - Note: 規格範例：行事曆拒絕新事件
    ///
    /// - Note: 未覆寫的 `saveReminderLink` 與 `removeReminder` 是 `unimplemented`；寫入連結或移除舊事件會使測試失敗
    @Test
    func reconcileRequested_重建時無可寫入行事曆_連結仍指向舊事件且不移除() async {
        // Given
        let campaign = Campaign.fixture(
            id: CampaignReminderFeatureTestSupport.campaignID,
            name: "四月韓國團"
        )
        let failingAddReminder: CalendarReminderService.AddReminder = { _, _, _ throws(CalendarReminderError) in
            throw .noWritableCalendar
        }
        let oldLink = CampaignReminderLink(
            eventIdentifier: "E-OLD",
            reminderTimestamp: CampaignReminderFeatureTestSupport.oldTimestamp
        )
        let store = CampaignReminderFeatureTestSupport.makeStore(
            links: Shared(value: [CampaignReminderFeatureTestSupport.campaignID: oldLink])
        ) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = failingAddReminder
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
        #expect(store.state.links[CampaignReminderFeatureTestSupport.campaignID] == oldLink)
    }
}
