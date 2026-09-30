//
//  RuntimeEnvironmentTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Testing

@testable import BuyLedger

/// 驗證執行環境能辨識單元測試程序
struct RuntimeEnvironmentTests {

    // MARK: - Tests

    /// 單元測試 host 允許 Preview stub 且不視為 UI 測試
    @Test
    func isUnitTesting_單元測試程序_只識別為單元測試() {
        // Given

        // When
        let isUnitTesting = RuntimeEnvironment.isUnitTesting
        let allowsPreviewStub = RuntimeEnvironment.allowsPreviewStub
        let isUITesting = RuntimeEnvironment.isUITesting

        // Then
        #expect(isUnitTesting)
        #expect(allowsPreviewStub)
        #expect(!isUITesting)
    }
}
