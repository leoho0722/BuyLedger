//
//  CampaignFeatureReminderIntegrationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignFeature` 的單元測試，涵蓋載入提醒連結，以及儲存開團後交給提醒流程的請求內容
@MainActor
struct CampaignFeatureReminderIntegrationTests {

    /// 驗證開團功能出現時，提醒流程載入連結，共用連結與已載入旗標同步更新
    @Test
    func task_容器出現_轉送提醒連結載入並保存共用連結() async {
        // Given
        let link = CampaignReminderLink(
            eventIdentifier: "EVT-1",
            reminderTimestamp: Date(timeIntervalSince1970: 1_776_675_600)
        )
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchReminderLinks = {
                ["C1": link]
            }
        }

        // When
        await store.send(.view(.task))

        // Then
        await store.receive(\.reminder.linksRequested) {
            $0.$reminderLinks.withLock {
                $0 = ["C1": link]
            }
        }
        await store.receive(\.reminder.linksResponse.success) {
            $0.reminder.hasLoadedLinks = true
        }
        #expect(store.state.reminderLinks == ["C1": link])
    }

    /// 驗證儲存成功後交給提醒流程的請求，六個欄位都與使用者在表單選定的提醒一致
    ///
    /// - Parameter scenario: 儲存的開團、既有連結與預期送出的請求
    /// - Note: 行事曆權限回應拒絕，讓每個案例都在建立事件前結束流程，請求內容是唯一變因
    @Test(arguments: CampaignFeatureTestSupport.ReminderRequestScenario.scenarios)
    func presentation_儲存成功_轉送內容正確的提醒請求(
        scenario: CampaignFeatureTestSupport.ReminderRequestScenario
    ) async {
        // Given
        var editState = CampaignEditFeature.State(
            original: scenario.original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            isReminderWanted: true,
            reminderTimestamp: scenario.reminderTimestamp
        )
        editState.draft.name = scenario.draftName
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = scenario.existingCampaigns
        }
        initial.$reminderLinks.withLock {
            $0 = scenario.links
        }
        initial.presentation.destination = .edit(editState)
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(1))
            $0.campaignService.saveCampaign = { _ in
            }
            $0.calendarReminderService.requestAccess = {
                .denied
            }
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveButtonTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$campaigns.withLock {
                $0 = [scenario.expectedCampaign]
            }
        }
        await store.receive(\.presentation.delegate.saveRequested) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.success)
        await store.receive(\.writes.delegate.saved)
        await store.receive(\.reminder.reconcileRequested, scenario.expectedRequest)
        await store.receive(\.reminder.createResponse)
        await store.receive(\.reminder.delegate.failed, .accessDenied)
        await store.receive(\.presentation.noticeRequested, .reminderFailure(.accessDenied)) {
            $0.presentation.queue.pendingNotice = CampaignFeatureTestSupport.accessDeniedAlert
        }
        #expect(store.state.reminderLinks == scenario.links)
    }

    /// 驗證儲存時關閉提醒，交給提醒流程的請求以既有連結的事件識別碼移除行事曆事件，並清除提醒連結
    @Test
    func presentation_儲存且清除提醒意圖_轉送移除請求並清除連結() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "四月團",
            closeDate: nil,
            status: .ongoing
        )
        let timestamp = Date(timeIntervalSince1970: 1_776_675_600)
        let editState = CampaignEditFeature.State(
            original: campaign,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            isReminderWanted: false,
            reminderTimestamp: timestamp
        )
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.$reminderLinks.withLock {
            $0 = [
                "C1": CampaignReminderLink(eventIdentifier: "EVT-1", reminderTimestamp: timestamp),
            ]
        }
        initial.presentation.destination = .edit(editState)
        let expectedCampaign = Campaign(
            id: "C1",
            name: "四月團",
            openDate: campaign.openDate,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let expectedRequest = CampaignReminderRequest(
            campaignID: "C1",
            reconcile: .remove(eventIdentifier: "EVT-1"),
            title: "「四月團」訂購提醒",
            eventDate: Date(timeIntervalSince1970: 1_776_643_200),
            alarmOffset: 32_400,
            timestamp: timestamp
        )
        let removedEventIDs = LockIsolated<[String]>([])
        let removedLinkIDs = LockIsolated<[String]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = { _ in
            }
            $0.calendarReminderService.removeReminder = { eventID in
                removedEventIDs.withValue {
                    $0.append(eventID)
                }
            }
            $0.campaignService.removeReminderLink = { campaignID in
                removedLinkIDs.withValue {
                    $0.append(campaignID)
                }
            }
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveButtonTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$campaigns.withLock {
                $0[0] = expectedCampaign
            }
            $0.$reminderLinks.withLock {
                $0["C1"] = nil
            }
        }
        await store.receive(\.presentation.delegate.saveRequested) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.success)
        await store.receive(\.writes.delegate.saved)
        await store.receive(\.reminder.reconcileRequested, expectedRequest)
        await store.receive(\.reminder.linkRemovalResponse)
        #expect(removedEventIDs.value == ["EVT-1"])
        #expect(removedLinkIDs.value == ["C1"])
    }
}
