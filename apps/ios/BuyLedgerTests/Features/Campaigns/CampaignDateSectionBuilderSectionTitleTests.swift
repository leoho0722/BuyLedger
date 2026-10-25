//
//  CampaignDateSectionBuilderSectionTitleTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CampaignFormatters` 的單元測試，涵蓋開團日期區段標題的文字格式化與多語系顯示
struct CampaignDateSectionBuilderSectionTitleTests {

    /// 驗證日標題以 2026-05-12 為現在時：同一天為「今天」、前一天為「昨天」，同年其他日顯示月日與星期，跨年顯示年月日
    ///
    /// - Parameter scenario: 日標題所屬的日期與預期的標題文字，日期取當日中午避開時區換日
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test(arguments: [
        DayTitleCase(day: "2026-05-12T12:00:00Z", expectedTitle: "今天"),
        DayTitleCase(day: "2026-05-11T12:00:00Z", expectedTitle: "昨天"),
        DayTitleCase(day: "2026-05-08T12:00:00Z", expectedTitle: "5月8日週五"),
        DayTitleCase(day: "2025-12-31T12:00:00Z", expectedTitle: "2025年12月31日"),
    ])
    func sectionTitle_日標題相對現在不同_依相對日或日期格式化(scenario: DayTitleCase) throws {
        // Given
        let context = try CampaignDateSectionBuilderTestSupport.makeContext(
            now: "2026-05-12T10:00:00Z"
        )
        let date = try CampaignDateSectionBuilderTestSupport.makeDate(scenario.day)
        let title = CampaignSectionTitle.day(date)

        // When
        let text = CampaignFormatters.sectionTitle(
            title,
            context: context,
            locale: Locale(identifier: "zh-Hant")
        )

        // Then
        #expect(text == scenario.expectedTitle)
    }

    /// 驗證年月標題在正體中文下，以四位數年份接月份呈現
    ///
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test
    func sectionTitle_年月標題_顯示年與月() throws {
        // Given
        let context = try CampaignDateSectionBuilderTestSupport.makeContext(
            now: "2026-05-12T10:00:00Z"
        )
        let date = try CampaignDateSectionBuilderTestSupport.makeDate("2026-05-15T12:00:00Z")
        let title = CampaignSectionTitle.yearMonth(date)

        // When
        let text = CampaignFormatters.sectionTitle(
            title,
            context: context,
            locale: Locale(identifier: "zh-Hant")
        )

        // Then
        #expect(text == "2026年5月")
    }

    /// 驗證年標題在正體中文下，只呈現四位數年份與年字
    ///
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test
    func sectionTitle_年標題_只顯示年() throws {
        // Given
        let context = try CampaignDateSectionBuilderTestSupport.makeContext(
            now: "2026-05-12T10:00:00Z"
        )
        let date = try CampaignDateSectionBuilderTestSupport.makeDate("2026-07-01T12:00:00Z")
        let title = CampaignSectionTitle.year(date)

        // When
        let text = CampaignFormatters.sectionTitle(
            title,
            context: context,
            locale: Locale(identifier: "zh-Hant")
        )

        // Then
        #expect(text == "2026年")
    }

    /// 驗證月標題依傳入的語系顯示完整月份，正體中文使用數字，英文使用完整月份名稱
    ///
    /// - Parameter scenario: 呈現用語系的識別字串與預期的標題文字
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test(arguments: [
        MonthTitleCase(localeIdentifier: "zh-Hant", expectedTitle: "5月"),
        MonthTitleCase(localeIdentifier: "en", expectedTitle: "May"),
    ])
    func sectionTitle_月標題_依語系顯示完整月份(scenario: MonthTitleCase) throws {
        // Given
        let context = try CampaignDateSectionBuilderTestSupport.makeContext(
            now: "2026-05-12T10:00:00Z"
        )
        let date = try CampaignDateSectionBuilderTestSupport.makeDate("2026-05-15T12:00:00Z")
        let title = CampaignSectionTitle.month(date)

        // When
        let text = CampaignFormatters.sectionTitle(
            title,
            context: context,
            locale: Locale(identifier: scenario.localeIdentifier)
        )

        // Then
        #expect(text == scenario.expectedTitle)
    }

    /// 驗證現在為 2026-05-12 10:00 (UTC) 時，三筆日分組開團的標題依序為今天、昨天與同年的月日加星期
    ///
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test
    func sectionTitle_規格範例的三筆日分組開團_標題依序為今天昨天與月日星期() throws {
        // Given
        let context = try CampaignDateSectionBuilderTestSupport.makeContext(
            now: "2026-05-12T10:00:00Z"
        )
        let campaigns = [
            Campaign.fixture(
                id: "ID-五月十二日團",
                name: "五月十二日團",
                openDate: Date(timeIntervalSince1970: 1_778_576_400)
            ),
            Campaign.fixture(
                id: "ID-五月十一日團",
                name: "五月十一日團",
                openDate: Date(timeIntervalSince1970: 1_778_490_000)
            ),
            Campaign.fixture(
                id: "ID-五月八日團",
                name: "五月八日團",
                openDate: Date(timeIntervalSince1970: 1_778_230_800)
            ),
        ]
        let locale = Locale(identifier: "zh-Hant")

        let sections = CampaignDateSectionBuilder.sections(
            for: campaigns,
            statusFilter: nil,
            grouping: .day,
            calendar: context.calendar
        )

        // When
        let titles = sections.map {
            CampaignFormatters.sectionTitle($0.title, context: context, locale: locale)
        }

        // Then
        #expect(titles == ["今天", "昨天", "5月8日週五"])
    }
}

// MARK: - Nested Types

extension CampaignDateSectionBuilderSectionTitleTests {

    /// 日標題測試的案例：日標題所屬的日期字串與預期的標題文字
    struct DayTitleCase: Sendable {

        /// 日標題所屬的日期字串，取當日中午避開時區換日
        let day: String

        /// 預期的標題文字
        let expectedTitle: String
    }

    /// 月標題測試的案例：呈現用 locale 的識別字串與預期的標題文字
    struct MonthTitleCase: Sendable {

        /// 呈現用 locale 的識別字串
        let localeIdentifier: String

        /// 預期的標題文字
        let expectedTitle: String
    }
}
