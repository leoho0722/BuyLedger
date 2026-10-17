//
//  LookupServiceTests+ReconciliationStatuses.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension LookupServiceTests {

    /// 讀取對帳狀態時依自然語言順序排序
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func fetchItems_對帳狀態多種名稱_依自然語言順序排序() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        try await service.addItem(
            .reconciliationStatus,
            LookupItemAddition(name: "Record 10", flags: .none)
        )
        try await service.addItem(
            .reconciliationStatus,
            LookupItemAddition(name: "Record 2", flags: .none)
        )
        try await service.addItem(
            .reconciliationStatus,
            LookupItemAddition(name: "Record 1", flags: .none)
        )

        // When
        let statuses = try await service.fetchItems(.reconciliationStatus).reconciliationStatuses

        // Then
        #expect(statuses == ["Record 1", "Record 2", "Record 10"])
    }

    /// 加入對帳狀態時移除空白並略過空名稱
    ///
    /// - Parameters:
    ///   - rawName: 尚未正規化的對帳狀態名稱
    ///   - expectedNames: 預期讀回的名稱
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test(arguments: [("  待對帳  ", ["待對帳"]), (" \n\t ", [])])
    func addItem_對帳狀態名稱含空白或為空_移除空白並略過空名稱(rawName: String, expectedNames: [String]) async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())

        // When
        try await service.addItem(
            .reconciliationStatus,
            LookupItemAddition(name: rawName, flags: .none)
        )

        // Then
        let statuses = try await service.fetchItems(.reconciliationStatus).reconciliationStatuses
        #expect(statuses == expectedNames)
    }

    /// 重複加入對帳狀態不會建立第二筆記錄
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func addItem_對帳狀態名稱已存在_不新增重複記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addItem(
            .reconciliationStatus,
            LookupItemAddition(name: "重複項目", flags: .none)
        )

        // When
        try await service.addItem(
            .reconciliationStatus,
            LookupItemAddition(name: "重複項目", flags: .none)
        )

        // Then
        let statuses = try await service.fetchItems(.reconciliationStatus).reconciliationStatuses
        #expect(statuses == ["重複項目"])
    }

    /// 刪除符合名稱的對帳狀態
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeItem_對帳狀態名稱相符_刪除該筆記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addItem(
            .reconciliationStatus,
            LookupItemAddition(name: "保留項目", flags: .none)
        )
        try await service.addItem(
            .reconciliationStatus,
            LookupItemAddition(name: "待刪項目", flags: .none)
        )

        // When
        try await service.removeItem(.reconciliationStatus, "待刪項目")

        // Then
        let statuses = try await service.fetchItems(.reconciliationStatus).reconciliationStatuses
        #expect(statuses == ["保留項目"])
    }

    /// 刪除不存在的對帳狀態不影響既有記錄
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeItem_對帳狀態名稱不存在_保留既有記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addItem(
            .reconciliationStatus,
            LookupItemAddition(name: "保留項目", flags: .none)
        )

        // When
        try await service.removeItem(.reconciliationStatus, "不存在的項目")

        // Then
        let statuses = try await service.fetchItems(.reconciliationStatus).reconciliationStatuses
        #expect(statuses == ["保留項目"])
    }
}
