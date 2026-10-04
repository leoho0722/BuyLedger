//
//  CampaignFeatureTests+WriteFailures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 新增開團儲存失敗時表單照樣關閉、清單不新增，儲存失敗提示先暫存等表單關好
    @Test
    func destination_儲存開團失敗_不加入清單() async {
        // Given
        let newID = UUID(1)
        var editState = CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
        editState.draft.name = "新團"
        var initial = CampaignFeature.State()
        initial.destination = .edit(editState)

        let expectedCampaign = Campaign(
            id: newID.uuidString,
            name: "新團",
            openDate: TestDependencies.fixedNow,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let failingSave: CampaignService.SaveCampaign = { campaign in
            savedCampaigns.withValue {
                $0.append(campaign)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(newID)
            $0.campaignService.saveCampaign = failingSave
        }

        // When
        await store.send(.destination(.presented(.edit(.view(.saveButtonTapped)))))

        // Then
        await store.receive(\.destination.presented.edit.delegate.saveRequested) {
            $0.destination = nil
            $0.presentationQueue.isFormClosing = true
        }
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.saveResponse.failure)
        await store.receive(\.writes.delegate.failed) {
            $0.presentationQueue.pendingNotice = Self.failureAlert("開團儲存失敗，請稍後再試。")
        }
        #expect(store.state.campaigns.isEmpty, "寫入失敗不應插入開團")
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 改開團狀態寫入失敗時清單維持原狀態，並跳出更新失敗提示
    @Test
    func list_要求變更開團狀態但寫入失敗_保留原狀態() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .ongoing
        )
        let initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }

        var expectedCampaign = campaign
        expectedCampaign.status = .closed
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let failingSave: CampaignService.SaveCampaign = { savedCampaign in
            savedCampaigns.withValue {
                $0.append(savedCampaign)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.campaignService.saveCampaign = failingSave
        }

        // When
        await store.send(.list(.delegate(.requested(.changeStatus(id: "C1", status: .closed)))))

        // Then
        await store.receive(\.writes.statusChangeRequested)
        await store.receive(\.writes.statusResponse.failure)
        await store.receive(\.writes.delegate.failed) {
            $0.destination = Self.failureAlert("開團狀態更新失敗，請稍後再試。")
        }
        #expect(store.state.campaigns == [campaign], "寫入失敗應維持先前開團資料")
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 確認結團後寫入失敗，開團不記錄結算日期，並跳出結團失敗提示
    @Test
    func destination_確認結團且寫入失敗_維持未結算狀態() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .closed
        )
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.destination = Self.settleAlert(id: "C1", name: "團")

        var expectedCampaign = campaign
        expectedCampaign.settledDate = TestDependencies.fixedNow
        let savedCampaigns = LockIsolated<[Campaign]>([])
        let failingSave: CampaignService.SaveCampaign = { savedCampaign in
            savedCampaigns.withValue {
                $0.append(savedCampaign)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.campaignService.saveCampaign = failingSave
        }

        // When
        await store.send(.destination(.presented(.alert(.confirmSettle("C1"))))) {
            $0.destination = nil
        }

        // Then
        await store.receive(\.writes.settleRequested)
        await store.receive(\.writes.settleResponse.failure)
        await store.receive(\.writes.delegate.failed) {
            $0.destination = Self.failureAlert("結團失敗，請稍後再試。")
        }
        #expect(store.state.campaigns == [campaign], "寫入失敗不應套用結算資料")
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 確認刪除後寫入失敗，開團仍留在清單，並跳出刪除失敗提示
    @Test
    func destination_刪除寫入失敗_保留清單項目() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .ongoing
        )
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.destination = Self.deletionAlert(id: "C1", name: "團")

        let removedCampaignIDs = LockIsolated<[String]>([])
        let removedCampaignNames = LockIsolated<[String]>([])
        let failingRemove: CampaignService.RemoveCampaign = { id, name in
            removedCampaignIDs.withValue {
                $0.append(id)
            }
            removedCampaignNames.withValue {
                $0.append(name)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.campaignService.removeCampaign = failingRemove
        }

        // When
        await store.send(.destination(.presented(.alert(.confirmDelete("C1"))))) {
            $0.destination = nil
        }

        // Then
        await store.receive(\.writes.deleteRequested)
        await store.receive(\.writes.deleteResponse.failure)
        await store.receive(\.writes.delegate.failed) {
            $0.destination = Self.failureAlert("開團刪除失敗，請稍後再試。")
        }
        #expect(store.state.campaigns == [campaign])
        #expect(removedCampaignIDs.value == ["C1"])
        #expect(removedCampaignNames.value == ["團"])
    }
}
