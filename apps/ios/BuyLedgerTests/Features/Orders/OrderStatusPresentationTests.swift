//
//  OrderStatusPresentationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/10.
//

import Testing

@testable import BuyLedger

/// `OrderStatus` 的單元測試，逐一核對各狀態的語意色調
///
/// - Note: 依 interface-consistency 規格，已採購屬進行中，不使用警示色
/// - Note: 需要注意的狀態保留警示色
struct OrderStatusPresentationTests {

    /// 驗證各訂單狀態的語意色調與設計規格指定的 `BLTone` 相同 (如 `cancelled` 為 `destructive`)
    ///
    /// - Parameter testCase: 訂單狀態與預期語意色調
    @Test(arguments: [
        StatusToneCase(status: .quoting, tone: .informative),
        StatusToneCase(status: .confirmed, tone: .accent),
        StatusToneCase(status: .purchased, tone: .informative),
        StatusToneCase(status: .shipping, tone: .informative),
        StatusToneCase(status: .partiallyArrived, tone: .warning),
        StatusToneCase(status: .arrived, tone: .accent),
        StatusToneCase(status: .delivered, tone: .success),
        StatusToneCase(status: .pickedUp, tone: .success),
        StatusToneCase(status: .cancelled, tone: .destructive),
        StatusToneCase(status: .merged, tone: .neutral),
    ])
    func tone_各訂單狀態_對應設計系統語意色調(testCase: StatusToneCase) {
        // Given

        // When
        let actualTone = testCase.status.tone

        // Then
        #expect(actualTone == testCase.tone)
    }
}

// MARK: - Nested Types

extension OrderStatusPresentationTests {

    /// 訂單狀態與設計系統色調的對應
    struct StatusToneCase: Sendable {

        /// 要查詢色調的訂單狀態
        let status: OrderStatus

        /// 規格指定的語意色調
        let tone: BLTone
    }
}
