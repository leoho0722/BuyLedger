//
//  LookupServiceRenameNoOpsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// `LookupService` 的單元測試，涵蓋主檔改名目標空白或未變更時不寫入，以及改名後保留訂單照片
struct LookupServiceRenameNoOpsTests {

    /// 驗證四種主檔改名收到只含空白與換行的目標名稱時，不開寫入交易，主檔與訂單都維持原樣
    ///
    /// - Parameter operation: 要測試的 `LookupRenameOperation` 案例
    /// - Throws: fixture 寫入或資料庫讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test(arguments: LookupRenameOperation.allCases)
    func normalizedRenameTarget_目標名稱為空白_不開交易且保留所有資料(operation: LookupRenameOperation) async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let fixture = try await Self.seedRenameFixture(in: database)
        let beforeNames = try await Self.fetchRenameMasterNames(from: database)
        try #require(beforeNames == [["舊名稱"], ["舊名稱"], ["舊名稱"], ["舊名稱"]])
        let beforeOrder = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: fixture.id, from: database)
        )
        try #require(beforeOrder.orderSource == "舊名稱")
        try #require(beforeOrder.categories == ["舊名稱"])
        try #require(beforeOrder.paymentMethod == "舊名稱")
        try #require(beforeOrder.reconciliationStatus == "舊名稱")
        try #require(beforeOrder.campaignNames == ["舊名稱"])
        let mock = MockBuyLedgerDatabase(database: database)
        let lookupService = LookupServiceTestSupport.makeService(database: mock)

        // When
        try await Self.applyRename(
            operation,
            oldName: "舊名稱",
            newName: "  \n ",
            lookupService: lookupService
        )

        // Then
        #expect(mock.writeCallCount == 0)
        let afterNames = try await Self.fetchRenameMasterNames(from: database)
        #expect(afterNames == [["舊名稱"], ["舊名稱"], ["舊名稱"], ["舊名稱"]])
        let afterOrder = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: fixture.id, from: database)
        )
        #expect(afterOrder == fixture)
    }

    /// 驗證四種主檔改名收到與原名稱相同的目標時，即使前後有空白也不開寫入交易，主檔與訂單都維持原樣
    ///
    /// - Parameter operation: 要測試的 `LookupRenameOperation` 案例
    /// - Throws: fixture 寫入或資料庫讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test(arguments: LookupRenameOperation.allCases)
    func normalizedRenameTarget_目標名稱未變_不開交易且保留所有資料(operation: LookupRenameOperation) async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let fixture = try await Self.seedRenameFixture(in: database)
        let beforeNames = try await Self.fetchRenameMasterNames(from: database)
        try #require(beforeNames == [["舊名稱"], ["舊名稱"], ["舊名稱"], ["舊名稱"]])
        let beforeOrder = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: fixture.id, from: database)
        )
        try #require(beforeOrder.orderSource == "舊名稱")
        try #require(beforeOrder.categories == ["舊名稱"])
        try #require(beforeOrder.paymentMethod == "舊名稱")
        try #require(beforeOrder.reconciliationStatus == "舊名稱")
        try #require(beforeOrder.campaignNames == ["舊名稱"])
        let mock = MockBuyLedgerDatabase(database: database)
        let lookupService = LookupServiceTestSupport.makeService(database: mock)

        // When
        try await Self.applyRename(
            operation,
            oldName: "舊名稱",
            newName: " 舊名稱 ",
            lookupService: lookupService
        )

        // Then
        #expect(mock.writeCallCount == 0)
        let afterNames = try await Self.fetchRenameMasterNames(from: database)
        #expect(afterNames == [["舊名稱"], ["舊名稱"], ["舊名稱"], ["舊名稱"]])
        let afterOrder = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: fixture.id, from: database)
        )
        #expect(afterOrder == fixture)
    }

    /// 驗證四種主檔改名交易中，只有對應的訂單欄位改為新名稱，其餘欄位與照片保持不變
    ///
    /// - Parameter operation: 要測試的 `LookupRenameOperation` 案例
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   未讀回改名後的訂單時由 `#require` 丟出測試斷言錯誤
    @Test(arguments: LookupRenameOperation.allCases)
    func renameItem_四種主檔改名交易_照片保持不變(operation: LookupRenameOperation) async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
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
        try await OrderServiceTestSupport.seed(
            [order],
            categories: ["舊名稱"],
            paymentMethods: [payment],
            database: database
        )
        try await database.write { context throws(PersistenceError) in
            context.insert(OrderSourceRecord(name: "舊名稱"))
            context.insert(ReconciliationStatusRecord(name: "舊名稱"))
        }
        let lookupService = LookupServiceTestSupport.makeService(database: database)

        // When
        try await Self.applyRename(
            operation,
            oldName: "舊名稱",
            newName: "新名稱",
            lookupService: lookupService
        )

        // Then
        let stored = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: order.id, from: database)
        )
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
        }
        #expect(stored == expected)
        #expect(stored.photos == [photo])
    }
}

