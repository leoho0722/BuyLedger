//
//  SignificantTimeChangeServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Testing
import UIKit

@testable import BuyLedger

/// `SignificantTimeChangeService` 的單元測試，以 `NotificationCenter` 發出系統的重大時間變更通知驅動 `liveValue` 串流
struct SignificantTimeChangeServiceTests {

    /// 驗證訂閱後系統發出重大時間變更通知，串流會送出元素，超過一分鐘未收到即視為失敗
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

        // Then
        let received: Void? = await iterator.next()
        #expect(received != nil)
    }
}
