//
//  BuyLedgerDatabasePreviewTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import SwiftData
import Testing

@testable import BuyLedger

/// `BuyLedgerDatabase` 的單元測試，涵蓋 Preview 資料庫的預置訂單
struct BuyLedgerDatabasePreviewTests {

    /// 驗證 Preview 資料庫首次讀取的訂單識別值，與預先放入的八筆範例訂單編號逐一相同 (不多不少)
    ///
    /// - Throws: Preview 資料庫讀取失敗時丟出持久化讀取錯誤
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
        #expect(
            firstReadIDs == [
                "BL-2604-011",
                "BL-2604-012",
                "BL-2604-013",
                "BL-2604-014",
                "BL-2604-015",
                "BL-2604-016",
                "BL-2604-017",
                "BL-2604-018",
            ]
        )
    }
}
