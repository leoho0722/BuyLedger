//
//  CampaignSummaryTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation
import Testing
@testable import BuyLedger

/// 驗證開團摘要
@MainActor
struct CampaignSummaryTests {
    
    // MARK: - Tests
    
    @Test func distributionGroupsByCustomerWithSummedQuantityAndReceiptMarker() {
        // 小明兩筆訂單、一筆已收款；小華一筆已收款
        let orders = [
            makeOrder(
                id: "A", customer: "小明", campaign: "團", charged: 600, quantity: 2,
                receipt: .received),
            makeOrder(
                id: "B", customer: "小明", campaign: "團", charged: 300, quantity: 1, receipt: .pending
            ),
            makeOrder(
                id: "C", customer: "小華", campaign: "團", charged: 400, quantity: 1,
                receipt: .received),
        ]
        let summary = CampaignSummary(campaignName: "團", orders: orders)
        
        #expect(summary.distribution.count == 2)
        
        let xiaoming = summary.distribution.first { $0.customerName == "小明" }
        #expect(xiaoming?.totalQuantity == 3)
        #expect(xiaoming?.totalAmount == 900)
        #expect(xiaoming?.isFullyReceived == false)
        
        let xiaohua = summary.distribution.first { $0.customerName == "小華" }
        #expect(xiaohua?.totalQuantity == 1)
        #expect(xiaohua?.totalAmount == 400)
        #expect(xiaohua?.isFullyReceived == true)
    }
    
    @Test func settlementTotalsFromMemberOrders() {
        // 應收 1,500、已收 1,000、未收 500
        let orders = [
            makeOrder(id: "O1", customer: "A", campaign: "團", charged: 1000, receipt: .received),
            makeOrder(id: "O2", customer: "B", campaign: "團", charged: 500, receipt: .pending),
        ]
        let summary = CampaignSummary(campaignName: "團", orders: orders)
        
        #expect(summary.receivables == 1500)
        #expect(summary.receivedAmount == 1000)
        #expect(summary.outstandingAmount == 500)
        #expect(abs(summary.receivedRatio - (1000.0 / 1500.0)) < 0.0001)
    }
    
    @Test func zeroReceivablesYieldsZeroRatioWithoutDividingByZero() {
        let orders = [
            makeOrder(id: "O1", customer: "A", campaign: "團", charged: 0, receipt: .pending)
        ]
        let summary = CampaignSummary(campaignName: "團", orders: orders)
        
        #expect(summary.receivables == 0)
        #expect(summary.receivedRatio == 0)
        #expect(summary.margin == 0)
    }
    
    @Test func deliveryRatioExcludesCancelledFromDenominator() {
        let orders = [
            makeOrder(id: "O1", customer: "A", campaign: "團", charged: 100, status: .delivered),
            makeOrder(id: "O2", customer: "B", campaign: "團", charged: 100, status: .delivered),
            makeOrder(id: "O3", customer: "C", campaign: "團", charged: 100, status: .cancelled),
            makeOrder(id: "O4", customer: "D", campaign: "團", charged: 100, status: .confirmed),
        ]
        let summary = CampaignSummary(campaignName: "團", orders: orders)
        
        #expect(summary.arrivedCount == 2)
        #expect(summary.activeCount == 3)
        #expect(abs(summary.deliveryRatio - (2.0 / 3.0)) < 0.0001)
    }
    
    @Test func arrivedCountsTowardDeliveryProgress() {
        // 已到貨、已交付與已取貨都算「已到貨」：到貨進度分子同時計入三者
        let orders = [
            makeOrder(id: "O1", customer: "A", campaign: "團", charged: 100, status: .arrived),
            makeOrder(id: "O2", customer: "B", campaign: "團", charged: 100, status: .delivered),
            makeOrder(id: "O3", customer: "C", campaign: "團", charged: 100, status: .pickedUp),
            makeOrder(id: "O4", customer: "D", campaign: "團", charged: 100, status: .shipping),
            makeOrder(id: "O5", customer: "E", campaign: "團", charged: 100, status: .cancelled),
        ]
        let summary = CampaignSummary(campaignName: "團", orders: orders)
        
        #expect(summary.arrivedCount == 3)
        #expect(summary.activeCount == 4)
        #expect(abs(summary.deliveryRatio - 0.75) < 0.0001)
    }
    
