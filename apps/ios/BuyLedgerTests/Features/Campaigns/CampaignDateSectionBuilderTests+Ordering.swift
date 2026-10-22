//
//  CampaignDateSectionBuilderTests+Ordering.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation
import Testing

@testable import BuyLedger

extension CampaignDateSectionBuilderTests {

    /// 指定狀態時只保留該狀態的開團，沒有符合的日子不產生區段
    ///
    /// - Parameters:
    ///   - status: 篩選的開團狀態
    ///   - expectedNames: 預期保留的開團名稱，依區段順序排列
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test(arguments: [
        (CampaignStatus.ongoing, ["進行中甲", "進行中丙"]),
        (CampaignStatus.closed, ["已結束乙"]),
    ])
    func sections_指定狀態_只保留該狀態開團(status: CampaignStatus, expectedNames: [String]) throws(any Error) {
        // Given
        let calendar = try Self.makeCalendar(secondsFromGMT: 0)
        let campaigns = [
            Campaign.fixture(
                id: "ID-進行中甲",
                name: "進行中甲",
                openDate: Date(timeIntervalSince1970: 1_778_576_400)
            ),
            Campaign.fixture(
                id: "ID-已結束乙",
                name: "已結束乙",
                openDate: Date(timeIntervalSince1970: 1_778_490_000),
                status: .closed
            ),
            Campaign.fixture(
                id: "ID-進行中丙",
                name: "進行中丙",
                openDate: Date(timeIntervalSince1970: 1_778_230_800)
            ),
        ]

        // When
        let sections = CampaignDateSectionBuilder.sections(
            for: campaigns,
            statusFilter: status,
            grouping: .day,
            calendar: calendar
        )

        // Then
        let names = sections.flatMap { $0.subgroups.flatMap(\.campaigns) }.map(\.name)
        #expect(names == expectedNames)
        #expect(sections.count == expectedNames.count)
    }

    /// 不指定狀態時進行中與已結束的開團都保留
    ///
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test
    func sections_未指定狀態_保留所有狀態的開團() throws(any Error) {
        // Given
        let calendar = try Self.makeCalendar(secondsFromGMT: 0)
        let campaigns = [
            Campaign.fixture(
                id: "ID-進行中甲",
                name: "進行中甲",
                openDate: Date(timeIntervalSince1970: 1_778_576_400)
            ),
            Campaign.fixture(
                id: "ID-已結束乙",
                name: "已結束乙",
                openDate: Date(timeIntervalSince1970: 1_778_490_000),
                status: .closed
            ),
        ]

        // When
        let sections = CampaignDateSectionBuilder.sections(
            for: campaigns,
            statusFilter: nil,
            grouping: .day,
            calendar: calendar
        )

        // Then
        let names = sections.flatMap { $0.subgroups.flatMap(\.campaigns) }.map(\.name)
        #expect(names == ["進行中甲", "已結束乙"])
    }

    /// 開團時間完全相同時依名稱遞增排序，數字依大小比較而不是逐字元比較
    ///
    /// - Parameter grouping: 頂層區段的分組粒度
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test(arguments: CampaignGrouping.allCases)
    func sections_開團時間完全相同_依名稱遞增排序(grouping: CampaignGrouping) throws(any Error) {
        // Given
        let calendar = try Self.makeCalendar(secondsFromGMT: 0)
        let campaigns = [
            Campaign.fixture(
                id: "ID-Batch 2",
                name: "Batch 2",
                openDate: Date(timeIntervalSince1970: 1_778_580_000)
            ),
            Campaign.fixture(
                id: "ID-Batch 10",
                name: "Batch 10",
                openDate: Date(timeIntervalSince1970: 1_778_580_000)
            ),
            Campaign.fixture(
                id: "ID-Batch 1",
                name: "Batch 1",
                openDate: Date(timeIntervalSince1970: 1_778_580_000)
            ),
        ]

        // When
        let sections = CampaignDateSectionBuilder.sections(
            for: campaigns,
            statusFilter: nil,
            grouping: grouping,
            calendar: calendar
        )

        // Then
        let names = sections.flatMap { $0.subgroups.flatMap(\.campaigns) }.map(\.name)
        #expect(sections.count == 1)
        #expect(names == ["Batch 1", "Batch 2", "Batch 10"])
    }

