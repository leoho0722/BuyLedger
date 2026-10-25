//
//  CustomerFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CustomerFormatters` 的單元測試，涵蓋客戶名單的名次文字與強調區塊標題
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
        let locale = language.locale

        // When
        let label = CustomerFormatters.topCountLabel(locale: locale)

        // Then
        #expect(label == "Top 3")
    }
}
