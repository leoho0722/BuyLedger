//
//  LocalizationCatalogTests+AppLanguage.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

@testable import BuyLedger

extension LocalizationCatalogTests {

    /// 根分頁標題依所選 App 語言解析為對應的英文或正體中文
    @Test
    func localized_根導覽標題_依所選語言解析() {
        // Given
        let titles: [String.LocalizationValue] = ["總覽", "訂單", "開團", "分析", "更多"]

        // When
        let englishTitles = titles.map { AppLanguage.english.localized($0) }
        let chineseTitles = titles.map { AppLanguage.traditionalChinese.localized($0) }

        // Then
        #expect(englishTitles == ["Overview", "Orders", "Campaigns", "Insights", "More"])
        #expect(chineseTitles == ["總覽", "訂單", "開團", "分析", "更多"])
    }

    /// 圖表的本地化軸標題與資料序列名稱依所選 App 語言解析
    @Test
    func localized_圖表描述字串_依所選語言解析() {
        // Given
        let ordinal = 3
        let titles: [String.LocalizationValue] = [
            "項目",
            "數值",
            "順序",
            "類別",
            "占比",
            "長條圖",
            "圈狀圖",
            "走勢圖",
            "第 \(ordinal) 筆",
        ]

        // When
        let englishTitles = titles.map { AppLanguage.english.localized($0) }
        let chineseTitles = titles.map { AppLanguage.traditionalChinese.localized($0) }

        // Then
        #expect(
            englishTitles == [
                "Item",
                "Value",
                "Sequence",
                "Category",
                "Share",
                "Bar Chart",
                "Donut Chart",
                "Trend Chart",
                "Point 3",
            ]
        )
        #expect(
            chineseTitles == [
                "項目",
                "數值",
                "順序",
                "類別",
                "占比",
                "長條圖",
                "圈狀圖",
                "走勢圖",
                "第 3 筆",
            ]
        )
    }

    /// 訂單頁導覽標題依選取狀態變化，並依所選 App 語言解析
    ///
    /// - Parameter example: 選取狀態與預期的中英文標題
    @Test(arguments: OrdersNavigationTitleExample.examples)
    func navigationTitleKey_各選取狀態_依所選語言解析(example: OrdersNavigationTitleExample) {
        // Given
        var state = OrderListFeatureTests.makeState()
        state.isSelecting = example.isSelecting
        state.selectedOrderIDs = example.selectedOrderIDs

        // When
        let englishTitle = AppLanguage.english.localized(state.navigationTitleKey)
        let chineseTitle = AppLanguage.traditionalChinese.localized(state.navigationTitleKey)

        // Then
        #expect(englishTitle == example.expectedEnglishTitle)
        #expect(chineseTitle == example.expectedChineseTitle)
    }

    /// 英文語系的 7 月 18 日規格範例不含中文日期文字
    ///
    /// - Throws: 測試日期建立失敗時丟出錯誤
    @Test
    func daySectionTitle_英文語系的七月十八日_標題不含中文日期文字() throws(any Error) {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let reportedDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 7,
                    day: 18,
                    hour: 12
                )
            )
        )
        let referenceDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 7,
                    day: 20,
                    hour: 12
                )
            )
        )

        // When
        let title = OrderFormatters.daySectionTitle(
            for: reportedDate,
            referenceDate: referenceDate,
            calendar: calendar,
            locale: Locale(identifier: "en")
        )

        // Then
        #expect(title.contains("July"))
        #expect(title.range(of: "[\\u{3400}-\\u{9FFF}]", options: .regularExpression) == nil)
    }
}

// MARK: - Nested Types

extension LocalizationCatalogTests {

    /// 訂單頁導覽標題在各選取狀態下的預期中英文標題
    struct OrdersNavigationTitleExample: Sendable {

        /// 預設、選取模式與已選兩筆三種狀態
        static let examples = [
            Self(
                isSelecting: false,
                selectedOrderIDs: [],
                expectedEnglishTitle: "Orders",
                expectedChineseTitle: "訂單"
            ),
            Self(
                isSelecting: true,
                selectedOrderIDs: [],
                expectedEnglishTitle: "Select Orders",
                expectedChineseTitle: "選擇訂單"
            ),
            Self(
                isSelecting: true,
                selectedOrderIDs: ["O1", "O2"],
                expectedEnglishTitle: "2 Selected",
                expectedChineseTitle: "已選 2 筆"
            ),
        ]

        /// 是否處於選取模式
        let isSelecting: Bool

        /// 已選取的訂單識別碼
        let selectedOrderIDs: Set<LedgerOrder.ID>

        /// 預期的英文標題
        let expectedEnglishTitle: String

        /// 預期的正體中文標題
        let expectedChineseTitle: String
    }
}
