//
//  CampaignReminderFeatureTests+Removal.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignReminderFeatureTests {

    /// 清除提醒時行事曆事件可能已被手動刪除，事件移除失敗仍清除連結，也不回報錯誤
    @Test
    func reconcileRequested_移除提醒且事件移除失敗_仍清除連結且不回報() async {
        // Given
        let removedEventIdentifiers = LockIsolated<[String]>([])
        let removedCampaignIDs = LockIsolated<[String]>([])
        let accessRequestCount = LockIsolated(0)
        let failingRemoveReminder: CalendarReminderService.RemoveReminder = { eventIdentifier throws(CalendarReminderError) in
            removedEventIdentifiers.withValue {
                $0.append(eventIdentifier)
            }
            throw .system(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = Self.makeStore(links: Shared(value: [Self.campaignID: Self.oldLink])) {
            $0.calendarReminderService.requestAccess = {
                accessRequestCount.withValue {
                    $0 += 1
                }
                return .denied
            }
            $0.calendarReminderService.removeReminder = failingRemoveReminder
            $0.campaignService.removeReminderLink = { campaignID in
                removedCampaignIDs.withValue {
                    $0.append(campaignID)
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
        #expect(removedEventIdentifiers.value == ["EVT-old"])
        #expect(removedCampaignIDs.value == ["C1"])
        #expect(accessRequestCount.value == 0)
    }

    /// 清除提醒時連結移除失敗，保留共用連結並回報連結移除失敗
    @Test
    func reconcileRequested_移除提醒但連結移除失敗_保留連結並回報() async {
        // Given
        let failingRemoveLink: CampaignService.RemoveReminderLink = { _ throws(PersistenceError) in
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = Self.makeStore(links: Shared(value: [Self.campaignID: Self.oldLink])) {
            $0.calendarReminderService.removeReminder = { _ in
            }
            $0.campaignService.removeReminderLink = failingRemoveLink
        }

        // When
        await store.send(.reconcileRequested(Self.makeRequest(.remove(eventIdentifier: "EVT-old"))))

        // Then
        await store.receive(\.linkRemovalResponse)
        await store.receive(\.delegate.failed, .linkRemovalFailed)
        #expect(store.state.links[Self.campaignID] == Self.oldLink)
    }

    /// 刪除沒有提醒的開團時只清除共用連結，不移除事件，也不呼叫 `removeReminderLink`
    ///
    /// - Note: 未覆寫的 `removeReminder` 是 `unimplemented`；被呼叫會使測試失敗
    @Test
    func campaignRemoved_沒有事件識別碼_清除共用連結且未呼叫移除連結() async {
        // Given
        let removedCampaignIDs = LockIsolated<[String]>([])
        let store = Self.makeStore(links: Shared(value: [Self.campaignID: Self.oldLink])) {
            $0.campaignService.removeReminderLink = { campaignID in
                removedCampaignIDs.withValue {
                    $0.append(campaignID)
                }
            }
        }

        // When
        await store.send(.campaignRemoved(campaignID: Self.campaignID, eventIdentifier: nil)) {
            $0.$links.withLock {
                $0[Self.campaignID] = nil
            }
        }

        // Then
        #expect(store.state.links[Self.campaignID] == nil)
        #expect(removedCampaignIDs.value.isEmpty)
    }

    /// 刪除有提醒的開團時清除共用連結並移除事件，不呼叫 `removeReminderLink`，也不請求行事曆權限
    @Test
    func campaignRemoved_有事件識別碼_清除共用連結並移除事件() async {
        // Given
        let removedEventIdentifiers = LockIsolated<[String]>([])
        let removedCampaignIDs = LockIsolated<[String]>([])
        let accessRequestCount = LockIsolated(0)
        let store = Self.makeStore(links: Shared(value: [Self.campaignID: Self.oldLink])) {
            $0.calendarReminderService.requestAccess = {
                accessRequestCount.withValue {
                    $0 += 1
                }
                return .denied
            }
            $0.calendarReminderService.removeReminder = { eventIdentifier in
                removedEventIdentifiers.withValue {
                    $0.append(eventIdentifier)
                }
            }
            $0.campaignService.removeReminderLink = { campaignID in
                removedCampaignIDs.withValue {
                    $0.append(campaignID)
                }
            }
        }

        // When
        await store.send(
            .campaignRemoved(campaignID: Self.campaignID, eventIdentifier: "EVT-old")
        ) {
            $0.$links.withLock {
                $0[Self.campaignID] = nil
            }
        }

        // Then
        await store.receive(\.eventRemovalResponse)
        #expect(store.state.links[Self.campaignID] == nil)
        #expect(removedEventIdentifiers.value == ["EVT-old"])
        #expect(removedCampaignIDs.value.isEmpty)
        #expect(accessRequestCount.value == 0)
    }

    /// 開團已刪除但事件移除失敗時，共用連結維持清除並回報事件移除失敗，不呼叫 `removeReminderLink`
    @Test
    func campaignRemoved_事件移除失敗_連結維持清除並回報() async {
        // Given
        let removedEventIdentifiers = LockIsolated<[String]>([])
        let removedCampaignIDs = LockIsolated<[String]>([])
        let failingRemoveReminder: CalendarReminderService.RemoveReminder = { eventIdentifier throws(CalendarReminderError) in
            removedEventIdentifiers.withValue {
                $0.append(eventIdentifier)
            }
            throw .system(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = Self.makeStore(links: Shared(value: [Self.campaignID: Self.oldLink])) {
            $0.calendarReminderService.removeReminder = failingRemoveReminder
            $0.campaignService.removeReminderLink = { campaignID in
                removedCampaignIDs.withValue {
                    $0.append(campaignID)
                }
            }
        }

        // When
        await store.send(
            .campaignRemoved(campaignID: Self.campaignID, eventIdentifier: "EVT-old")
        ) {
            $0.$links.withLock {
                $0[Self.campaignID] = nil
            }
        }

        // Then
        await store.receive(\.eventRemovalResponse)
        await store.receive(\.delegate.failed, .eventRemovalAfterDeleteFailed)
        #expect(store.state.links[Self.campaignID] == nil)
        #expect(removedEventIdentifiers.value == ["EVT-old"])
        #expect(removedCampaignIDs.value.isEmpty)
    }
}