// MARK: - Nested Types

extension LookupServiceRenameNoOpsTests {

    /// 四種主檔改名入口的列舉，供參數化測試逐一執行
    enum LookupRenameOperation: CaseIterable, Sendable {

        /// 訂單來源改名
        case orderSource

        /// 商品類別改名
        case category

        /// 付款方式改名
        case paymentMethod

        /// 對帳狀態改名
        case reconciliationStatus
    }
}

// MARK: - Private Method

private extension LookupServiceRenameNoOpsTests {

    /// 為目標空白與未變更的改名測試建立資料
    ///
    /// - Parameter database: 要寫入 fixture 的資料庫
    /// - Returns: 已寫入的訂單，作為改名前後比對的基準
    /// - Throws: 寫入失敗時丟出 `.saveFailed(underlying:)`
    static func seedRenameFixture(
        in database: BuyLedgerDatabase
    ) async throws(PersistenceError) -> LedgerOrder {
        let order = LedgerOrder.fixture(
            id: "ORDER-RENAME-NOOP",
            orderSource: "舊名稱",
            categories: ["舊名稱"],
            paymentMethod: "舊名稱",
            reconciliationStatus: "舊名稱",
            campaignNames: ["舊名稱"],
            photos: [Data([0xA0, 0xA1])]
        )
        try await OrderServiceTestSupport.seed(
            [order],
            categories: ["舊名稱"],
            paymentMethods: [PaymentMethodInfo(name: "舊名稱", flags: .none)],
            database: database
        )
        try await database.write { context throws(PersistenceError) in
            context.insert(OrderSourceRecord(name: "舊名稱"))
            context.insert(ReconciliationStatusRecord(name: "舊名稱"))
        }
        return order
    }

    /// 以固定順序讀取四種查詢主檔名稱
    ///
    /// - Parameter database: 要讀取主檔的資料庫
    /// - Returns: 類別、付款方式、訂單來源、對帳狀態的名稱陣列
    /// - Throws: 查詢失敗時丟出 `.fetchFailed(underlying:)`
    static func fetchRenameMasterNames(
        from database: any BuyLedgerDatabaseProtocol
    ) async throws(PersistenceError) -> [[String]] {
        try await database.read { context throws(PersistenceError) in
            let categories = try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<CategoryRecord>()).map(\.name).sorted()
            }
            let paymentMethods = try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<PaymentMethodRecord>()).map(\.name).sorted()
            }
            let orderSources = try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<OrderSourceRecord>()).map(\.name).sorted()
            }
            let reconciliationStatuses = try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<ReconciliationStatusRecord>())
                    .map(\.name)
                    .sorted()
            }
            return [categories, paymentMethods, orderSources, reconciliationStatuses]
        }
    }

    /// 依選擇的 `LookupRenameOperation` 執行改名
    ///
    /// - Parameters:
    ///   - operation: 要執行的 `LookupRenameOperation` 案例
    ///   - oldName: 原本的名稱
    ///   - newName: 尚未去除前後空白的新名稱
    ///   - lookupService: 主檔改名使用的 Service
    /// - Throws: 查詢失敗時丟出 `.fetchFailed(underlying:)`；儲存失敗時丟出 `.saveFailed(underlying:)`
    static func applyRename(
        _ operation: LookupRenameOperation,
        oldName: String,
        newName: String,
        lookupService: LookupService
    ) async throws(PersistenceError) {
        switch operation {
        case .orderSource:
            try await lookupService.renameItem(
                .orderSource,
                LookupItemRename(oldName: oldName, newName: newName)
            )

        case .category:
            try await lookupService.renameItem(
                .category,
                LookupItemRename(oldName: oldName, newName: newName)
            )

        case .paymentMethod:
            try await lookupService.renameItem(
                .paymentMethod,
                LookupItemRename(oldName: oldName, newName: newName)
            )

        case .reconciliationStatus:
            try await lookupService.renameItem(
                .reconciliationStatus,
                LookupItemRename(oldName: oldName, newName: newName)
            )
        }
    }
}
