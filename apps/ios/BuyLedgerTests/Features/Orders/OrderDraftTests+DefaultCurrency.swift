//
//  OrderDraftTests+DefaultCurrency.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import Testing

@testable import BuyLedger

extension OrderDraftTests {

    /// 新訂單草稿使用呼叫端指定的預設幣別
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

    /// 編輯既有訂單時，傳入的預設幣別不覆寫原韓圓
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
