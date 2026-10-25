//
//  CampaignWritesFeatureSettleTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignWritesFeature` 的單元測試，涵蓋結算開團的寫入行為
@MainActor
struct CampaignWritesFeatureSettleTests {

    /// 驗證結算開團寫入成功後，只更新目標的結算日期，其他欄位維持原值
    @Test
    func settleRequested_寫入成功_只更新結算日期() async {
        // Given
        let campaigns = Shared(value: [
            CampaignWritesFeatureTestSupport.campaign,
            CampaignWritesFeatureTestSupport.otherCampaign,
        ])
        var expected = CampaignWritesFeatureTestSupport.campaign
        expected.settledDate = Date(timeIntervalSince1970: 3_000)
        let calls = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        } withDependencies: {
            $0.date = .constant(Date(timeIntervalSince1970: 3_000))
            $0.campaignService.saveCampaign = { campaign in
                calls.withValue {
                    $0.append(campaign)
                }
            }
        }

        // When
        await store.send(.settleRequested("C1"))

        // Then
        await store.receive(\.settleResponse.success, expected) {
            $0.$campaigns.withLock {
                $0[0].settledDate = Date(timeIntervalSince1970: 3_000)
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

    /// 驗證結算開團寫入失敗時，開團原值不變，並回報結算失敗
    @Test
    func settleRequested_寫入失敗_保留開團並回報失敗() async {
        // Given
        let campaigns = Shared(value: [
            CampaignWritesFeatureTestSupport.campaign,
            CampaignWritesFeatureTestSupport.otherCampaign,
        ])
        var expected = CampaignWritesFeatureTestSupport.campaign
        expected.settledDate = Date(timeIntervalSince1970: 3_000)
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
            $0.date = .constant(Date(timeIntervalSince1970: 3_000))
            $0.campaignService.saveCampaign = failingSave
        }

        // When
        await store.send(.settleRequested("C1"))

        // Then
        await store.receive(\.settleResponse.failure)
        await store.receive(\.delegate, .failed(.settle))
        await store.finish()
        #expect(calls.value == [expected])
        #expect(
            campaigns.wrappedValue == [
                CampaignWritesFeatureTestSupport.campaign,
                CampaignWritesFeatureTestSupport.otherCampaign,
            ]
        )
    }

    /// 驗證結算回應帶的是舊快照時，只套用結算日期，不覆蓋等待期間其他欄位的新值
    @Test
    func settleResponse_等待期間開團已變更_只套用結算日期() async {
        // Given
        var latest = CampaignWritesFeatureTestSupport.campaign
        latest.name = "最新團"
        latest.notes = "最新備註"
        latest.openDate = Date(timeIntervalSince1970: 8_000)
        latest.closeDate = nil
        latest.status = .closed
        let campaigns = Shared(value: [latest, CampaignWritesFeatureTestSupport.otherCampaign])
        var stale = CampaignWritesFeatureTestSupport.campaign
        stale.settledDate = Date(timeIntervalSince1970: 3_000)
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        }

        // When
        await store.send(.settleResponse(.success(stale))) {
            $0.$campaigns.withLock {
                $0[0].settledDate = Date(timeIntervalSince1970: 3_000)
            }
        }

        // Then
        latest.settledDate = Date(timeIntervalSince1970: 3_000)
        #expect(store.state.campaigns == [latest, CampaignWritesFeatureTestSupport.otherCampaign])
    }
}
