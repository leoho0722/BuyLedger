//
//  CampaignEditFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/19.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct CampaignEditFeatureTests {

    // MARK: - Tests

    // MARK: Dirty State

    @Test func newCampaignIsNotDirtyUntilEdited() async {
        var state = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        #expect(state.isDirty == false)

        state.draftName = "四月團"
        #expect(state.isDirty == true)
    }

    @Test func existingCampaignIsDirtyThenCleanWhenRestored() async {
        let original = Campaign(
            id: "C1",
            name: "三月團",
            openDate: Date(timeIntervalSince1970: 0),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        var state = CampaignEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        #expect(state.isDirty == false)

        state.draftName = "四月團"
        #expect(state.isDirty == true)

        state.draftName = original.name
        #expect(state.isDirty == false)
    }

    @Test func reminderIntentChangeMarksDirty() async {
        var state = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        #expect(state.isDirty == false)

        // 提醒意圖屬可儲存內容，變更應觸發 dirty
        state.wantsReminder = true
        #expect(state.isDirty == true)
    }

    @Test func reminderTimestampChangeMarksDirty() async {
        var state = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            wantsReminder: true,
            reminderTimestamp: TestDependencies.fixedNow
        )
        #expect(state.isDirty == false)

        // 提醒時間戳屬可儲存內容，inline 編輯後應觸發 dirty
        state.reminderTimestamp = TestDependencies.fixedNow.addingTimeInterval(3600)
        #expect(state.isDirty == true)
    }

    @Test func cancelWithChangesPresentsDiscardConfirmation() async {
        var initial = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        initial.draftName = "四月團"
        let store = TestStore(initialState: initial) {
            CampaignEditFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off

        await store.send(.cancelTapped)
        #expect(store.state.discardConfirmation != nil)

        // 確認捨棄後關閉表單 (dismiss 由注入的 no-op 承接)
        await store.send(.discardConfirmation(.presented(.discard)))
    }

    @Test func cancelWithoutChangesDismissesDirectly() async {
        let store = TestStore(
            initialState: CampaignEditFeature.State(
                id: UUID(0),
                currentDate: TestDependencies.fixedNow,
                reminderTimestamp: TestDependencies.fixedNow
            )
        ) {
            CampaignEditFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off

        await store.send(.cancelTapped)
        #expect(store.state.discardConfirmation == nil)
    }
}
