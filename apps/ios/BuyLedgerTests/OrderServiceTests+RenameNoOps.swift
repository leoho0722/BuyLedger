//
//  OrderServiceTests+RenameNoOps.swift
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

    /// 五種改名操作收到空白目標時不開交易且保留所有資料
    ///
    /// - Parameter operation: 要測試的 `LookupRenameOperation` 案例
    /// - Throws: fixture 寫入或資料庫讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；主檔名稱、訂單欄位不符或未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test(arguments: LookupRenameOperation.allCases)
    func normalizedRenameTarget_目標名稱為空白_不開交易且保留所有資料(operation: LookupRenameOperation) async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let fixture = try await Self.seedRenameFixture(in: database)
        let beforeNames = try await Self.fetchRenameMasterNames(from: database)
        try #require(beforeNames == [["舊名稱"], ["舊名稱"], ["舊名稱"], ["舊名稱"]])
        let beforeOrder = try #require(try await Self.fetchOrder(id: fixture.id, from: database))
        try #require(beforeOrder.orderSource == "舊名稱")
        try #require(beforeOrder.categories == ["舊名稱"])
        try #require(beforeOrder.paymentMethod == "舊名稱")
        try #require(beforeOrder.reconciliationStatus == "舊名稱")
        try #require(beforeOrder.campaignNames == ["舊名稱"])
        let mock = MockBuyLedgerDatabase(database: database)
        let service = Self.makeService(database: mock)

        // When
        try await Self.applyRename(
            operation,
            oldName: "舊名稱",
            newName: "  \n ",
            using: service
        )

        // Then
        #expect(mock.writeCallCount == 0)
        #expect(try await Self.fetchRenameMasterNames(from: database) == beforeNames)
        let afterOrder = try #require(try await Self.fetchOrder(id: fixture.id, from: database))
        #expect(
            LedgerOrder.normalizingItemIdentifiers(afterOrder)
                == LedgerOrder.normalizingItemIdentifiers(beforeOrder)
        )
    }

    /// 五種改名操作收到未變更目標時不開交易且保留所有資料
    ///
    /// - Parameter operation: 要測試的 `LookupRenameOperation` 案例
    /// - Throws: fixture 寫入或資料庫讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；主檔名稱、訂單欄位不符或未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test(arguments: LookupRenameOperation.allCases)
    func normalizedRenameTarget_目標名稱未變_不開交易且保留所有資料(operation: LookupRenameOperation) async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let fixture = try await Self.seedRenameFixture(in: database)
        let beforeNames = try await Self.fetchRenameMasterNames(from: database)
        try #require(beforeNames == [["舊名稱"], ["舊名稱"], ["舊名稱"], ["舊名稱"]])
        let beforeOrder = try #require(try await Self.fetchOrder(id: fixture.id, from: database))
        try #require(beforeOrder.orderSource == "舊名稱")
        try #require(beforeOrder.categories == ["舊名稱"])
        try #require(beforeOrder.paymentMethod == "舊名稱")
        try #require(beforeOrder.reconciliationStatus == "舊名稱")
        try #require(beforeOrder.campaignNames == ["舊名稱"])
        let mock = MockBuyLedgerDatabase(database: database)
        let service = Self.makeService(database: mock)

        // When
        try await Self.applyRename(
            operation,
            oldName: "舊名稱",
            newName: " 舊名稱 ",
            using: service
        )

        // Then
        #expect(mock.writeCallCount == 0)
        #expect(try await Self.fetchRenameMasterNames(from: database) == beforeNames)
        let afterOrder = try #require(try await Self.fetchOrder(id: fixture.id, from: database))
        #expect(
            LedgerOrder.normalizingItemIdentifiers(afterOrder)
                == LedgerOrder.normalizingItemIdentifiers(beforeOrder)
        )
    }

    /// 每種連鎖改名都更新對應欄位並保留訂單照片
    ///
    /// - Parameter operation: 要測試的 `LookupRenameOperation` 案例
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   未讀回改名後的訂單時由 `#require` 丟出測試斷言錯誤
    @Test(arguments: LookupRenameOperation.allCases)
    func lookupRenameOperation_五種改名交易_照片保持不變(operation: LookupRenameOperation) async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x20])
        let order = LedgerOrder.fixture(
            id: "ORDER-RENAME-PHOTOS",
            orderSource: "舊名稱",
            categories: ["舊名稱"],
            paymentMethod: "舊名稱",
            reconciliationStatus: "舊名稱",
            campaignNames: ["舊名稱"],
            photos: [photo]
        )
        let payment = PaymentMethodInfo(name: "舊名稱", flags: .none)
        try await Self.seed(
            [order],
            categories: ["舊名稱"],
            paymentMethods: [payment],
            database: database
        )
        try await database.write { context throws(PersistenceError) in
            context.insert(OrderSourceRecord(name: "舊名稱"))
            context.insert(ReconciliationStatusRecord(name: "舊名稱"))
        }
        let service = Self.makeService(database: database)

        // When
        try await Self.applyRename(
            operation,
            oldName: "舊名稱",
            newName: "新名稱",
            using: service
        )

        // Then
        let stored = try #require(try await Self.fetchOrder(id: order.id, from: database))
        let expected: LedgerOrder
        switch operation {
        case .orderSource:
            expected = LedgerOrder.fixture(
                id: order.id,
                orderSource: "新名稱",
                categories: ["舊名稱"],
                paymentMethod: "舊名稱",
                reconciliationStatus: "舊名稱",
                campaignNames: ["舊名稱"],
                photos: [photo]
            )

        case .category:
            expected = LedgerOrder.fixture(
                id: order.id,
                orderSource: "舊名稱",
                categories: ["新名稱"],
                paymentMethod: "舊名稱",
                reconciliationStatus: "舊名稱",
                campaignNames: ["舊名稱"],
                photos: [photo]
            )

        case .paymentMethod:
            expected = LedgerOrder.fixture(
                id: order.id,
                orderSource: "舊名稱",
                categories: ["舊名稱"],
                paymentMethod: "新名稱",
                reconciliationStatus: "舊名稱",
                campaignNames: ["舊名稱"],
                photos: [photo]
            )

        case .reconciliationStatus:
            expected = LedgerOrder.fixture(
                id: order.id,
                orderSource: "舊名稱",
                categories: ["舊名稱"],
                paymentMethod: "舊名稱",
                reconciliationStatus: "新名稱",
                campaignNames: ["舊名稱"],
                photos: [photo]
            )

        case .campaign:
            expected = LedgerOrder.fixture(
                id: order.id,
                orderSource: "舊名稱",
                categories: ["舊名稱"],
                paymentMethod: "舊名稱",
                reconciliationStatus: "舊名稱",
                campaignNames: ["新名稱"],
                photos: [photo]
            )
        }
        #expect(
            LedgerOrder.normalizingItemIdentifiers(stored)
                == LedgerOrder.normalizingItemIdentifiers(expected)
        )
        #expect(stored.photos == [photo])
    }
}
