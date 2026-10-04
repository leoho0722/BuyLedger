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

/// 驗證開團寫入的前置判斷與共用開團來源
@MainActor
struct CampaignWritesFeatureTests {

    // MARK: - Properties

    /// 固定的開團日期，與結算及提醒時間不同
    static let openDate = Date(timeIntervalSince1970: 1_000)

    /// 固定的原始開團，供寫入與欄位隔離測試使用
    static let campaign = Campaign.fixture(
        id: "C1",
        name: "原團",
        openDate: Date(timeIntervalSince1970: 1_000),
        closeDate: Date(timeIntervalSince1970: 2_000),
        status: .ongoing,
        notes: "原備註"
    )

    /// 不參與本次寫入的另一開團，驗證回應不修改其他資料列
    static let otherCampaign = Campaign.fixture(
        id: "OTHER",
        name: "其他團",
        openDate: Date(timeIntervalSince1970: 6_000),
        status: .ongoing,
        notes: "其他備註"
    )

    /// 儲存成功後必須原樣交給父層的提醒請求
    static let reminder = CampaignReminderRequest(
        campaignID: "C1",
        reconcile: .create,
        title: "「新團」訂購提醒",
        eventDate: Date(timeIntervalSince1970: 0),
        alarmOffset: 3_600,
        timestamp: Date(timeIntervalSince1970: 3_600)
    )

    /// 狀態變更找不到目標或狀態未變時，不寫入也不送後續事件
    ///
    /// - Parameter isMissing: 是否指定不存在的識別值
    @Test(arguments: [true, false])
    func statusChangeRequested_找不到或狀態未變_不寫入且不發出回應(isMissing: Bool) async {
        // Given
        let campaigns = Shared(value: [Self.campaign])
        let calls = LockIsolated(0)
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        } withDependencies: {
            $0.campaignService.saveCampaign = { _ in
                calls.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.statusChangeRequested(id: isMissing ? "MISSING" : "C1", status: .ongoing))

        // Then
        await store.finish()
        #expect(calls.value == 0)
        #expect(store.state.campaigns == [Self.campaign])
    }

    /// 找不到要結團的開團或已結團時，不寫入也不送後續事件
    ///
    /// - Parameter isMissing: 是否指定不存在的識別值
    @Test(arguments: [true, false])
    func settleRequested_找不到或已結團_不寫入且不發出回應(isMissing: Bool) async {
        // Given
        var settled = Self.campaign
        settled.settledDate = Date(timeIntervalSince1970: 3_000)
        let campaigns = Shared(value: [settled])
        let calls = LockIsolated(0)
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        } withDependencies: {
            $0.campaignService.saveCampaign = { _ in
                calls.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.settleRequested(isMissing ? "MISSING" : "C1"))

        // Then
        await store.finish()
        #expect(calls.value == 0)
        #expect(store.state.campaigns == [settled])
    }

    /// 狀態回應抵達前目標已不存在時，不插入開團
    @Test
    func statusResponse_目標已不存在_不新增開團() async {
        // Given
        let campaigns = Shared<[Campaign]>(value: [])
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        }

        // When
        await store.send(.statusResponse(.success(Self.campaign)))

        // Then
        await store.finish()
        #expect(store.state.campaigns.isEmpty)
    }

    /// 結團回應抵達前目標已不存在時，不插入開團
    @Test
    func settleResponse_目標已不存在_不新增開團() async {
        // Given
        let campaigns = Shared<[Campaign]>(value: [])
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        }

        // When
        await store.send(.settleResponse(.success(Self.campaign)))

        // Then
        await store.finish()
        #expect(store.state.campaigns.isEmpty)
    }
}
