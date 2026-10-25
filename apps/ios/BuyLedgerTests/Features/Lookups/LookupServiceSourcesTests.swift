//
//  LookupServiceSourcesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Testing

@testable import BuyLedger

/// `LookupService` 的單元測試，涵蓋訂單來源主檔，以記憶體內資料庫逐項驗證讀取排序、新增與刪除
struct LookupServiceSourcesTests {

    /// 驗證訂單來源名稱含數字時，讀取結果依自然語言順序排序，Record 2 排在 Record 10 之前
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func fetchItems_訂單來源多種名稱_依自然語言順序排序() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = LookupServiceTestSupport.makeService(database: database)
        try await service.addItem(.orderSource, LookupItemAddition(name: "Record 10", flags: .none))
        try await service.addItem(.orderSource, LookupItemAddition(name: "Record 2", flags: .none))
        try await service.addItem(.orderSource, LookupItemAddition(name: "Record 1", flags: .none))

        // When
        let orderSources = try await service.fetchItems(.orderSource).orderSources

        // Then
        #expect(orderSources == ["Record 1", "Record 2", "Record 10"])
    }

    /// 驗證加入訂單來源時，名稱前後的空白會被移除，只含空白與換行的名稱不寫入
    ///
    /// - Parameter scenario: 尚未正規化的訂單來源名稱與預期讀回的名稱
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test(arguments: [
        RawNameScenario(rawName: "  網路商店  ", expectedNames: ["網路商店"]),
        RawNameScenario(rawName: " \n\t ", expectedNames: []),
    ])
    func addItem_訂單來源輸入含空白或為空_移除空白並略過空名稱(scenario: RawNameScenario) async throws {
        // Given
        let service = LookupServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )

        // When
        try await service.addItem(
            .orderSource,
            LookupItemAddition(name: scenario.rawName, flags: .none)
        )

        // Then
        let orderSources = try await service.fetchItems(.orderSource).orderSources
        #expect(orderSources == scenario.expectedNames)
    }

    /// 驗證加入同名的訂單來源時，只保留一筆記錄，不建立第二筆
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func addItem_訂單來源名稱已存在_不新增重複記錄() async throws {
        // Given
        let service = LookupServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )
        try await service.addItem(.orderSource, LookupItemAddition(name: "重複項目", flags: .none))

        // When
        try await service.addItem(.orderSource, LookupItemAddition(name: "重複項目", flags: .none))

        // Then
        let orderSources = try await service.fetchItems(.orderSource).orderSources
        #expect(orderSources == ["重複項目"])
    }

    /// 驗證 `removeItem` 依名稱刪除相符的訂單來源，同時保留其他項目
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeItem_訂單來源名稱相符_刪除該筆記錄() async throws {
        // Given
        let service = LookupServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )
        try await service.addItem(.orderSource, LookupItemAddition(name: "保留項目", flags: .none))
        try await service.addItem(.orderSource, LookupItemAddition(name: "待刪項目", flags: .none))

        // When
        try await service.removeItem(.orderSource, "待刪項目")

        // Then
        let orderSources = try await service.fetchItems(.orderSource).orderSources
        #expect(orderSources == ["保留項目"])
    }

    /// 驗證刪除不存在的名稱時不丟錯，既有的訂單來源原樣保留
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeItem_訂單來源名稱不存在_保留既有記錄() async throws {
        // Given
        let service = LookupServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )
        try await service.addItem(.orderSource, LookupItemAddition(name: "保留項目", flags: .none))

        // When
        try await service.removeItem(.orderSource, "不存在的項目")

        // Then
        let orderSources = try await service.fetchItems(.orderSource).orderSources
        #expect(orderSources == ["保留項目"])
    }
}

// MARK: - Nested Types

extension LookupServiceSourcesTests {

    /// `addItem` 名稱正規化測試的參數案例，帶入原始名稱與預期讀回的名稱
    struct RawNameScenario: Sendable {

        /// 尚未正規化的名稱
        let rawName: String

        /// 預期讀回的名稱
        let expectedNames: [String]
    }
}
