//
//  CategoryServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// 驗證商品類別 Service 的持久化行為
struct CategoryServiceTests {

    // MARK: - Tests

    /// 讀取商品類別時依自然語言順序排序，數字依大小比較 (`Record 2` 排在 `Record 10` 前)
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func fetchCategories_多種名稱_依自然語言順序排序() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        try await service.addCategory("Record 10")
        try await service.addCategory("Record 2")
        try await service.addCategory("Record 1")

        // When
        let categories = try await service.fetchCategories()

        // Then
        #expect(categories == ["Record 1", "Record 2", "Record 10"])
    }

    /// 加入商品類別時去除前後空白後才儲存，只含空白、換行或定位字元的名稱不建立記錄
    ///
    /// - Parameters:
    ///   - rawName: 尚未正規化的類別名稱
    ///   - expectedNames: 預期讀回的名稱
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test(arguments: [("  服飾  ", ["服飾"]), (" \n\t ", [])])
    func addCategory_名稱含空白或為空_移除空白並略過空名稱(rawName: String, expectedNames: [String]) async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())

        // When
        try await service.addCategory(rawName)

        // Then
        let categories = try await service.fetchCategories()
        #expect(categories == expectedNames)
    }

    /// 重複加入同名商品類別不會出錯，讀回仍只有一筆記錄
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func addCategory_名稱已存在_不新增重複記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addCategory("重複項目")

        // When
        try await service.addCategory("重複項目")

        // Then
        let categories = try await service.fetchCategories()
        #expect(categories == ["重複項目"])
    }

    /// 刪除符合名稱的商品類別，只移除該筆，其他類別保留
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeCategory_名稱相符_刪除該筆記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addCategory("保留項目")
        try await service.addCategory("待刪項目")

        // When
        try await service.removeCategory("待刪項目")

        // Then
        let categories = try await service.fetchCategories()
        #expect(categories == ["保留項目"])
    }

    /// 刪除不存在的商品類別不會出錯，既有類別維持不變
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeCategory_名稱不存在_保留既有記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addCategory("保留項目")

        // When
        try await service.removeCategory("不存在的項目")

        // Then
        let categories = try await service.fetchCategories()
        #expect(categories == ["保留項目"])
    }
}

// MARK: - Private Method

private extension CategoryServiceTests {

    /// 以注入的資料庫建立正式 `CategoryService`
    ///
    /// - Parameter database: 要提供給 Service 的資料庫
    /// - Returns: 已擷取資料庫依賴的 `CategoryService`
    static func makeService(database: any BuyLedgerDatabaseProtocol) -> CategoryService {
        withDependencies {
            $0.buyLedgerDatabase = database
        } operation: {
            CategoryService.liveValue
        }
    }
}
