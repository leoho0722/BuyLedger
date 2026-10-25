//
//  CampaignListFeatureInteractionsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignListFeature` 的單元測試，以 TestStore 逐步驗證使用者操作、狀態篩選與日期分組
@MainActor
struct CampaignListFeatureInteractionsTests {

    /// 驗證點擊開團列時，列表只送出顯示該開團詳情的請求，自身狀態不變
    @Test
    func campaignTapped_點擊開團列_委派顯示指定開團詳情() async {
        // Given
        let store = TestStore(initialState: CampaignListFeatureTestSupport.makeState()) {
            CampaignListFeature()
        }

        // When
        await store.send(.view(.campaignTapped("C1")))

        // Then
        await store.receive(\.delegate, .requested(.showDetail("C1")))
        await store.finish()
    }

    /// 驗證點擊新增開團時，列表只送出新增請求，自身狀態不變
    @Test
    func newCampaignTapped_列表新增操作_委派對應請求() async {
        // Given
        let store = TestStore(initialState: CampaignListFeatureTestSupport.makeState()) {
            CampaignListFeature()
        }

        // When
        await store.send(.view(.newCampaignTapped))

        // Then
        await store.receive(\.delegate.requested, .create)
        await store.finish()
    }

    /// 驗證點擊編輯開團時，列表只送出編輯該開團的請求，自身狀態不變
    @Test
    func editCampaignTapped_列表編輯操作_委派對應請求() async {
        // Given
        let store = TestStore(initialState: CampaignListFeatureTestSupport.makeState()) {
            CampaignListFeature()
        }

        // When
        await store.send(.view(.editCampaignTapped("C1")))

        // Then
        await store.receive(\.delegate.requested, .edit("C1"))
        await store.finish()
    }

    /// 驗證點擊刪除開團時，列表只送出刪除該開團的請求，自身狀態不變
    @Test
    func deleteCampaignTapped_列表刪除操作_委派對應請求() async {
        // Given
        let store = TestStore(initialState: CampaignListFeatureTestSupport.makeState()) {
            CampaignListFeature()
        }

        // When
        await store.send(.view(.deleteCampaignTapped("C1")))

        // Then
        await store.receive(\.delegate.requested, .delete("C1"))
        await store.finish()
    }

    /// 驗證選取狀態篩選後，日期區段只含符合該狀態的開團，選取全部時兩種狀態的開團都包含
    ///
    /// - Parameter scenario: 要套用的狀態與獨立預期的開團識別值
    @Test(arguments: FilterCase.allCases)
    func statusFilterSelected_選取狀態篩選_日期區段只包含符合的開團(scenario: FilterCase) async {
        // Given
        let ongoing = Campaign.fixture(
            id: "A",
            name: "進行團",
            closeDate: nil,
            status: .ongoing
        )
        let closed = Campaign.fixture(
            id: "B",
            name: "已結束團",
            closeDate: nil,
            status: .closed
        )
        var initial = CampaignListFeatureTestSupport.makeState(campaigns: [ongoing, closed])
        initial.statusFilter = scenario.status == .closed ? .ongoing : .closed
        initial.dateContext = CampaignDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            CampaignListFeature()
        }

        // When
        await store.send(.view(.statusFilterSelected(scenario.status))) {
            $0.statusFilter = scenario.status
        }

        // Then
        let ids = store.state.dateSections.flatMap {
            $0.subgroups.flatMap {
                $0.campaigns.map(\.id)
            }
        }
        #expect(ids.sorted() == scenario.expectedIDs)
    }

    /// 驗證選取分組方式後，區段標題跟著變：日分組沒有子群組標題，月分組為年月與日，年分組為年與月
    ///
    /// - Parameter scenario: 分組方式與獨立預期的頂層、子群組標題
    @Test(arguments: GroupingCase.allCases)
    func groupingSelected_選取日期分組_更新分組與區段標題(scenario: GroupingCase) async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "四月團",
            closeDate: nil,
            status: .ongoing
        )
        var initial = CampaignListFeatureTestSupport.makeState(campaigns: [campaign])
        initial.grouping = scenario.grouping == .day ? .month : .day
        initial.dateContext = CampaignDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            CampaignListFeature()
        }

        // When
        await store.send(.view(.groupingSelected(scenario.grouping))) {
            $0.grouping = scenario.grouping
        }

        // Then
        let section = store.state.dateSections.first
        let subtitle = section?.subgroups.first?.title
        #expect(section?.title == scenario.expectedTitle)
        #expect(subtitle == scenario.expectedSubtitle)
    }
}

// MARK: - Nested Types

extension CampaignListFeatureInteractionsTests {

    /// 所選狀態與預期可見的開團識別值
    struct FilterCase: Sendable {

        /// 全部、進行中與已結束三種篩選各自應保留的開團識別值
        static let allCases = [
            Self(status: nil, expectedIDs: ["A", "B"]),
            Self(status: .ongoing, expectedIDs: ["A"]),
            Self(status: .closed, expectedIDs: ["B"]),
        ]

        /// 所選狀態；`nil` 表示全部
        let status: CampaignStatus?

        /// 應保留的開團識別值
        let expectedIDs: [String]
    }

    /// 日期分組方式及其獨立預期的區段標題
    struct GroupingCase: Sendable {

        /// 日、月、年分組各自的頂層標題與子群組標題
        static let allCases = [
            Self(
                grouping: .day,
                expectedTitle: .day(Date(timeIntervalSince1970: 1_775_001_600)),
                expectedSubtitle: nil
            ),
            Self(
                grouping: .month,
                expectedTitle: .yearMonth(Date(timeIntervalSince1970: 1_775_001_600)),
                expectedSubtitle: .day(Date(timeIntervalSince1970: 1_775_001_600))
            ),
            Self(
                grouping: .year,
                expectedTitle: .year(Date(timeIntervalSince1970: 1_767_225_600)),
                expectedSubtitle: .month(Date(timeIntervalSince1970: 1_775_001_600))
            ),
        ]

        /// 所選分組方式
        let grouping: CampaignGrouping

        /// 頂層區段應呈現的標題
        let expectedTitle: CampaignSectionTitle

        /// 子群組應呈現的標題；`nil` 表示不顯示
        let expectedSubtitle: CampaignSectionTitle?
    }
}
