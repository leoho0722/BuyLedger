//
//  BLUITestHarnessViewAnimationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/13.
//

import Testing

@testable import BuyLedger

#if DEBUG

/// `BLUITestHarness` 動畫開關判斷的單元測試，以替身 closure 記錄呼叫，不碰 UIKit 的全域狀態
struct BLUITestHarnessViewAnimationTests {

    // MARK: - Properties

    /// 各啟動參數與預期的動畫開關呼叫
    private static let scenarios: [ViewAnimationCase] = [
        ViewAnimationCase(arguments: ["-BLUITest"], expectedCalls: [false]),
        ViewAnimationCase(
            arguments: ["-BLUITest", "-BLUITestSeed", "lookupsOnly"],
            expectedCalls: [false]
        ),
        ViewAnimationCase(
            arguments: ["-BLUITest", "-BLUITestKeepViewAnimations"],
            expectedCalls: []
        ),
        ViewAnimationCase(arguments: [], expectedCalls: []),
        ViewAnimationCase(arguments: ["-BLUITestKeepViewAnimations"], expectedCalls: []),
    ]

    /// 驗證只有帶測試旗標且未要求保留動畫時，動畫開關被關閉一次，其餘情況都不碰開關
    ///
    /// - Parameter scenario: 啟動參數與預期的動畫開關呼叫
    @Test(arguments: BLUITestHarnessViewAnimationTests.scenarios)
    @MainActor
    func applyViewAnimationPolicy_各種啟動參數_只在測試模式且未保留時關閉一次(scenario: ViewAnimationCase) {
        // Given
        let configuration = BLUITestConfiguration(arguments: scenario.arguments)
        var calls: [Bool] = []

        // When
        BLUITestHarness.applyViewAnimationPolicy(for: configuration) {
            calls.append($0)
        }

        // Then
        #expect(calls == scenario.expectedCalls)
    }
}

// MARK: - Nested Types

extension BLUITestHarnessViewAnimationTests {

    /// 動畫開關判斷測試使用的啟動參數與預期呼叫
    struct ViewAnimationCase: CustomTestStringConvertible, Sendable {

        /// 傳給 `BLUITestConfiguration` 的啟動參數
        let arguments: [String]

        /// 預期 `setAnimationsEnabled` 依序收到的值
        let expectedCalls: [Bool]

        /// 測試報告顯示的案例名稱
        var testDescription: String {
            "參數 \(arguments) 預期呼叫 \(expectedCalls)"
        }
    }
}

#endif
