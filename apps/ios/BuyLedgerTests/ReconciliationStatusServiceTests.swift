//
//  ReconciliationStatusServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// 驗證對帳狀態 Service 的持久化行為
struct ReconciliationStatusServiceTests {

    // MARK: - Tests

    /// 讀取對帳狀態時依自然語言順序排序
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func fetchReconciliationStatuses_多種名稱_依自然語言順序排序() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        try await service.addReconciliationStatus("Record 10")
        try await service.addReconciliationStatus("Record 2")
        try await service.addReconciliationStatus("Record 1")

        // When
        let statuses = try await service.fetchReconciliationStatuses()

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
    func addReconciliationStatus_名稱含空白或為空_移除空白並略過空名稱(
        rawName: String,
        expectedNames: [String]
    ) async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())

        // When
        try await service.addReconciliationStatus(rawName)

        // Then
        let statuses = try await service.fetchReconciliationStatuses()
        #expect(statuses == expectedNames)
    }

    /// 重複加入對帳狀態不會建立第二筆記錄
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func addReconciliationStatus_名稱已存在_不新增重複記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addReconciliationStatus("重複項目")

        // When
        try await service.addReconciliationStatus("重複項目")

        // Then
        let statuses = try await service.fetchReconciliationStatuses()
        #expect(statuses == ["重複項目"])
    }

    /// 刪除符合名稱的對帳狀態
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeReconciliationStatus_名稱相符_刪除該筆記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addReconciliationStatus("保留項目")
        try await service.addReconciliationStatus("待刪項目")

        // When
        try await service.removeReconciliationStatus("待刪項目")

        // Then
        let statuses = try await service.fetchReconciliationStatuses()
        #expect(statuses == ["保留項目"])
    }

    /// 刪除不存在的對帳狀態不影響既有記錄
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeReconciliationStatus_名稱不存在_保留既有記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addReconciliationStatus("保留項目")

        // When
        try await service.removeReconciliationStatus("不存在的項目")

        // Then
        let statuses = try await service.fetchReconciliationStatuses()
        #expect(statuses == ["保留項目"])
    }
}

// MARK: - Private Method

private extension ReconciliationStatusServiceTests {

    /// 以注入的資料庫建立正式 `ReconciliationStatusService`
    ///
    /// - Parameter database: 要提供給 Service 的資料庫
    /// - Returns: 已擷取資料庫依賴的 `ReconciliationStatusService`
    static func makeService(
        database: any BuyLedgerDatabaseProtocol
    ) -> ReconciliationStatusService {
        withDependencies {
            $0.buyLedgerDatabase = database
        } operation: {
            ReconciliationStatusService.liveValue
        }
    }
}
