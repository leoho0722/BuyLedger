//
//  CampaignSummaryTests+Membership.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation
import Testing

@testable import BuyLedger

extension CampaignSummaryTests {

    /// 沒有歸屬任何開團的訂單不計入彙總，即使金額再大也不影響應收與分貨
    @Test
    func init_含未歸團訂單_彙總排除未歸團訂單() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "O1",
                customer: "A",
                campaign: "團",
                charged: 100,
                receipt: .received
            ),
            Self.makeOrder(
                id: "O2",
                customer: "B",
                campaign: "",
                charged: 999,
                receipt: .received
            ),
        ]

        // When
        let summary = CampaignSummary(campaignName: "團", orders: orders)

        // Then
        #expect(summary.orderCount == 1)
        #expect(summary.receivables == 100)
        #expect(summary.distribution.map(\.customerName) == ["A"])
    }

    /// 合併後產生的結果訂單不算成員，只統計合併前的原始訂單
    @Test
    func init_含合併結果訂單_只統計合併前的原始訂單() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "A",
                customer: "客",
                campaign: "May-JP",
                charged: 1_000,
                status: .merged,
                itemCost: 200
            ),
            Self.makeOrder(
                id: "B",
                customer: "客",
                campaign: "June-KR",
                charged: 2_000,
                status: .merged,
                itemCost: 300
            ),
            Self.makeOrder(
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

        // When
        let mayTeam = CampaignSummary(campaignName: "May-JP", orders: orders)
        let juneTeam = CampaignSummary(campaignName: "June-KR", orders: orders)

        // Then
        #expect(mayTeam.memberOrders.map(\.id) == ["A"])
        #expect(mayTeam.receivables == 1_000)
        #expect(mayTeam.profit == 800)
        #expect(juneTeam.memberOrders.map(\.id) == ["B"])
        #expect(juneTeam.receivables == 2_000)
    }

    /// 防衛性規則：原始訂單若帶多個開團，全額計入它的每一團
    @Test
    func init_原始訂單帶多個開團_全額計入每一個開團() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "O1",
                customer: "客",
                campaign: "",
                charged: 900,
                campaignNames: ["May-JP", "June-KR"]
            ),
        ]

        // When
        let mayTeam = CampaignSummary(campaignName: "May-JP", orders: orders)
        let juneTeam = CampaignSummary(campaignName: "June-KR", orders: orders)

        // Then
        #expect(mayTeam.receivables == 900)
        #expect(juneTeam.receivables == 900)
    }

    /// 批次投影涵蓋空團、重複團名與多團歸屬：每個開團的成員、筆數與應收都符合預期
    @Test
    func batch_含空團重複團名與多團訂單_各團成員筆數與應收符合預期() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "O1",
                customer: "小明",
                campaign: "五月團",
                charged: 1_000,
                receipt: .received
            ),
            Self.makeOrder(
                id: "O2",
                customer: "小華",
                campaign: "",
                charged: 500,
                campaignNames: ["五月團", "六月團"]
            ),
            Self.makeOrder(
                id: "O3",
                customer: "小美",
                campaign: "六月團",
                charged: 300,
                status: .cancelled
            ),
        ]
        // 同名開團「五月團」重複兩次，批次投影以先出現者為準，每個團名只留一份彙總
        let campaignNames = ["五月團", "五月團", "六月團", "空團"]

        // When
        let batched = CampaignSummary.batch(campaignNames: campaignNames, orders: orders)

        // Then
        #expect(Set(batched.keys) == Set(["五月團", "六月團", "空團"]))
        // 訂單同時歸屬多團：O2 同時計入「五月團」與「六月團」
        #expect(batched["五月團"]?.memberOrders.map(\.id) == ["O1", "O2"])
        #expect(batched["五月團"]?.orderCount == 2)
        #expect(batched["五月團"]?.receivables == 1_500)
        #expect(batched["六月團"]?.memberOrders.map(\.id) == ["O2", "O3"])
        #expect(batched["六月團"]?.orderCount == 2)
        #expect(batched["六月團"]?.receivables == 800)
        // 零成員團 (無任何訂單歸屬) 不崩潰，彙總為空
        #expect(batched["空團"]?.memberOrders.isEmpty == true)
        #expect(batched["空團"]?.orderCount == 0)
        #expect(batched["空團"]?.receivables == 0)
    }
}
