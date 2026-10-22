//
//  BLTrendTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證由差值判定走勢方向時，缺值、負值、零與正值各自對應的方向
struct BLTrendTests {

    /// 差值為缺值、負值、零與正值時，判定對應的走勢方向；零歸為上升
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

        /// 窮舉缺值、負值、零與正值，預期結果逐筆指定
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
