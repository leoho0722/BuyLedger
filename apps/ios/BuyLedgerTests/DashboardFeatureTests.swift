//
//  DashboardFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證總覽功能
@MainActor
struct DashboardFeatureTests {

    /// 畫面出現時送出 `.view(.task)`，功能轉成 `refresh` 委派交給根功能
    @Test
    func task_畫面出現_轉成refresh委派() async {
        // Given
        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        }

        // When
        await store.send(.view(.task))

        // Then
        await store.receive(\.delegate.refresh)
    }

    /// 載入失敗畫面的重試鈕與畫面出現相同，同樣轉成 `refresh` 委派
    @Test
    func retryTapped_點擊重試_轉成refresh委派() async {
        // Given
        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        }

        // When
        await store.send(.view(.retryTapped))

        // Then
        await store.receive(\.delegate.refresh)
    }

    /// 點擊進行中開團卡，把開團名稱交給根功能，不改動狀態
    @Test
    func campaignTapped_點擊進行中開團卡_轉成帶開團名稱的委派() async {
        // Given
        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        }

        // When
        await store.send(.view(.campaignTapped("四月韓國團")))

        // Then
        await store.receive(\.delegate.campaignTapped, "四月韓國團")
    }

    /// 點擊「建立第一筆訂單」，轉成新訂單委派，不改動狀態
    @Test
    func newOrderTapped_點擊建立第一筆訂單_轉成新訂單委派() async {
        // Given
        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        }

        // When
        await store.send(.view(.newOrderTapped))

        // Then
        await store.receive(\.delegate.newOrderTapped)
    }

    /// 點擊「查看全部」，轉成查看全部訂單委派，不改動狀態
    @Test
    func viewAllOrdersTapped_點擊查看全部_轉成查看全部委派() async {
        // Given
        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        }

        // When
        await store.send(.view(.viewAllOrdersTapped))

        // Then
        await store.receive(\.delegate.viewAllOrdersTapped)
    }

    /// 沒有進行中的開團時，進行中開團列為空
    @Test
    func ongoingCampaignRows_沒有進行中開團_回傳空陣列() {
        // Given
        var state = DashboardFeature.State()
        state.campaigns = [Campaign.fixture(id: "C1", name: "已結束團", status: .closed)]

        // When
        let rows = state.ongoingCampaignRows

        // Then
        #expect(rows.isEmpty)
    }

    /// 只列出進行中的開團，並依開團清單的順序排列
    @Test
    func ongoingCampaignRows_混合開團狀態_只列進行中且依清單順序() {
        // Given
        var state = DashboardFeature.State()
        state.campaigns = [
            Campaign.fixture(id: "C1", name: "甲團", status: .ongoing),
            Campaign.fixture(id: "C2", name: "乙團", status: .closed),
            Campaign.fixture(id: "C3", name: "丙團", status: .ongoing),
        ]

        // When
        let names = state.ongoingCampaignRows.map(\.campaign.name)

        // Then
        #expect(names == ["甲團", "丙團"])
    }

    /// 進行中開團的彙總依歸屬訂單計算，數字以字面值比對
    @Test
    func ongoingCampaignRows_進行中開團有訂單_彙總與字面值相符() {
        // Given
        var state = DashboardFeature.State()
        state.campaigns = [Campaign.fixture(id: "C1", name: "甲團", status: .ongoing)]
        state.orders = [
            LedgerOrder.fixture(
                id: "O1",
                status: .arrived,
                chargedAmount: 1000,
                campaignNames: ["甲團"],
                paymentReceiptStatus: .received
            ),
            LedgerOrder.fixture(
                id: "O2",
                status: .confirmed,
                chargedAmount: 500,
                campaignNames: ["甲團"],
                paymentReceiptStatus: .pending
            ),
        ]

        // When
        let summary = state.ongoingCampaignRows.first?.summary

        // Then
        #expect(summary?.orderCount == 2)
        #expect(summary?.receivables == 1500)
        #expect(summary?.receivedAmount == 1000)
        #expect(summary?.arrivedCount == 1)
        #expect(summary?.activeCount == 2)
        #expect(summary?.deliveryRatio == 0.5)
    }

    /// 進行中的開團沒有歸屬訂單時仍保留該列，彙總為零
    @Test
    func ongoingCampaignRows_進行中開團沒有訂單_彙總為零() {
        // Given
        var state = DashboardFeature.State()
        state.campaigns = [Campaign.fixture(id: "C1", name: "甲團", status: .ongoing)]

        // When
        let rows = state.ongoingCampaignRows

        // Then
        #expect(rows.map(\.campaign.name) == ["甲團"])
        #expect(rows.first?.summary.orderCount == 0)
        #expect(rows.first?.summary.receivables == 0)
        #expect(rows.first?.summary.deliveryRatio == 0)
    }
}
