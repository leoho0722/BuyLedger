//
//  CampaignWritesFeatureSaveTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignWritesFeature` 的單元測試，涵蓋新增與編輯的儲存行為
@MainActor
struct CampaignWritesFeatureSaveTests {

    /// 驗證儲存成功時，指定開團新增或取代原有資料，其他開團保留並依開團日期由新到舊排序，最後回報提醒請求
    ///
    /// - Parameter scenario: 是否取代既有的同識別值開團，以及是否有提醒請求需要回報
    @Test(arguments: SaveCase.allCases)
    func saveRequested_新增或編輯成功_更新共用清單並最後回報提醒(scenario: SaveCase) async {
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
        let campaigns = Shared(
            value: scenario.isEditing
                ? [older, CampaignWritesFeatureTestSupport.campaign, newer]
                : [older, newer]
        )
        let reminder = scenario.hasReminder ? CampaignWritesFeatureTestSupport.reminder : nil
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

    /// 驗證帶改名的儲存失敗時，共用開團保持不變，回報儲存失敗，且不送出儲存完成通知
    @Test
    func saveRequested_儲存失敗_清單不變且不送儲存完成() async {
        // Given
        var saved = CampaignWritesFeatureTestSupport.campaign
        saved.name = "新團"
        let campaigns = Shared(value: [CampaignWritesFeatureTestSupport.campaign])
        let plan = CampaignSavePlan(
            campaign: saved,
            rename: .init(from: "原團", to: "新團"),
            reminder: CampaignWritesFeatureTestSupport.reminder
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
        #expect(campaigns.wrappedValue == [CampaignWritesFeatureTestSupport.campaign])
    }
}

// MARK: - Nested Types

extension CampaignWritesFeatureSaveTests {

    /// 新增或編輯與有無提醒請求的組合
    struct SaveCase: Sendable {

        /// 編輯或新增、有或沒有提醒請求的四種組合
        static let allCases = [
            Self(isEditing: true, hasReminder: true),
            Self(isEditing: true, hasReminder: false),
            Self(isEditing: false, hasReminder: true),
            Self(isEditing: false, hasReminder: false),
        ]

        /// 是否取代既有的同識別值開團
        let isEditing: Bool

        /// 是否有提醒請求需要回報
        let hasReminder: Bool
    }
}
