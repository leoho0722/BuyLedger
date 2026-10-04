//
//  CampaignIntegrationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 經列表、詳情與 Service 驗證開團操作的委派、開團篩選及 Root 的訂單投影同步
@MainActor
struct CampaignIntegrationTests {

    /// 列表出現後由 Service 載入開團，Root 同步訂單、總覽與分析的開團副本
    @Test
    func campaigns_列表出現並載入開團_同步各頁開團副本() async {
        // Given
        let loaded = [
            Campaign.fixture(
                id: "C1",
                name: "團",
                openDate: TestDependencies.fixedNow,
                status: .ongoing
            ),
        ]
        let fetches = LockIsolated(0)
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                fetches.withValue {
                    $0 += 1
                }
                return loaded
            }
        }

        // When
        await store.send(.campaigns(.list(.view(.task)))) {
            $0.campaigns.list.isLoading = true
            $0.campaigns.list.dateContext = CampaignDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.campaigns.list.campaignsResponse.success) {
            $0.campaigns.$campaigns.withLock {
                $0 = loaded
            }
            $0.campaigns.list.isLoading = false
            $0.campaigns.list.hasLoaded = true
            $0.orders.campaigns = loaded
            $0.dashboard.campaigns = loaded
            $0.insights.campaigns = loaded
        }
        await store.finish()
        #expect(fetches.value == 1)
        #expect(store.state.campaigns.campaigns == loaded)
        #expect(store.state.orders.campaigns == loaded)
        #expect(store.state.dashboard.campaigns == loaded)
        #expect(store.state.insights.campaigns == loaded)
    }

    /// 訂單投影更新後同步開團摘要
    ///
    /// - Throws: 初始摘要與第一筆訂單不符時由 `try #require` 丟出
    @Test
    func orders_訂單投影更新_同步開團摘要() async throws(any Error) {
        // Given
        let firstOrder = Self.makeOrder(id: "O1", campaign: "四月團", chargedAmount: 500)
        let secondOrder = Self.makeOrder(id: "O2", campaign: "四月團", chargedAmount: 300)
        var initial = RootFeature.State()
        initial.orders.orders = [firstOrder]
        initial.campaigns.$orders.withLock {
            $0 = [firstOrder]
        }
        initial.more.$orders.withLock {
            $0 = [firstOrder]
        }

        let store = TestStore(initialState: initial) {
            RootFeature()
        }
        let summaryBeforeSync = CampaignSummary(
            campaignName: "四月團",
            orders: store.state.campaigns.orders
        )

        try #require(summaryBeforeSync.orderCount == 1)
        try #require(summaryBeforeSync.receivables == 500)

        let updatedOrders = [firstOrder, secondOrder]

        // When
        await store.send(.orders(.ordersLoaded(updatedOrders))) {
            $0.orders.orders = updatedOrders
            $0.orders.hasLoaded = true
            $0.orders.selectedOrderID = "O1"
            $0.campaigns.$orders.withLock {
                $0 = updatedOrders
            }
            $0.more.$orders.withLock {
                $0 = updatedOrders
            }
            $0.dashboard.orders = updatedOrders
            $0.dashboard.loadState = .loaded
            $0.insights.orders = updatedOrders
            $0.insights.loadState = .loaded
        }

        // Then
        #expect(store.state.campaigns.orders == updatedOrders)
        let summaryAfterSync = CampaignSummary(
            campaignName: "四月團",
            orders: store.state.campaigns.orders
        )
        #expect(summaryAfterSync.orderCount == 2)
        #expect(summaryAfterSync.receivables == 800)
        #expect(summaryBeforeSync != summaryAfterSync)
    }
}
