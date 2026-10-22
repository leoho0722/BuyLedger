//
//  CampaignDateSectionBuilderTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證開團日期區段依分組粒度分桶與排序，並由格式化函式轉成畫面標題
struct CampaignDateSectionBuilderTests {

    /// 日分組時同一天的開團併成一個區段，區段由新到舊，且每個區段只有一個沒有標題的子群組
    ///
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test
    func sections_日分組_同日併入單一區段且依日期由新到舊() throws(any Error) {
        // Given
        let calendar = try Self.makeCalendar(secondsFromGMT: 0)
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
        let may12 = try Self.makeDate("2026-05-12T00:00:00Z")
        let may11 = try Self.makeDate("2026-05-11T00:00:00Z")
        let may8 = try Self.makeDate("2026-05-08T00:00:00Z")

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

    /// 月分組時頂層依年月分區，每個區段再依日切成子群組，區段與子群組都由新到舊
    ///
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test
    func sections_月分組_頂層為年月且子群組依日由新到舊() throws(any Error) {
        // Given
        let calendar = try Self.makeCalendar(secondsFromGMT: 0)
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
        let may = try Self.makeDate("2026-05-01T00:00:00Z")
        let april = try Self.makeDate("2026-04-01T00:00:00Z")
        let may12 = try Self.makeDate("2026-05-12T00:00:00Z")
        let may8 = try Self.makeDate("2026-05-08T00:00:00Z")
        let april30 = try Self.makeDate("2026-04-30T00:00:00Z")
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

    /// 年分組時頂層依年分區，同一個月的開團併入同一個月子群組，區段與子群組都由新到舊
    ///
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test
    func sections_年分組_頂層為年且同月併入單一月子群組() throws(any Error) {
        // Given
        let calendar = try Self.makeCalendar(secondsFromGMT: 0)
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
        let year2026 = try Self.makeDate("2026-01-01T00:00:00Z")
        let year2025 = try Self.makeDate("2025-01-01T00:00:00Z")
        let may = try Self.makeDate("2026-05-01T00:00:00Z")
        let march = try Self.makeDate("2026-03-01T00:00:00Z")
        let december = try Self.makeDate("2025-12-01T00:00:00Z")
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

    /// 沒有任何開團時不產生區段，三種分組粒度都一樣
    ///
    /// - Parameter grouping: 頂層區段的分組粒度
    /// - Throws: 行事曆建立失敗時丟出錯誤
    @Test(arguments: CampaignGrouping.allCases)
    func sections_沒有開團_回傳空陣列(grouping: CampaignGrouping) throws(any Error) {
        // Given
        let calendar = try Self.makeCalendar(secondsFromGMT: 0)

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

// MARK: - Internal Method

extension CampaignDateSectionBuilderTests {

    /// 建立以 UTC 為時區的現在時間與行事曆
    ///
    /// - Parameter now: 帶 `Z` 時區的 ISO 8601 現在時間
    /// - Returns: 現在時間與 UTC 西曆組成的日期脈絡
    /// - Throws: 時間字串格式不符時丟出解析錯誤
    static func makeContext(now: String) throws(any Error) -> CampaignDateContext {
        let currentDate = try makeDate(now)
        let calendar = try makeCalendar(secondsFromGMT: 0)
        return CampaignDateContext(now: currentDate, calendar: calendar)
    }

    /// 解析 ISO 8601 時間字串，讓測試輸入與預期值都以字面日期呈現
    ///
    /// - Parameter text: 帶 `Z` 時區的 ISO 8601 時間字串
    /// - Returns: 對應的時間點
    /// - Throws: 字串格式不符時丟出解析錯誤
    static func makeDate(_ text: String) throws(any Error) -> Date {
        try Date(text, strategy: .iso8601)
    }

    /// 建立固定與 UTC 時差的西曆
    ///
    /// - Parameter secondsFromGMT: 與 UTC 相差的秒數
    /// - Returns: 使用該時區的西曆
    /// - Throws: 該時差無法建立時區時由 `#require` 丟出測試斷言錯誤
    static func makeCalendar(secondsFromGMT: Int) throws(any Error) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: secondsFromGMT))
        return calendar
    }
}