    @Test func partiallyArrivedCountsInDenominatorButNotNumerator() {
        // 部分到貨不計入已到貨數，但仍計入進行中訂單。
        let orders = [
            makeOrder(id: "O1", customer: "A", campaign: "團", charged: 100, status: .arrived),
            makeOrder(
                id: "O2", customer: "B", campaign: "團", charged: 100, status: .partiallyArrived),
            makeOrder(id: "O3", customer: "C", campaign: "團", charged: 100, status: .shipping),
        ]
        let summary = CampaignSummary(campaignName: "團", orders: orders)
        
        #expect(summary.arrivedCount == 1)
        #expect(summary.activeCount == 3)
        #expect(abs(summary.deliveryRatio - (1.0 / 3.0)) < 0.0001)
    }
    
    @Test func unassignedOrdersAreExcluded() {
        let orders = [
            makeOrder(id: "O1", customer: "A", campaign: "團", charged: 100, receipt: .received),
            makeOrder(id: "O2", customer: "B", campaign: "", charged: 999, receipt: .received),
        ]
        let summary = CampaignSummary(campaignName: "團", orders: orders)
        
        #expect(summary.orderCount == 1)
        #expect(summary.receivables == 100)
        #expect(summary.distribution.allSatisfy { $0.customerName == "A" })
    }
    
    @Test func profitAndCostAggregateMemberOrderSummaries() {
        // 成本與費率以外皆 0：profit = charged − itemCost
        let orders = [
            makeOrder(
                id: "O1", customer: "A", campaign: "團", charged: 1000, receipt: .received,
                itemCost: 200),
            makeOrder(
                id: "O2", customer: "B", campaign: "團", charged: 500, receipt: .pending,
                itemCost: 100),
        ]
        let summary = CampaignSummary(campaignName: "團", orders: orders)
        
        #expect(summary.totalRevenue == 1500)
        #expect(summary.totalCost == 300)
        #expect(summary.profit == 1200)
    }
    
    @Test func emptyCampaignHasZeroAggregatesAndNoDistribution() {
        let summary = CampaignSummary(campaignName: "空團", orders: [])
        
        #expect(summary.orderCount == 0)
        #expect(summary.receivables == 0)
        #expect(summary.receivedRatio == 0)
        #expect(summary.deliveryRatio == 0)
        #expect(summary.distribution.isEmpty)
    }
    
    @Test func mergeResultOrdersAreNotMembers() {
        // 只統計合併前的原始訂單。
        let orders = [
            makeOrder(
                id: "A", customer: "客", campaign: "May-JP", charged: 1_000, status: .merged,
                itemCost: 200),
            makeOrder(
                id: "B", customer: "客", campaign: "June-KR", charged: 2_000, status: .merged,
                itemCost: 300),
            makeOrder(
                id: "M",
                customer: "客",
                campaign: "",
                charged: 3_000,
                status: .shipping,
                itemCost: 500,
                campaignNames: ["May-JP", "June-KR"],
                mergedSourceIDs: ["A", "B"]
            ),
        ]
        
        let mayTeam = CampaignSummary(campaignName: "May-JP", orders: orders)
        #expect(mayTeam.memberOrders.map(\.id) == ["A"])
        #expect(mayTeam.receivables == 1_000)
        #expect(mayTeam.profit == 800)
        
        let juneTeam = CampaignSummary(campaignName: "June-KR", orders: orders)
        #expect(juneTeam.memberOrders.map(\.id) == ["B"])
        #expect(juneTeam.receivables == 2_000)
    }
    
    @Test func multiCampaignLeafCountsFullyInEachCampaign() {
        // 防衛性規則：原始訂單若帶多個開團，全額計入它的每一團
        let orders = [
            makeOrder(
                id: "O1", customer: "客", campaign: "", charged: 900,
                campaignNames: ["May-JP", "June-KR"])
        ]
        
        #expect(CampaignSummary(campaignName: "May-JP", orders: orders).receivables == 900)
        #expect(CampaignSummary(campaignName: "June-KR", orders: orders).receivables == 900)
    }
    
