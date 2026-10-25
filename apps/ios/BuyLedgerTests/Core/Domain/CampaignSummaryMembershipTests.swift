//
//  CampaignSummaryMembershipTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CampaignSummary` 的單元測試，涵蓋未歸團、合併結果與多團訂單的成員歸屬
struct CampaignSummaryMembershipTests {

    /// 驗證未歸團的訂單不計入彙總，即使金額再大也不影響應收與分貨
    @Test
    func init_含未歸團訂單_彙總排除未歸團訂單() {
        // Given
        let orders = [
            CampaignSummaryTestSupport.makeOrder(
                id: "O1",
                customer: "A",
                campaign: "團",
                charged: 100,
                receipt: .received
            ),
            CampaignSummaryTestSupport.makeOrder(
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

    /// 驗證合併結果訂單不算五月團成員，五月團只統計合併前的原始訂單 A，應收 1,000、利潤 800
    @Test
    func init_含合併結果訂單的五月團_只統計合併前的原始訂單() {
        // Given
        let orders = Self.makeMergedOrders()

        // When
        let mayTeam = CampaignSummary(campaignName: "May-JP", orders: orders)

        // Then
        #expect(mayTeam.memberOrders.map(\.id) == ["A"])
        #expect(mayTeam.receivables == 1_000)
        #expect(mayTeam.profit == 800)
    }

    /// 驗證合併結果訂單不算六月團成員，六月團只統計合併前的原始訂單 B，應收 2,000
    @Test
    func init_含合併結果訂單的六月團_只統計合併前的原始訂單() {
        // Given
        let orders = Self.makeMergedOrders()

        // When
        let juneTeam = CampaignSummary(campaignName: "June-KR", orders: orders)

        // Then
        #expect(juneTeam.memberOrders.map(\.id) == ["B"])
        #expect(juneTeam.receivables == 2_000)
    }

    /// 驗證原始訂單帶多個開團時，應收全額 900 計入五月團，不按開團拆分
    @Test
    func init_原始訂單帶多個開團_全額計入五月團() {
        // Given
        let orders = Self.makeMultiCampaignOrders()

        // When
        let mayTeam = CampaignSummary(campaignName: "May-JP", orders: orders)

        // Then
        #expect(mayTeam.receivables == 900)
    }

    /// 驗證原始訂單帶多個開團時，應收全額 900 也計入六月團，不按開團拆分
    @Test
    func init_原始訂單帶多個開團_全額計入六月團() {
        // Given
        let orders = Self.makeMultiCampaignOrders()

        // When
        let juneTeam = CampaignSummary(campaignName: "June-KR", orders: orders)

        // Then
        #expect(juneTeam.receivables == 900)
    }

    /// 驗證批次彙總涵蓋空團、重複團名與多團歸屬時，各團的成員、筆數與應收都符合預期
    @Test
    func batch_含空團重複團名與多團訂單_各團成員筆數與應收符合預期() {
        // Given
        let orders = [
            CampaignSummaryTestSupport.makeOrder(
                id: "O1",
                customer: "小明",
                campaign: "五月團",
                charged: 1_000,
                receipt: .received
            ),
            CampaignSummaryTestSupport.makeOrder(
                id: "O2",
                customer: "小華",
                campaign: "",
                charged: 500,
                campaignNames: ["五月團", "六月團"]
            ),
            CampaignSummaryTestSupport.makeOrder(
                id: "O3",
                customer: "小美",
                campaign: "六月團",
                charged: 300,
                status: .cancelled
            ),
        ]
        // 同名開團「五月團」重複兩次，批次彙總以先出現者為準，每個團名只留一份彙總
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

// MARK: - Private Method

private extension CampaignSummaryMembershipTests {

    /// 建立合併前後的三筆訂單：兩筆原始訂單分屬五月團與六月團，一筆合併結果訂單
    ///
    /// - Returns: 含合併結果訂單的訂單清單
    static func makeMergedOrders() -> [LedgerOrder] {
        [
            CampaignSummaryTestSupport.makeOrder(
                id: "A",
                customer: "客",
                campaign: "May-JP",
                charged: 1_000,
                status: .merged,
                itemCost: 200
            ),
            CampaignSummaryTestSupport.makeOrder(
                id: "B",
                customer: "客",
                campaign: "June-KR",
                charged: 2_000,
                status: .merged,
                itemCost: 300
            ),
            CampaignSummaryTestSupport.makeOrder(
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
    }

    /// 建立一筆同時帶五月團與六月團名稱的原始訂單，應收 900
    ///
    /// - Returns: 帶兩個開團名稱的單筆訂單清單
    static func makeMultiCampaignOrders() -> [LedgerOrder] {
        [
            CampaignSummaryTestSupport.makeOrder(
                id: "O1",
                customer: "客",
                campaign: "",
                charged: 900,
                campaignNames: ["May-JP", "June-KR"]
            ),
        ]
    }
}
