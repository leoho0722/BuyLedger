//
//  CampaignListFeatureVisibleSectionsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Testing

@testable import BuyLedger

/// `CampaignListFeature` 的單元測試，涵蓋可見區段投影的條件判定
struct CampaignListFeatureVisibleSectionsTests {

    /// 驗證日期脈絡尚未記錄時，可見區段為 `nil`
    @Test
    func visibleSections_日期脈絡尚未建立_回傳空值() {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .ongoing
        )
        let state = CampaignListFeatureTestSupport.makeState(campaigns: [campaign])

        // When
        let visible = state.visibleSections

        // Then
        #expect(visible == nil)
    }

    /// 驗證沒有任何開團時，即使已記錄日期脈絡，可見區段仍為 `nil`
    @Test
    func visibleSections_沒有開團_回傳空值() {
        // Given
        var state = CampaignListFeatureTestSupport.makeState(campaigns: [])
        state.dateContext = CampaignDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let visible = state.visibleSections

        // Then
        #expect(visible == nil)
    }

    /// 驗證狀態篩選後沒有符合的開團時，可見區段為 `nil`
    @Test
    func visibleSections_篩選後沒有符合的開團_回傳空值() {
        // Given
        let ongoing = Campaign.fixture(
            id: "A",
            name: "進行團",
            closeDate: nil,
            status: .ongoing
        )
        var state = CampaignListFeatureTestSupport.makeState(campaigns: [ongoing])
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

    /// 驗證有符合篩選的開團且已記錄日期脈絡時，可見區段帶著記錄的日期脈絡，且只含符合篩選的開團
    @Test
    func visibleSections_有符合的開團且已記錄日期脈絡_回傳區段與脈絡() {
        // Given
        let ongoing = Campaign.fixture(
            id: "A",
            name: "進行團",
            closeDate: nil,
            status: .ongoing
        )
        var state = CampaignListFeatureTestSupport.makeState(campaigns: [ongoing])
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
