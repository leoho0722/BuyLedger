//
//  OrderServiceTests+RenameFailures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

// MARK: - Tests

extension OrderServiceTests {

    /// 改名真實存檔失敗時主檔與訂單仍維持原值
    ///
    /// - Parameter hasExistingTarget: 改名前是否已有目標類別
    /// - Throws: fixture 建立時丟出底層檔案或 SwiftData 錯誤；未取得改名錯誤、錯誤不是 `.saveFailed`，
    ///   或未讀回來源與後續訂單時由 `#require` 丟出測試斷言錯誤；
    ///   建立後續訂單時以 `OrderPersistenceError` 丟出 `.identifierCollision(id:)`、
    ///   `.storage(.fetchFailed(underlying:))` 或
    ///   `.storage(.saveFailed(underlying:))`；讀取失敗時丟出 `.fetchFailed(underlying:)`
    @Test(arguments: [false, true])
    func applyCategoryRename_真實儲存失敗_主檔與訂單維持原值(hasExistingTarget: Bool) async throws {
        // Given
        let fixture = try Self.makeRenameFixture(hasExistingTarget: hasExistingTarget)
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTests.makeDatabase(with: fixture)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .saveFailureAfterBody
        let service = Self.makeService(database: mock)
        let originalNames = hasExistingTarget ? ["服飾", "衣著"] : ["服飾"]
        let originalOrders = hasExistingTarget
            ? ["ORDER-RENAME-SOURCE": ["服飾"], "ORDER-RENAME-TARGET": ["衣著"]]
            : ["ORDER-RENAME-SOURCE": ["服飾"]]
        var actualError: PersistenceError?
        do throws(PersistenceError) {
            try await service.applyCategoryRename("服飾", "衣著")
        } catch {
            actualError = error
        }
        let error = try #require(actualError)
        let isSaveFailure: Bool
        switch error {
        case .saveFailed:
            isSaveFailure = true

        case .fetchFailed, .containerCreationFailed:
            isSaveFailure = false
        }
        try #require(isSaveFailure)
        mock.mode = .passthrough
        let followup = Self.makeOrder(id: "ORDER-RENAME-FOLLOWUP")

        // When
        try await service.createOrder(followup)

        // Then
        let names = try await database.read { context throws(PersistenceError) in
            try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<CategoryRecord>()).map(\.name).sorted()
            }
        }
        let orders = try await service.fetchOrders()
        #expect(names == originalNames.sorted())
        for (id, categories) in originalOrders {
            let stored = try #require(orders.first { $0.id == id })
            #expect(stored.categories == categories)
        }
        let storedFollowup = try #require(orders.first { $0.id == followup.id })
        #expect(storedFollowup.categories.isEmpty)
    }

    /// 改名主體完成後注入查詢錯誤，保留原資料且同資料庫可繼續寫入
    ///
    /// - Throws: fixture 建立時丟出底層檔案或 SwiftData 錯誤；未取得改名錯誤、錯誤不是
    ///   `.fetchFailed(underlying:)`、錯誤描述不符或未讀回來源訂單時由 `#require` 丟出測試斷言錯誤；
    ///   建立後續訂單時以 `OrderPersistenceError` 丟出
    ///   `.identifierCollision(id:)`、`.storage(.fetchFailed(underlying:))` 或
    ///   `.storage(.saveFailed(underlying:))`；讀取失敗時丟出 `.fetchFailed(underlying:)`
    @Test
    func applyCategoryRename_寫入後注入查詢錯誤_保留原資料且可繼續寫入() async throws {
        // Given
        let fixture = try Self.makeRenameFixture(hasExistingTarget: false)
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTests.makeDatabase(with: fixture)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .writeFailureAfterBody(
            error: PersistenceError.fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(
                    message: "lookup rename fetch failed"
                )
            )
        )
        let service = Self.makeService(database: mock)
        var actualError: PersistenceError?
        do throws(PersistenceError) {
            try await service.applyCategoryRename("服飾", "衣著")
        } catch {
            actualError = error
        }
        let error = try #require(actualError)
        let actualFetchFailure: (any Error)?
        switch error {
        case .fetchFailed(let underlying):
            actualFetchFailure = underlying

        case .saveFailed, .containerCreationFailed:
            actualFetchFailure = nil
        }
        let fetchFailure = try #require(actualFetchFailure)
        try #require(fetchFailure.localizedDescription == "lookup rename fetch failed")
        mock.mode = .passthrough
        let followup = Self.makeOrder(id: "ORDER-LOOKUP-FAIL-FOLLOWUP")

        // When
        try await service.createOrder(followup)

        // Then
        let names = try await database.read { context throws(PersistenceError) in
            try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<CategoryRecord>()).map(\.name)
            }
        }
        let orders = try await service.fetchOrders()
        #expect(names == ["服飾"])
        let source = try #require(orders.first { $0.id == "ORDER-RENAME-SOURCE" })
        #expect(source.categories == ["服飾"])
        #expect(orders.contains { $0.id == followup.id })
    }
}

// MARK: - Private Method

private extension OrderServiceTests {

    /// 建立含類別與交易失敗探針模型的暫存磁碟 store
    ///
    /// - Parameter hasExistingTarget: 是否建立既有目標類別與訂單
    /// - Returns: 已 seed 測試資料的暫存磁碟 fixture
    /// - Throws: 暫存目錄建立或 `ModelContainer` 建立失敗時丟出底層檔案或 SwiftData 錯誤
    static func makeRenameFixture(
        hasExistingTarget: Bool
    ) throws -> ResidueProbeModels.DiskFixture {
        var orders = [
            LedgerOrder.fixture(id: "ORDER-RENAME-SOURCE", categories: ["服飾"]),
        ]
        var categories = ["服飾"]
        if hasExistingTarget {
            orders.append(LedgerOrder.fixture(id: "ORDER-RENAME-TARGET", categories: ["衣著"]))
            categories.append("衣著")
        }
        return try ResidueProbeModels.makeDiskFixture(orders: orders, categories: categories)
    }
}
