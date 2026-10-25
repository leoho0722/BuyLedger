//
//  RuntimeEnvironmentTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Testing

@testable import BuyLedger

/// `RuntimeEnvironment` 的單元測試，涵蓋單元測試程序的辨識結果
struct RuntimeEnvironmentTests {

    /// 驗證目前的單元測試 host 被識別為單元測試程序
    @Test
    func isUnitTesting_單元測試程序_識別為單元測試() {
        // Given

        // When
        let isUnitTesting = RuntimeEnvironment.isUnitTesting

        // Then
        #expect(isUnitTesting)
    }

    /// 驗證單元測試 host 的環境判定允許使用預覽替身，供測試讀取預置資料
    @Test
    func allowsPreviewStub_單元測試程序_允許預覽替身() {
        // Given

        // When
        let isPreviewStubAllowed = RuntimeEnvironment.allowsPreviewStub

        // Then
        #expect(isPreviewStubAllowed)
    }

    /// 驗證單元測試 host 不會被誤判為由介面測試啟動的程序
    @Test
    func isUITesting_單元測試程序_不視為介面測試() {
        // Given

        // When
        let isUITesting = RuntimeEnvironment.isUITesting

        // Then
        #expect(!isUITesting)
    }
}
