//
//  BuyLedgerDatabaseTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// 驗證資料庫交易的 context 隔離、寫入與復原邊界
struct BuyLedgerDatabaseTests {

    // MARK: - Tests

    /// 每次讀取使用新 `ModelContext` 且不保留前次未儲存的模型
    ///
    /// - Throws: store 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；fixture 建立失敗時丟出底層錯誤
    @Test
    func read_連續讀取_每次建立新資料上下文並隔離未儲存模型() async throws {
        // Given
        let fixture = try ResidueProbeModels.makeDiskFixture()
        defer {
            Self.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = Self.makeDatabase(with: fixture)

        // When
        await database.read { context in
            context.autosaveEnabled = false
            context.insert(ResidueProbeModels.ResidueProbeParent(name: "read-pending"))
        }

        // Then
        let secondRead = try await database.read { context throws(PersistenceError) in
            let names = try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<ResidueProbeModels.ResidueProbeParent>())
                    .map(\.name)
            }
            return (hasChanges: context.hasChanges, parentNames: names)
        }
        #expect(!secondRead.hasChanges)
        #expect(!secondRead.parentNames.contains("read-pending"))
    }

    /// 成功寫入只送出一次 `save()` 通知並將訂單保存至 store
    ///
    /// - Throws: 儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   讀回失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    @Test
    func write_操作成功_僅儲存一次且可讀回訂單() async throws {
        // Given
        let database = Self.makeInMemoryDatabase()
        let contextIdentifier = LockIsolated<ObjectIdentifier?>(nil)
        let saveCount = LockIsolated(0)
        // 使用同步 block observer 立即記錄 save 通知，改用 AsyncSequence 會引入排程時序
        let observer = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave,
            object: nil,
            queue: nil
        ) { notification in
            guard let context = notification.object as? ModelContext,
                  let expectedIdentifier = contextIdentifier.value,
                  ObjectIdentifier(context) == expectedIdentifier else {
                return
            }
            saveCount.withValue {
                $0 += 1
            }
        }
        defer {
            NotificationCenter.default.removeObserver(observer)
        }
        let order = LedgerOrder.fixture(id: "DATABASE-SAVE-ONCE")

        // When
        try await database.write { context throws(PersistenceError) in
            let identifier = ObjectIdentifier(context)
            contextIdentifier.withValue {
                $0 = identifier
            }
            context.insert(OrderRecord(order: order))
        }

        // Then
        let storedIDs = try await database.read { context throws(PersistenceError) in
            try Self.orderIDs(in: context)
        }
        #expect(saveCount.value == 1)
        #expect(storedIDs == ["DATABASE-SAVE-ONCE"])
    }

    /// 二十個相同識別值的並發 `write` 只建立一筆訂單
    ///
    /// - Throws: 最後讀取 store 失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    @Test
    func write_相同識別值並行寫入_只建立一筆() async throws {
        // Given
        let database = Self.makeInMemoryDatabase()
        let orderID = "order-001"

        // When
        let outcomes = await withTaskGroup(of: WriteOutcome.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    do throws(OrderPersistenceError) {
                        try await database.write { context throws(OrderPersistenceError) in
                            let storedIDs: [String]
                            do {
                                storedIDs = try context
                                    .fetch(FetchDescriptor<OrderRecord>())
                                    .map(\.id)
                            } catch {
                                throw .storage(.fetchFailed(underlying: error as NSError))
                            }
                            if storedIDs.contains(orderID) {
                                throw .identifierCollision(id: orderID)
                            }
                            context.insert(OrderRecord(order: LedgerOrder.fixture(id: orderID)))
                        }
                        return .created
                    } catch {
                        if case .identifierCollision(let id) = error, id == orderID {
                            return .collision
                        }
                        return .unexpected
                    }
                }
            }
            var results: [WriteOutcome] = []
            for await outcome in group {
                results.append(outcome)
            }
            return results
        }

        // Then
        let storedIDs = try await database.read { context throws(PersistenceError) in
            try Self.orderIDs(in: context)
        }
        #expect(outcomes.filter { $0 == .created }.count == 1)
        #expect(outcomes.filter { $0 == .collision }.count == 19)
        #expect(outcomes.allSatisfy { $0 == .created || $0 == .collision })
        #expect(storedIDs == ["order-001"])
    }
}

// MARK: - Nested Types

extension BuyLedgerDatabaseTests {

    /// 並發寫入的完成結果
    private enum WriteOutcome: Equatable, Sendable {

        /// 訂單成功建立
        case created

        /// 同識別值的訂單已存在
        case collision

        /// 發生非預期錯誤
        case unexpected
    }
}

// MARK: - Internal Method

extension BuyLedgerDatabaseTests {

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

    /// 建立使用 in-memory container 的資料庫
    ///
    /// - Returns: `storeLocation` 為 `.inMemory` 的資料庫，容器建立經 `TestContainerCreationLock` 串行化
    static func makeInMemoryDatabase() -> BuyLedgerDatabase {
        let container = TestContainerCreationLock.withLock {
            PersistenceContainer.makeInMemory(for: .testing)
        }
        return BuyLedgerDatabase(modelContainer: container, storeLocation: .inMemory)
    }

    /// 讀取目前 store 中的訂單識別值
    ///
    /// - Parameter context: 查詢用的 SwiftData context
    /// - Returns: 依 store 回傳的順序排列之訂單識別值
    /// - Throws: 訂單讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func orderIDs(in context: ModelContext) throws(PersistenceError) -> [String] {
        try PersistenceError.mapFetch {
            try context.fetch(FetchDescriptor<OrderRecord>()).map(\.id)
        }
    }
}
