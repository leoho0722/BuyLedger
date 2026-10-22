//
//  SidebarBadgeCountsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Testing

@testable import BuyLedger

/// 側邊欄徽章朗讀值的數量與本地化
struct SidebarBadgeCountsTests {

    /// 沒有徽章或數量非正數時不朗讀筆數
    ///
    /// - Parameter count: 不應顯示的徽章數量
    @Test(arguments: [nil as Int?, 0, -1])
    func accessibilityValue_數量非正數或缺值_回傳空字串(count: Int?) {
        // Given
        let language = AppLanguage.traditionalChinese

        // When
        let value = SidebarBadgeCounts.accessibilityValue(count, language: language)

        // Then
        #expect(value == "")
    }

    /// 正數徽章使用既有的筆數本地化文案
    ///
    /// - Parameters:
    ///   - count: 徽章數量
    ///   - language: 顯示語言
    ///   - expectedValue: 原有的朗讀文字
    @Test(arguments: [
        (1, AppLanguage.traditionalChinese, "1 件進行中"),
        (12, .traditionalChinese, "12 件進行中"),
        (1, .english, "1 in progress"),
        (12, .english, "12 in progress"),
    ])
    func accessibilityValue_正數徽章_保留筆數與本地化文案(
        count: Int,
        language: AppLanguage,
        expectedValue: String
    ) {
        // Given
        let badgeCount: Int? = count

        // When
        let value = SidebarBadgeCounts.accessibilityValue(badgeCount, language: language)

        // Then
        #expect(value == expectedValue)
    }
}
