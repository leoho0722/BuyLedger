//
//  CampaignFeatureTests+Writes.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 確認結團後先寫入結算日期，寫入成功才套用到清單，開團狀態維持不變
    @Test
    func destination_確認結算開團_記錄結算日期且不改狀態() async {
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

        let savedCampaigns = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.campaignService.saveCampaign = { savedCampaign in
                savedCampaigns.withValue {
                    $0.append(savedCampaign)
                }
            }
        }

        // When
        await store.send(.destination(.presented(.alert(.confirmSettle("C1"))))) {
            $0.destination = nil
        }

        // Then
        await store.receive(\.writes.settleRequested) {
            $0.$campaigns.withLock {
                $0[0].settledDate = TestDependencies.fixedNow
            }
        }
        await store.receive(\.writes.settleResponse.success)
        #expect(store.state.campaigns[0].status == .closed, "結團不應改變狀態")
        await store.finish()
        var expectedCampaign = campaign
        expectedCampaign.settledDate = TestDependencies.fixedNow
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 確認刪除後刪除開團並從清單移除
    @Test
    func destination_確認刪除開團_從清單移除() async {
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
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.campaignService.removeCampaign = { id, name in
                removedCampaignIDs.withValue {
                    $0.append(id)
                }
                removedCampaignNames.withValue {
                    $0.append(name)
                }
                return nil
            }
        }

        // When
        await store.send(.destination(.presented(.alert(.confirmDelete("C1"))))) {
            $0.destination = nil
        }

        // Then
        await store.receive(\.writes.deleteRequested) {
            $0.$campaigns.withLock {
                $0 = []
            }
        }
        await store.receive(\.writes.deleteResponse.success)
        await store.receive(\.writes.delegate.deleted)
        await store.receive(\.delegate.campaignDeleted)
        await store.receive(\.reminder.campaignRemoved)
        await store.finish()
        #expect(removedCampaignIDs.value == ["C1"])
        #expect(removedCampaignNames.value == ["團"])
    }
}
