//
//  BuyLedgerDatabaseTests+WriteFailures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

// MARK: - Tests

extension BuyLedgerDatabaseTests {

    /// `write` 主體失敗時不保存已插入的訂單
    ///
    /// - Throws: 讀取 store 失敗時丟出 `.fetchFailed(underlying:)`；`write` 沒有丟出錯誤時
    ///   由 `#require` 丟出測試斷言錯誤
    @Test
    func write_操作主體失敗_不保存已插入訂單() async throws {
        // Given
        let database = Self.makeInMemoryDatabase()
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
            try Self.orderIDs(in: context)
        }
        #expect(isSaveFailure)
        #expect(!storedIDs.contains("DATABASE-CLOSURE-FAIL"))
    }

    /// 真正 `save()` 失敗時丟棄同一交易插入的訂單與違規子項
    ///
    /// - Throws: fixture 建立或子項查詢失敗時丟出底層錯誤；訂單讀取失敗時丟出
    ///   `.fetchFailed(underlying:)`；`write` 沒有丟出錯誤時由 `#require` 丟出測試斷言錯誤
    @Test
    func write_儲存失敗_不留下訂單與違規子項() async throws {
        // Given
        let fixture = try ResidueProbeModels.makeDiskFixture(
            orders: [LedgerOrder.fixture(id: "DATABASE-SAVE-SEED")]
        )
        defer {
            Self.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = Self.makeDatabase(with: fixture)
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
        let storedIDs = try Self.orderIDs(in: context)
        let storedChildren = try context.fetch(
            FetchDescriptor<ResidueProbeModels.ResidueProbeChild>()
        )
        let invalidChildCount = storedChildren.filter { $0.name.hasPrefix("invalid-child-") }.count
        #expect(isSaveFailure)
        #expect(storedIDs == ["DATABASE-SAVE-SEED"])
        #expect(storedChildren.map(\.name) == ["fixture-child"])
        #expect(invalidChildCount == 0)
    }

    /// 前一筆失敗交易的未儲存模型不會進入下一個 `write` context
    ///
    /// - Throws: fixture 建立失敗時丟出底層錯誤；後續讀取失敗時丟出
    ///   `.fetchFailed(underlying:)`、保存失敗時丟出 `.saveFailed(underlying:)`；第一次 `write`
    ///   沒有丟出錯誤時由 `#require` 丟出測試斷言錯誤
    @Test
    func write_前次交易失敗_後續不帶入未儲存模型() async throws {
        // Given
        let fixture = try ResidueProbeModels.makeDiskFixture()
        defer {
            Self.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = Self.makeDatabase(with: fixture)
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
