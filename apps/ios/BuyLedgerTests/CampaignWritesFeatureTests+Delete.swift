//
//  CampaignWritesFeatureTests+Delete.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignWritesFeatureTests {

    /// 刪除成功只移除指定開團，並原樣交回交易實際刪除的提醒事件識別碼
    ///
    /// - Parameter eventIdentifier: 本機交易回傳的事件識別碼；沒有連結時為 `nil`
    @Test(arguments: ["TRANSACTION-EVENT", nil] as [String?])
    func deleteRequested_刪除成功_只移除目標並回報交易事件識別碼(eventIdentifier: String?) async {
        // Given
        let other = Campaign.fixture(
            id: "OTHER",
            name: "原團",
            openDate: Self.openDate,
            status: .closed,
            notes: "其他備註"
        )
        let campaigns = Shared(value: [Self.campaign, other])
        let calls = LockIsolated<[String]>([])
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        } withDependencies: {
            $0.campaignService.removeCampaign = { id, name in
                calls.withValue {
                    $0.append(contentsOf: [id, name])
                }
                return eventIdentifier
            }
        }

        // When
        await store.send(.deleteRequested(id: "C1", name: "原團"))

        // Then
        await store.receive(\.deleteResponse.success) {
            $0.$campaigns.withLock {
                $0 = [other]
            }
        }
        await store.receive(
            \.delegate,
            .deleted(.init(id: "C1", name: "原團", eventIdentifier: eventIdentifier))
        )
        await store.finish()
        #expect(calls.value == ["C1", "原團"])
        #expect(campaigns.wrappedValue == [other])
    }

    /// 刪除失敗時共用清單保留原值，也不送刪除完成通知
    @Test
    func deleteRequested_刪除失敗_清單不變且不送刪除完成() async {
        // Given
        let campaigns = Shared(value: [Self.campaign])
        let calls = LockIsolated<[String]>([])
        let failingRemove: CampaignService.RemoveCampaign = { id, name throws(PersistenceError) in
            calls.withValue {
                $0.append(contentsOf: [id, name])
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "刪除失敗"))
        }
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        } withDependencies: {
            $0.campaignService.removeCampaign = failingRemove
        }

        // When
        await store.send(.deleteRequested(id: "C1", name: "原團"))

        // Then
        await store.receive(\.deleteResponse.failure)
        await store.receive(\.delegate, .failed(.delete))
        await store.finish()
        #expect(calls.value == ["C1", "原團"])
        #expect(campaigns.wrappedValue == [Self.campaign])
    }
}
