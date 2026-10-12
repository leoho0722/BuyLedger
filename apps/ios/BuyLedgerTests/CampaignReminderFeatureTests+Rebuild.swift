//
//  CampaignReminderFeatureTests+Rebuild.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignReminderFeatureTests {

    /// 改名重建時以新標題與原提醒時間建立新事件，新連結生效後移除舊事件
    @Test
    func reconcileRequested_改名重建_以新標題建立新事件並移除舊事件() async {
        // Given
        let operations = LockIsolated<[String]>([])
        let addedReminders = LockIsolated<[RecordedReminder]>([])
        let savedLinks = LockIsolated<[SavedLink]>([])
        let expectedLink = CampaignReminderLink(
            eventIdentifier: "EVT-new",
            reminderTimestamp: Self.oldTimestamp
        )
        let expectedReminder = RecordedReminder(
            title: "「新團名」訂購提醒",
            eventDate: Self.eventDate,
            alarmOffset: 32_400
        )
        let store = Self.makeStore(links: Shared(value: [Self.campaignID: Self.oldLink])) {
            $0.calendarReminderService.requestAccess = {
                .granted
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
            $0.calendarReminderService.removeReminder = { eventIdentifier in
                operations.withValue {
                    $0.append("removeReminder:\(eventIdentifier)")
                }
            }
        }
        let request = Self.makeRequest(
            .rebuild(oldEventIdentifier: "EVT-old"),
            title: "「新團名」訂購提醒",
            alarmOffset: 32_400,
            timestamp: Self.oldTimestamp
        )

        // When
        await store.send(.reconcileRequested(request))

        // Then
        await store.receive(\.createResponse) {
            $0.$links.withLock {
                $0[Self.campaignID] = expectedLink
            }
        }
        await store.receive(\.oldEventRemovalResponse)
        #expect(operations.value == ["addReminder", "saveLink", "removeReminder:EVT-old"])
        #expect(addedReminders.value == [expectedReminder])
        #expect(savedLinks.value == [SavedLink(campaignID: Self.campaignID, link: expectedLink)])
    }

    /// 提醒時間變更重建時以新日期與提示位移建立新事件，新連結生效後移除舊事件
    @Test
    func reconcileRequested_時間重建_以新日期與提示位移建立新事件並移除舊事件() async {
        // Given
        let operations = LockIsolated<[String]>([])
        let addedReminders = LockIsolated<[RecordedReminder]>([])
        let savedLinks = LockIsolated<[SavedLink]>([])
        let april26 = Date(timeIntervalSince1970: 1_777_161_600)
        let expectedLink = CampaignReminderLink(
            eventIdentifier: "EVT-new",
            reminderTimestamp: Date(timeIntervalSince1970: 1_777_226_400)
        )
        let expectedReminder = RecordedReminder(
            title: "「四月團」訂購提醒",
            eventDate: april26,
            alarmOffset: 64_800
        )
        let store = Self.makeStore(links: Shared(value: [Self.campaignID: Self.oldLink])) {
            $0.calendarReminderService.requestAccess = {
                .granted
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
            $0.calendarReminderService.removeReminder = { eventIdentifier in
                operations.withValue {
                    $0.append("removeReminder:\(eventIdentifier)")
                }
            }
        }
        let request = Self.makeRequest(
            .rebuild(oldEventIdentifier: "EVT-old"),
            eventDate: april26,
            timestamp: expectedLink.reminderTimestamp
        )

        // When
        await store.send(.reconcileRequested(request))

        // Then
        await store.receive(\.createResponse) {
            $0.$links.withLock {
                $0[Self.campaignID] = expectedLink
            }
        }
        await store.receive(\.oldEventRemovalResponse)
        #expect(operations.value == ["addReminder", "saveLink", "removeReminder:EVT-old"])
        #expect(addedReminders.value == [expectedReminder])
        #expect(savedLinks.value == [SavedLink(campaignID: Self.campaignID, link: expectedLink)])
    }

    /// 新事件與連結寫入完成後才移除舊事件 (規格範例：重建順序，改名「四月韓國團」為「五月韓國團」)
    @Test
    func reconcileRequested_重建舊事件為新事件_連結先指向新事件再移除舊事件() async {
        // Given
        let operations = LockIsolated<[String]>([])
        let oldLink = CampaignReminderLink(
            eventIdentifier: "E-OLD",
            reminderTimestamp: Self.oldTimestamp
        )
        let links = Shared(value: [Self.campaignID: oldLink])
        let linksWhenRemoving = LockIsolated<[CampaignReminderLink?]>([])
        let expectedLink = CampaignReminderLink(
            eventIdentifier: "E-NEW",
            reminderTimestamp: Self.oldTimestamp
        )
        let store = Self.makeStore(links: links) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = { _, _, _ in
                operations.withValue {
                    $0.append("addReminder")
                }
                return "E-NEW"
            }
            $0.campaignReminderService.saveLink = { _, _ in
                operations.withValue {
                    $0.append("saveLink")
                }
            }
            $0.calendarReminderService.removeReminder = { eventIdentifier in
                operations.withValue {
                    $0.append("removeReminder:\(eventIdentifier)")
                }
                linksWhenRemoving.withValue {
                    $0.append(links.wrappedValue["C1"])
                }
            }
        }
        let request = Self.makeRequest(
            .rebuild(oldEventIdentifier: "E-OLD"),
            title: "「五月韓國團」訂購提醒",
            timestamp: Self.oldTimestamp
        )

        // When
        await store.send(.reconcileRequested(request))

        // Then
        await store.receive(\.createResponse) {
            $0.$links.withLock {
                $0[Self.campaignID] = expectedLink
            }
        }
        await store.receive(\.oldEventRemovalResponse)
        #expect(operations.value == ["addReminder", "saveLink", "removeReminder:E-OLD"])
        #expect(linksWhenRemoving.value == [expectedLink])
    }

    /// 新事件與提醒連結保存完成後才移除舊事件
    @Test
    func reconcileRequested_建立新事件成功_之後才移除舊事件() async {
        // Given
        let operations = LockIsolated<[String]>([])
        let savedLinks = LockIsolated<[SavedLink]>([])
        let store = Self.makeStore(links: Shared(value: [Self.campaignID: Self.oldLink])) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = { _, _, _ in
                operations.withValue {
                    $0.append("addReminder")
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
            $0.calendarReminderService.removeReminder = { eventIdentifier in
                operations.withValue {
                    $0.append("removeReminder:\(eventIdentifier)")
                }
            }
        }
        let request = Self.makeRequest(.rebuild(oldEventIdentifier: "EVT-old"))

        // When
        await store.send(.reconcileRequested(request))

        // Then
        await store.receive(\.createResponse) {
            $0.$links.withLock {
                $0[Self.campaignID] = Self.newLink
            }
        }
        await store.receive(\.oldEventRemovalResponse)
        #expect(operations.value == ["addReminder", "saveLink", "removeReminder:EVT-old"])
        #expect(savedLinks.value == [SavedLink(campaignID: Self.campaignID, link: Self.newLink)])
    }

    /// 移除舊事件失敗時新連結不回滾，並回報舊事件移除失敗
    @Test
    func reconcileRequested_重建後移除舊事件失敗_保留新連結並回報() async {
        // Given
        let removedEventIdentifiers = LockIsolated<[String]>([])
        let failingRemoveReminder: CalendarReminderService.RemoveReminder = { eventIdentifier throws(CalendarReminderError) in
            removedEventIdentifiers.withValue {
                $0.append(eventIdentifier)
            }
            throw .system(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = Self.makeStore(links: Shared(value: [Self.campaignID: Self.oldLink])) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = { _, _, _ in
                "EVT-new"
            }
            $0.campaignReminderService.saveLink = { _, _ in
            }
            $0.calendarReminderService.removeReminder = failingRemoveReminder
        }
        let request = Self.makeRequest(.rebuild(oldEventIdentifier: "EVT-old"))

        // When
        await store.send(.reconcileRequested(request))

        // Then
        await store.receive(\.createResponse) {
            $0.$links.withLock {
                $0[Self.campaignID] = Self.newLink
            }
        }
        await store.receive(\.oldEventRemovalResponse)
        await store.receive(\.delegate.failed, .oldEventRemovalFailed)
        #expect(store.state.links[Self.campaignID] == Self.newLink, "連結應指向新事件，不因舊事件移除失敗而回滾")
        #expect(removedEventIdentifiers.value == ["EVT-old"])
    }
}
