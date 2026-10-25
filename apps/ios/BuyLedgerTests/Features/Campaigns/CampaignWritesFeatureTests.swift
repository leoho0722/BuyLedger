//
//  CampaignWritesFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignWritesFeature` 的單元測試，涵蓋寫入前的前置判斷與共用開團來源
@MainActor
struct CampaignWritesFeatureTests {

    /// 驗證要求變更狀態時，目標不存在或狀態未變，都不寫入，也不送出後續事件
    ///
    /// - Parameter isMissing: 是否指定不存在的識別值
    /// - Note: 未覆寫的 `saveCampaign` 是 `unimplemented`；寫入會使測試失敗
    @Test(arguments: [true, false])
    func statusChangeRequested_找不到或狀態未變_不寫入且不發出回應(isMissing: Bool) async {
        // Given
        let campaigns = Shared(value: [CampaignWritesFeatureTestSupport.campaign])
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        }

        // When
        await store.send(.statusChangeRequested(id: isMissing ? "MISSING" : "C1", status: .ongoing))

        // Then
        await store.finish()
        #expect(store.state.campaigns == [CampaignWritesFeatureTestSupport.campaign])
    }

    /// 驗證要求結團時，開團不存在或已有結算日期，都不寫入，也不送出後續事件
    ///
    /// - Parameter isMissing: 是否指定不存在的識別值
    /// - Note: 未覆寫的 `saveCampaign` 是 `unimplemented`；寫入會使測試失敗
    @Test(arguments: [true, false])
    func settleRequested_找不到或已結團_不寫入且不發出回應(isMissing: Bool) async {
        // Given
        var settled = CampaignWritesFeatureTestSupport.campaign
        settled.settledDate = Date(timeIntervalSince1970: 3_000)
        let campaigns = Shared(value: [settled])
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        }

        // When
        await store.send(.settleRequested(isMissing ? "MISSING" : "C1"))

        // Then
        await store.finish()
        #expect(store.state.campaigns == [settled])
    }

    /// 驗證狀態回應抵達時目標已不存在，不會把開團插回清單
    @Test
    func statusResponse_目標已不存在_不新增開團() async {
        // Given
        let campaigns = Shared<[Campaign]>(value: [])
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        }

        // When
        await store.send(.statusResponse(.success(CampaignWritesFeatureTestSupport.campaign)))

        // Then
        await store.finish()
        #expect(store.state.campaigns.isEmpty)
    }

    /// 驗證結團回應抵達時目標已不存在，不會把開團插回清單
    @Test
    func settleResponse_目標已不存在_不新增開團() async {
        // Given
        let campaigns = Shared<[Campaign]>(value: [])
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        }

        // When
        await store.send(.settleResponse(.success(CampaignWritesFeatureTestSupport.campaign)))

        // Then
        await store.finish()
        #expect(store.state.campaigns.isEmpty)
    }
}
