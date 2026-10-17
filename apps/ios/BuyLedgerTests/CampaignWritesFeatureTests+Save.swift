//
//  CampaignWritesFeatureTests+Save.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignWritesFeatureTests {

    /// 儲存成功時新增或取代指定開團，其他開團保留並按開團日期由新到舊排序
    ///
    /// - Parameters:
    ///   - isEditing: 是否取代既有的同識別值開團
    ///   - hasReminder: 是否有提醒請求需要交回父層
    @Test(arguments: [(true, true), (true, false), (false, true), (false, false)])
    func saveRequested_新增或編輯成功_更新共用清單並最後回報提醒(isEditing: Bool, hasReminder: Bool) async {
        // Given
        let older = Campaign.fixture(
            id: "OLD",
            name: "舊團",
            openDate: Date(timeIntervalSince1970: 0),
            status: .closed,
            notes: "舊備註"
        )
        let newer = Campaign.fixture(
            id: "NEW",
            name: "最近團",
            openDate: Date(timeIntervalSince1970: 9_000),
            status: .ongoing,
            notes: "最近備註"
        )
        let saved = Campaign.fixture(
            id: "C1",
            name: "新團",
            openDate: Date(timeIntervalSince1970: 5_000),
            status: .closed,
            notes: "已改備註"
        )
        let campaigns = Shared(value: isEditing ? [older, Self.campaign, newer] : [older, newer])
        let reminder = hasReminder ? Self.reminder : nil
        let plan = CampaignSavePlan(campaign: saved, rename: nil, reminder: reminder)
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
        await store.send(.saveRequested(plan))

        // Then
        await store.receive(\.saveResponse.success, plan) {
            $0.$campaigns.withLock {
                $0 = [newer, saved, older]
            }
        }
        await store.receive(\.delegate, .saved(reminder))
        await store.finish()
        #expect(calls.value == [saved])
        #expect(campaigns.wrappedValue == [newer, saved, older])
    }

    /// 儲存失敗不改共用開團，且不啟動改名或提醒的儲存完成通知
    @Test
    func saveRequested_儲存失敗_清單不變且不送儲存完成() async {
        // Given
        var saved = Self.campaign
        saved.name = "新團"
        let campaigns = Shared(value: [Self.campaign])
        let plan = CampaignSavePlan(
            campaign: saved,
            rename: .init(from: "原團", to: "新團"),
            reminder: Self.reminder
        )
        let calls = LockIsolated<[Campaign]>([])
        let failingRename: CampaignService.RenameCampaign = { campaign, _ throws(PersistenceError) in
            calls.withValue {
                $0.append(campaign)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "儲存失敗"))
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
        #expect(calls.value == [saved])
        #expect(campaigns.wrappedValue == [Self.campaign])
    }
}
