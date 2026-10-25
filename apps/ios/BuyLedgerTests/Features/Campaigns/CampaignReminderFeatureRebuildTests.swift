//
//  CampaignReminderFeatureRebuildTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignReminderFeature` 的單元測試，涵蓋改名或時間變更時的重建順序，先建立新事件再移除舊事件
@MainActor
struct CampaignReminderFeatureRebuildTests {

    /// 驗證改名重建時，以新標題與原提醒時間建立新事件，連結寫入後才移除舊事件
    @Test
    func reconcileRequested_改名重建_以新標題建立新事件並移除舊事件() async {
        // Given
        let operations = LockIsolated<[String]>([])
        let addedReminders = LockIsolated<[CampaignReminderFeatureTestSupport.RecordedReminder]>([])
        let savedLinks = LockIsolated<[CampaignReminderFeatureTestSupport.SavedLink]>([])
        let expectedLink = CampaignReminderLink(
            eventIdentifier: "EVT-new",
            reminderTimestamp: CampaignReminderFeatureTestSupport.oldTimestamp
        )
        let expectedReminder = CampaignReminderFeatureTestSupport.RecordedReminder(
            title: "「新團名」訂購提醒",
            eventDate: CampaignReminderFeatureTestSupport.eventDate,
            alarmOffset: 32_400
        )
        let store = CampaignReminderFeatureTestSupport.makeStore(
            links: Shared(value: [
                CampaignReminderFeatureTestSupport.campaignID:
                    CampaignReminderFeatureTestSupport.oldLink,
            ])
        ) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = { title, date, offset in
                operations.withValue {
                    $0.append("addReminder")
                }
                addedReminders.withValue {
                    $0.append(
                        CampaignReminderFeatureTestSupport.RecordedReminder(
                            title: title,
                            eventDate: date,
                            alarmOffset: offset
                        )
                    )
                }
                return "EVT-new"
            }
            $0.campaignService.saveReminderLink = { campaignID, link in
                operations.withValue {
                    $0.append("saveReminderLink")
                }
                savedLinks.withValue {
                    $0.append(
                        CampaignReminderFeatureTestSupport.SavedLink(
                            campaignID: campaignID,
                            link: link
                        )
                    )
                }
            }
            $0.calendarReminderService.removeReminder = { eventIdentifier in
                operations.withValue {
                    $0.append("removeReminder:\(eventIdentifier)")
                }
            }
        }
        let request = CampaignReminderFeatureTestSupport.makeRequest(
            .rebuild(oldEventIdentifier: "EVT-old"),
            title: "「新團名」訂購提醒",
            alarmOffset: 32_400,
            timestamp: CampaignReminderFeatureTestSupport.oldTimestamp
        )

        // When
        await store.send(.reconcileRequested(request))

