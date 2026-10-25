//
//  CampaignDateSectionBuilderOrderingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CampaignDateSectionBuilder` 的單元測試，涵蓋開團日期區段的狀態篩選、排序與時區分桶
struct CampaignDateSectionBuilderOrderingTests {

    /// 驗證篩選指定狀態時，區段只保留該狀態的開團，沒有符合的日子不產生區段
    ///
    /// - Parameter scenario: 篩選的開團狀態與預期保留的開團名稱，名稱依區段順序排列
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test(arguments: [
        StatusFilterCase(status: .ongoing, expectedNames: ["進行中甲", "進行中丙"]),
        StatusFilterCase(status: .closed, expectedNames: ["已結束乙"]),
    ])
    func sections_指定狀態_只保留該狀態開團(scenario: StatusFilterCase) throws {
        // Given
        let calendar = try CampaignDateSectionBuilderTestSupport.makeCalendar(secondsFromGMT: 0)
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
            statusFilter: scenario.status,
            grouping: .day,
            calendar: calendar
        )

        // Then
        let names = sections.flatMap { $0.subgroups.flatMap(\.campaigns) }.map(\.name)
        #expect(names == scenario.expectedNames)
        #expect(sections.count == scenario.expectedNames.count)
    }

    /// 驗證未指定狀態篩選時，進行中與已結束的開團都保留，並依開團時間由新到舊排列
    ///
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test
    func sections_未指定狀態_保留所有狀態的開團() throws {
        // Given
        let calendar = try CampaignDateSectionBuilderTestSupport.makeCalendar(secondsFromGMT: 0)
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

    /// 驗證開團時間完全相同時，三種分組粒度都併成一個區段，區段內依名稱遞增排序，數字依大小比較而非逐字元比較
    ///
    /// - Parameter grouping: 頂層區段的分組粒度
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test(arguments: CampaignGrouping.allCases)
    func sections_開團時間完全相同_依名稱遞增排序(grouping: CampaignGrouping) throws {
        // Given
        let calendar = try CampaignDateSectionBuilderTestSupport.makeCalendar(secondsFromGMT: 0)
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

    /// 驗證同一天不同時間的開團併成一個區段，且依時間由新到舊排序，不依名稱或加入順序
    ///
    /// - Parameter grouping: 頂層區段的分組粒度
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test(arguments: CampaignGrouping.allCases)
    func sections_同一天不同時間_依時間由新到舊排序(grouping: CampaignGrouping) throws {
        // Given
        let calendar = try CampaignDateSectionBuilderTestSupport.makeCalendar(secondsFromGMT: 0)
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

    /// 驗證同一時刻在不同時區下，日區段的起點取行事曆時區的午夜，UTC+8 已進入隔天
    ///
    /// - Parameter scenario: 行事曆與 UTC 的時差，以及預期的日區段起始時刻
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test(arguments: [
        TimeZoneBucketCase(secondsFromGMT: 0, expectedBucket: "2026-05-12T00:00:00Z"),
        TimeZoneBucketCase(secondsFromGMT: 28_800, expectedBucket: "2026-05-12T16:00:00Z"),
    ])
    func sections_同一時刻不同時區_日分桶依時區切換(scenario: TimeZoneBucketCase) throws {
        // Given
        let calendar = try CampaignDateSectionBuilderTestSupport.makeCalendar(
            secondsFromGMT: scenario.secondsFromGMT
        )
        let campaign = Campaign.fixture(
            id: "ID-跨日團",
            name: "跨日團",
            openDate: Date(timeIntervalSince1970: 1_778_616_000)
        )
        let bucket = try CampaignDateSectionBuilderTestSupport.makeDate(scenario.expectedBucket)

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

    /// 驗證同一時刻在不同時區下，月區段的起點取行事曆時區的月初午夜，UTC+8 已進入下個月
    ///
    /// - Parameter scenario: 行事曆與 UTC 的時差，以及預期的月區段起始時刻
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test(arguments: [
        TimeZoneBucketCase(secondsFromGMT: 0, expectedBucket: "2026-04-01T00:00:00Z"),
        TimeZoneBucketCase(secondsFromGMT: 28_800, expectedBucket: "2026-04-30T16:00:00Z"),
    ])
    func sections_同一時刻不同時區_月分桶依時區切換(scenario: TimeZoneBucketCase) throws {
        // Given
        let calendar = try CampaignDateSectionBuilderTestSupport.makeCalendar(
            secondsFromGMT: scenario.secondsFromGMT
        )
        let campaign = Campaign.fixture(
            id: "ID-月底團",
            name: "月底團",
            openDate: Date(timeIntervalSince1970: 1_777_579_200)
        )
        let bucket = try CampaignDateSectionBuilderTestSupport.makeDate(scenario.expectedBucket)

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

// MARK: - Nested Types

extension CampaignDateSectionBuilderOrderingTests {

    /// 狀態篩選測試的案例：篩選的開團狀態與預期保留的開團名稱
    struct StatusFilterCase: Sendable {

        /// 篩選的開團狀態
        let status: CampaignStatus

        /// 預期保留的開團名稱，依區段順序排列
        let expectedNames: [String]
    }

    /// 時區分桶測試的案例：行事曆與 UTC 的時差，以及預期的區段起始時刻
    struct TimeZoneBucketCase: Sendable {

        /// 行事曆與 UTC 相差的秒數
        let secondsFromGMT: Int

        /// 預期的區段起始時刻，以 ISO 8601 字串表示
        let expectedBucket: String
    }
}
