//
//  CampaignDateSectionBuilderTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CampaignDateSectionBuilder` 的單元測試，涵蓋依分組粒度分桶、排序與各區段的標題值
struct CampaignDateSectionBuilderTests {

    /// 驗證日分組時，同一天的開團併成一個區段，區段與區段內的開團都由新到舊排列，每個區段只有一個沒有標題的子群組
    ///
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test
    func sections_日分組_同日併入單一區段且依日期由新到舊() throws {
        // Given
        let calendar = try CampaignDateSectionBuilderTestSupport.makeCalendar(secondsFromGMT: 0)
        let campaigns = [
            Campaign.fixture(
                id: "ID-舊團",
                name: "舊團",
                openDate: Date(timeIntervalSince1970: 1_778_230_800)
            ),
            Campaign.fixture(
                id: "ID-今天早團",
                name: "今天早團",
                openDate: Date(timeIntervalSince1970: 1_778_572_800)
            ),
            Campaign.fixture(
                id: "ID-昨天團",
                name: "昨天團",
                openDate: Date(timeIntervalSince1970: 1_778_542_200)
            ),
            Campaign.fixture(
                id: "ID-今天晚團",
                name: "今天晚團",
                openDate: Date(timeIntervalSince1970: 1_778_616_000)
            ),
        ]
        let may12 = try CampaignDateSectionBuilderTestSupport.makeDate("2026-05-12T00:00:00Z")
        let may11 = try CampaignDateSectionBuilderTestSupport.makeDate("2026-05-11T00:00:00Z")
        let may8 = try CampaignDateSectionBuilderTestSupport.makeDate("2026-05-08T00:00:00Z")

        // When
        let sections = CampaignDateSectionBuilder.sections(
            for: campaigns,
            statusFilter: nil,
            grouping: .day,
            calendar: calendar
        )

        // Then
        #expect(sections.map(\.id) == [may12, may11, may8])
        #expect(sections.map(\.title) == [.day(may12), .day(may11), .day(may8)])
        #expect(sections.map { $0.subgroups.map(\.id) } == [[may12], [may11], [may8]])
        #expect(sections.map { $0.subgroups.map(\.title) } == [[nil], [nil], [nil]])
        let names = sections.map {
            $0.subgroups.map {
                $0.campaigns.map(\.name)
            }
        }
        #expect(names == [[["今天晚團", "今天早團"]], [["昨天團"]], [["舊團"]]])
    }

    /// 驗證月分組時，頂層區段依年月分區，每個區段再依日切成子群組，區段與子群組都由新到舊
    ///
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test
    func sections_月分組_頂層為年月且子群組依日由新到舊() throws {
        // Given
        let calendar = try CampaignDateSectionBuilderTestSupport.makeCalendar(secondsFromGMT: 0)
        let campaigns = [
            Campaign.fixture(
                id: "ID-四月底團",
                name: "四月底團",
                openDate: Date(timeIntervalSince1970: 1_777_550_400)
            ),
            Campaign.fixture(
                id: "ID-五月初團",
                name: "五月初團",
                openDate: Date(timeIntervalSince1970: 1_778_230_800)
            ),
            Campaign.fixture(
                id: "ID-五月中團",
                name: "五月中團",
                openDate: Date(timeIntervalSince1970: 1_778_580_000)
            ),
            Campaign.fixture(
                id: "ID-五月中晚團",
                name: "五月中晚團",
                openDate: Date(timeIntervalSince1970: 1_778_616_000)
            ),
        ]
        let may = try CampaignDateSectionBuilderTestSupport.makeDate("2026-05-01T00:00:00Z")
        let april = try CampaignDateSectionBuilderTestSupport.makeDate("2026-04-01T00:00:00Z")
        let may12 = try CampaignDateSectionBuilderTestSupport.makeDate("2026-05-12T00:00:00Z")
        let may8 = try CampaignDateSectionBuilderTestSupport.makeDate("2026-05-08T00:00:00Z")
        let april30 = try CampaignDateSectionBuilderTestSupport.makeDate("2026-04-30T00:00:00Z")
        let expectedSubtitles: [[CampaignSectionTitle?]] = [
            [.day(may12), .day(may8)],
            [.day(april30)],
        ]

        // When
        let sections = CampaignDateSectionBuilder.sections(
            for: campaigns,
            statusFilter: nil,
            grouping: .month,
            calendar: calendar
        )

        // Then
        #expect(sections.map(\.id) == [may, april])
        #expect(sections.map(\.title) == [.yearMonth(may), .yearMonth(april)])
        #expect(sections.map { $0.subgroups.map(\.id) } == [[may12, may8], [april30]])
        #expect(sections.map { $0.subgroups.map(\.title) } == expectedSubtitles)
        let names = sections.map {
            $0.subgroups.map {
                $0.campaigns.map(\.name)
            }
        }
        #expect(names == [[["五月中晚團", "五月中團"], ["五月初團"]], [["四月底團"]]])
    }

