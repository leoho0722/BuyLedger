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

/// 驗證開團與訂單同步
@MainActor
struct CampaignIntegrationTests {
    
    // MARK: - RootFeature Tests
    
    @Test func campaignSelectedJumpsToCampaignsTabAndSelectsCampaign() async {
        var state = RootFeature.State()
        state.campaigns.campaigns = [makeCampaign(id: "C1", name: "四月韓國團", status: .ongoing)]
        
        let store = TestStore(initialState: state) {
            RootFeature()
        }
        await store.send(.campaignSelected("四月韓國團")) {
            $0.selectedTab = .campaigns
            $0.campaigns.selectedCampaignID = "C1"
        }
        
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
        let campaign = makeCampaign(id: "C1", name: "新團", status: .ongoing)
        state.campaigns.campaigns = [campaign]
        // campaignSaved 已同步三份投影，測試從這個狀態開始
        state.orders.campaigns = [campaign]
        state.dashboard.campaigns = [campaign]
        state.insights.campaigns = [campaign]
        
        let store = TestStore(initialState: state) {
            RootFeature()
        }
        await store.send(.campaigns(.campaignRenamed(from: "舊團", to: "新團"))) {
            $0.orders.orders[0] = self.withoutCampaigns(
                state.orders.orders[0], campaignNames: ["新團"])
            $0.orders.orders[1] = self.withoutCampaigns(
                state.orders.orders[1], campaignNames: ["新團"])
            $0.customers.orders = $0.orders.orders
            $0.campaigns.orders = $0.orders.orders
            $0.dashboard.orders = $0.orders.orders
            $0.insights.orders = $0.orders.orders
        }
        
        #expect(
            store.state.orders.orders.filter { $0.campaignNames == ["新團"] }.map(\.id) == [
                "O1", "O2",
            ])
        #expect(store.state.orders.orders.filter { $0.campaignNames == ["舊團"] }.isEmpty)
        #expect(store.state.orders.orders.first { $0.id == "O3" }?.campaignNames.isEmpty == true)
        #expect(store.state.orders.campaigns.map(\.name) == ["新團"])
    }
    
    @Test func campaignDeletedCascadesToOrdersInMemoryAndSyncsCopy() async {
        // DB 刪除已在同一交易完成，這裡只驗證記憶體副本同步
        let order1 = makeOrder(id: "O1", campaign: "四月團")
        let order2 = makeOrder(id: "O2", campaign: "四月團")
        let order3 = makeOrder(id: "O3", campaign: "")
        let campaign = makeCampaign(id: "C1", name: "四月團", status: .ongoing)
        var state = RootFeature.State()
        state.orders.orders = [order1, order2, order3]
        state.campaigns.campaigns = [campaign]
        state.orders.campaigns = [campaign]
        
        let store = TestStore(initialState: state) {
            RootFeature()
        }
        
        // 刪除開團後，同步訂單名稱與所有畫面投影
        await store.send(.campaigns(.campaignDeleted("C1", name: "四月團"))) {
            $0.campaigns.campaigns = []
            $0.orders.orders[0] = self.withoutCampaigns(order1)
            $0.orders.orders[1] = self.withoutCampaigns(order2)
            $0.orders.campaigns = []
            $0.dashboard.campaigns = []
            $0.insights.campaigns = []
            $0.customers.orders = $0.orders.orders
            $0.campaigns.orders = $0.orders.orders
            $0.dashboard.orders = $0.orders.orders
            $0.insights.orders = $0.orders.orders
        }
    }
    
    @Test func anyCampaignActionSyncsOrdersCampaignCopy() async {
        var state = RootFeature.State()
        state.campaigns.campaigns = []
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        let loaded = [makeCampaign(id: "C1", name: "團", status: .ongoing)]
        await store.send(.campaigns(.campaignsLoaded(loaded))) {
            $0.campaigns.campaigns = loaded
            $0.campaigns.hasLoaded = true
            $0.orders.campaigns = loaded
            $0.dashboard.campaigns = loaded
            $0.insights.campaigns = loaded
        }
        
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
            $0.calendar = TestDependencies.fixedCalendar
        }
        await store.send(.campaignFilterSelected("團A")) {
            $0.selectedCampaign = "團A"
            $0.selectedOrderID = "O1"
        }
        
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
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
            $0.calendar = TestDependencies.fixedCalendar
        }
        await store.send(.campaignStatusFilterSelected(.ongoing)) {
            $0.selectedCampaignStatus = .ongoing
            $0.selectedOrderID = "O1"
        }
        #expect(
            store.state.filteredOrders(
                referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar
            ).map(\.id) == ["O1"])
        
        await store.send(.campaignStatusFilterSelected(.closed)) {
            $0.selectedCampaignStatus = .closed
            $0.selectedOrderID = "O2"
        }
        #expect(
            store.state.filteredOrders(
                referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar
            ).map(\.id) == ["O2"])
    }
}

// MARK: - Helper Method

private extension CampaignIntegrationTests {
    
    /// 建立供開團整合測試使用的最小訂單
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - campaign: 訂單所屬的開團名稱
    /// - Returns: 建立的測試訂單
    func makeOrder(id: String, campaign: String) -> LedgerOrder {
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
            categories: [],
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: campaign.isEmpty ? [] : [campaign],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
    
    /// 建立清空 campaignNames 的訂單副本
    /// - Parameters:
    ///   - order: 原始訂單
    ///   - campaignNames: 要寫入的開團名稱
    /// - Returns: 清除或替換開團名稱後的訂單
    func withoutCampaigns(_ order: LedgerOrder, campaignNames: [String] = []) -> LedgerOrder {
        LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: order.status,
            currency: order.currency,
            date: order.date,
            items: order.items,
            itemCost: order.itemCost,
            domesticShipping: order.domesticShipping,
            internationalShipping: order.internationalShipping,
            foreignDomesticShipping: order.foreignDomesticShipping,
            cardFeeRate: order.cardFeeRate,
            platformFeeRate: order.platformFeeRate,
            paymentFeeRate: order.paymentFeeRate,
            chargedAmount: order.chargedAmount,
            cardlessDeductionAmount: order.cardlessDeductionAmount,
            cardlessSupplementAmount: order.cardlessSupplementAmount,
            orderSource: order.orderSource,
            categories: order.categories,
            paymentMethod: order.paymentMethod,
            notes: order.notes,
            reconciliationStatus: order.reconciliationStatus,
            campaignNames: campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }
    
    /// 建立供開團整合測試使用的最小開團
    /// - Parameters:
    ///   - id: 開團識別值
    ///   - name: 開團名稱
    ///   - status: 開團狀態
    /// - Returns: 建立的測試開團
    func makeCampaign(
        id: String,
        name: String,
        status: CampaignStatus
    ) -> Campaign {
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
