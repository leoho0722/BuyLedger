//
//  CampaignFeatureReminderCancellationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignFeature` 的單元測試，涵蓋修改提醒時間後捨棄表單
@MainActor
struct CampaignFeatureReminderCancellationTests {

    /// 驗證既有提醒保持開啟且時間已修改時，取消並捨棄草稿，行事曆不被觸碰，提醒連結維持原值
    ///
    /// - Throws: 表單未帶入既有提醒與時間，或改時間後表單未視為已修改時丟出測試錯誤
    /// - Note: 行事曆與提醒連結 Service 保留 `unimplemented`，任何呼叫都會使測試失敗
    @Test
    func presentation_修改提醒時間後取消並捨棄_不觸碰行事曆且保留連結() async throws {
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
        editState.discardConfirmation = CampaignFeatureTestSupport.discardAlert
        let originalLinks = ["C1": oldLink]
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.$reminderLinks.withLock {
            $0 = originalLinks
        }
        initial.presentation.destination = .edit(editState)
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(
            .presentation(
                .destination(.presented(.edit(.discardConfirmation(.presented(.discard)))))
            )
        ) {
            $0.presentation.destination?.modify(\.edit) {
                $0.discardConfirmation = nil
            }
        }

        // Then
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.finish()
        #expect(store.state.presentation.destination == nil)
        #expect(store.state.reminderLinks == originalLinks)
        #expect(store.state.reminder.links == originalLinks)
    }
}