    /// 驗證年分組時，頂層區段依年分區，同一個月的開團併入同一個月子群組，區段與子群組都由新到舊
    ///
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test
    func sections_年分組_頂層為年且同月併入單一月子群組() throws {
        // Given
        let calendar = try CampaignDateSectionBuilderTestSupport.makeCalendar(secondsFromGMT: 0)
        let campaigns = [
            Campaign.fixture(
                id: "ID-去年底團",
                name: "去年底團",
                openDate: Date(timeIntervalSince1970: 1_767_182_400)
            ),
            Campaign.fixture(
                id: "ID-三月團",
                name: "三月團",
                openDate: Date(timeIntervalSince1970: 1_772_452_800)
            ),
            Campaign.fixture(
                id: "ID-五月初團",
                name: "五月初團",
                openDate: Date(timeIntervalSince1970: 1_778_230_800)
            ),
            Campaign.fixture(
                id: "ID-五月中團",
                name: "五月中團",
                openDate: Date(timeIntervalSince1970: 1_778_580_000)
            ),
        ]
        let year2026 = try CampaignDateSectionBuilderTestSupport.makeDate("2026-01-01T00:00:00Z")
        let year2025 = try CampaignDateSectionBuilderTestSupport.makeDate("2025-01-01T00:00:00Z")
        let may = try CampaignDateSectionBuilderTestSupport.makeDate("2026-05-01T00:00:00Z")
        let march = try CampaignDateSectionBuilderTestSupport.makeDate("2026-03-01T00:00:00Z")
        let december = try CampaignDateSectionBuilderTestSupport.makeDate("2025-12-01T00:00:00Z")
        let expectedSubtitles: [[CampaignSectionTitle?]] = [
            [.month(may), .month(march)],
            [.month(december)],
        ]

        // When
        let sections = CampaignDateSectionBuilder.sections(
            for: campaigns,
            statusFilter: nil,
            grouping: .year,
            calendar: calendar
        )

        // Then
        #expect(sections.map(\.id) == [year2026, year2025])
        #expect(sections.map(\.title) == [.year(year2026), .year(year2025)])
        #expect(sections.map { $0.subgroups.map(\.id) } == [[may, march], [december]])
        #expect(sections.map { $0.subgroups.map(\.title) } == expectedSubtitles)
        let names = sections.map {
            $0.subgroups.map {
                $0.campaigns.map(\.name)
            }
        }
        #expect(names == [[["五月中團", "五月初團"], ["三月團"]], [["去年底團"]]])
    }

    /// 驗證沒有任何開團時，三種分組粒度都回傳空陣列，不產生區段
    ///
    /// - Parameter grouping: 頂層區段的分組粒度
    /// - Throws: 行事曆建立失敗時丟出錯誤
    @Test(arguments: CampaignGrouping.allCases)
    func sections_沒有開團_回傳空陣列(grouping: CampaignGrouping) throws {
        // Given
        let calendar = try CampaignDateSectionBuilderTestSupport.makeCalendar(secondsFromGMT: 0)

        // When
        let sections = CampaignDateSectionBuilder.sections(
            for: [],
            statusFilter: nil,
            grouping: grouping,
            calendar: calendar
        )

        // Then
        #expect(sections.isEmpty)
    }
}
