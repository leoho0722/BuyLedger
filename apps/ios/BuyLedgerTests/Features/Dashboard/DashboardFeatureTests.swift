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

/// `DashboardFeature` 的單元測試，以 TestStore 核對重新整理與導覽請求，並檢查進行中開團列
struct DashboardFeatureTests {

    /// 驗證畫面出現送出 `.view(.task)` 時，`dateContext` 記錄注入的現在時間與行事曆，並轉成 `delegate(.refresh)` 交給根功能
    @Test
    @MainActor
    func task_畫面出現_轉成refresh委派() async {
        // Given
        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.task)) {
            $0.dateContext = DashboardDateContext(
                now: Date(timeIntervalSince1970: 1_777_507_200),
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.delegate.refresh)
    }

    /// 驗證點擊重試時，`dateContext` 記錄注入的現在時間與行事曆，並轉成 `delegate(.refresh)`，與畫面出現相同
    @Test
    @MainActor
    func retryTapped_點擊重試_轉成refresh委派() async {
        // Given
        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.retryTapped)) {
            $0.dateContext = DashboardDateContext(
                now: Date(timeIntervalSince1970: 1_777_507_200),
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.delegate.refresh)
    }

    /// 驗證點擊進行中開團卡時，把開團名稱以 `delegate(.campaignTapped)` 交給根功能，State 維持不變
    @Test
    @MainActor
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

    /// 驗證點擊「建立第一筆訂單」時，轉成 `delegate(.newOrderTapped)`，State 維持不變
    @Test
    @MainActor
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

    /// 驗證點擊「查看全部」時，轉成 `delegate(.viewAllOrdersTapped)`，State 維持不變
    @Test
    @MainActor
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

    /// 驗證開團都已結束時，`ongoingCampaignRows` 為空陣列
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

    /// 驗證 `ongoingCampaignRows` 只列出進行中的開團，並保留 `campaigns` 清單的順序
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

    /// 驗證進行中開團有兩筆歸屬訂單時，`summary` 依訂單彙總出訂單數、應收、已收、到貨筆數、有效筆數 (未取消、未合併) 與到貨比例
    @Test
    func ongoingCampaignRows_進行中開團有訂單_彙總訂單數應收已收與到貨() {
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

    /// 驗證進行中開團沒有歸屬訂單時，`ongoingCampaignRows` 仍保留該列，`summary` 的訂單數、應收與到貨比例皆為零
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
