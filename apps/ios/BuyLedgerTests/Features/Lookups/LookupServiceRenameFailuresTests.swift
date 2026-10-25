//
//  LookupServiceRenameFailuresTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// `LookupService` 的單元測試，涵蓋改名失敗路徑，以磁碟 store 搭配 Mock 資料庫模擬寫入與查詢失敗，確認主檔與訂單維持原值
struct LookupServiceRenameFailuresTests {

    /// 驗證改名交易內容寫入後 save 失敗時，`renameItem` 丟出 `saveFailed`，主檔與訂單維持原值，無論改名前是否已有目標類別
    ///
    /// - Parameter hasExistingTarget: 改名前是否已有目標類別
    /// - Throws: fixture 建立時丟出底層檔案或 SwiftData 錯誤；未取得改名錯誤
    ///   或未讀回來源訂單時由 `#require` 丟出測試斷言錯誤；
    ///   讀取失敗時丟出 `.fetchFailed(underlying:)`
    @Test(arguments: [false, true])
    func renameItem_真實儲存失敗_主檔與訂單維持原值(hasExistingTarget: Bool) async throws {
        // Given
        let fixture = try Self.makeRenameFixture(hasExistingTarget: hasExistingTarget)
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTestSupport.makeDatabase(with: fixture)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .saveFailureAfterBody
        let orderService = OrderServiceTestSupport.makeService(database: mock)
        let lookupService = LookupServiceTestSupport.makeService(database: mock)
        let originalNames = hasExistingTarget ? ["服飾", "衣著"] : ["服飾"]
        let originalOrders = hasExistingTarget
            ? ["ORDER-RENAME-SOURCE": ["服飾"], "ORDER-RENAME-TARGET": ["衣著"]]
            : ["ORDER-RENAME-SOURCE": ["服飾"]]
        var actualError: PersistenceError?

        // When
        do {
            try await lookupService.renameItem(
                .category,
                LookupItemRename(oldName: "服飾", newName: "衣著")
            )
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let isSaveFailure: Bool
        switch error {
        case .saveFailed:
            isSaveFailure = true

        case .fetchFailed, .containerCreationFailed:
            isSaveFailure = false
        }
        #expect(isSaveFailure)
        let names = try await database.read { context throws(PersistenceError) in
            try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<CategoryRecord>()).map(\.name).sorted()
            }
        }
        let orders = try await orderService.fetchOrders()
        #expect(names == originalNames.sorted())
        for (id, categories) in originalOrders {
            let stored = try #require(orders.first { $0.id == id })
            #expect(stored.categories == categories)
        }
    }

    /// 驗證改名寫入失敗後，同一資料庫仍能建立新訂單，且新訂單沒有類別，無論改名前是否已有目標類別
    ///
    /// - Parameter hasExistingTarget: 改名前是否已有目標類別
    /// - Throws: fixture 建立時丟出底層檔案或 SwiftData 錯誤；建立後續訂單時以 `OrderError` 丟出
    ///   `.identifierCollision(id:)`、`.storage(.fetchFailed(underlying:))` 或
    ///   `.storage(.saveFailed(underlying:))`；未讀回後續訂單時由 `#require` 丟出測試斷言錯誤
    @Test(arguments: [false, true])
    func renameItem_真實儲存失敗_之後仍可建立訂單(hasExistingTarget: Bool) async throws {
        // Given
        let fixture = try Self.makeRenameFixture(hasExistingTarget: hasExistingTarget)
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTestSupport.makeDatabase(with: fixture)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .saveFailureAfterBody
        let orderService = OrderServiceTestSupport.makeService(database: mock)
        let lookupService = LookupServiceTestSupport.makeService(database: mock)
        let renameResult: Void? = try? await lookupService.renameItem(  // 失敗可忽略，因為稍後會確認改名失敗
            .category,
            LookupItemRename(oldName: "服飾", newName: "衣著")
        )
        try #require(renameResult == nil)
        mock.mode = .passthrough
        let followup = OrderServiceTestSupport.makeOrder(id: "ORDER-RENAME-FOLLOWUP")

        // When
        try await orderService.createOrder(followup)

        // Then
        let orders = try await orderService.fetchOrders()
        let storedFollowup = try #require(orders.first { $0.id == followup.id })
        #expect(storedFollowup.categories.isEmpty)
    }

    /// 驗證改名交易主體執行完成後才注入查詢錯誤時，`renameItem` 丟出 `fetchFailed`，主檔與來源訂單都維持原值
    ///
    /// - Throws: fixture 建立時丟出底層檔案或 SwiftData 錯誤；未取得改名錯誤、錯誤不是
    ///   `.fetchFailed(underlying:)` 或未讀回來源訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameItem_寫入後注入查詢錯誤_丟出查詢失敗並保留原資料() async throws {
        // Given
        let fixture = try Self.makeRenameFixture(hasExistingTarget: false)
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTestSupport.makeDatabase(with: fixture)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .writeFailureAfterBody(
            error: PersistenceError.fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(
                    message: "lookup rename fetch failed"
                )
            )
        )
        let orderService = OrderServiceTestSupport.makeService(database: mock)
        let lookupService = LookupServiceTestSupport.makeService(database: mock)
        var actualError: PersistenceError?

        // When
        do {
            try await lookupService.renameItem(
                .category,
                LookupItemRename(oldName: "服飾", newName: "衣著")
            )
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let actualFetchFailure: (any Error)?
        switch error {
        case .fetchFailed(let underlying):
            actualFetchFailure = underlying

        case .saveFailed, .containerCreationFailed:
            actualFetchFailure = nil
        }
        let fetchFailure = try #require(actualFetchFailure)
        #expect(fetchFailure.localizedDescription == "lookup rename fetch failed")
        let names = try await database.read { context throws(PersistenceError) in
            try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<CategoryRecord>()).map(\.name)
            }
        }
        let orders = try await orderService.fetchOrders()
        #expect(names == ["服飾"])
        let source = try #require(orders.first { $0.id == "ORDER-RENAME-SOURCE" })
        #expect(source.categories == ["服飾"])
    }

    /// 驗證改名交易主體執行後注入查詢錯誤，之後同一資料庫仍能建立新訂單，且該訂單出現在清單中
    ///
    /// - Throws: fixture 建立時丟出底層檔案或 SwiftData 錯誤；建立後續訂單時以 `OrderError` 丟出
    ///   `.identifierCollision(id:)`、`.storage(.fetchFailed(underlying:))` 或
    ///   `.storage(.saveFailed(underlying:))`
    @Test
    func renameItem_寫入後注入查詢錯誤_之後同資料庫仍可建立訂單() async throws {
        // Given
        let fixture = try Self.makeRenameFixture(hasExistingTarget: false)
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTestSupport.makeDatabase(with: fixture)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .writeFailureAfterBody(
            error: PersistenceError.fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(
                    message: "lookup rename fetch failed"
                )
            )
        )
        let orderService = OrderServiceTestSupport.makeService(database: mock)
        let lookupService = LookupServiceTestSupport.makeService(database: mock)
        let renameResult: Void? = try? await lookupService.renameItem(  // 失敗可忽略，因為稍後會確認改名失敗
            .category,
            LookupItemRename(oldName: "服飾", newName: "衣著")
        )
        try #require(renameResult == nil)
        mock.mode = .passthrough
        let followup = OrderServiceTestSupport.makeOrder(id: "ORDER-LOOKUP-FAIL-FOLLOWUP")

        // When
        try await orderService.createOrder(followup)

        // Then
        let orders = try await orderService.fetchOrders()
        #expect(orders.contains { $0.id == followup.id })
    }
}

// MARK: - Private Method

private extension LookupServiceRenameFailuresTests {

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
