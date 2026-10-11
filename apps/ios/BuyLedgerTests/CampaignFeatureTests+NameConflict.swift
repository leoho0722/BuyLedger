//
//  CampaignFeatureTests+NameConflict.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 新名稱去掉前後空白後與既有開團相同時顯示重名原因，不寫入也不要求行事曆權限
    ///
    /// - Note: `testValue` 的 `campaignService.saveCampaign` 與
    ///   `calendarReminderService.requestAccess` 都是 `unimplemented`；重名時誤寫入或要求
    ///   行事曆權限會使測試失敗
    @Test
    func presentation_新增名稱與既有開團重複_拒絕寫入() async {
        // Given
        let existing = Campaign.fixture(
            id: "C1",
            name: "母親節團",
            closeDate: nil,
            status: .ongoing
        )
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            // 開啟提醒；若守門失效應觸發行事曆呼叫
            wantsReminder: true,
            reminderTimestamp: TestDependencies.fixedNow
        )
        // 前後空白不應影響比對：去掉前後空白後與既有開團同名
        editState.draft.name = "  母親節團  "
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [existing]
        }
        initial.presentation.destination = .edit(editState)

        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveButtonTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested)
        await store.receive(\.presentation.delegate.saveRequested) {
            $0.presentation.destination?.modify(\.edit) {
                $0.nameConflictMessage = "campaigns.edit.message.anotherCampaignAlready"
            }
        }
        #expect(
            store.state.presentation.destination?.edit?.nameConflictMessage
                == "campaigns.edit.message.anotherCampaignAlready"
        )
    }

    /// 表單開啟後才載入同名開團，送出時以最新清單拒絕且不寫入或操作行事曆
    @Test
    func presentation_表單開啟後載入同名開團_維持表單並拒絕寫入() async {
        // Given
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: true,
            reminderTimestamp: TestDependencies.fixedNow
        )
        editState.draft.name = "  母親節團  "
        let loaded = Campaign(
            id: "C1",
            name: " 母親節團 ",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        var initial = CampaignFeature.State()
        initial.load.$isLoading.withLock {
            $0 = true
        }
        initial.presentation.destination = .edit(editState)
        let saveCalls = LockIsolated(0)
        let calendarCalls = LockIsolated<[String]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = { _ in
                saveCalls.withValue {
                    $0 += 1
                }
            }
            $0.calendarReminderService.requestAccess = {
                calendarCalls.withValue {
                    $0.append("requestAccess")
                }
                return .granted
            }
            $0.calendarReminderService.addReminder = { _, _, _ in
                calendarCalls.withValue {
                    $0.append("addReminder")
                }
                return "UNEXPECTED-EVENT"
            }
            $0.calendarReminderService.removeReminder = { _ in
                calendarCalls.withValue {
                    $0.append("removeReminder")
                }
            }
        }
        await store.send(.load(.campaignsResponse(.success([loaded])))) {
            $0.load.$isLoading.withLock {
                $0 = false
            }
            $0.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.$campaigns.withLock {
                $0 = [loaded]
            }
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveButtonTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested)
        await store.receive(\.presentation.delegate.saveRequested) {
            $0.presentation.destination?.modify(\.edit) {
                $0.nameConflictMessage = "campaigns.edit.message.anotherCampaignAlready"
            }
        }
        await store.finish()
        var expectedEdit = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: Date(timeIntervalSince1970: 1_777_507_200),
            wantsReminder: true,
            reminderTimestamp: Date(timeIntervalSince1970: 1_777_507_200)
        )
        expectedEdit.draft.name = "  母親節團  "
        expectedEdit.nameConflictMessage = "campaigns.edit.message.anotherCampaignAlready"
        #expect(store.state.presentation.destination == .edit(expectedEdit))
        #expect(store.state.campaigns == [loaded])
        #expect(saveCalls.value == 0)
        #expect(calendarCalls.value == [])
    }
}
