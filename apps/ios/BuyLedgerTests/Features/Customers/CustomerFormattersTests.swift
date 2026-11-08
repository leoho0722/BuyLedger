//
//  CustomerFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CustomerFormatters` 的單元測試，涵蓋客戶名單的名次文字、分級名稱與強調區塊標題
struct CustomerFormattersTests {

    /// 驗證名次為一時，名次膠囊的文字是井字號接名次數字
    @Test
    func rankLabel_名次為一_回傳井字號加名次() {
        // Given
        let rank = 1

        // When
        let label = CustomerFormatters.rankLabel(rank)

        // Then
        #expect(label == "#1")
    }

    /// 驗證強調區塊標題在英文與正體中文下都固定顯示「Top 3」，不隨語言改為中文
    ///
    /// - Parameter language: 顯示語言
    @Test(arguments: [AppLanguage.english, .traditionalChinese])
    func topCountLabel_英文或正體中文_顯示前三名(language: AppLanguage) {
        // Given

        // When
        let label = CustomerFormatters.topCountLabel()

        // Then
        #expect(label.key == "customers.list.label.topCount")
        #expect(language.resolve(label) == "Top 3")
    }

    /// 驗證三種分級在英文與正體中文下的完整名稱，貴賓固定原樣顯示 VIP
    ///
    /// - Parameter scenario: 分級、語言與字面值預期
    @Test(arguments: [
        TierTitleScenario(tier: .new, language: .english, expectedText: "New"),
        TierTitleScenario(tier: .new, language: .traditionalChinese, expectedText: "新客"),
        TierTitleScenario(tier: .regular, language: .english, expectedText: "Returning"),
        TierTitleScenario(tier: .regular, language: .traditionalChinese, expectedText: "常客"),
        TierTitleScenario(tier: .vip, language: .english, expectedText: "VIP"),
        TierTitleScenario(tier: .vip, language: .traditionalChinese, expectedText: "VIP"),
    ])
    func tierTitle_新客常客貴賓搭配英文與正體中文_回傳完整分級名稱(scenario: TierTitleScenario) {
        // Given
        let locale = scenario.language.locale

        // When
        let title = CustomerFormatters.tierTitle(scenario.tier, locale: locale)

        // Then
        #expect(title == scenario.expectedText)
    }
}

// MARK: - Nested Types

extension CustomerFormattersTests {

    /// 分級名稱的測試案例
    struct TierTitleScenario: Sendable {

        /// 要顯示的客戶分級
        let tier: CustomerTier

        /// 解析分級名稱的 App 語言
        let language: AppLanguage

        /// 指定語言下的完整預期文字
        let expectedText: String
    }
}
