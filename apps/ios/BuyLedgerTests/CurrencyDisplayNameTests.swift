//
//  CurrencyDisplayNameTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/19.
//

import Foundation
import Testing
@testable import BuyLedger

/// 驗證 ``CurrencyDisplayName`` 的幣別名稱與搜尋關鍵字
struct CurrencyDisplayNameTests {

    // MARK: - Tests

    /// 正體中文顯示已知幣別時回傳本地化名稱
    @Test func textUsesLocalizedNameInTraditionalChinese() {
        // Given
        let code = "TWD"

        // When
        let text = CurrencyDisplayName.text(code: code, language: .traditionalChinese)

        // Then
        #expect(
            text == "新台幣"
        )
    }

    /// 英文顯示已知幣別時回傳 ISO 代碼
    @Test func textUsesCodeInEnglish() {
        // Given
        let code = "TWD"

        // When
        let text = CurrencyDisplayName.text(code: code, language: .english)

        // Then
        #expect(
            text == "TWD"
        )
    }

    /// 顯示未知幣別時回傳原始 ISO 代碼
    @Test func textFallsBackToCodeForUnknownCurrency() {
        // Given
        let code = "ZZZ"

        // When
        let text = CurrencyDisplayName.text(code: code, language: .traditionalChinese)

        // Then
        #expect(
            text == "ZZZ"
        )
    }

    /// 正體中文搜尋時回傳目前 locale 的本地化名稱
    @Test func searchKeywordsUsesTraditionalChineseLocaleName() {
        // Given
        let code = "TWD"
        let locale = Locale(identifier: "zh-Hant-TW")

        // When
        let keywords = CurrencyDisplayName.searchKeywords(code: code, locale: locale)

        // Then
        #expect(
            keywords == "新台幣"
        )
    }

    /// 英文搜尋時回傳目前 locale 的本地化名稱
    @Test func searchKeywordsUsesEnglishLocaleName() {
        // Given
        let code = "TWD"
        let locale = Locale(identifier: "en")

        // When
        let keywords = CurrencyDisplayName.searchKeywords(code: code, locale: locale)

        // Then
        #expect(
            keywords == "New Taiwan Dollar"
        )
    }

    /// 搜尋未知幣別時回傳空字串
    @Test func searchKeywordsReturnsEmptyForUnknownCurrency() {
        // Given
        let code = "ZZZ"
        let locale = Locale(identifier: "en")

        // When
        let keywords = CurrencyDisplayName.searchKeywords(code: code, locale: locale)

        // Then
        #expect(
            keywords.isEmpty
        )
    }
}