    @Test func deliveryRatioExcludesMergedFromDenominator() {
        // 已合併舊單已不再各自等待到貨：到貨進度分母比照已取消排除
        let orders = [
            makeOrder(id: "O1", customer: "A", campaign: "團", charged: 100, status: .delivered),
            makeOrder(id: "O2", customer: "B", campaign: "團", charged: 100, status: .merged),
            makeOrder(id: "O3", customer: "C", campaign: "團", charged: 100, status: .shipping),
        ]
        let summary = CampaignSummary(campaignName: "團", orders: orders)
        
        #expect(summary.arrivedCount == 1)
        #expect(summary.activeCount == 2)
        #expect(abs(summary.deliveryRatio - 0.5) < 0.0001)
    }
    
    /// 批次投影與逐團建構結果相同，涵蓋空團、同名開團與多團歸屬
    @Test func batchMatchesPerCampaignConstructionIncludingEmptyDuplicateAndMultiCampaignOrders() {
        let orders = [
            makeOrder(
                id: "O1", customer: "小明", campaign: "五月團", charged: 1_000, receipt: .received),
            makeOrder(
                id: "O2",
                customer: "小華",
                campaign: "",
                charged: 500,
                campaignNames: ["五月團", "六月團"]
            ),
            makeOrder(id: "O3", customer: "小美", campaign: "六月團", charged: 300, status: .cancelled),
        ]
        // 同名開團「五月團」重複兩次：批次投影只計算一次、以先出現者為準
        let campaignNames = ["五月團", "五月團", "六月團", "空團"]
        
        let batched = CampaignSummary.batch(campaignNames: campaignNames, orders: orders)
        
        #expect(Set(batched.keys) == Set(campaignNames))
        
        for name in campaignNames {
            let perCampaign = CampaignSummary(campaignName: name, orders: orders)
            #expect(
                batched[name]?.memberOrders.map(\.id) == perCampaign.memberOrders.map(\.id),
                "\(name) 的成員清單應與逐團建構相同")
            #expect(batched[name]?.receivables == perCampaign.receivables, "\(name) 的應收金額應與逐團建構相同")
            #expect(batched[name]?.orderCount == perCampaign.orderCount, "\(name) 的筆數應與逐團建構相同")
        }
        
        // 零成員團 (無任何訂單歸屬) 不崩潰，彙總為空
        #expect(batched["空團"]?.orderCount == 0)
        #expect(batched["空團"]?.memberOrders.isEmpty == true)
        
        // 訂單同時歸屬多團：O2 應同時計入「五月團」與「六月團」
        #expect(batched["五月團"]?.memberOrders.map(\.id).contains("O2") == true)
        #expect(batched["六月團"]?.memberOrders.map(\.id).contains("O2") == true)
    }
    
    // MARK: - Helper
    
    /// 建立只含 CampaignSummary 所需欄位的訂單
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - customer: 客戶名稱
    ///   - campaign: 主要開團名稱
    ///   - charged: 客戶實付金額
    ///   - quantity: 商品數量
    ///   - receipt: 付款收據狀態
    ///   - status: 訂單狀態
    ///   - itemCost: 商品成本
    ///   - campaignNames: 訂單所屬的開團名稱
    ///   - mergedSourceIDs: 被合併的來源訂單編號
    /// - Returns: 建立的測試訂單
    private func makeOrder(
        id: String,
        customer: String,
        campaign: String,
        charged: Decimal,
        quantity: Int = 1,
        receipt: PaymentReceiptStatus = .pending,
        status: OrderStatus = .confirmed,
        itemCost: Decimal = 0,
        campaignNames: [String]? = nil,
        mergedSourceIDs: [String] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: customer, initials: "XX", tier: .regular),
            status: status,
            currency: .twd,
            date: Date(timeIntervalSince1970: 0),
            items: [LedgerOrderItem(name: "item", quantity: quantity, unitPrice: 0)],
            itemCost: itemCost,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: charged,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: [],
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: campaignNames ?? (campaign.isEmpty ? [] : [campaign]),
            paymentReceiptStatus: receipt,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: mergedSourceIDs
        )
    }
}
