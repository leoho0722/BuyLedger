//
//  BuyLedgerDatabaseWriteFailuresTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// `BuyLedgerDatabase` 的單元測試，涵蓋失敗交易的模型不保存，也不影響下一次寫入
struct BuyLedgerDatabaseWriteFailuresTests {

    /// 驗證 `write` 在主體執行後失敗時，已插入的訂單不被保存，且錯誤為 `.saveFailed`
    ///
    /// - Throws: 讀取資料庫失敗時丟出持久化讀取錯誤；寫入沒有回報預期錯誤時丟出測試斷言錯誤
    @Test
    func write_操作主體失敗_不保存已插入訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .writeFailureAfterBody(
            error: PersistenceError.saveFailed(underlying: NSError(domain: "TestDomain", code: 42))
        )
        var actualError: PersistenceError?

        // When
        do throws(PersistenceError) {
            try await mock.write { context throws(PersistenceError) in
                context.insert(OrderRecord(order: LedgerOrder.fixture(id: "DATABASE-CLOSURE-FAIL")))
            }
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let isSaveFailure: Bool
        switch error {
        case .saveFailed:
            isSaveFailure = true

        case .fetchFailed, .containerCreationFailed:
            isSaveFailure = false
        }
        let storedIDs = try await database.read { context throws(PersistenceError) in
            try BuyLedgerDatabaseTestSupport.orderIDs(in: context)
        }
        #expect(isSaveFailure)
        #expect(!storedIDs.contains("DATABASE-CLOSURE-FAIL"))
    }

    /// 驗證 `save()` 真的失敗時，同一交易插入的訂單與違規子項都被丟棄，既有的訂單與子項保持不變
    ///
    /// - Throws: 建立測試資料或查詢子項失敗時丟出底層錯誤；讀取訂單失敗時丟出持久化讀取錯誤；寫入未回報預期錯誤時丟出測試斷言錯誤
    @Test
    func write_儲存失敗_不留下訂單與違規子項() async throws {
        // Given
        let fixture = try ResidueProbeModels.makeDiskFixture(
            orders: [LedgerOrder.fixture(id: "DATABASE-SAVE-SEED")]
        )
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTestSupport.makeDatabase(with: fixture)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .saveFailureAfterBody
        var actualError: PersistenceError?

        // When
        do throws(PersistenceError) {
            try await mock.write { context throws(PersistenceError) in
                context.insert(OrderRecord(order: LedgerOrder.fixture(id: "DATABASE-SAVE-FAIL")))
            }
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let isSaveFailure: Bool
        switch error {
        case .saveFailed:
            isSaveFailure = true

        case .fetchFailed, .containerCreationFailed:
            isSaveFailure = false
        }
        let context = ModelContext(fixture.container)
        let storedIDs = try BuyLedgerDatabaseTestSupport.orderIDs(in: context)
        let storedChildren = try context.fetch(
            FetchDescriptor<ResidueProbeModels.ResidueProbeChild>()
        )
        let invalidChildCount = storedChildren.filter { $0.name.hasPrefix("invalid-child-") }.count
        #expect(isSaveFailure)
        #expect(storedIDs == ["DATABASE-SAVE-SEED"])
        #expect(storedChildren.map(\.name) == ["fixture-child"])
        #expect(invalidChildCount == 0)
    }

    /// 驗證前一筆寫入失敗後，其未儲存的模型不會帶入下一次 `write` 的 context
    ///
    /// - Throws: 建立測試資料失敗時丟出底層錯誤；後續讀寫失敗時丟出對應的持久化錯誤；第一次寫入未回報預期錯誤時丟出測試斷言錯誤
    @Test
    func write_前次交易失敗_後續不帶入未儲存模型() async throws {
        // Given
        let fixture = try ResidueProbeModels.makeDiskFixture()
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTestSupport.makeDatabase(with: fixture)
        var actualError: PersistenceError?

        // When
        do throws(PersistenceError) {
            try await database.write { context throws(PersistenceError) in
                context.insert(ResidueProbeModels.ResidueProbeParent(name: "write-pending"))
                throw .saveFailed(underlying: NSError(domain: "TestDomain", code: 43))
            }
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let isSaveFailure: Bool
        switch error {
        case .saveFailed:
            isSaveFailure = true

        case .fetchFailed, .containerCreationFailed:
            isSaveFailure = false
        }
        let secondWrite = try await database.write { context throws(PersistenceError) in
            let names = try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<ResidueProbeModels.ResidueProbeParent>())
                    .map(\.name)
            }
            return (hasChanges: context.hasChanges, parentNames: names)
        }
        #expect(isSaveFailure)
        #expect(!secondWrite.hasChanges)
        #expect(!secondWrite.parentNames.contains("write-pending"))
    }
}
