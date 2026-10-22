//
//  CampaignListFeatureTests+Interactions.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignListFeatureTests {

    /// 點擊開團列只送出詳情請求，不改列表資料
    @Test
    func campaignTapped_點擊開團列_委派顯示指定開團詳情() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            CampaignListFeature()
        }

        // When
        await store.send(.view(.campaignTapped("C1")))

        // Then
        await store.receive(\.delegate, .requested(.showDetail("C1")))
        await store.finish()
    }

    /// 列表新增操作只向父層送出對應請求，不改列表資料
    @Test
    func newCampaignTapped_列表新增操作_委派對應請求() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            CampaignListFeature()
        }

        // When
        await store.send(.view(.newCampaignTapped))

        // Then
        await store.receive(\.delegate.requested, .create)
        await store.finish()
    }

    /// 列表編輯操作只向父層送出對應請求，不改列表資料
    @Test
    func editCampaignTapped_列表編輯操作_委派對應請求() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            CampaignListFeature()
        }

        // When
        await store.send(.view(.editCampaignTapped("C1")))

        // Then
        await store.receive(\.delegate.requested, .edit("C1"))
        await store.finish()
    }

    /// 列表刪除操作只向父層送出對應請求，不改列表資料
    @Test
    func deleteCampaignTapped_列表刪除操作_委派對應請求() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            CampaignListFeature()
        }

        // When
        await store.send(.view(.deleteCampaignTapped("C1")))

        // Then
        await store.receive(\.delegate.requested, .delete("C1"))
        await store.finish()
    }

    /// 狀態篩選只保留所選狀態，清除篩選時重新包含所有開團
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
        var initial = Self.makeState(campaigns: [ongoing, closed])
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

    /// 選取日、月、年分組後，`State` 產生對應的頂層與子群組標題型別
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
        var initial = Self.makeState(campaigns: [campaign])
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

extension CampaignListFeatureTests {

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
