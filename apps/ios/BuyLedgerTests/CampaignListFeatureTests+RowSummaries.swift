//
//  CampaignListFeatureTests+RowSummaries.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

extension CampaignListFeatureTests {

    /// 列彙總含有投影過的開團名稱時，回傳該開團的彙總
    @Test
    func summary_已投影的開團名稱_回傳該開團彙總() {
        // Given
        let ongoing = Campaign.fixture(
            id: "A",
            name: "進行團",
            closeDate: nil,
            status: .ongoing
        )
        let order = LedgerOrder.fixture(id: "OA", chargedAmount: 1_200, campaignNames: ["進行團"])
        var state = Self.makeState(campaigns: [ongoing], orders: [order])
        state.dateContext = CampaignDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let summary = state.rowSummaries.summary(forCampaignNamed: "進行團")

        // Then
        #expect(summary.orderCount == 1)
        #expect(summary.receivables == 1_200)
    }

    /// 列彙總沒有投影過的開團名稱時，回傳沒有訂單的空彙總
    @Test
    func summary_未投影的開團名稱_回傳沒有訂單的空彙總() {
        // Given
        let ongoing = Campaign.fixture(
            id: "A",
            name: "進行團",
            closeDate: nil,
            status: .ongoing
        )
        var state = Self.makeState(campaigns: [ongoing])
        state.dateContext = CampaignDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let summary = state.rowSummaries.summary(forCampaignNamed: "未投影團")

        // Then
        #expect(summary.memberOrders.isEmpty)
        #expect(summary.orderCount == 0)
        #expect(summary.receivables == 0)
    }
}
