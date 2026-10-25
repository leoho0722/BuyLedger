//
//  CampaignReminderFeatureRemovalTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `CampaignReminderFeature` 的單元測試，涵蓋清除提醒與開團刪除時的移除流程
@MainActor
struct CampaignReminderFeatureRemovalTests {

    /// 驗證清除提醒時事件移除失敗 (事件可能已被手動刪除)，仍清除連結，且不回報錯誤
    ///
    /// - Note: 未覆寫的 `requestAccess` 是 `unimplemented`；被呼叫會使測試失敗
    @Test
    func reconcileRequested_移除提醒且事件移除失敗_仍清除連結且不回報() async {
        // Given
        let removedEventIdentifiers = LockIsolated<[String]>([])
        let removedCampaignIDs = LockIsolated<[String]>([])
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
            $0.calendarReminderService.removeReminder = failingRemoveReminder
            $0.campaignService.removeReminderLink = { campaignID in
                removedCampaignIDs.withValue {
                    $0.append(campaignID)
                }
            }
        }

        // When
        await store.send(
            .reconcileRequested(
                CampaignReminderFeatureTestSupport.makeRequest(.remove(eventIdentifier: "EVT-old"))
            )
        )

        // Then
        await store.receive(\.linkRemovalResponse) {
            $0.$links.withLock {
                $0[CampaignReminderFeatureTestSupport.campaignID] = nil
            }
        }
        #expect(removedEventIdentifiers.value == ["EVT-old"])
        #expect(removedCampaignIDs.value == ["C1"])
    }

    /// 驗證移除 EVT-old 的提醒請求遇到連結刪除失敗時，共用連結仍指向 EVT-old，並回報 `.linkRemovalFailed`
    @Test
    func reconcileRequested_移除提醒但連結移除失敗_保留連結並回報() async {
        // Given
        let failingRemoveLink: CampaignService.RemoveReminderLink = { _ throws(PersistenceError) in
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = CampaignReminderFeatureTestSupport.makeStore(
            links: Shared(value: [
                CampaignReminderFeatureTestSupport.campaignID:
                    CampaignReminderFeatureTestSupport.oldLink,
            ])
        ) {
            $0.calendarReminderService.removeReminder = { _ in
            }
            $0.campaignService.removeReminderLink = failingRemoveLink
        }

        // When
        await store.send(
            .reconcileRequested(
                CampaignReminderFeatureTestSupport.makeRequest(.remove(eventIdentifier: "EVT-old"))
            )
        )

        // Then
        await store.receive(\.linkRemovalResponse)
        await store.receive(\.delegate.failed, .linkRemovalFailed)
        #expect(
            store.state.links[CampaignReminderFeatureTestSupport.campaignID]
                == CampaignReminderFeatureTestSupport.oldLink
        )
    }

    /// 驗證刪除沒有事件識別碼的開團時，只清除共用連結，不移除事件，也不呼叫 `removeReminderLink`
    ///
    /// - Note: 未覆寫的 `removeReminder` 與 `removeReminderLink` 是 `unimplemented`；被呼叫會使測試失敗
    @Test
    func campaignRemoved_沒有事件識別碼_清除共用連結且未呼叫移除連結() async {
        // Given
        let store = CampaignReminderFeatureTestSupport.makeStore(
            links: Shared(value: [
                CampaignReminderFeatureTestSupport.campaignID:
                    CampaignReminderFeatureTestSupport.oldLink,
            ])
        ) { _ in
        }

        // When
        await store.send(
            .campaignRemoved(
                campaignID: CampaignReminderFeatureTestSupport.campaignID,
                eventIdentifier: nil
            )
        ) {
            $0.$links.withLock {
                $0[CampaignReminderFeatureTestSupport.campaignID] = nil
            }
        }

        // Then
        #expect(store.state.links[CampaignReminderFeatureTestSupport.campaignID] == nil)
    }

    /// 驗證刪除有提醒的開團時，清除共用連結並移除事件，不呼叫 `removeReminderLink`，也不請求行事曆權限
    ///
    /// - Note: 未覆寫的 `removeReminderLink` 與 `requestAccess` 是 `unimplemented`；被呼叫會使測試失敗
    @Test
    func campaignRemoved_有事件識別碼_清除共用連結並移除事件() async {
        // Given
        let removedEventIdentifiers = LockIsolated<[String]>([])
        let store = CampaignReminderFeatureTestSupport.makeStore(
            links: Shared(value: [
                CampaignReminderFeatureTestSupport.campaignID:
                    CampaignReminderFeatureTestSupport.oldLink,
            ])
        ) {
            $0.calendarReminderService.removeReminder = { eventIdentifier in
                removedEventIdentifiers.withValue {
                    $0.append(eventIdentifier)
                }
            }
        }

        // When
        await store.send(
            .campaignRemoved(
                campaignID: CampaignReminderFeatureTestSupport.campaignID,
                eventIdentifier: "EVT-old"
            )
        ) {
            $0.$links.withLock {
                $0[CampaignReminderFeatureTestSupport.campaignID] = nil
            }
        }

        // Then
        await store.receive(\.eventRemovalResponse)
        #expect(store.state.links[CampaignReminderFeatureTestSupport.campaignID] == nil)
        #expect(removedEventIdentifiers.value == ["EVT-old"])
    }

    /// 驗證開團已刪除但事件移除失敗時，共用連結維持清除並回報事件移除失敗，不呼叫 `removeReminderLink`
    ///
    /// - Note: 未覆寫的 `removeReminderLink` 是 `unimplemented`；被呼叫會使測試失敗
    @Test
    func campaignRemoved_事件移除失敗_連結維持清除並回報() async {
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
            $0.calendarReminderService.removeReminder = failingRemoveReminder
        }

        // When
        await store.send(
            .campaignRemoved(
                campaignID: CampaignReminderFeatureTestSupport.campaignID,
                eventIdentifier: "EVT-old"
            )
        ) {
            $0.$links.withLock {
                $0[CampaignReminderFeatureTestSupport.campaignID] = nil
            }
        }

        // Then
        await store.receive(\.eventRemovalResponse)
        await store.receive(\.delegate.failed, .eventRemovalAfterDeleteFailed)
        #expect(store.state.links[CampaignReminderFeatureTestSupport.campaignID] == nil)
        #expect(removedEventIdentifiers.value == ["EVT-old"])
    }
}
