//
//  SignificantTimeChangeServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Testing
import UIKit

@testable import BuyLedger

/// 系統重大時間變更通知與殼層串流接線的單元測試
struct SignificantTimeChangeServiceTests {

    /// 訂閱後發送系統重大時間變更通知，第一個串流元素立即可供讀取
    @Test(.timeLimit(.minutes(1)))
    func liveValue_系統發出重大時間變更通知_串流收到元素() async {
        // Given
        let stream = SignificantTimeChangeService.liveValue.changes()
        var iterator = stream.makeAsyncIterator()

        // When
        NotificationCenter.default.post(
            name: UIApplication.significantTimeChangeNotification,
            object: nil
        )
        let received = await iterator.next()

        // Then
        #expect(received != nil)
    }
}
