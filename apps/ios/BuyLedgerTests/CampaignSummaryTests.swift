//
//  CampaignSummaryTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證開團彙總的分貨清單、結算金額、到貨進度與成員歸屬
struct CampaignSummaryTests {

    /// 小明兩筆訂單、一筆已收款，小華一筆已收款：同一客戶合併成一列，只要有一筆未收款就不算收齊
    @Test
    func init_兩位客戶且其一部分已收款_分貨依客戶加總並標記是否收齊() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "A",
                customer: "小明",
                campaign: "團",
                charged: 600,
                quantity: 2,
                receipt: .received
            ),
            Self.makeOrder(
                id: "B",
                customer: "小明",
                campaign: "團",
                charged: 300,
                quantity: 1,
                receipt: .pending
            ),
            Self.makeOrder(
                id: "C",
                customer: "小華",
                campaign: "團",
                charged: 400,
                quantity: 1,
                receipt: .received
            ),
        ]

        // When
        let summary = CampaignSummary(campaignName: "團", orders: orders)

        // Then
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

    /// 應收 1,500、已收 1,000、未收 500，已收比例為三分之二
    @Test
    func init_已收款與未收款訂單_彙總應收已收未收與已收比例() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "O1",
                customer: "A",
                campaign: "團",
                charged: 1000,
                receipt: .received
            ),
            Self.makeOrder(
                id: "O2",
                customer: "B",
                campaign: "團",
                charged: 500,
                receipt: .pending
            ),
        ]

        // When
        let summary = CampaignSummary(campaignName: "團", orders: orders)

        // Then
        #expect(summary.receivables == 1500)
        #expect(summary.receivedAmount == 1000)
        #expect(summary.outstandingAmount == 500)
        #expect(abs(summary.receivedRatio - (1000.0 / 1500.0)) < 0.0001)
    }

    /// 應收總額為零時，已收比例與利潤率都是零，不會除以零
    @Test
    func init_應收總額為零_已收比例與利潤率皆為零() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "O1",
                customer: "A",
                campaign: "團",
                charged: 0,
                receipt: .pending
            ),
        ]

        // When
        let summary = CampaignSummary(campaignName: "團", orders: orders)

        // Then
        #expect(summary.receivables == 0)
        #expect(summary.receivedRatio == 0)
        #expect(summary.margin == 0)
    }

    /// 成本與費率以外皆為零：毛利等於實收金額減商品成本，總成本與總實收各筆加總
    @Test
    func init_兩筆有商品成本的訂單_總收款總成本與毛利加總各筆訂單() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "O1",
                customer: "A",
                campaign: "團",
                charged: 1000,
                receipt: .received,
                itemCost: 200
            ),
            Self.makeOrder(
                id: "O2",
                customer: "B",
                campaign: "團",
                charged: 500,
                receipt: .pending,
                itemCost: 100
            ),
        ]

        // When
        let summary = CampaignSummary(campaignName: "團", orders: orders)

        // Then
        #expect(summary.totalRevenue == 1500)
        #expect(summary.totalCost == 300)
        #expect(summary.profit == 1200)
    }

    /// 沒有任何訂單歸屬的開團：筆數、金額與進度全為零，分貨清單為空
    @Test
    func init_沒有任何訂單_彙總全為零且無分貨() {
        // Given
        let orders: [LedgerOrder] = []

        // When
        let summary = CampaignSummary(campaignName: "空團", orders: orders)

        // Then
        #expect(summary.orderCount == 0)
        #expect(summary.receivables == 0)
        #expect(summary.receivedRatio == 0)
        #expect(summary.deliveryRatio == 0)
        #expect(summary.distribution.isEmpty)
    }
}

// MARK: - Internal Method

extension CampaignSummaryTests {

    /// 建立只含 `CampaignSummary` 所需欄位的訂單，每筆訂單固定一個商品項目
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - customer: 客戶名稱
    ///   - campaign: 主要開團名稱，空字串代表未歸團
    ///   - charged: 客戶實付金額
    ///   - quantity: 商品數量
    ///   - receipt: 付款收據狀態
    ///   - status: 訂單狀態
    ///   - itemCost: 商品成本
    ///   - campaignNames: 訂單所屬的開團名稱，帶值時取代 `campaign`
    ///   - mergedSourceIDs: 被合併的來源訂單編號
    /// - Returns: 含單項商品、指定金額與收款狀態的訂單
    static func makeOrder(
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
        LedgerOrder.fixture(
            id: id,
            customer: LedgerCustomer(name: customer, initials: "XX", tier: .regular),
            status: status,
            items: [LedgerOrderItem(name: "item", quantity: quantity, unitPrice: 0)],
            itemCost: itemCost,
            chargedAmount: charged,
            campaignNames: campaignNames ?? (campaign.isEmpty ? [] : [campaign]),
            paymentReceiptStatus: receipt,
            mergedSourceIDs: mergedSourceIDs
        )
    }
}
