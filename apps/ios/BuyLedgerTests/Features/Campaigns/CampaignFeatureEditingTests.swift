//
//  CampaignFeatureEditingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignFeature` 的單元測試，涵蓋從開團列表開啟新增與編輯表單
@MainActor
struct CampaignFeatureEditingTests {

    /// 驗證按下新增開團時開啟新表單，提醒時間預設為當天上午 9 點 (以注入的曆法計算)
    @Test
    func list_點選新增開團_呈現空白表單() async {
        // Given
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
        }

        // When
        await store.send(.list(.view(.newCampaignTapped)))

        // Then
        await store.receive(\.list.delegate.requested) {
            $0.presentation.destination = .edit(
                CampaignEditFeature.State(
                    id: UUID(0),
                    currentDate: TestDependencies.fixedNow,
                    reminderTimestamp: Date(timeIntervalSince1970: 1_777_539_600)
                )
            )
        }
        #expect(
            store.state.presentation.destination?.edit?.draft.reminderTimestamp
                == Date(timeIntervalSince1970: 1_777_539_600)
        )
    }

    /// 驗證點選編輯時，表單帶入開團的名稱、結單日與狀態；有提醒連結時開啟提醒並沿用連結時間，沒有時關閉提醒並取結單日上午 9 點
    ///
    /// - Parameter hasReminder: 開團是否已有提醒連結
    @Test(arguments: [false, true])
    func list_點選編輯開團_表單帶入原資料與提醒設定(hasReminder: Bool) async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: Date(timeIntervalSince1970: 1_777_766_400),
            status: .closed
        )
        let timestamp = Date(timeIntervalSince1970: 1_777_744_800)
        let initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        if hasReminder {
            initial.$reminderLinks.withLock {
                $0 = [
                    "C1": CampaignReminderLink(
                        eventIdentifier: "EVT-1",
                        reminderTimestamp: timestamp
                    ),
                ]
            }
        }
        let defaultTimestamp = Date(timeIntervalSince1970: 1_777_798_800)
        let expected = CampaignEditFeature.State(
            original: campaign,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            isReminderWanted: hasReminder,
            reminderTimestamp: hasReminder ? timestamp : defaultTimestamp
        )
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
        }

        // When
        await store.send(.list(.view(.editCampaignTapped("C1"))))

        // Then
        await store.receive(\.list.delegate.requested) {
            $0.presentation.destination = .edit(expected)
        }
        #expect(store.state.presentation.destination == .edit(expected))
        let draft = store.state.presentation.destination?.edit?.draft
        #expect(draft?.name == "團")
        #expect(draft?.closeDate == Date(timeIntervalSince1970: 1_777_766_400))
        #expect(draft?.status == .closed)
        #expect(draft?.wantsReminder == hasReminder)
        #expect(draft?.reminderTimestamp == (hasReminder ? timestamp : defaultTimestamp))
    }

    /// 驗證列表要求編輯不存在的開團時，請求仍會送出，但表單不開啟
    @Test
    func list_要求編輯不存在的開團_不呈現表單() async {
        // Given
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        }

        // When
        await store.send(.list(.view(.editCampaignTapped("missing"))))

        // Then
        await store.receive(\.list.delegate.requested)
        #expect(store.state.presentation.destination == nil)
    }
}
