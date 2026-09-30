//
//  OrderSourceServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// 驗證訂單來源 Service 的持久化行為
struct OrderSourceServiceTests {

    // MARK: - Tests

    /// 讀取訂單來源時依自然語言順序排序
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func fetchOrderSources_多種名稱_依自然語言順序排序() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        try await service.addOrderSource("Record 10")
        try await service.addOrderSource("Record 2")
        try await service.addOrderSource("Record 1")

        // When
        let orderSources = try await service.fetchOrderSources()

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
    func addOrderSource_輸入含空白或為空_移除空白並略過空名稱(rawName: String, expectedNames: [String]) async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())

        // When
        try await service.addOrderSource(rawName)

        // Then
        let orderSources = try await service.fetchOrderSources()
        #expect(orderSources == expectedNames)
    }

    /// 重複加入訂單來源不會建立第二筆記錄
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func addOrderSource_名稱已存在_不新增重複記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addOrderSource("重複項目")

        // When
        try await service.addOrderSource("重複項目")

        // Then
        let orderSources = try await service.fetchOrderSources()
        #expect(orderSources == ["重複項目"])
    }

    /// 刪除符合名稱的訂單來源
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeOrderSource_名稱相符_刪除該筆記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addOrderSource("保留項目")
        try await service.addOrderSource("待刪項目")

        // When
        try await service.removeOrderSource("待刪項目")

        // Then
        let orderSources = try await service.fetchOrderSources()
        #expect(orderSources == ["保留項目"])
    }

    /// 刪除不存在的訂單來源不影響既有記錄
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeOrderSource_名稱不存在_保留既有記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addOrderSource("保留項目")

        // When
        try await service.removeOrderSource("不存在的項目")

        // Then
        let orderSources = try await service.fetchOrderSources()
        #expect(orderSources == ["保留項目"])
    }
}

// MARK: - Private Method

private extension OrderSourceServiceTests {

    /// 以注入的資料庫建立正式 `OrderSourceService`
    ///
    /// - Parameter database: 要提供給 Service 的資料庫
    /// - Returns: 已擷取資料庫依賴的 `OrderSourceService`
    static func makeService(database: any BuyLedgerDatabaseProtocol) -> OrderSourceService {
        withDependencies {
            $0.buyLedgerDatabase = database
        } operation: {
            OrderSourceService.liveValue
        }
    }
}
