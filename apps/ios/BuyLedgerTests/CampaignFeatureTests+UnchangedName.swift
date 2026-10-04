//
//  CampaignFeatureTests+UnchangedName.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 編輯既有開團沒改名時直接儲存並關閉表單
    @Test
    func destination_編輯時保留原開團名稱_成功儲存() async {
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
        initial.destination = .edit(editState)

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
        await store.send(.destination(.presented(.edit(.view(.saveButtonTapped)))))

        // Then
        await store.receive(\.destination.presented.edit.delegate.saveRequested) {
            $0.destination = nil
            $0.presentationQueue.isFormClosing = true
            $0.$campaigns.withLock {
                $0[0] = expectedCampaign
            }
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.success)
        await store.receive(\.writes.delegate.saved)
        await store.finish()
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 資料原本就有同名開團時，沒改名仍可儲存且不清理重名
    @Test
    func destination_既有資料已有同名開團_未改名仍可儲存() async {
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
        initial.destination = .edit(editState)

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
        await store.send(.destination(.presented(.edit(.view(.saveButtonTapped)))))

        // Then
        await store.receive(\.destination.presented.edit.delegate.saveRequested) {
            $0.destination = nil
            $0.presentationQueue.isFormClosing = true
            $0.$campaigns.withLock {
                $0[0] = expectedCampaign
            }
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.success)
        await store.receive(\.writes.delegate.saved)
        await store.finish()
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 兩個不同識別值的同名開團只修改其中一團備註時，原名直接放行且保留另一團
    @Test
    func destination_兩個同名開團之一只改備註_儲存成功並保留另一團() async {
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
        initial.destination = .edit(editState)
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
        await store.send(.destination(.presented(.edit(.view(.saveButtonTapped)))))

        // Then
        await store.receive(\.destination.presented.edit.delegate.saveRequested) {
            $0.destination = nil
            $0.presentationQueue.isFormClosing = true
            $0.$campaigns.withLock {
                $0 = [expectedCampaign, campaignB]
            }
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.success)
        await store.receive(\.writes.delegate.saved)
        await store.finish()
        #expect(store.state.destination == nil)
        #expect(store.state.campaigns == [expectedCampaign, campaignB])
        #expect(savedCampaigns.value == [expectedCampaign])
    }
}
