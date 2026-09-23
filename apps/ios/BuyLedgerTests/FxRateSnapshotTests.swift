//
//  FxRateSnapshotTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/22.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證匯率快照轉換成新台幣匯率的規則
struct FxRateSnapshotTests {

    // MARK: - Tests

    /// 驗證查詢新台幣時固定回傳一
    @Test func twdRateReturnsOneForTwd() {
        // Given
        let snapshot = FxRateSnapshot(
            date: Date(timeIntervalSince1970: 0),
            base: .usd,
            rates: [.twd: 32]
        )

        // When
        let rate = snapshot.twdRate(for: .twd)

        // Then
        #expect(rate == 1)
    }

    /// 驗證新台幣為基準時回傳指定幣別匯率的倒數
    @Test func twdRateReturnsInverseForTwdBase() {
        // Given
        let snapshot = FxRateSnapshot(
            date: Date(timeIntervalSince1970: 0),
            base: .twd,
            rates: [.usd: 0.125]
        )

        // When
        let rate = snapshot.twdRate(for: .usd)

        // Then
        #expect(rate == 8)
    }

    /// 驗證指定幣別為基準時回傳快照中的新台幣匯率
    @Test func twdRateReturnsTwdRateForCurrencyBase() {
        // Given
        let snapshot = FxRateSnapshot(
            date: Date(timeIntervalSince1970: 0),
            base: .usd,
            rates: [.twd: 31.5]
        )

        // When
        let rate = snapshot.twdRate(for: .usd)

        // Then
        #expect(rate == 31.5)
    }

    /// 驗證沒有可用換算路徑時回傳 nil
    @Test func twdRateReturnsNilForUnavailableCurrency() {
        // Given
        let snapshot = FxRateSnapshot(
            date: Date(timeIntervalSince1970: 0),
            base: .krw,
            rates: [.usd: 32]
        )

        // When
        let rate = snapshot.twdRate(for: .jpy)

        // Then
        #expect(rate == nil)
    }
}
