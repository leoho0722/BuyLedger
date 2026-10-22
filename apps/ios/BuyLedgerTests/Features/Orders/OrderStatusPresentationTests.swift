//
//  OrderStatusPresentationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/10.
//

import Testing

@testable import BuyLedger

/// 訂單狀態語意色調的對應測試，確認每個狀態與設計規格一致
///
/// - Note: 落實 interface-consistency 的「Purchased status reads as progress, not warning」
/// - Note: 落實 interface-consistency 的「Statuses genuinely needing attention keep the warning color」
struct OrderStatusPresentationTests {

    /// 確認訂單狀態顯示的色調與規格指定的色調相同
    ///
    /// - Parameters:
    ///   - status: 要查詢色調的訂單狀態
    ///   - tone: 規格指定的語意色調
    @Test(arguments: [
        (OrderStatus.quoting, BLTone.informative),
        (.confirmed, .accent),
        (.purchased, .informative),
        (.shipping, .informative),
        (.partiallyArrived, .warning),
        (.arrived, .accent),
        (.delivered, .success),
        (.pickedUp, .success),
        (.cancelled, .destructive),
        (.merged, .neutral),
    ])
    func tone_各訂單狀態_對應設計系統語意色調(status: OrderStatus, tone: BLTone) {
        // Given

        // When
        let actualTone = status.tone

        // Then
        #expect(actualTone == tone)
    }
}
