//
//  CampaignWritesFeatureTests+Status.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignWritesFeatureTests {

    /// 狀態寫入成功後才更新目標，其他欄位維持原值
    @Test
    func statusChangeRequested_寫入成功_只更新狀態() async {
        // Given
        let campaigns = Shared(value: [Self.campaign, Self.otherCampaign])
        var expected = Self.campaign
        expected.status = .closed
        let calls = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        } withDependencies: {
            $0.campaignService.saveCampaign = { campaign in
                calls.withValue {
                    $0.append(campaign)
                }
            }
        }

        // When
        await store.send(.statusChangeRequested(id: "C1", status: .closed))

        // Then
        await store.receive(\.statusResponse.success, expected) {
            $0.$campaigns.withLock {
                $0[0].status = .closed
            }
        }
        await store.finish()
        #expect(calls.value == [expected])
        #expect(campaigns.wrappedValue == [expected, Self.otherCampaign])
    }

    /// 狀態寫入失敗時原值不變，並回報對應的失敗種類
    @Test
    func statusChangeRequested_寫入失敗_保留開團並回報失敗() async {
        // Given
        let campaigns = Shared(value: [Self.campaign, Self.otherCampaign])
        var expected = Self.campaign
        expected.status = .closed
        let calls = LockIsolated<[Campaign]>([])
        let failingSave: CampaignService.SaveCampaign = { campaign in
            calls.withValue {
                $0.append(campaign)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "寫入失敗"))
        }
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        } withDependencies: {
            $0.campaignService.saveCampaign = failingSave
        }

        // When
        await store.send(.statusChangeRequested(id: "C1", status: .closed))

        // Then
        await store.receive(\.statusResponse.failure)
        await store.receive(\.delegate, .failed(.status))
        await store.finish()
        #expect(calls.value == [expected])
        #expect(campaigns.wrappedValue == [Self.campaign, Self.otherCampaign])
    }

    /// 舊快照寫入完成時，僅套用狀態，不覆蓋等待期間其他欄位的新值
    @Test
    func statusResponse_等待期間開團已變更_只套用狀態() async {
        // Given
        var latest = Self.campaign
        latest.name = "最新團"
        latest.notes = "最新備註"
        latest.openDate = Date(timeIntervalSince1970: 8_000)
        latest.closeDate = nil
        latest.settledDate = Date(timeIntervalSince1970: 7_000)
        let campaigns = Shared(value: [latest, Self.otherCampaign])
        var stale = Self.campaign
        stale.status = .closed
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        }

        // When
        await store.send(.statusResponse(.success(stale))) {
            $0.$campaigns.withLock {
                $0[0].status = .closed
            }
        }

        // Then
        latest.status = .closed
        #expect(store.state.campaigns == [latest, Self.otherCampaign])
    }
}
