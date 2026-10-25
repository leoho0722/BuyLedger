//
//  CampaignSummaryTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CampaignSummary` 的單元測試，涵蓋分貨清單、結算金額、到貨進度與成員歸屬
struct CampaignSummaryTests {

    /// 驗證分貨依客戶合併成一列，同一客戶只要有一筆未收款，就不標記為收齊
    @Test
    func init_兩位客戶且其一部分已收款_分貨依客戶加總並標記是否收齊() {
        // Given
        let orders = [
            CampaignSummaryTestSupport.makeOrder(
                id: "A",
                customer: "小明",
                campaign: "團",
                charged: 600,
                quantity: 2,
                receipt: .received
            ),
            CampaignSummaryTestSupport.makeOrder(
                id: "B",
                customer: "小明",
                campaign: "團",
                charged: 300,
                quantity: 1,
                receipt: .pending
            ),
            CampaignSummaryTestSupport.makeOrder(
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

    /// 驗證應收 1,500、已收 1,000、未收 500 的彙總正確，已收比例為三分之二
    @Test
    func init_已收款與未收款訂單_彙總應收已收未收與已收比例() {
        // Given
        let orders = [
            CampaignSummaryTestSupport.makeOrder(
                id: "O1",
                customer: "A",
                campaign: "團",
                charged: 1000,
                receipt: .received
            ),
            CampaignSummaryTestSupport.makeOrder(
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
        #expect(abs(summary.receivedRatio - 0.6666666666666666) < 0.0001)
    }

    /// 驗證應收總額為零時，已收比例與利潤率都為零，不會除以零
    @Test
    func init_應收總額為零_已收比例與利潤率皆為零() {
        // Given
        let orders = [
            CampaignSummaryTestSupport.makeOrder(
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

    /// 驗證總收款與總成本為各筆訂單加總，毛利等於總收款減總成本
    @Test
    func init_兩筆有商品成本的訂單_總收款總成本與毛利加總各筆訂單() {
        // Given
        let orders = [
            CampaignSummaryTestSupport.makeOrder(
                id: "O1",
                customer: "A",
                campaign: "團",
                charged: 1000,
                receipt: .received,
                itemCost: 200
            ),
            CampaignSummaryTestSupport.makeOrder(
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

    /// 驗證沒有任何訂單歸屬的開團時，筆數、金額與進度皆為零，分貨清單為空
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

    /// 驗證全部已收款的分貨列，朗讀的收款狀態為已收款，英文朗讀為 Received
    ///
    /// - Throws: 英文資源目錄不存在時由 `#require` 丟出
    @Test
    func receiptAccessibilityLabel_全部已收款_朗讀已收款() throws {
        // Given
        let row = CampaignDistributionRow(
            customerName: "小明",
            totalQuantity: 1,
            totalAmount: 400,
            isFullyReceived: true,
            orders: []
        )

        // When
        let label = row.receiptAccessibilityLabel
        let text = try Self.localizedText(label, language: .english)

        // Then
        #expect(label.key == "orders.general.status.received")
        #expect(text == "Received")
    }

    /// 驗證仍有未收款訂單的分貨列，朗讀的收款狀態為待收款，英文朗讀為 Pending Payment
    ///
    /// - Throws: 英文資源目錄不存在時由 `#require` 丟出
    @Test
    func receiptAccessibilityLabel_仍有未收款_朗讀待收款() throws {
        // Given
        let row = CampaignDistributionRow(
            customerName: "小華",
            totalQuantity: 2,
            totalAmount: 900,
            isFullyReceived: false,
            orders: []
        )

        // When
        let label = row.receiptAccessibilityLabel
        let text = try Self.localizedText(label, language: .english)

        // Then
        #expect(label.key == "orders.filter.status.pendingPayment")
        #expect(text == "Pending Payment")
    }
}

// MARK: - Private Method

private extension CampaignSummaryTests {

    /// 以指定語言的資源目錄解析本地化值，不受測試程序預設語言影響
    ///
    /// - Parameters:
    ///   - resource: 分貨列提供的本地化值
    ///   - language: 測試指定的 App 語言
    /// - Returns: 以指定語言解析後的文字
    /// - Throws: 指定語言的資源目錄不存在時由 `#require` 丟出
    static func localizedText(
        _ resource: LocalizedStringResource,
        language: AppLanguage
    ) throws -> String {
        let bundleURL = try #require(
            Bundle.main.url(forResource: language.localeIdentifier, withExtension: "lproj")
        )
        let bundle = try #require(Bundle(url: bundleURL))
        return String(
            localized: resource.defaultValue,
            table: resource.table,
            bundle: bundle,
            locale: language.locale
        )
    }
}
