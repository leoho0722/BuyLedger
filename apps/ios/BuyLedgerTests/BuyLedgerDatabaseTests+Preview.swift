//
//  BuyLedgerDatabaseTests+Preview.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import SwiftData
import Testing

@testable import BuyLedger

// MARK: - Tests

extension BuyLedgerDatabaseTests {

    /// Preview 資料庫首次讀取的訂單識別值，與 `LedgerOrder.sampleOrders` 的識別值逐一相同 (不多不少)
    ///
    /// - Throws: 預覽資料庫讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    @Test
    func previewValue_預覽資料庫首次讀取_包含全部範例訂單() async throws {
        // Given
        let database = TestContainerCreationLock.withLock {
            BuyLedgerDatabaseKey.previewValue
        }

        // When
        let firstReadIDs = try await database.read { context throws(PersistenceError) in
            try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<OrderRecord>()).map(\.id).sorted()
            }
        }

        // Then
        #expect(firstReadIDs == LedgerOrder.sampleOrders.map(\.id).sorted())
    }
}
