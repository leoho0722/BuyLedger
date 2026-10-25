//
//  FxRateSnapshotTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/22.
//

import Foundation
import Testing

@testable import BuyLedger

/// `FxRateSnapshot` 的單元測試，涵蓋換算新台幣匯率
struct FxRateSnapshotTests {

    /// 驗證查詢新台幣本身時，不論快照中的匯率為何，都回傳 1
    @Test
    func twdRate_查詢新台幣_回傳一() {
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

    /// 驗證快照以新台幣為基準時，回傳指定幣別匯率的倒數，例如匯率 0.125 得到 8
    @Test
    func twdRate_新台幣為基準_回傳指定幣別匯率的倒數() {
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

    /// 驗證查詢幣別即為快照基準時，直接回傳快照中記錄的新台幣匯率，不做換算
    @Test
    func twdRate_指定幣別為基準_回傳快照中的新台幣匯率() {
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

    /// 驗證快照缺少查詢幣別的匯率時回傳 `nil`，例如只有美元匯率卻查詢日圓
    @Test
    func twdRate_無可用換算路徑_回傳空值() {
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
