//
//  CampaignEditFeatureInitTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignEditFeature.State` 的單元測試，涵蓋不同初始條件下的預設草稿與提醒時間
struct CampaignEditFeatureInitTests {

    /// 驗證新增表單沒有原開團與提醒連結時，草稿取預設值，提醒時間為現在當天上午九點，且尚未有未儲存變更
    @Test
    func init_新增表單_帶預設草稿與今天上午九點提醒時間() {
        // Given
        let now = TestDependencies.fixedNow

        // When
        let state = CampaignEditFeature.State(
            id: UUID(0),
            now: now,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(state.original == nil)
        #expect(state.draft.name.isEmpty)
        #expect(state.draft.openDate == now)
        #expect(state.draft.wantsReminder == false)
        #expect(state.draft.reminderTimestamp == Date(timeIntervalSince1970: 1_777_539_600))
        #expect(state.isDirty == false)
    }

    /// 驗證既有開團有提醒連結時，開啟提醒並帶入連結的提醒時間，不採用結單日的預設時間
    @Test
    func init_既有開團有提醒連結_帶入連結時間並開啟提醒() {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "三月團",
            openDate: Date(timeIntervalSince1970: 0),
            closeDate: Date(timeIntervalSince1970: 1_778_846_400)
        )
        let linkedTimestamp = Date(timeIntervalSince1970: 1_778_423_400)
        let link = CampaignReminderLink(eventIdentifier: "E1", reminderTimestamp: linkedTimestamp)

        // When
        let state = CampaignEditFeature.State(
            original: campaign,
            link: link,
            id: UUID(0),
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(state.original == campaign)
        #expect(state.draft.name == campaign.name)
        #expect(state.draft.wantsReminder)
        #expect(state.draft.reminderTimestamp == linkedTimestamp)
        #expect(state.isDirty == false)
    }

    /// 驗證既有開團沒有提醒連結但有結單日時，不開啟提醒，提醒時間取結單日上午九點
    @Test
    func init_既有開團無連結有結單日_不開啟提醒並取結單日上午九點() {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "三月團",
            openDate: Date(timeIntervalSince1970: 0),
            closeDate: Date(timeIntervalSince1970: 1_778_846_400)
        )

        // When
        let state = CampaignEditFeature.State(
            original: campaign,
            link: nil,
            id: UUID(0),
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(state.draft.wantsReminder == false)
        #expect(state.draft.reminderTimestamp == Date(timeIntervalSince1970: 1_778_835_600))
    }

    /// 驗證既有開團沒有提醒連結也沒有結單日時，不開啟提醒，提醒時間取現在當天上午九點
    @Test
    func init_既有開團無連結無結單日_不開啟提醒並取今天上午九點() {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "三月團",
            openDate: Date(timeIntervalSince1970: 0),
            closeDate: nil
        )

        // When
        let state = CampaignEditFeature.State(
            original: campaign,
            link: nil,
            id: UUID(0),
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(state.draft.wantsReminder == false)
        #expect(state.draft.reminderTimestamp == Date(timeIntervalSince1970: 1_777_539_600))
    }
}