        // Then
        await store.receive(\.createResponse) {
            $0.$links.withLock {
                $0[CampaignReminderFeatureTestSupport.campaignID] = expectedLink
            }
        }
        await store.receive(\.oldEventRemovalResponse)
        #expect(operations.value == ["addReminder", "saveReminderLink", "removeReminder:EVT-old"])
        #expect(addedReminders.value == [expectedReminder])
        #expect(
            savedLinks.value == [
                CampaignReminderFeatureTestSupport.SavedLink(
                    campaignID: CampaignReminderFeatureTestSupport.campaignID,
                    link: expectedLink
                ),
            ]
        )
    }

    /// 驗證提醒時間變更重建時，以新日期與提示位移建立新事件，連結寫入後才移除舊事件
    @Test
    func reconcileRequested_時間重建_以新日期與提示位移建立新事件並移除舊事件() async {
        // Given
        let operations = LockIsolated<[String]>([])
        let addedReminders = LockIsolated<[CampaignReminderFeatureTestSupport.RecordedReminder]>([])
        let savedLinks = LockIsolated<[CampaignReminderFeatureTestSupport.SavedLink]>([])
        let april26 = Date(timeIntervalSince1970: 1_777_161_600)
        let expectedLink = CampaignReminderLink(
            eventIdentifier: "EVT-new",
            reminderTimestamp: Date(timeIntervalSince1970: 1_777_226_400)
        )
        let expectedReminder = CampaignReminderFeatureTestSupport.RecordedReminder(
            title: "「四月團」訂購提醒",
            eventDate: april26,
            alarmOffset: 64_800
        )
        let store = CampaignReminderFeatureTestSupport.makeStore(
            links: Shared(value: [
                CampaignReminderFeatureTestSupport.campaignID:
                    CampaignReminderFeatureTestSupport.oldLink,
            ])
        ) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = { title, date, offset in
                operations.withValue {
                    $0.append("addReminder")
                }
                addedReminders.withValue {
                    $0.append(
                        CampaignReminderFeatureTestSupport.RecordedReminder(
                            title: title,
                            eventDate: date,
                            alarmOffset: offset
                        )
                    )
                }
                return "EVT-new"
            }
            $0.campaignService.saveReminderLink = { campaignID, link in
                operations.withValue {
                    $0.append("saveReminderLink")
                }
                savedLinks.withValue {
                    $0.append(
                        CampaignReminderFeatureTestSupport.SavedLink(
                            campaignID: campaignID,
                            link: link
                        )
                    )
                }
            }
            $0.calendarReminderService.removeReminder = { eventIdentifier in
                operations.withValue {
                    $0.append("removeReminder:\(eventIdentifier)")
                }
            }
        }
        let request = CampaignReminderFeatureTestSupport.makeRequest(
            .rebuild(oldEventIdentifier: "EVT-old"),
            eventDate: april26,
            timestamp: expectedLink.reminderTimestamp
        )

        // When
        await store.send(.reconcileRequested(request))

        // Then
        await store.receive(\.createResponse) {
            $0.$links.withLock {
                $0[CampaignReminderFeatureTestSupport.campaignID] = expectedLink
            }
        }
        await store.receive(\.oldEventRemovalResponse)
        #expect(operations.value == ["addReminder", "saveReminderLink", "removeReminder:EVT-old"])
        #expect(addedReminders.value == [expectedReminder])
        #expect(
            savedLinks.value == [
                CampaignReminderFeatureTestSupport.SavedLink(
                    campaignID: CampaignReminderFeatureTestSupport.campaignID,
                    link: expectedLink
                ),
            ]
        )
    }

    /// 驗證新事件與連結寫入完成後才移除舊事件，移除舊事件時連結已指向新事件
    ///
    /// - Note: 規格範例：重建順序，改名「四月韓國團」為「五月韓國團」
    @Test
    func reconcileRequested_重建舊事件為新事件_連結先指向新事件再移除舊事件() async {
        // Given
        let operations = LockIsolated<[String]>([])
        let oldLink = CampaignReminderLink(
            eventIdentifier: "E-OLD",
            reminderTimestamp: CampaignReminderFeatureTestSupport.oldTimestamp
        )
        let links = Shared(value: [CampaignReminderFeatureTestSupport.campaignID: oldLink])
        let linksWhenRemoving = LockIsolated<[CampaignReminderLink?]>([])
        let expectedLink = CampaignReminderLink(
            eventIdentifier: "E-NEW",
            reminderTimestamp: CampaignReminderFeatureTestSupport.oldTimestamp
        )
        let store = CampaignReminderFeatureTestSupport.makeStore(links: links) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = { _, _, _ in
                operations.withValue {
                    $0.append("addReminder")
                }
                return "E-NEW"
            }
            $0.campaignService.saveReminderLink = { _, _ in
                operations.withValue {
                    $0.append("saveReminderLink")
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
        let request = CampaignReminderFeatureTestSupport.makeRequest(
            .rebuild(oldEventIdentifier: "E-OLD"),
            title: "「五月韓國團」訂購提醒",
            timestamp: CampaignReminderFeatureTestSupport.oldTimestamp
        )

        // When
        await store.send(.reconcileRequested(request))

        // Then
        await store.receive(\.createResponse) {
            $0.$links.withLock {
                $0[CampaignReminderFeatureTestSupport.campaignID] = expectedLink
            }
        }
        await store.receive(\.oldEventRemovalResponse)
        #expect(operations.value == ["addReminder", "saveReminderLink", "removeReminder:E-OLD"])
        #expect(linksWhenRemoving.value == [expectedLink])
    }

    /// 驗證建立新事件成功後，依新增事件、寫入連結、移除舊事件的順序執行，移除在最後
    @Test
    func reconcileRequested_建立新事件成功_之後才移除舊事件() async {
        // Given
        let operations = LockIsolated<[String]>([])
        let savedLinks = LockIsolated<[CampaignReminderFeatureTestSupport.SavedLink]>([])
        let store = CampaignReminderFeatureTestSupport.makeStore(
            links: Shared(value: [
                CampaignReminderFeatureTestSupport.campaignID:
                    CampaignReminderFeatureTestSupport.oldLink,
            ])
        ) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = { _, _, _ in
                operations.withValue {
                    $0.append("addReminder")
                }
                return "EVT-new"
            }
            $0.campaignService.saveReminderLink = { campaignID, link in
                operations.withValue {
                    $0.append("saveReminderLink")
                }
                savedLinks.withValue {
                    $0.append(
                        CampaignReminderFeatureTestSupport.SavedLink(
                            campaignID: campaignID,
                            link: link
                        )
                    )
                }
            }
            $0.calendarReminderService.removeReminder = { eventIdentifier in
                operations.withValue {
                    $0.append("removeReminder:\(eventIdentifier)")
                }
            }
        }
        let request = CampaignReminderFeatureTestSupport.makeRequest(
            .rebuild(oldEventIdentifier: "EVT-old")
        )
        let newLink = CampaignReminderFeatureTestSupport.newLink

        // When
        await store.send(.reconcileRequested(request))

        // Then
        await store.receive(\.createResponse) {
            $0.$links.withLock {
                $0[CampaignReminderFeatureTestSupport.campaignID] = newLink
            }
        }
        await store.receive(\.oldEventRemovalResponse)
        #expect(operations.value == ["addReminder", "saveReminderLink", "removeReminder:EVT-old"])
        #expect(
            savedLinks.value == [
                CampaignReminderFeatureTestSupport.SavedLink(
                    campaignID: CampaignReminderFeatureTestSupport.campaignID,
                    link: CampaignReminderFeatureTestSupport.newLink
                ),
            ]
        )
    }

    /// 驗證重建後移除舊事件失敗時，連結維持指向新事件不回滾，並回報舊事件移除失敗
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
        let store = CampaignReminderFeatureTestSupport.makeStore(
            links: Shared(value: [
                CampaignReminderFeatureTestSupport.campaignID:
                    CampaignReminderFeatureTestSupport.oldLink,
            ])
        ) {
            $0.calendarReminderService.requestAccess = {
                .granted
            }
            $0.calendarReminderService.addReminder = { _, _, _ in
                "EVT-new"
            }
            $0.campaignService.saveReminderLink = { _, _ in
            }
            $0.calendarReminderService.removeReminder = failingRemoveReminder
        }
        let request = CampaignReminderFeatureTestSupport.makeRequest(
            .rebuild(oldEventIdentifier: "EVT-old")
        )
        let newLink = CampaignReminderFeatureTestSupport.newLink

        // When
        await store.send(.reconcileRequested(request))

        // Then
        await store.receive(\.createResponse) {
            $0.$links.withLock {
                $0[CampaignReminderFeatureTestSupport.campaignID] = newLink
            }
        }
        await store.receive(\.oldEventRemovalResponse)
        await store.receive(\.delegate.failed, .oldEventRemovalFailed)
        #expect(
            store.state.links[CampaignReminderFeatureTestSupport.campaignID]
                == CampaignReminderFeatureTestSupport.newLink,
            "連結應指向新事件，不因舊事件移除失敗而回滾"
        )
        #expect(removedEventIdentifiers.value == ["EVT-old"])
    }
}
