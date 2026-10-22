//
//  CampaignWritesFeatureTests+Rename.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension CampaignWritesFeatureTests {

    /// 帶改名計畫儲存成功時先更新清單，並依序送出改名與儲存完成通知
    @Test
    func saveRequested_改名成功_先改名再送儲存完成() async {
        // Given
        var saved = Self.campaign
        saved.name = "新團"
        let campaigns = Shared(value: [Self.campaign])
        let plan = CampaignSavePlan(
            campaign: saved,
            rename: .init(from: "原團", to: "新團"),
            reminder: Self.reminder
        )
        let calls = LockIsolated<[String]>([])
        let renamedNames = LockIsolated<[String]>([])
        let rename: CampaignService.RenameCampaign = { campaign, previousName in
            calls.withValue {
                $0.append("rename")
            }
            renamedNames.setValue([previousName, campaign.name])
        }
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        } withDependencies: {
            $0.campaignService.renameCampaign = rename
        }

        // When
        await store.send(.saveRequested(plan))

        // Then
        await store.receive(\.saveResponse.success, plan) {
            $0.$campaigns.withLock {
                $0 = [saved]
            }
        }
        await store.receive(\.delegate, .renamed(from: "原團", to: "新團"))
        await store.receive(\.delegate, .saved(Self.reminder))
        await store.finish()
        #expect(calls.value == ["rename"])
        #expect(renamedNames.value == ["原團", "新團"])
        #expect(campaigns.wrappedValue == [saved])
    }

    /// 帶改名計畫儲存失敗時清單維持原樣，回報儲存失敗且不送儲存完成
    @Test
    func saveRequested_改名失敗_回報儲存失敗且不送儲存完成() async {
        // Given
        var saved = Self.campaign
        saved.name = "新團"
        let campaigns = Shared(value: [Self.campaign])
        let plan = CampaignSavePlan(
            campaign: saved,
            rename: .init(from: "原團", to: "新團"),
            reminder: Self.reminder
        )
        let calls = LockIsolated<[String]>([])
        let failingRename: CampaignService.RenameCampaign = { _, _ throws(PersistenceError) in
            calls.withValue {
                $0.append("rename")
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "改名失敗"))
        }
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        } withDependencies: {
            $0.campaignService.renameCampaign = failingRename
        }

        // When
        await store.send(.saveRequested(plan))

        // Then
        await store.receive(\.saveResponse.failure)
        await store.receive(\.delegate, .failed(.save))
        await store.finish()
        #expect(calls.value == ["rename"])
        #expect(campaigns.wrappedValue == [Self.campaign])
    }
}
