//
//  CampaignWritesFeatureTests+Settle.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignWritesFeatureTests {

    /// 結算日期寫入成功後才更新目標，其他欄位維持原值
    @Test
    func settleRequested_寫入成功_只更新結算日期() async {
        // Given
        let campaigns = Shared(value: [Self.campaign, Self.otherCampaign])
        var expected = Self.campaign
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
        #expect(campaigns.wrappedValue == [expected, Self.otherCampaign])
    }

    /// 結算日期寫入失敗時原值不變，並回報對應的失敗種類
    @Test
    func settleRequested_寫入失敗_保留開團並回報失敗() async {
        // Given
        let campaigns = Shared(value: [Self.campaign, Self.otherCampaign])
        var expected = Self.campaign
        expected.settledDate = Date(timeIntervalSince1970: 3_000)
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
        #expect(campaigns.wrappedValue == [Self.campaign, Self.otherCampaign])
    }

    /// 舊快照寫入完成時，僅套用結算日期，不覆蓋等待期間其他欄位的新值
    @Test
    func settleResponse_等待期間開團已變更_只套用結算日期() async {
        // Given
        var latest = Self.campaign
        latest.name = "最新團"
        latest.notes = "最新備註"
        latest.openDate = Date(timeIntervalSince1970: 8_000)
        latest.closeDate = nil
        latest.status = .closed
        let campaigns = Shared(value: [latest, Self.otherCampaign])
        var stale = Self.campaign
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
        #expect(store.state.campaigns == [latest, Self.otherCampaign])
    }
}
