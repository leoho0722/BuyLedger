//
//  BLTrendTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `BLTrend` 的單元測試，涵蓋由差值判定走勢方向的四種輸入
struct BLTrendTests {

    /// 驗證差值為缺值時判定為 `.unavailable`，為負時判定為 `.down`，為零或為正時判定為 `.up`
    ///
    /// - Parameter scenario: 差值與該差值應判定的走勢方向
    @Test(arguments: DeltaCase.allCases)
    func init_四種差值輸入_判定對應的走勢方向(scenario: DeltaCase) {
        // Given
        let delta = scenario.delta
        let expected = scenario.expected

        // When
        let trend = BLTrend(delta: delta)

        // Then
        #expect(trend == expected)
    }
}

// MARK: - Nested Types

extension BLTrendTests {

    /// 一組差值輸入與它應判定的走勢方向
    struct DeltaCase: Sendable {

        /// 缺值、負值、零與正值四種差值，每種的預期方向逐筆指定
        static let allCases = [
            Self(delta: nil, expected: .unavailable),
            Self(delta: Decimal(-0.05), expected: .down),
            Self(delta: Decimal(0), expected: .up),
            Self(delta: Decimal(0.12), expected: .up),
        ]

        /// 差值，`nil` 表示無法計算
        let delta: Decimal?

        /// 依差值應判定的走勢方向
        let expected: BLTrend
    }
}
