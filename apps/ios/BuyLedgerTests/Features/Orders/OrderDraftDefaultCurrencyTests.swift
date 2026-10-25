//
//  OrderDraftDefaultCurrencyTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import Testing

@testable import BuyLedger

/// `OrderDraft` 的單元測試，涵蓋預設幣別與既有幣別的保留
struct OrderDraftDefaultCurrencyTests {

    /// 驗證新訂單的草稿幣別沿用呼叫端傳入的預設日圓，日期取注入的現在時間
    @Test
    func init_新訂單預設日圓_使用日圓() {
        // Given
        let now = TestDependencies.fixedNow

        // When
        let draft = OrderDraft(original: nil, currentDate: now, defaultCurrency: .jpy)

        // Then
        #expect(draft.currency == .jpy)
        #expect(draft.date == TestDependencies.fixedNow)
    }

    /// 驗證編輯既有的韓圓訂單時，傳入的預設日圓不覆寫原幣別，草稿仍為韓圓
    @Test
    func init_既有韓圓訂單預設日圓_保留韓圓() {
        // Given
        let original = LedgerOrder.fixture(currency: .krw)

        // When
        let draft = OrderDraft(
            original: original,
            currentDate: TestDependencies.fixedNow,
            defaultCurrency: .jpy
        )

        // Then
        #expect(draft.currency == .krw)
    }
}
