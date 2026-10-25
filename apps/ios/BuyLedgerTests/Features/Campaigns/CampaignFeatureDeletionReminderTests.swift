//
//  CampaignFeatureDeletionReminderTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `CampaignFeature` 的單元測試，涵蓋刪除含提醒的開團
@MainActor
struct CampaignFeatureDeletionReminderTests {

    /// 驗證刪除有提醒的開團時，開團與共用提醒連結一併清除，行事曆事件以刪除結果回傳的識別碼只移除一次，不採用共用連結記錄的識別碼
    ///
    /// - Note: 持久化連結已在本機交易中刪除，提醒流程只清除共用連結，不會呼叫 `removeReminderLink`
    @Test
    func presentation_刪除含提醒開團_轉送移除提醒並清除共用連結() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .ongoing
        )
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.presentation.destination = CampaignFeatureTestSupport.deletionAlert(
            id: "C1",
            name: "團"
        )
        initial.$reminderLinks.withLock {
            $0 = [
                "C1": CampaignReminderLink(
                    eventIdentifier: "EVT-link",
                    reminderTimestamp: TestDependencies.fixedNow
                ),
            ]
        }

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
                return "EVT-deleted"
            }
            $0.calendarReminderService.removeReminder = { identifier in
                removedEventIdentifiers.withValue {
                    $0.append(identifier)
                }
            }
        }

        // When
        await store.send(.presentation(.destination(.presented(.alert(.confirmDelete("C1")))))) {
            $0.presentation.destination = nil
        }

        // Then
        await store.receive(\.presentation.delegate.deleteConfirmed, "C1") {
            $0.$campaigns.withLock {
                $0 = []
            }
            $0.$reminderLinks.withLock {
                $0["C1"] = nil
            }
        }
        await store.receive(\.writes.deleteRequested)
        await store.receive(\.writes.deleteResponse.success)
        await store.receive(\.writes.delegate.deleted)
        await store.receive(\.delegate.campaignDeleted)
        await store.receive(\.reminder.campaignRemoved)
        await store.receive(\.reminder.eventRemovalResponse)
        #expect(removedCampaignIDs.value == ["C1"])
        #expect(removedCampaignNames.value == ["團"])
        #expect(
            removedEventIdentifiers.value == ["EVT-deleted"],
            "刪除應以刪除結果回傳的事件識別碼呼叫一次 removeReminder"
        )
    }

    /// 驗證提醒連結尚未載入時刪除開團，仍以刪除結果回傳的事件識別碼移除行事曆事件，且提醒連結維持為空
    @Test
    func presentation_連結尚未載入_仍以刪除結果的事件識別碼移除事件() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .ongoing
        )
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.presentation.destination = CampaignFeatureTestSupport.deletionAlert(
            id: "C1",
            name: "團"
        )

        let removedEventIdentifiers = LockIsolated<[String]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.campaignService.removeCampaign = { _, _ in
                "EVT-1"
            }
            $0.calendarReminderService.removeReminder = { identifier in
                removedEventIdentifiers.withValue {
                    $0.append(identifier)
                }
            }
        }

        // When
        await store.send(.presentation(.destination(.presented(.alert(.confirmDelete("C1")))))) {
            $0.presentation.destination = nil
        }

        // Then
        await store.receive(\.presentation.delegate.deleteConfirmed, "C1") {
            $0.$campaigns.withLock {
                $0 = []
            }
        }
        await store.receive(\.writes.deleteRequested)
        await store.receive(\.writes.deleteResponse.success)
        await store.receive(\.writes.delegate.deleted)
        await store.receive(\.delegate.campaignDeleted)
        await store.receive(\.reminder.campaignRemoved)
        await store.receive(\.reminder.eventRemovalResponse)
        #expect(store.state.reminderLinks.isEmpty)
        #expect(removedEventIdentifiers.value == ["EVT-1"])
    }

    /// 驗證行事曆事件移除失敗時，已刪除的開團不還原到清單，並提示使用者自行到行事曆刪除
    @Test
    func presentation_移除行事曆事件失敗_不還原已刪開團() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .ongoing
        )
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.presentation.destination = CampaignFeatureTestSupport.deletionAlert(
            id: "C1",
            name: "團"
        )
        initial.$reminderLinks.withLock {
            $0 = [
                "C1": CampaignReminderLink(
                    eventIdentifier: "EVT-1",
                    reminderTimestamp: TestDependencies.fixedNow
                ),
            ]
        }

        let removedCampaignIDs = LockIsolated<[String]>([])
        let removedCampaignNames = LockIsolated<[String]>([])
        let removedEventIdentifiers = LockIsolated<[String]>([])
        let failingRemoveReminder: CalendarReminderService.RemoveReminder = { identifier throws(CalendarReminderError) in
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
        await store.send(.presentation(.destination(.presented(.alert(.confirmDelete("C1")))))) {
            $0.presentation.destination = nil
        }

        // Then
        await store.receive(\.presentation.delegate.deleteConfirmed, "C1") {
            $0.$campaigns.withLock {
                $0 = []
            }
            $0.$reminderLinks.withLock {
                $0["C1"] = nil
            }
        }
        await store.receive(\.writes.deleteRequested)
        await store.receive(\.writes.deleteResponse.success)
        await store.receive(\.writes.delegate.deleted)
        await store.receive(\.delegate.campaignDeleted)
        await store.receive(\.reminder.campaignRemoved)
        await store.receive(\.reminder.eventRemovalResponse)
        await store.receive(\.reminder.delegate.failed, .eventRemovalAfterDeleteFailed)
        await store.receive(
            \.presentation.noticeRequested,
            CampaignFeatureTestSupport.failureAlert("campaigns.general.message.campaignDeletedBut")
        ) {
            $0.presentation.destination = CampaignFeatureTestSupport.failureAlert(
                "campaigns.general.message.campaignDeletedBut"
            )
        }
        #expect(removedCampaignIDs.value == ["C1"])
        #expect(removedCampaignNames.value == ["團"])
        #expect(removedEventIdentifiers.value == ["EVT-1"])
    }
}
