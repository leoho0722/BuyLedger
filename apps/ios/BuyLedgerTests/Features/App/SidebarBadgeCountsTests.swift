//
//  SidebarBadgeCountsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Testing

@testable import BuyLedger

/// `SidebarBadgeCounts` 的單元測試，涵蓋側邊欄徽章朗讀值的筆數與本地化
struct SidebarBadgeCountsTests {

    /// 驗證徽章數量缺值、為零或為負數時，朗讀值回傳空字串，不朗讀筆數
    ///
    /// - Parameter count: 缺值或非正數的徽章數量
    @Test(arguments: [nil as Int?, 0, -1])
    func accessibilityValue_數量非正數或缺值_回傳空字串(count: Int?) {
        // Given
        let language = AppLanguage.traditionalChinese

        // When
        let value = SidebarBadgeCounts.accessibilityValue(count, language: language)

        // Then
        #expect(value == "")
    }

    /// 驗證正數徽章的朗讀值沿用既有的筆數文案，單筆與多筆、正體中文與英文都保留數字
    ///
    /// - Parameter scenario: 徽章數量、顯示語言與原有的朗讀文字
    @Test(arguments: BadgeValueCase.allCases)
    func accessibilityValue_正數徽章_保留筆數與本地化文案(scenario: BadgeValueCase) {
        // Given
        let badgeCount: Int? = scenario.count

        // When
        let value = SidebarBadgeCounts.accessibilityValue(badgeCount, language: scenario.language)

        // Then
        #expect(value == scenario.expectedValue)
    }
}

// MARK: - Nested Types

extension SidebarBadgeCountsTests {

    /// 一組徽章測試案例，含徽章數量、顯示語言與預期的朗讀文字
    struct BadgeValueCase: Sendable {

        /// 正體中文與英文各一筆與多筆的朗讀文字
        static let allCases = [
            Self(count: 1, language: .traditionalChinese, expectedValue: "1 件進行中"),
            Self(count: 12, language: .traditionalChinese, expectedValue: "12 件進行中"),
            Self(count: 1, language: .english, expectedValue: "1 in progress"),
            Self(count: 12, language: .english, expectedValue: "12 in progress"),
        ]

        /// 徽章數量
        let count: Int

        /// 顯示語言
        let language: AppLanguage

        /// 原有的朗讀文字
        let expectedValue: String
    }
}
