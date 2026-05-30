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

@MainActor
struct CampaignIntegrationTests {

    // MARK: - RootFeature Tests

    @Test func campaignSelectedJumpsToCampaignsTabAndSelectsCampaign() async {
        var state = RootFeature.State()
        state.campaigns.campaigns = [makeCampaign(id: "C1", name: "四月韓國團", status: .ongoing)]

        let store = TestStore(initialState: state) {
            RootFeature()
        }
        store.exhaustivity = .off

        await store.send(.campaignSelected("四月韓國團"))

        #expect(store.state.selectedTab == .campaigns)
        #expect(store.state.campaigns.selectedCampaignID == "C1")
    }

    @Test func campaignRenamedCascadesToOrdersInMemoryAndSyncsCopy() async {
        var state = RootFeature.State()
        state.orders.orders = [
            makeOrder(id: "O1", campaign: "舊團"),
            makeOrder(id: "O2", campaign: "舊團"),
            makeOrder(id: "O3", campaign: ""),
        ]
        state.campaigns.campaigns = [makeCampaign(id: "C1", name: "新團", status: .ongoing)]

        let store = TestStore(initialState: state) {
            RootFeature()
        }
        store.exhaustivity = .off

        await store.send(.campaigns(.campaignRenamed(from: "舊團", to: "新團")))

        #expect(store.state.orders.orders.filter { $0.campaignName == "新團" }.map(\.id) == ["O1", "O2"])
        #expect(store.state.orders.orders.filter { $0.campaignName == "舊團" }.isEmpty)
        #expect(store.state.orders.orders.first { $0.id == "O3" }?.campaignName == "")
        #expect(store.state.orders.campaigns.map(\.name) == ["新團"])
    }

    @Test func anyCampaignActionSyncsOrdersCampaignCopy() async {
        var state = RootFeature.State()
        state.campaigns.campaigns = []

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
        }
        store.exhaustivity = .off

        let loaded = [makeCampaign(id: "C1", name: "團", status: .ongoing)]
        await store.send(.campaigns(.campaignsLoaded(loaded)))

        #expect(store.state.orders.campaigns.map(\.name) == ["團"])
    }

    // MARK: - OrdersFeature Filter Tests

    @Test func ordersFilterBySpecificCampaign() async {
        var state = OrdersFeature.State()
        state.orders = [
            makeOrder(id: "O1", campaign: "團A"),
            makeOrder(id: "O2", campaign: "團B"),
            makeOrder(id: "O3", campaign: ""),
        ]

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
        }
        store.exhaustivity = .off

        await store.send(.campaignFilterSelected("團A"))

        let filtered = store.state.filteredOrders(referenceDate: TestDependencies.fixedNow)
        #expect(filtered.map(\.id) == ["O1"])
    }

    @Test func ordersFilterByCampaignStatusResolvesThroughCampaignCopy() async {
        var state = OrdersFeature.State()
        state.orders = [
            makeOrder(id: "O1", campaign: "團A"),
            makeOrder(id: "O2", campaign: "團B"),
            makeOrder(id: "O3", campaign: ""),
        ]
        state.campaigns = [
            makeCampaign(id: "A", name: "團A", status: .ongoing),
            makeCampaign(id: "B", name: "團B", status: .closed),
        ]

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
        }
        store.exhaustivity = .off

        await store.send(.campaignStatusFilterSelected(.ongoing))
        #expect(store.state.filteredOrders(referenceDate: TestDependencies.fixedNow).map(\.id) == ["O1"])

        await store.send(.campaignStatusFilterSelected(.closed))
        #expect(store.state.filteredOrders(referenceDate: TestDependencies.fixedNow).map(\.id) == ["O2"])
    }

    // MARK: - Helper

    private func makeOrder(id: String, campaign: String) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [LedgerOrderItem(name: "item", quantity: 1, unitPrice: 0)],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 100,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            category: "",
            paymentMethod: "",
            notes: "",
            verificationStatus: "",
            campaignName: campaign,
            paymentReceiptStatus: .pending
        )
    }

    private func makeCampaign(id: String, name: String, status: CampaignStatus) -> Campaign {
        Campaign(
            id: id,
            name: name,
            openDate: TestDependencies.fixedNow,
            closeDate: nil,
            status: status,
            settledDate: nil,
            notes: ""
        )
    }
}
