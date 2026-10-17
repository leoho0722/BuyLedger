//
//  BLLayoutClassTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/4.
//

import SwiftUI
import Testing

@testable import BuyLedger

/// 驗證水平與垂直尺寸分類的九種組合只在雙向常規時使用寬版
struct BLLayoutClassTests {

    /// 只有水平與垂直都為 `.regular` 時回傳寬版，其餘組合皆回傳窄版
    ///
    /// - Parameter scenario: 兩個尺寸分類與獨立指定的預期版面
    @Test(arguments: SizeClassCase.allCases)
    func init_九種尺寸分類組合_僅雙向常規回傳寬版(scenario: SizeClassCase) {
        // Given
        let expected = scenario.expected

        // When
        let layoutClass = BLLayoutClass(
            horizontal: scenario.horizontal,
            vertical: scenario.vertical
        )

        // Then
        #expect(layoutClass == expected)
    }
}

// MARK: - Nested Types

extension BLLayoutClassTests {

    /// 水平與垂直尺寸分類及該組合應使用的版面
    struct SizeClassCase: Sendable {

        /// 窮舉 `.compact`、`.regular` 與 `nil` 的九種組合，預期結果逐筆指定
        static let allCases = [
            Self(horizontal: .compact, vertical: .compact, expected: .compact),
            Self(horizontal: .compact, vertical: .regular, expected: .compact),
            Self(horizontal: .compact, vertical: nil, expected: .compact),
            Self(horizontal: .regular, vertical: .compact, expected: .compact),
            Self(horizontal: .regular, vertical: .regular, expected: .regular),
            Self(horizontal: .regular, vertical: nil, expected: .compact),
            Self(horizontal: nil, vertical: .compact, expected: .compact),
            Self(horizontal: nil, vertical: .regular, expected: .compact),
            Self(horizontal: nil, vertical: nil, expected: .compact),
        ]

        /// 水平方向的尺寸分類，未提供時為 `nil`
        let horizontal: UserInterfaceSizeClass?

        /// 垂直方向的尺寸分類，未提供時為 `nil`
        let vertical: UserInterfaceSizeClass?

        /// 不依賴受測初始化方法計算的預期版面
        let expected: BLLayoutClass
    }
}
