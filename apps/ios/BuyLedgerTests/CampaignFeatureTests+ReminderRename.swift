//
//  CampaignFeatureTests+ReminderRename.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 原開團改名並儲存成功時，轉送以新名稱為標題的重建提醒請求
    ///
    /// - Note: 行事曆權限回應拒絕，流程在建立事件前結束，只驗證轉送的請求內容
    @Test
    func destination_改名儲存成功_轉送內容正確的重建提醒請求() async {
        // Given
        let scenario = ReminderRequestScenario.renamedScenario
        var editState = CampaignEditFeature.State(
            original: scenario.original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: true,
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
        initial.destination = .edit(editState)
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(1))
            $0.campaignService.saveCampaign = { _ in
            }
            $0.orderService.renameOrderCampaign = { _, _ in
            }
            $0.calendarReminderService.requestAccess = {
                .denied
            }
        }

        // When
        await store.send(.destination(.presented(.edit(.view(.saveButtonTapped)))))

        // Then
        await store.receive(\.destination.presented.edit.delegate.saveRequested) {
            $0.destination = nil
            $0.presentationQueue.isFormClosing = true
            $0.$campaigns.withLock {
                $0 = [scenario.expectedCampaign]
            }
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.success)
        await store.receive(\.writes.renameResponse)
        await store.receive(\.writes.delegate.renamed)
        await store.receive(\.writes.delegate.saved)
        await store.receive(\.delegate.campaignRenamed)
        await store.receive(\.reminder.reconcileRequested, scenario.expectedRequest)
        await store.receive(\.reminder.createResponse)
        await store.receive(\.reminder.delegate.failed, .accessDenied) {
            $0.presentationQueue.pendingNotice = Self.accessDeniedAlert
        }
        #expect(store.state.reminderLinks == scenario.links)
    }
}
