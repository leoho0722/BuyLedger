//
//  CampaignSummaryTests+Delivery.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation
import Testing

@testable import BuyLedger

extension CampaignSummaryTests {

    /// 兩筆已交付、一筆已取消、一筆確認中：到貨進度分母排除已取消訂單
    @Test
    func init_含已取消訂單_到貨進度分母排除已取消() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "O1",
                customer: "A",
                campaign: "團",
                charged: 100,
                status: .delivered
            ),
            Self.makeOrder(
                id: "O2",
                customer: "B",
                campaign: "團",
                charged: 100,
                status: .delivered
            ),
            Self.makeOrder(
                id: "O3",
                customer: "C",
                campaign: "團",
                charged: 100,
                status: .cancelled
            ),
            Self.makeOrder(
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
        #expect(abs(summary.deliveryRatio - (2.0 / 3.0)) < 0.0001)
    }

    /// 已到貨、已交付與已取貨都算「已到貨」：到貨進度分子同時計入三者，運送中不計入
    @Test
    func init_已到貨已交付已取貨與運送中_到貨進度分子計入前三者() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "O1",
                customer: "A",
                campaign: "團",
                charged: 100,
                status: .arrived
            ),
            Self.makeOrder(
                id: "O2",
                customer: "B",
                campaign: "團",
                charged: 100,
                status: .delivered
            ),
            Self.makeOrder(
                id: "O3",
                customer: "C",
                campaign: "團",
                charged: 100,
                status: .pickedUp
            ),
            Self.makeOrder(
                id: "O4",
                customer: "D",
                campaign: "團",
                charged: 100,
                status: .shipping
            ),
            Self.makeOrder(
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

    /// 部分到貨不計入已到貨數，但仍計入進行中訂單
    @Test
    func init_含部分到貨訂單_計入分母但不計入分子() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "O1",
                customer: "A",
                campaign: "團",
                charged: 100,
                status: .arrived
            ),
            Self.makeOrder(
                id: "O2",
                customer: "B",
                campaign: "團",
                charged: 100,
                status: .partiallyArrived
            ),
            Self.makeOrder(
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
        #expect(abs(summary.deliveryRatio - (1.0 / 3.0)) < 0.0001)
    }

    /// 已合併的舊單已不再各自等待到貨，到貨進度分母比照已取消排除
    @Test
    func init_含已合併訂單_到貨進度分母排除已合併() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "O1",
                customer: "A",
                campaign: "團",
                charged: 100,
                status: .delivered
            ),
            Self.makeOrder(
                id: "O2",
                customer: "B",
                campaign: "團",
                charged: 100,
                status: .merged
            ),
            Self.makeOrder(
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