    /// 同一天不同時間的開團依時間由新到舊排序，不被名稱順序影響
    ///
    /// - Parameter grouping: 頂層區段的分組粒度
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test(arguments: CampaignGrouping.allCases)
    func sections_同一天不同時間_依時間由新到舊排序(grouping: CampaignGrouping) throws(any Error) {
        // Given
        let calendar = try Self.makeCalendar(secondsFromGMT: 0)
        let campaigns = [
            Campaign.fixture(
                id: "ID-A團",
                name: "A團",
                openDate: Date(timeIntervalSince1970: 1_778_572_800)
            ),
            Campaign.fixture(
                id: "ID-B團",
                name: "B團",
                openDate: Date(timeIntervalSince1970: 1_778_616_000)
            ),
            Campaign.fixture(
                id: "ID-C團",
                name: "C團",
                openDate: Date(timeIntervalSince1970: 1_778_587_200)
            ),
        ]

        // When
        let sections = CampaignDateSectionBuilder.sections(
            for: campaigns,
            statusFilter: nil,
            grouping: grouping,
            calendar: calendar
        )

        // Then
        let names = sections.flatMap { $0.subgroups.flatMap(\.campaigns) }.map(\.name)
        #expect(sections.count == 1)
        #expect(names == ["B團", "C團", "A團"])
    }

    /// 同一時刻在不同時區的日分桶不同，UTC+8 已進入隔天
    ///
    /// - Parameters:
    ///   - secondsFromGMT: 行事曆與 UTC 相差的秒數
    ///   - expectedBucket: 預期的日區段起始時刻
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test(arguments: [(0, "2026-05-12T00:00:00Z"), (28_800, "2026-05-12T16:00:00Z")])
    func sections_同一時刻不同時區_日分桶依時區切換(secondsFromGMT: Int, expectedBucket: String) throws(any Error) {
        // Given
        let calendar = try Self.makeCalendar(secondsFromGMT: secondsFromGMT)
        let campaign = Campaign.fixture(
            id: "ID-跨日團",
            name: "跨日團",
            openDate: Date(timeIntervalSince1970: 1_778_616_000)
        )
        let bucket = try Self.makeDate(expectedBucket)

        // When
        let sections = CampaignDateSectionBuilder.sections(
            for: [campaign],
            statusFilter: nil,
            grouping: .day,
            calendar: calendar
        )

        // Then
        #expect(sections.map(\.id) == [bucket])
        #expect(sections.map(\.title) == [.day(bucket)])
    }

    /// 同一時刻在不同時區的月分桶不同，UTC+8 已進入下個月
    ///
    /// - Parameters:
    ///   - secondsFromGMT: 行事曆與 UTC 相差的秒數
    ///   - expectedBucket: 預期的月區段起始時刻
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test(arguments: [(0, "2026-04-01T00:00:00Z"), (28_800, "2026-04-30T16:00:00Z")])
    func sections_同一時刻不同時區_月分桶依時區切換(secondsFromGMT: Int, expectedBucket: String) throws(any Error) {
        // Given
        let calendar = try Self.makeCalendar(secondsFromGMT: secondsFromGMT)
        let campaign = Campaign.fixture(
            id: "ID-月底團",
            name: "月底團",
            openDate: Date(timeIntervalSince1970: 1_777_579_200)
        )
        let bucket = try Self.makeDate(expectedBucket)

        // When
        let sections = CampaignDateSectionBuilder.sections(
            for: [campaign],
            statusFilter: nil,
            grouping: .month,
            calendar: calendar
        )

        // Then
        #expect(sections.map(\.id) == [bucket])
        #expect(sections.map(\.title) == [.yearMonth(bucket)])
    }
}
