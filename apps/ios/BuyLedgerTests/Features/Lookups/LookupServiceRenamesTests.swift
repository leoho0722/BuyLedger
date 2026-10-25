//
//  LookupServiceRenamesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// `LookupService` 的單元測試，涵蓋主檔改名，以記憶體內資料庫檢查四種主檔改名時合併主檔與更新訂單引用
struct LookupServiceRenamesTests {

    /// 驗證多筆訂單引用舊類別時，主檔合併為新名稱，訂單類別陣列中的舊值 (含重複的) 全部改為新名稱，其他類別維持不變
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   前置訂單資料不符或未讀回改名後的訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameItem_多筆訂單引用舊類別_合併主檔並更新所有引用() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let source = OrderServiceTestSupport.makeOrder(
            id: "ORDER-CATEGORY-SOURCE",
            categories: ["服飾", "配件", "服飾"]
        )
        let secondSource = OrderServiceTestSupport.makeOrder(
            id: "ORDER-CATEGORY-SECOND",
            categories: ["服飾"]
        )
        let target = OrderServiceTestSupport.makeOrder(
            id: "ORDER-CATEGORY-TARGET",
            categories: ["衣著"]
        )
        try await OrderServiceTestSupport.seed(
            [source, secondSource, target],
            categories: ["服飾", "衣著"],
            database: database
        )
        let orderService = OrderServiceTestSupport.makeService(database: database)
        let lookupService = LookupServiceTestSupport.makeService(database: database)
        let ordersBeforeRename = try await orderService.fetchOrders()
        try #require(
            ordersBeforeRename.first { $0.id == source.id }?.categories == ["服飾", "配件", "服飾"]
        )

        // When
        try await lookupService.renameItem(
            .category,
            LookupItemRename(oldName: "服飾", newName: "衣著")
        )

        // Then
        let orders = try await orderService.fetchOrders()
        let categories = try await database.read { context throws(PersistenceError) in
            try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<CategoryRecord>()).map(\.name)
            }
        }
        let categoriesByID = Dictionary(uniqueKeysWithValues: orders.map { ($0.id, $0.categories) })
        #expect(categories.sorted() == ["衣著"])
        #expect(categoriesByID[source.id] == ["衣著", "配件", "衣著"])
        #expect(categoriesByID[secondSource.id] == ["衣著"])
        #expect(categoriesByID[target.id] == ["衣著"])
    }

    /// 驗證改名的目標類別原本不存在時，主檔的舊名稱換成新名稱，訂單的類別也改為新名稱
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   未讀回改名後的訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameItem_目標類別不存在_新增主檔並更新訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let order = OrderServiceTestSupport.makeOrder(
            id: "ORDER-CATEGORY-MISSING",
            categories: ["服飾"]
        )
        try await OrderServiceTestSupport.seed([order], categories: ["服飾"], database: database)
        let lookupService = LookupServiceTestSupport.makeService(database: database)

        // When
        try await lookupService.renameItem(
            .category,
            LookupItemRename(oldName: "服飾", newName: "衣著")
        )

        // Then
        let categories = try await database.read { context throws(PersistenceError) in
            try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<CategoryRecord>()).map(\.name)
            }
        }
        #expect(categories.sorted() == ["衣著"])
        let stored = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: order.id, from: database)
        )
        #expect(stored.categories == ["衣著"])
    }

    /// 驗證訂單來源改名為已存在的名稱時，主檔的舊項目併入新名稱，訂單來源也改為新名稱
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   未讀回改名後的訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameItem_訂單來源改名成功_同步更新主檔與訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let order = LedgerOrder.fixture(id: "ORDER-SOURCE", orderSource: "舊來源")
        try await OrderServiceTestSupport.seed([order], database: database)
        try await database.write { context throws(PersistenceError) in
            context.insert(OrderSourceRecord(name: "舊來源"))
            context.insert(OrderSourceRecord(name: "新來源"))
        }
        let lookupService = LookupServiceTestSupport.makeService(database: database)

        // When
        try await lookupService.renameItem(
            .orderSource,
            LookupItemRename(oldName: "舊來源", newName: "新來源")
        )

        // Then
        let names = try await database.read { context throws(PersistenceError) in
            try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<OrderSourceRecord>()).map(\.name)
            }
        }
        #expect(names.sorted() == ["新來源"])
        let stored = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: order.id, from: database)
        )
        #expect(stored.orderSource == "新來源")
    }

    /// 驗證付款方式改名與既有項目同名時，以資料庫當下的來源旗標與目標旗標做 OR 合併，並改寫引用的訂單
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   未取得來源付款方式旗標或未讀回改名後的訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameItem_付款方式名稱衝突_合併旗標並更新訂單() async throws {
        // Given
        let modelContainer = TestContainerCreationLock.withLock {
            PersistenceContainer.makeInMemory(for: .testing)
        }
        let database = BuyLedgerDatabase(modelContainer: modelContainer, storeLocation: .inMemory)
        let externalWriter = BuyLedgerDatabase(
            modelContainer: modelContainer,
            storeLocation: .inMemory
        )
        let source = PaymentMethodInfo(name: "匯款", flags: .none)
        let target = PaymentMethodInfo(
            name: "orders.edit.label.bankTransfer",
            flags: PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            )
        )
        let order = LedgerOrder.fixture(id: "ORDER-PAYMENT", paymentMethod: "匯款")
        try await OrderServiceTestSupport.seed(
            [order],
            paymentMethods: [source, target],
            database: database
        )
        let lookupService = LookupServiceTestSupport.makeService(database: database)
        let priorFlags = try await database.read { context throws(PersistenceError) in
            try PersistenceError.mapFetch {
                try context.fetch(
                    FetchDescriptor<PaymentMethodRecord>(
                        predicate: #Predicate {
                            $0.name == "匯款"
                        }
                    )
                ).first.map {
                    PaymentMethodFlags(
                        isCardless: $0.isCardless,
                        isBankTransfer: $0.isBankTransfer,
                        isCashOnDelivery: $0.isCashOnDelivery
                    )
                }
            }
        }
        let sourceFlags = try #require(priorFlags)
        try #require(sourceFlags == PaymentMethodFlags.none)
        try await externalWriter.write { context throws(PersistenceError) in
            let sourceRecord = try PersistenceError.mapFetch {
                try context.fetch(
                    FetchDescriptor<PaymentMethodRecord>(
                        predicate: #Predicate {
                            $0.name == "匯款"
                        }
                    )
                ).first
            }
            guard let sourceRecord else {
                throw .fetchFailed(
                    underlying: NSError(domain: "MissingSourcePaymentMethod", code: 1)
                )
            }
            sourceRecord.isCardless = true
        }

        // When
        try await lookupService.renameItem(
            .paymentMethod,
            LookupItemRename(oldName: "匯款", newName: "orders.edit.label.bankTransfer")
        )

        // Then
        let methods = try await database.read { context throws(PersistenceError) in
            try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<PaymentMethodRecord>()).map {
                    PaymentMethodInfo(
                        name: $0.name,
                        flags: PaymentMethodFlags(
                            isCardless: $0.isCardless,
                            isBankTransfer: $0.isBankTransfer,
                            isCashOnDelivery: $0.isCashOnDelivery
                        )
                    )
                }
            }
        }
        #expect(
            methods == [
                PaymentMethodInfo(
                    name: "orders.edit.label.bankTransfer",
                    flags: PaymentMethodFlags(
                        isCardless: true,
                        isBankTransfer: true,
                        isCashOnDelivery: false
                    )
                ),
            ]
        )
        let stored = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: order.id, from: database)
        )
        #expect(stored.paymentMethod == "orders.edit.label.bankTransfer")
    }

    /// 驗證對帳狀態改名為已存在的名稱時，主檔的舊項目併入目標名稱，訂單的對帳狀態也改為目標名稱
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   未讀回改名後的訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameItem_對帳狀態改名成功_同步更新主檔與訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let order = LedgerOrder.fixture(id: "ORDER-RECONCILIATION", reconciliationStatus: "待對帳")
        try await OrderServiceTestSupport.seed([order], database: database)
        try await database.write { context throws(PersistenceError) in
            context.insert(ReconciliationStatusRecord(name: "待對帳"))
            context.insert(ReconciliationStatusRecord(name: "orders.detail.label.confirmed"))
        }
        let lookupService = LookupServiceTestSupport.makeService(database: database)

        // When
        try await lookupService.renameItem(
            .reconciliationStatus,
            LookupItemRename(oldName: "待對帳", newName: "orders.detail.label.confirmed")
        )

        // Then
        let names = try await database.read { context throws(PersistenceError) in
            try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<ReconciliationStatusRecord>()).map(\.name)
            }
        }
        #expect(names.sorted() == ["orders.detail.label.confirmed"])
        let stored = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: order.id, from: database)
        )
        #expect(stored.reconciliationStatus == "orders.detail.label.confirmed")
    }
}
