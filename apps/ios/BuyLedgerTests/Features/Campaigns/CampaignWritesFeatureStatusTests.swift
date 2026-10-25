//
//  CampaignWritesFeatureStatusTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignWritesFeature` 的單元測試，涵蓋開團狀態變更的寫入行為
@MainActor
struct CampaignWritesFeatureStatusTests {

    /// 驗證狀態寫入成功後，只更新目標的狀態，其他欄位維持原值
    @Test
    func statusChangeRequested_寫入成功_只更新狀態() async {
        // Given
        let campaigns = Shared(value: [
            CampaignWritesFeatureTestSupport.campaign,
            CampaignWritesFeatureTestSupport.otherCampaign,
        ])
        var expected = CampaignWritesFeatureTestSupport.campaign
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
        #expect(
            campaigns.wrappedValue == [
                expected,
                CampaignWritesFeatureTestSupport.otherCampaign,
            ]
        )
    }

    /// 驗證狀態寫入失敗時，開團原值不變，並回報狀態變更失敗
    @Test
    func statusChangeRequested_寫入失敗_保留開團並回報失敗() async {
        // Given
        let campaigns = Shared(value: [
            CampaignWritesFeatureTestSupport.campaign,
            CampaignWritesFeatureTestSupport.otherCampaign,
        ])
        var expected = CampaignWritesFeatureTestSupport.campaign
        expected.status = .closed
        let calls = LockIsolated<[Campaign]>([])
        let failingSave: CampaignService.SaveCampaign = { campaign throws(PersistenceError) in
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
        #expect(
            campaigns.wrappedValue == [
                CampaignWritesFeatureTestSupport.campaign,
                CampaignWritesFeatureTestSupport.otherCampaign,
            ]
        )
    }

    /// 驗證狀態回應帶的是舊快照時，只套用狀態，不覆蓋等待期間其他欄位的新值
    @Test
    func statusResponse_等待期間開團已變更_只套用狀態() async {
        // Given
        var latest = CampaignWritesFeatureTestSupport.campaign
        latest.name = "最新團"
        latest.notes = "最新備註"
        latest.openDate = Date(timeIntervalSince1970: 8_000)
        latest.closeDate = nil
        latest.settledDate = Date(timeIntervalSince1970: 7_000)
        let campaigns = Shared(value: [latest, CampaignWritesFeatureTestSupport.otherCampaign])
        var stale = CampaignWritesFeatureTestSupport.campaign
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
        #expect(store.state.campaigns == [latest, CampaignWritesFeatureTestSupport.otherCampaign])
    }
}
