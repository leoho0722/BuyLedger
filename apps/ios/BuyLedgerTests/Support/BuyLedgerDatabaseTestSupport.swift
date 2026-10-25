//
//  BuyLedgerDatabaseTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// 提供資料庫測試共用的容器建立、訂單識別值查詢與暫存目錄清理操作
enum BuyLedgerDatabaseTestSupport {}

// MARK: - Internal Method

extension BuyLedgerDatabaseTestSupport {

    /// 建立使用 in-memory container 的資料庫
    ///
    /// - Returns: `storeLocation` 為 `.inMemory` 的資料庫
    /// - Note: 容器建立經 `TestContainerCreationLock` 串行化
    static func makeInMemoryDatabase() -> BuyLedgerDatabase {
        let container = TestContainerCreationLock.withLock {
            PersistenceContainer.makeInMemory(for: .testing)
        }
        return BuyLedgerDatabase(modelContainer: container, storeLocation: .inMemory)
    }

    /// 以 fixture 建立磁碟資料庫
    ///
    /// - Parameter fixture: 含容器與 store 目錄的測試 fixture
    /// - Returns: 使用 fixture store 位置的資料庫
    static func makeDatabase(with fixture: ResidueProbeModels.DiskFixture) -> BuyLedgerDatabase {
        BuyLedgerDatabase(
            modelContainer: fixture.container,
            storeLocation: .directory(fixture.directoryURL)
        )
    }

    /// 讀取目前 store 中的訂單識別值
    ///
    /// - Parameter context: 查詢用的 `SwiftData` context
    /// - Returns: 依 store 回傳的順序排列之訂單識別值
    /// - Throws: 訂單讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func orderIDs(in context: ModelContext) throws(PersistenceError) -> [String] {
        try PersistenceError.mapFetch {
            try context.fetch(FetchDescriptor<OrderRecord>()).map(\.id)
        }
    }

    /// 移除測試建立的暫存資料夾；移除失敗時以 `Issue.record` 記錄測試失敗
    ///
    /// - Parameter directoryURL: 暫存 store 所在目錄
    static func removeTemporaryDirectory(at directoryURL: URL) {
        do {
            try FileManager.default.removeItem(at: directoryURL)
        } catch {
            Issue.record("無法移除資料庫測試暫存目錄：\(error.localizedDescription)")
        }
    }
}
