//
//  LookupServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// 驗證主檔 Service 的持久化行為
struct LookupServiceTests {

    /// 讀取商品類別時依自然語言順序排序，數字依大小比較 (`Record 2` 排在 `Record 10` 前)
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func fetchItems_類別多種名稱_依自然語言順序排序() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        try await service.addItem(.category, LookupItemAddition(name: "Record 10", flags: .none))
        try await service.addItem(.category, LookupItemAddition(name: "Record 2", flags: .none))
        try await service.addItem(.category, LookupItemAddition(name: "Record 1", flags: .none))

        // When
        let categories = try await service.fetchItems(.category).categories

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
    func addItem_類別名稱含空白或為空_移除空白並略過空名稱(rawName: String, expectedNames: [String]) async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())

        // When
        try await service.addItem(.category, LookupItemAddition(name: rawName, flags: .none))

        // Then
        let categories = try await service.fetchItems(.category).categories
        #expect(categories == expectedNames)
    }

    /// 重複加入同名商品類別不會出錯，讀回仍只有一筆記錄
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func addItem_類別名稱已存在_不新增重複記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addItem(.category, LookupItemAddition(name: "重複項目", flags: .none))

        // When
        try await service.addItem(.category, LookupItemAddition(name: "重複項目", flags: .none))

        // Then
        let categories = try await service.fetchItems(.category).categories
        #expect(categories == ["重複項目"])
    }

    /// 刪除符合名稱的商品類別，只移除該筆，其他類別保留
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeItem_類別名稱相符_刪除該筆記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addItem(.category, LookupItemAddition(name: "保留項目", flags: .none))
        try await service.addItem(.category, LookupItemAddition(name: "待刪項目", flags: .none))

        // When
        try await service.removeItem(.category, "待刪項目")

        // Then
        let categories = try await service.fetchItems(.category).categories
        #expect(categories == ["保留項目"])
    }

    /// 刪除不存在的商品類別不會出錯，既有類別維持不變
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeItem_類別名稱不存在_保留既有記錄() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.addItem(.category, LookupItemAddition(name: "保留項目", flags: .none))

        // When
        try await service.removeItem(.category, "不存在的項目")

        // Then
        let categories = try await service.fetchItems(.category).categories
        #expect(categories == ["保留項目"])
    }

    /// 讀取一種主檔時只填入該種類，其他種類維持空目錄
    ///
    /// - Parameter kind: 要讀取的主檔種類
    /// - Throws: 資料庫讀寫失敗時丟出 `PersistenceError`
    @Test(arguments: LookupKind.allCases)
    func fetchItems_指定一種主檔_只填入該種類的目錄(kind: LookupKind) async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        for kind in LookupKind.allCases {
            try await service.addItem(kind, LookupItemAddition(name: "項目", flags: .none))
        }
        let expected: LookupCatalog
        switch kind {
        case .orderSource:
            expected = LookupCatalog(orderSources: ["項目"])

        case .category:
            expected = LookupCatalog(categories: ["項目"])

        case .paymentMethod:
            expected = LookupCatalog(paymentMethods: [PaymentMethodInfo(name: "項目", flags: .none)])

        case .reconciliationStatus:
            expected = LookupCatalog(reconciliationStatuses: ["項目"])
        }

        // When
        let catalog = try await service.fetchItems(kind)

        // Then
        #expect(catalog == expected)
    }
}

// MARK: - Internal Method

extension LookupServiceTests {

    /// 以注入的資料庫建立正式主檔 Service
    ///
    /// - Parameter database: 要提供給 Service 的資料庫
    /// - Returns: 已擷取資料庫依賴的主檔 Service
    static func makeService(database: any BuyLedgerDatabaseProtocol) -> LookupService {
        withDependencies {
            $0.buyLedgerDatabase = database
        } operation: {
            LookupService.liveValue
        }
    }
}
