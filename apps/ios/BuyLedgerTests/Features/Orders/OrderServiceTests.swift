//
//  OrderServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderService` 的單元測試，涵蓋正式依賴與共用資料庫實例的組裝
struct OrderServiceTests {

    /// 驗證正式 (`.live`) 環境下連續解析 `buyLedgerDatabase` 兩次，取得同一個 `BuyLedgerDatabase` 實例，不另建第二個
    @Test
    func liveValue_連續解析兩次_取得同一資料庫實例() {
        // Given

        // When
        let identities = TestContainerCreationLock.withLock {
            withDependencies {
                $0.context = .live
            } operation: {
                @Dependency(\.buyLedgerDatabase) var first
                @Dependency(\.buyLedgerDatabase) var second
                return (ObjectIdentifier(first as AnyObject), ObjectIdentifier(second as AnyObject))
            }
        }

        // Then
        #expect(identities.0 == identities.1)
    }
}
