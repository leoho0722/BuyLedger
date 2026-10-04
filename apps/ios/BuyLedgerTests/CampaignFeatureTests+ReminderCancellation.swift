//
//  CampaignFeatureTests+ReminderCancellation.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 既有提醒保持開啟且時間已修改時，取消並捨棄草稿不會調解行事曆或改寫提醒連結
    ///
    /// - Note: 行事曆與提醒連結 Service 保留 `unimplemented`，任何呼叫都會使測試失敗
    /// - Throws: 表單未帶入既有提醒或未標記提醒時間變更時拋出測試錯誤
    @Test
    func formSheetDismissed_修改提醒時間後取消並捨棄_不觸碰行事曆且保留連結() async throws(any Error) {
        // Given
        let campaign = Campaign.fixture(id: "C1", name: "四月韓國團")
        let oldLink = CampaignReminderLink(
            eventIdentifier: "E-OLD",
            reminderTimestamp: Date(timeIntervalSince1970: 1_776_675_600)
        )
        // 提醒由 2026-04-20 09:00 UTC 改為同日 18:00 UTC
        let changedTimestamp = Date(timeIntervalSince1970: 1_776_708_000)
        var editState = CampaignEditFeature.State(
            original: campaign,
            link: oldLink,
            id: UUID(0),
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        try #require(editState.draft.wantsReminder)
        try #require(editState.draft.reminderTimestamp == oldLink.reminderTimestamp)
        editState.draft.reminderTimestamp = changedTimestamp
        try #require(editState.isDirty)
        let originalLinks = ["C1": oldLink]
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.$reminderLinks.withLock {
            $0 = originalLinks
        }
        initial.destination = .edit(editState)
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        await store.send(.destination(.presented(.edit(.view(.cancelButtonTapped))))) {
            $0.destination?.modify(\.edit) {
                $0.discardConfirmation = Self.discardAlert
            }
        }

        await store.send(
            .destination(.presented(.edit(.discardConfirmation(.presented(.discard)))))
        ) {
            $0.destination?.modify(\.edit) {
                $0.discardConfirmation = nil
            }
        }
        await store.receive(\.destination.dismiss) {
            $0.destination = nil
            $0.presentationQueue.isFormClosing = true
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentationQueue.isFormClosing = false
        }

        // Then
        await store.finish()
        #expect(store.state.destination == nil)
        #expect(store.state.presentationQueue == CampaignPresentationQueue())
        #expect(store.state.reminderLinks == originalLinks)
        #expect(store.state.reminder.links == originalLinks)
    }
}
