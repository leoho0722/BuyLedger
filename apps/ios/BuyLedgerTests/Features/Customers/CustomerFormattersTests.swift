//
//  CustomerFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證客戶名單的名次與強調區塊標題文字
struct CustomerFormattersTests {

    /// 驗證名次膠囊以井字號接名次數字
    @Test
    func rankLabel_名次為一_回傳井字號加名次() {
        // Given
        let rank = 1

        // When
        let label = CustomerFormatters.rankLabel(rank)

        // Then
        #expect(label == "#1")
    }

    /// 驗證強調區塊標題在英文與正體中文都顯示前三名
    @Test
    func topCountLabel_英文與正體中文_皆顯示前三名() {
        // Given
        let english = AppLanguage.english.locale
        let traditionalChinese = AppLanguage.traditionalChinese.locale

        // When
        let englishLabel = CustomerFormatters.topCountLabel(locale: english)
        let chineseLabel = CustomerFormatters.topCountLabel(locale: traditionalChinese)

        // Then
        #expect(englishLabel == "Top 3")
        #expect(chineseLabel == "Top 3")
    }
}
