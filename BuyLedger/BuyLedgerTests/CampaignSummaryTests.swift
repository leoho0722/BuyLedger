//
//  CampaignSummaryTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct CampaignSummaryTests {

    // MARK: - Tests

    @Test func distributionGroupsByCustomerWithSummedQuantityAndReceiptMarker() {
        // SBE：A("小明", qty2, 600, received)、B("小明", qty1, 300, pending)、C("小華", qty1, 400, received)。
        let orders = [
            makeOrder(id: "A", customer: "小明", campaign: "團", charged: 600, quantity: 2, receipt: .received),
            makeOrder(id: "B", customer: "小明", campaign: "團", charged: 300, quantity: 1, receipt: .pending),
            makeOrder(id: "C", customer: "小華", campaign: "團", charged: 400, quantity: 1, receipt: .received),
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
        // SBE：O1(charged=1000, received)、O2(charged=500, pending) → 應收 1500、已收 1000、未收 500。
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

        #expect(summary.deliveredCount == 2)
        #expect(summary.activeCount == 3)
        #expect(abs(summary.deliveryRatio - (2.0 / 3.0)) < 0.0001)
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
        // 成本與費率以外皆 0：profit = charged − itemCost。
        let orders = [
            makeOrder(id: "O1", customer: "A", campaign: "團", charged: 1000, receipt: .received, itemCost: 200),
            makeOrder(id: "O2", customer: "B", campaign: "團", charged: 500, receipt: .pending, itemCost: 100),
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

    // MARK: - Helper

    /// 建立僅填入 ``CampaignSummary`` 相關欄位的訂單；其餘成本／費率欄位皆為 0，使 profit = charged − itemCost。
    private func makeOrder(
        id: String,
        customer: String,
        campaign: String,
        charged: Decimal,
        quantity: Int = 1,
        receipt: PaymentReceiptStatus = .pending,
        status: OrderStatus = .confirmed,
        itemCost: Decimal = 0
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
            category: "",
            paymentMethod: "",
            notes: "",
            verificationStatus: "",
            campaignName: campaign,
            paymentReceiptStatus: receipt,
            isCashOnDelivery: false
        )
    }
}
