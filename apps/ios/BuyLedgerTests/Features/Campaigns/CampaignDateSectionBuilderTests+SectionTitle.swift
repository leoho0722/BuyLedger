//
//  CampaignDateSectionBuilderTests+SectionTitle.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation
import Testing

@testable import BuyLedger

extension CampaignDateSectionBuilderTests {

    /// 日標題與現在同一天為「今天」、前一天為「昨天」，同年其他日顯示月日星期，跨年顯示年月日
    ///
    /// - Parameters:
    ///   - day: 日標題所屬的日期，取當日中午避開時區換日
    ///   - expectedTitle: 預期的標題文字
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test(arguments: [
        ("2026-05-12T12:00:00Z", "今天"),
        ("2026-05-11T12:00:00Z", "昨天"),
        ("2026-05-08T12:00:00Z", "5月8日週五"),
        ("2025-12-31T12:00:00Z", "2025年12月31日"),
    ])
    func sectionTitle_日標題相對現在不同_依相對日或日期格式化(day: String, expectedTitle: String) throws(any Error) {
        // Given
        let context = try Self.makeContext(now: "2026-05-12T10:00:00Z")
        let date = try Self.makeDate(day)
        let title = CampaignSectionTitle.day(date)

        // When
        let text = CampaignFormatters.sectionTitle(
            title,
            context: context,
            locale: Locale(identifier: "zh-Hant")
        )

        // Then
        #expect(text == expectedTitle)
    }

    /// 年月標題在正體中文顯示年與月
    ///
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test
    func sectionTitle_年月標題_顯示年與月() throws(any Error) {
        // Given
        let context = try Self.makeContext(now: "2026-05-12T10:00:00Z")
        let date = try Self.makeDate("2026-05-15T12:00:00Z")
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

    /// 年標題在正體中文只顯示年
    ///
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test
    func sectionTitle_年標題_只顯示年() throws(any Error) {
        // Given
        let context = try Self.makeContext(now: "2026-05-12T10:00:00Z")
        let date = try Self.makeDate("2026-07-01T12:00:00Z")
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

    /// 月標題依選定的 locale 顯示完整月份
    ///
    /// - Parameters:
    ///   - localeIdentifier: 呈現用 locale 的識別字串
    ///   - expectedTitle: 預期的標題文字
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test(arguments: [("zh-Hant", "5月"), ("en", "May")])
    func sectionTitle_月標題_依locale顯示完整月份(
        localeIdentifier: String,
        expectedTitle: String
    ) throws(any Error) {
        // Given
        let context = try Self.makeContext(now: "2026-05-12T10:00:00Z")
        let date = try Self.makeDate("2026-05-15T12:00:00Z")
        let title = CampaignSectionTitle.month(date)

        // When
        let text = CampaignFormatters.sectionTitle(
            title,
            context: context,
            locale: Locale(identifier: localeIdentifier)
        )

        // Then
        #expect(text == expectedTitle)
    }

    /// 規格範例：記錄日期為 2026-05-12 10:00 (UTC) 時，三筆開團的日區段標題依序為今天、昨天與月日星期
    ///
    /// - Throws: 測試日期解析或行事曆建立失敗時丟出錯誤
    @Test
    func sectionTitle_規格範例的三筆日分組開團_標題依序為今天昨天與月日星期() throws(any Error) {
        // Given
        let context = try Self.makeContext(now: "2026-05-12T10:00:00Z")
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
