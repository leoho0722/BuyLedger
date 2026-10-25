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

/// `RootFeature` 的單元測試，涵蓋開團載入與訂單投影同步到各頁
@MainActor
struct CampaignIntegrationTests {

    /// 驗證列表出現時由服務載入一次開團，載入結果同步到開團、訂單、總覽與分析的開團副本
    @Test
    func campaigns_列表出現並載入開團_同步各頁開團副本() async {
        // Given
        let loaded = [
            Campaign(
                id: "C1",
                name: "團",
                openDate: Date(timeIntervalSince1970: 1_777_507_200),
                closeDate: nil,
                status: .ongoing,
                settledDate: nil,
                notes: ""
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
        let loading = await store.send(.campaigns(.list(.view(.task)))) {
            $0.campaigns.list.dateContext = CampaignDateContext(
                now: Date(timeIntervalSince1970: 1_777_507_200),
                calendar: TestDependencies.fixedCalendar
            )
            $0.campaigns.load.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await loading.finish()
        await store.receive(\.campaigns.list.delegate.loadRequested) {
            $0.campaigns.$campaigns.withLock {
                $0 = loaded
            }
            $0.orders.$campaigns.withLock {
                $0 = loaded
            }
            $0.campaigns.load.$isLoading.withLock {
                $0 = false
            }
            $0.campaigns.load.$hasLoaded.withLock {
                $0 = true
            }
        }
        await store.receive(\.campaigns.load.loadRequested)
        await store.receive(\.campaigns.load.campaignsResponse.success) {
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

    /// 驗證訂單投影更新後，開團摘要的訂單數與應收金額隨之更新
    ///
    /// - Throws: 初始摘要與第一筆訂單不符時由 `try #require` 丟出
    @Test
    func orders_訂單投影更新_同步開團摘要() async throws {
        // Given
        let firstOrder = LedgerOrder(
            id: "O1",
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_507_200),
            items: [
                LedgerOrderItem(
                    id: UUID(0),
                    name: "item",
                    quantity: 1,
                    unitPrice: 0
                ),
            ],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 500,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: [],
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: ["四月團"],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        let secondOrder = LedgerOrder(
            id: "O2",
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_507_200),
            items: [
                LedgerOrderItem(
                    id: UUID(0),
                    name: "item",
                    quantity: 1,
                    unitPrice: 0
                ),
            ],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 300,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: [],
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: ["四月團"],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        let initial = RootFeature.State()
        initial.orders.$orders.withLock {
            $0 = [firstOrder]
        }
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
        let outcome = OrdersLoadFeature.Outcome(orders: .success(updatedOrders))

        // When
        await store.send(.orders(.load(.loadResponse(outcome)))) {
            $0.orders.$orders.withLock {
                $0 = updatedOrders
            }
            $0.orders.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.orders.list.selectedOrderID = "O1"
            $0.orders.detail.regularDetail = OrderDetailFeature.State(
                orderID: "O1",
                orders: SharedReader(initial.orders.$orders)
            )
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
    }
}
