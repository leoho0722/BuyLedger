//
//  CampaignFeatureUnchangedNameTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignFeature` 的單元測試，涵蓋編輯既有開團沒改名時的儲存
@MainActor
struct CampaignFeatureUnchangedNameTests {

    /// 驗證編輯既有開團沒改名時，直接儲存成功並關閉表單
    @Test
    func presentation_編輯時保留原開團名稱_成功儲存() async {
        // Given
        let existing = Campaign.fixture(
            id: "C1",
            name: "四月團",
            closeDate: nil,
            status: .ongoing
        )
        let editState = CampaignEditFeature.State(
            original: existing,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [existing]
        }
        initial.presentation.destination = .edit(editState)

        // 沒有結單日的舊開團，儲存草稿會以目前日期填入
        let expectedCampaign = Campaign(
            id: "C1",
            name: "四月團",
            openDate: existing.openDate,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = { campaign in
                savedCampaigns.withValue {
                    $0.append(campaign)
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
        }
        await store.receive(\.presentation.delegate.saveRequested) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.success)
        await store.receive(\.writes.delegate.saved)
        await store.finish()
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 驗證資料原本就有同名開團時，沒改名的編輯仍可儲存，另一筆同名開團保留
    @Test
    func presentation_既有資料已有同名開團_未改名仍可儲存() async {
        // Given
        // 既有同名開團可維持原名，新建或改名時才檢查重複
        let campaignA = Campaign.fixture(
            id: "A",
            name: "重複團",
            closeDate: nil,
            status: .ongoing
        )
        let campaignB = Campaign.fixture(
            id: "B",
            name: "重複團",
            closeDate: nil,
            status: .ongoing
        )
        let editState = CampaignEditFeature.State(
            original: campaignA,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaignA, campaignB]
        }
        initial.presentation.destination = .edit(editState)

        // 沒有結單日的舊開團，儲存草稿會以目前日期填入
        let expectedCampaign = Campaign(
            id: "A",
            name: "重複團",
            openDate: campaignA.openDate,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = { campaign in
                savedCampaigns.withValue {
                    $0.append(campaign)
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
        }
        await store.receive(\.presentation.delegate.saveRequested) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.success)
        await store.receive(\.writes.delegate.saved)
        await store.finish()
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 驗證兩個識別值不同的同名開團中，只改其中一團的備註時，原名直接放行、儲存成功，另一團保留
    @Test
    func presentation_兩個同名開團之一只改備註_儲存成功並保留另一團() async {
        // Given
        let campaignA = Campaign.fixture(
            id: "A",
            name: "重複團",
            closeDate: nil,
            status: .ongoing
        )
        let campaignB = Campaign.fixture(
            id: "B",
            name: "重複團",
            closeDate: nil,
            status: .ongoing
        )
        var editState = CampaignEditFeature.State(
            original: campaignA,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        editState.draft.notes = "新備註"
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaignA, campaignB]
        }
        initial.presentation.destination = .edit(editState)
        let expectedCampaign = Campaign(
            id: "A",
            name: "重複團",
            openDate: campaignA.openDate,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            notes: "新備註"
        )
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.saveCampaign = { campaign in
                savedCampaigns.withValue {
                    $0.append(campaign)
                }
            }
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveButtonTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$campaigns.withLock {
                $0 = [expectedCampaign, campaignB]
            }
        }
        await store.receive(\.presentation.delegate.saveRequested) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.success)
        await store.receive(\.writes.delegate.saved)
        await store.finish()
        #expect(store.state.presentation.destination == nil)
        #expect(store.state.campaigns == [expectedCampaign, campaignB])
        #expect(savedCampaigns.value == [expectedCampaign])
    }
}
