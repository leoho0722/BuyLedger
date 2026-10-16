//
//  CampaignListFeatureTests+VisibleSections.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Testing

@testable import BuyLedger

extension CampaignListFeatureTests {

    /// 日期脈絡尚未記錄時，沒有可呈現的日期區段
    @Test
    func visibleSections_日期脈絡尚未建立_回傳空值() {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .ongoing
        )
        let state = Self.makeState(campaigns: [campaign])

        // When
        let visible = state.visibleSections

        // Then
        #expect(visible == nil)
    }

    /// 沒有任何開團時，即使已記錄日期脈絡也沒有可呈現的日期區段
    @Test
    func visibleSections_沒有開團_回傳空值() {
        // Given
        var state = Self.makeState(campaigns: [])
        state.dateContext = CampaignDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let visible = state.visibleSections

        // Then
        #expect(visible == nil)
    }

    /// 狀態篩選後沒有符合的開團時，不呈現日期區段
    @Test
    func visibleSections_篩選後沒有符合的開團_回傳空值() {
        // Given
        let ongoing = Campaign.fixture(
            id: "A",
            name: "進行團",
            closeDate: nil,
            status: .ongoing
        )
        var state = Self.makeState(campaigns: [ongoing])
        state.statusFilter = .closed
        state.dateContext = CampaignDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let visible = state.visibleSections

        // Then
        #expect(visible == nil)
    }

    /// 有符合篩選的開團且已記錄日期脈絡時，回傳該開團的區段與記錄的日期脈絡
    @Test
    func visibleSections_有符合的開團且已記錄日期脈絡_回傳區段與脈絡() {
        // Given
        let ongoing = Campaign.fixture(
            id: "A",
            name: "進行團",
            closeDate: nil,
            status: .ongoing
        )
        var state = Self.makeState(campaigns: [ongoing])
        state.statusFilter = .ongoing
        let context = CampaignDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.dateContext = context

        // When
        let visible = state.visibleSections

        // Then
        #expect(visible?.dateContext == context)
        #expect(visible?.sections.flatMap(\.subgroups).flatMap(\.campaigns).map(\.id) == ["A"])
    }
}
