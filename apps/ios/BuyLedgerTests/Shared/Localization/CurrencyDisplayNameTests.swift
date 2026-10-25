//
//  CurrencyDisplayNameTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/19.
//

import Foundation
import Testing

@testable import BuyLedger

/// ``CurrencyDisplayName`` 的單元測試，涵蓋幣別名稱與搜尋關鍵字
struct CurrencyDisplayNameTests {

    /// 驗證正體中文顯示已知幣別時，回傳本地化名稱，例如 TWD 顯示為「新台幣」
    @Test
    func text_正體中文_回傳本地化名稱() {
        // Given
        let code = "TWD"

        // When
        let text = CurrencyDisplayName.text(code: code, language: .traditionalChinese)

        // Then
        #expect(text == "新台幣")
    }

    /// 驗證英文顯示已知幣別時回傳 ISO 代碼
    @Test
    func text_英文_回傳ISO代碼() {
        // Given
        let code = "TWD"

        // When
        let text = CurrencyDisplayName.text(code: code, language: .english)

        // Then
        #expect(text == "TWD")
    }

    /// 驗證顯示未知幣別 (如 ZZZ) 時，原樣回傳該代碼
    @Test
    func text_未知幣別_回傳原始ISO代碼() {
        // Given
        let code = "ZZZ"

        // When
        let text = CurrencyDisplayName.text(code: code, language: .traditionalChinese)

        // Then
        #expect(text == "ZZZ")
    }

    /// 驗證 `zh-Hant-TW` 地區搜尋 TWD 時，回傳本地化名稱「新台幣」
    @Test
    func searchKeywords_正體中文地區_回傳本地化名稱() {
        // Given
        let code = "TWD"
        let locale = Locale(identifier: "zh-Hant-TW")

        // When
        let keywords = CurrencyDisplayName.searchKeywords(code: code, locale: locale)

        // Then
        #expect(keywords == "新台幣")
    }

    /// 驗證 `en` 地區搜尋 TWD 時，回傳英文名稱 New Taiwan Dollar
    @Test
    func searchKeywords_英文地區_回傳本地化名稱() {
        // Given
        let code = "TWD"
        let locale = Locale(identifier: "en")

        // When
        let keywords = CurrencyDisplayName.searchKeywords(code: code, locale: locale)

        // Then
        #expect(keywords == "New Taiwan Dollar")
    }

    /// 驗證搜尋未知幣別 (如 ZZZ) 時回傳空字串
    @Test
    func searchKeywords_未知幣別_回傳空字串() {
        // Given
        let code = "ZZZ"
        let locale = Locale(identifier: "en")

        // When
        let keywords = CurrencyDisplayName.searchKeywords(code: code, locale: locale)

        // Then
        #expect(keywords.isEmpty)
    }
}
