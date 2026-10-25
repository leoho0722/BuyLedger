//
//  CampaignFeatureNameConflictTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignFeature` 的單元測試，涵蓋開團名稱與既有開團重複時的拒絕寫入
@MainActor
struct CampaignFeatureNameConflictTests {

    /// 驗證新名稱去掉前後空白後與既有開團相同時，表單顯示重名原因，不寫入也不要求行事曆權限
    ///
    /// - Note: 表單已開啟提醒，未覆寫 `campaignService.saveCampaign` 與
    ///   `calendarReminderService.requestAccess`，守門失效而呼叫任一方法時測試失敗
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
            isReminderWanted: true,
            reminderTimestamp: TestDependencies.fixedNow
        )
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

    /// 驗證表單開啟中才收到含同名開團的載入回應時，表單維持開啟，送出前不顯示重名原因
    @Test
    func load_表單開啟中收到同名開團_維持表單且不提前顯示重名() async {
        // Given
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            isReminderWanted: true,
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
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
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

        // Then
        await store.finish()
        #expect(store.state.presentation.destination == .edit(editState))
        #expect(store.state.presentation.destination?.edit?.nameConflictMessage == nil)
    }

    /// 驗證表單開啟後才載入同名開團，送出時以最新清單判定重名，表單維持開啟，不寫入也不操作行事曆
    @Test
    func presentation_表單開啟後載入同名開團_維持表單並拒絕寫入() async {
        // Given
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            isReminderWanted: true,
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
        initial.$campaigns.withLock {
            $0 = [loaded]
        }
        initial.load.$hasLoaded.withLock {
            $0 = true
        }
        initial.presentation.destination = .edit(editState)
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
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
            isReminderWanted: true,
            reminderTimestamp: Date(timeIntervalSince1970: 1_777_507_200)
        )
        expectedEdit.draft.name = "  母親節團  "
        expectedEdit.nameConflictMessage = "campaigns.edit.message.anotherCampaignAlready"
        #expect(store.state.presentation.destination == .edit(expectedEdit))
        #expect(
            store.state.presentation.destination?.edit?.nameConflictMessage
                == "campaigns.edit.message.anotherCampaignAlready"
        )
        #expect(store.state.presentation.destination?.edit?.draft.name == "  母親節團  ")
        #expect(store.state.campaigns == [loaded])
    }
}
