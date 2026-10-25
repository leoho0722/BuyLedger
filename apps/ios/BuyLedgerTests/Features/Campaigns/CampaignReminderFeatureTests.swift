//
//  CampaignReminderFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `CampaignReminderFeature` 的單元測試，涵蓋連結載入、建立與移除
@MainActor
struct CampaignReminderFeatureTests {

    /// 驗證尚未載入時讀取全部連結，存入共用連結，並標記為已載入
    @Test
    func linksRequested_尚未載入_載入並保存連結() async {
        // Given
        let loadedLinks = [
            CampaignReminderFeatureTestSupport.campaignID:
                CampaignReminderFeatureTestSupport.oldLink,
        ]
        let store = CampaignReminderFeatureTestSupport.makeStore(links: Shared(value: [:])) {
            $0.campaignService.fetchReminderLinks = {
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

    /// 驗證已成功載入過時，不再讀取連結
    ///
    /// - Note: 未覆寫的 `fetchReminderLinks` 是 `unimplemented`；重複讀取會使測試失敗
    @Test
    func linksRequested_已載入過_不重複讀取() async {
        // Given
        let store = CampaignReminderFeatureTestSupport.makeStore(
            links: Shared(value: [:]),
            hasLoadedLinks: true
        ) { _ in
        }

        // When
        await store.send(.linksRequested)

        // Then
        #expect(store.state.hasLoadedLinks)
    }

    /// 驗證讀取連結失敗時，連結維持為空，不標記已載入，也不回報任何提示
    @Test
    func linksRequested_載入失敗_連結維持空且不回報() async {
        // Given
        let failingFetchLinks: CampaignService.FetchReminderLinks = { () throws(PersistenceError) in
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = CampaignReminderFeatureTestSupport.makeStore(links: Shared(value: [:])) {
            $0.campaignService.fetchReminderLinks = failingFetchLinks
        }

        // When
        await store.send(.linksRequested)

        // Then
        await store.receive(\.linksResponse.failure)
        #expect(store.state.links.isEmpty)
        #expect(store.state.hasLoadedLinks == false)
    }

    /// 驗證建立提醒時，依請求的標題、日期與提示位移建立全天事件，先請求權限，再保存連結
    @Test
    func reconcileRequested_建立提醒_以指定日期與提示位移建立事件並保存連結() async {
        // Given
        let operations = LockIsolated<[String]>([])
        let addedReminders = LockIsolated<[CampaignReminderFeatureTestSupport.RecordedReminder]>([])
        let savedLinks = LockIsolated<[CampaignReminderFeatureTestSupport.SavedLink]>([])
        let expectedReminder = CampaignReminderFeatureTestSupport.RecordedReminder(
            title: "「新團」訂購提醒",
            eventDate: CampaignReminderFeatureTestSupport.eventDate,
            alarmOffset: 64_800
        )
        let store = CampaignReminderFeatureTestSupport.makeStore(links: Shared(value: [:])) {
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
        }
        let newLink = CampaignReminderFeatureTestSupport.newLink

        // When
        await store.send(
            .reconcileRequested(
                CampaignReminderFeatureTestSupport.makeRequest(.create, title: "「新團」訂購提醒")
            )
        )

        // Then
        await store.receive(\.createResponse) {
            $0.$links.withLock {
                $0[CampaignReminderFeatureTestSupport.campaignID] = newLink
            }
        }
        #expect(operations.value == ["requestAccess", "addReminder", "saveReminderLink"])
        #expect(addedReminders.value == [expectedReminder])
        #expect(
            savedLinks.value == [
                CampaignReminderFeatureTestSupport.SavedLink(
                    campaignID: CampaignReminderFeatureTestSupport.campaignID,
                    link: CampaignReminderFeatureTestSupport.newLink
                ),
            ]
        )
    }

    /// 驗證清除提醒意圖時，先移除行事曆事件再清除連結，且不請求行事曆權限
    ///
    /// - Note: 未覆寫的 `requestAccess` 是 `unimplemented`；請求權限會使測試失敗
    @Test
    func reconcileRequested_移除提醒_移除事件與連結且不請求權限() async {
        // Given
        let operations = LockIsolated<[String]>([])
        let store = CampaignReminderFeatureTestSupport.makeStore(
            links: Shared(value: [
                CampaignReminderFeatureTestSupport.campaignID:
                    CampaignReminderFeatureTestSupport.oldLink,
            ])
        ) {
            $0.calendarReminderService.removeReminder = { eventIdentifier in
                operations.withValue {
                    $0.append("removeReminder:\(eventIdentifier)")
                }
            }
            $0.campaignService.removeReminderLink = { campaignID in
                operations.withValue {
                    $0.append("removeReminderLink:\(campaignID)")
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
        #expect(operations.value == ["removeReminder:EVT-old", "removeReminderLink:C1"])
    }
}
