//
//  CampaignFeatureTests+DeletionReminder.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 刪除有提醒的開團時轉送移除提醒，共用連結清除，並以刪除結果的事件識別碼移除行事曆事件一次
    ///
    /// - Note: 本機交易已刪除持久化連結，提醒子 Feature 只清共用連結，不呼叫 `removeLink`
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
        initial.presentation.destination = Self.deletionAlert(id: "C1", name: "團")
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
        let removedLinkIDs = LockIsolated<[String]>([])
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
            $0.campaignReminderService.removeLink = { campaignID in
                removedLinkIDs.withValue {
                    $0.append(campaignID)
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
        #expect(removedEventIdentifiers.value == ["EVT-1"], "刪除應以連結記錄的事件識別碼呼叫一次 removeReminder")
        #expect(removedLinkIDs.value.isEmpty, "刪除路徑不應再呼叫 removeLink")
    }

    /// 提醒連結尚未載入時刪除開團，仍以刪除結果帶回的事件識別碼移除行事曆事件
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
        initial.presentation.destination = Self.deletionAlert(id: "C1", name: "團")

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

    /// 開團已刪除但行事曆事件移除失敗時，開團不回到清單，並提示使用者自行到行事曆刪除
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
        initial.presentation.destination = Self.deletionAlert(id: "C1", name: "團")
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
            Self.failureAlert("開團已刪除，但行事曆上的提醒事件移除失敗，請自行到行事曆刪除。")
        ) {
            $0.presentation.destination = Self.failureAlert("開團已刪除，但行事曆上的提醒事件移除失敗，請自行到行事曆刪除。")
        }
        #expect(removedCampaignIDs.value == ["C1"])
        #expect(removedCampaignNames.value == ["團"])
        #expect(removedEventIdentifiers.value == ["EVT-1"])
    }
}
