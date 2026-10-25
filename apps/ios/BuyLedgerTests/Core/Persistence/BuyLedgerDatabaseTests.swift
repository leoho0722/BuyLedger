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

/// `BuyLedgerDatabase` 的單元測試，涵蓋交易的 context 隔離、寫入與復原邊界
struct BuyLedgerDatabaseTests {

    /// 驗證連續讀取時每次都使用新的 `ModelContext`，前次未儲存的模型不會帶入下一次讀取
    ///
    /// - Throws: 資料庫讀取失敗時丟出持久化讀取錯誤；測試資料建立失敗時丟出底層錯誤
    @Test
    func read_連續讀取_每次建立新資料上下文並隔離未儲存模型() async throws {
        // Given
        let fixture = try ResidueProbeModels.makeDiskFixture()
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTestSupport.makeDatabase(with: fixture)

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

    /// 驗證成功寫入只觸發一次儲存通知，且訂單可於之後的讀取中讀回
    ///
    /// - Throws: 資料庫儲存或讀回失敗時丟出對應的持久化錯誤
    @Test
    func write_操作成功_僅儲存一次且可讀回訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let contextIdentifier = LockIsolated<ObjectIdentifier?>(nil)
        let saveCount = LockIsolated(0)
        // 使用同步 block observer 立即記錄 save 通知，改用 `AsyncSequence` 會引入排程時序
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
            try BuyLedgerDatabaseTestSupport.orderIDs(in: context)
        }
        #expect(saveCount.value == 1)
        #expect(storedIDs == ["DATABASE-SAVE-ONCE"])
    }

    /// 驗證二十個相同識別值的並發 `write` 只建立一筆訂單，其餘十九筆回報識別值撞號
    ///
    /// - Throws: 最後讀取資料庫失敗時丟出持久化讀取錯誤
    @Test
    func write_相同識別值並行寫入_只建立一筆() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let orderID = "order-001"

        // When
        let outcomes = await withTaskGroup(of: WriteOutcome.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    do throws(OrderError) {
                        try await database.write { context throws(OrderError) in
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
            try BuyLedgerDatabaseTestSupport.orderIDs(in: context)
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
