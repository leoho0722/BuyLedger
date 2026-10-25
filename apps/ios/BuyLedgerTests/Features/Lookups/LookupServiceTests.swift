//
//  LookupServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Testing

@testable import BuyLedger

/// `LookupService` 的單元測試，以記憶體內資料庫檢查主檔的讀寫與持久化行為
struct LookupServiceTests {

    /// 驗證商品類別名稱含數字時，讀取結果依自然語言順序排序，數字按大小比較，Record 2 排在 Record 10 之前
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func fetchItems_類別多種名稱_依自然語言順序排序() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = LookupServiceTestSupport.makeService(database: database)
        try await service.addItem(.category, LookupItemAddition(name: "Record 10", flags: .none))
        try await service.addItem(.category, LookupItemAddition(name: "Record 2", flags: .none))
        try await service.addItem(.category, LookupItemAddition(name: "Record 1", flags: .none))

        // When
        let categories = try await service.fetchItems(.category).categories

        // Then
        #expect(categories == ["Record 1", "Record 2", "Record 10"])
    }

    /// 驗證加入商品類別時，名稱先去除前後空白再儲存，只含空白、換行或定位字元的名稱不建立記錄
    ///
    /// - Parameter scenario: 尚未正規化的類別名稱與預期讀回的名稱
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test(arguments: [
        RawNameScenario(rawName: "  服飾  ", expectedNames: ["服飾"]),
        RawNameScenario(rawName: " \n\t ", expectedNames: []),
    ])
    func addItem_類別名稱含空白或為空_移除空白並略過空名稱(scenario: RawNameScenario) async throws {
        // Given
        let service = LookupServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )

        // When
        try await service.addItem(
            .category,
            LookupItemAddition(name: scenario.rawName, flags: .none)
        )

        // Then
        let categories = try await service.fetchItems(.category).categories
        #expect(categories == scenario.expectedNames)
    }

    /// 驗證重複加入同名商品類別時不丟錯，讀回仍只有一筆記錄
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func addItem_類別名稱已存在_不新增重複記錄() async throws {
        // Given
        let service = LookupServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )
        try await service.addItem(.category, LookupItemAddition(name: "重複項目", flags: .none))

        // When
        try await service.addItem(.category, LookupItemAddition(name: "重複項目", flags: .none))

        // Then
        let categories = try await service.fetchItems(.category).categories
        #expect(categories == ["重複項目"])
    }

    /// 驗證 `removeItem` 只移除名稱相符的商品類別，其他類別保留
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeItem_類別名稱相符_刪除該筆記錄() async throws {
        // Given
        let service = LookupServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )
        try await service.addItem(.category, LookupItemAddition(name: "保留項目", flags: .none))
        try await service.addItem(.category, LookupItemAddition(name: "待刪項目", flags: .none))

        // When
        try await service.removeItem(.category, "待刪項目")

        // Then
        let categories = try await service.fetchItems(.category).categories
        #expect(categories == ["保留項目"])
    }

    /// 驗證刪除不存在的名稱時不丟錯，既有的商品類別維持不變
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeItem_類別名稱不存在_保留既有記錄() async throws {
        // Given
        let service = LookupServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )
        try await service.addItem(.category, LookupItemAddition(name: "保留項目", flags: .none))

        // When
        try await service.removeItem(.category, "不存在的項目")

        // Then
        let categories = try await service.fetchItems(.category).categories
        #expect(categories == ["保留項目"])
    }

    /// 驗證讀取任一種類的主檔時，回傳的目錄只含該種類的項目，其他種類為空
    ///
    /// - Parameter kind: 要讀取的主檔種類
    /// - Throws: 資料庫讀寫失敗時丟出 `PersistenceError`
    @Test(arguments: LookupKind.allCases)
    func fetchItems_指定一種主檔_只填入該種類的目錄(kind: LookupKind) async throws {
        // Given
        let service = LookupServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )
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

// MARK: - Nested Types

extension LookupServiceTests {

    /// `addItem` 名稱正規化測試的參數案例，帶入原始名稱與預期讀回的名稱
    struct RawNameScenario: Sendable {

        /// 尚未正規化的名稱
        let rawName: String

        /// 預期讀回的名稱
        let expectedNames: [String]
    }
}
