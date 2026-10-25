//
//  CampaignSummaryDeliveryTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CampaignSummary` 的單元測試，涵蓋到貨進度
struct CampaignSummaryDeliveryTests {

    /// 驗證含已取消訂單時，到貨進度分母排除已取消的訂單，剩 3 筆進行中訂單，其中 2 筆已到貨
    @Test
    func init_含已取消訂單_到貨進度分母排除已取消() {
        // Given
        let orders = [
            CampaignSummaryTestSupport.makeOrder(
                id: "O1",
                customer: "A",
                campaign: "團",
                charged: 100,
                status: .delivered
            ),
            CampaignSummaryTestSupport.makeOrder(
                id: "O2",
                customer: "B",
                campaign: "團",
                charged: 100,
                status: .delivered
            ),
            CampaignSummaryTestSupport.makeOrder(
                id: "O3",
                customer: "C",
                campaign: "團",
                charged: 100,
                status: .cancelled
            ),
            CampaignSummaryTestSupport.makeOrder(
                id: "O4",
                customer: "D",
                campaign: "團",
                charged: 100,
                status: .confirmed
            ),
        ]

        // When
        let summary = CampaignSummary(campaignName: "團", orders: orders)

        // Then
        #expect(summary.arrivedCount == 2)
        #expect(summary.activeCount == 3)
        #expect(abs(summary.deliveryRatio - 0.6666666666666666) < 0.0001)
    }

    /// 驗證已到貨、已交付與已取貨都計為已到貨，運送中只計入進行中，已取消的訂單則都不計入
    @Test
    func init_已到貨已交付已取貨與運送中_到貨進度分子計入前三者() {
        // Given
        let orders = [
            CampaignSummaryTestSupport.makeOrder(
                id: "O1",
                customer: "A",
                campaign: "團",
                charged: 100,
                status: .arrived
            ),
            CampaignSummaryTestSupport.makeOrder(
                id: "O2",
                customer: "B",
                campaign: "團",
                charged: 100,
                status: .delivered
            ),
            CampaignSummaryTestSupport.makeOrder(
                id: "O3",
                customer: "C",
                campaign: "團",
                charged: 100,
                status: .pickedUp
            ),
            CampaignSummaryTestSupport.makeOrder(
                id: "O4",
                customer: "D",
                campaign: "團",
                charged: 100,
                status: .shipping
            ),
            CampaignSummaryTestSupport.makeOrder(
                id: "O5",
                customer: "E",
                campaign: "團",
                charged: 100,
                status: .cancelled
            ),
        ]

        // When
        let summary = CampaignSummary(campaignName: "團", orders: orders)

        // Then
        #expect(summary.arrivedCount == 3)
        #expect(summary.activeCount == 4)
        #expect(abs(summary.deliveryRatio - 0.75) < 0.0001)
    }

    /// 驗證部分到貨的訂單不計入已到貨數，但仍計入進行中訂單
    @Test
    func init_含部分到貨訂單_計入分母但不計入分子() {
        // Given
        let orders = [
            CampaignSummaryTestSupport.makeOrder(
                id: "O1",
                customer: "A",
                campaign: "團",
                charged: 100,
                status: .arrived
            ),
            CampaignSummaryTestSupport.makeOrder(
                id: "O2",
                customer: "B",
                campaign: "團",
                charged: 100,
                status: .partiallyArrived
            ),
            CampaignSummaryTestSupport.makeOrder(
                id: "O3",
                customer: "C",
                campaign: "團",
                charged: 100,
                status: .shipping
            ),
        ]

        // When
        let summary = CampaignSummary(campaignName: "團", orders: orders)

        // Then
        #expect(summary.arrivedCount == 1)
        #expect(summary.activeCount == 3)
        #expect(abs(summary.deliveryRatio - 0.3333333333333333) < 0.0001)
    }

    /// 驗證已合併的訂單不再各自等待到貨，到貨進度分母與已取消的訂單一樣排除
    @Test
    func init_含已合併訂單_到貨進度分母排除已合併() {
        // Given
        let orders = [
            CampaignSummaryTestSupport.makeOrder(
                id: "O1",
                customer: "A",
                campaign: "團",
                charged: 100,
                status: .delivered
            ),
            CampaignSummaryTestSupport.makeOrder(
                id: "O2",
                customer: "B",
                campaign: "團",
                charged: 100,
                status: .merged
            ),
            CampaignSummaryTestSupport.makeOrder(
                id: "O3",
                customer: "C",
                campaign: "團",
                charged: 100,
                status: .shipping
            ),
        ]

        // When
        let summary = CampaignSummary(campaignName: "團", orders: orders)

        // Then
        #expect(summary.arrivedCount == 1)
        #expect(summary.activeCount == 2)
        #expect(abs(summary.deliveryRatio - 0.5) < 0.0001)
    }
}
