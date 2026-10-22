//
//  LookupServiceTests+Sources.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension LookupServiceTests {

    /// 讀取訂單來源時依自然語言順序排序
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func fetchItems_訂單來源多種名稱_依自然語言順序排序() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        try await service.addItem(.orderSource, LookupItemAddition(name: "Record 10", flags: .none))
        try await service.addItem(.orderSource, LookupItemAddition(name: "Record 2", flags: .none))
        try await service.addItem(.orderSource, LookupItemAddition(name: "Record 1", flags: .none))

        // When
        let orderSources = try await service.fetchItems(.orderSource).orderSources

        // Then
        #expect(orderSources == ["Record 1", "Record 2", "Record 10"])
    }

    /// 加入訂單來源時移除空白並略過空名稱
    ///
    /// - Parameters:
    ///   - rawName: 尚未正規化的訂單來源名稱
    ///   - expectedNames: 預期讀回的名稱
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test(arguments: [("  網路商店  ", ["網路商店"]), (" \n\t ", [])])
    func addItem_訂單來源輸入含空白或為空_移除空白並略過空名稱(rawName: String, expectedNames: [String]) async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())

        // When
        try await service.addItem(.orderSource, LookupItemAddition(name: rawName, flags: .none))

        // Then
        let orderSources = try await service.fetchItems(.orderSource).orderSources
        #expect(orderSources == expectedNames)
    }

    /// 重複加入訂單來源不會建立第二筆記錄
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func addItem_訂單來源名稱已存在_不新增重複記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addItem(.orderSource, LookupItemAddition(name: "重複項目", flags: .none))

        // When
        try await service.addItem(.orderSource, LookupItemAddition(name: "重複項目", flags: .none))

        // Then
        let orderSources = try await service.fetchItems(.orderSource).orderSources
        #expect(orderSources == ["重複項目"])
    }

    /// 刪除符合名稱的訂單來源
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeItem_訂單來源名稱相符_刪除該筆記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addItem(.orderSource, LookupItemAddition(name: "保留項目", flags: .none))
        try await service.addItem(.orderSource, LookupItemAddition(name: "待刪項目", flags: .none))

        // When
        try await service.removeItem(.orderSource, "待刪項目")

        // Then
        let orderSources = try await service.fetchItems(.orderSource).orderSources
        #expect(orderSources == ["保留項目"])
    }

    /// 刪除不存在的訂單來源不影響既有記錄
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeItem_訂單來源名稱不存在_保留既有記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addItem(.orderSource, LookupItemAddition(name: "保留項目", flags: .none))

        // When
        try await service.removeItem(.orderSource, "不存在的項目")

        // Then
        let orderSources = try await service.fetchItems(.orderSource).orderSources
        #expect(orderSources == ["保留項目"])
    }
}
