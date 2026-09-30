//
//  OrderServiceTests+Renames.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

// MARK: - Tests

extension OrderServiceTests {

    /// 類別改名合併主檔並更新所有訂單陣列中的舊值
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   前置訂單資料不符或未讀回改名後的訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func applyCategoryRename_多筆訂單引用舊類別_合併主檔並更新所有引用() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let source = Self.makeOrder(id: "ORDER-CATEGORY-SOURCE", categories: ["服飾", "配件", "服飾"])
        let secondSource = Self.makeOrder(id: "ORDER-CATEGORY-SECOND", categories: ["服飾"])
        let target = Self.makeOrder(id: "ORDER-CATEGORY-TARGET", categories: ["衣著"])
        try await Self.seed(
            [source, secondSource, target],
            categories: ["服飾", "衣著"],
            database: database
        )
        let service = Self.makeService(database: database)
        let ordersBeforeRename = try await service.fetchOrders()
        try #require(
            ordersBeforeRename.first { $0.id == source.id }?.categories == ["服飾", "配件", "服飾"]
        )

        // When
        try await service.applyCategoryRename("服飾", "衣著")

        // Then
        let orders = try await service.fetchOrders()
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

    /// 類別改名目標不存在時會新增主檔並更新訂單
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   未讀回改名後的訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func applyCategoryRename_目標類別不存在_新增主檔並更新訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let order = Self.makeOrder(id: "ORDER-CATEGORY-MISSING", categories: ["服飾"])
        try await Self.seed([order], categories: ["服飾"], database: database)
        let service = Self.makeService(database: database)

        // When
        try await service.applyCategoryRename("服飾", "衣著")

        // Then
        let categories = try await database.read { context throws(PersistenceError) in
            try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<CategoryRecord>()).map(\.name)
            }
        }
        #expect(categories.sorted() == ["衣著"])
        let stored = try #require(try await Self.fetchOrder(id: order.id, from: database))
        #expect(stored.categories == ["衣著"])
    }

    /// 訂單來源改名同步更新主檔與訂單欄位
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   未讀回改名後的訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func applyOrderSourceRename_改名成功_同步更新主檔與訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let order = LedgerOrder.fixture(id: "ORDER-SOURCE", orderSource: "舊來源")
        try await Self.seed([order], database: database)
        try await database.write { context throws(PersistenceError) in
            context.insert(OrderSourceRecord(name: "舊來源"))
            context.insert(OrderSourceRecord(name: "新來源"))
        }
        let service = Self.makeService(database: database)

        // When
        try await service.applyOrderSourceRename("舊來源", "新來源")

        // Then
        let names = try await database.read { context throws(PersistenceError) in
            try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<OrderSourceRecord>()).map(\.name)
            }
        }
        #expect(names.sorted() == ["新來源"])
        let stored = try #require(try await Self.fetchOrder(id: order.id, from: database))
        #expect(stored.orderSource == "新來源")
    }

    /// 付款方式改名以 OR 合併來源與目標旗標並改寫訂單引用
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   未取得來源付款方式旗標或未讀回改名後的訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func applyPaymentMethodRename_名稱衝突_合併旗標並更新訂單() async throws {
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
            name: "銀行匯款",
            flags: PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            )
        )
        let order = LedgerOrder.fixture(id: "ORDER-PAYMENT", paymentMethod: "匯款")
        try await Self.seed([order], paymentMethods: [source, target], database: database)
        let service = Self.makeService(database: database)
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
        try await service.applyPaymentMethodRename("匯款", "銀行匯款")

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
                    name: "銀行匯款",
                    flags: PaymentMethodFlags(
                        isCardless: true,
                        isBankTransfer: true,
                        isCashOnDelivery: false
                    )
                ),
            ]
        )
        let stored = try #require(try await Self.fetchOrder(id: order.id, from: database))
        #expect(stored.paymentMethod == "銀行匯款")
    }

    /// 對帳狀態改名同步合併主檔並更新訂單
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   未讀回改名後的訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func applyReconciliationStatusRename_改名成功_同步更新主檔與訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let order = LedgerOrder.fixture(id: "ORDER-RECONCILIATION", reconciliationStatus: "待對帳")
        try await Self.seed([order], database: database)
        try await database.write { context throws(PersistenceError) in
            context.insert(ReconciliationStatusRecord(name: "待對帳"))
            context.insert(ReconciliationStatusRecord(name: "已確認"))
        }
        let service = Self.makeService(database: database)

        // When
        try await service.applyReconciliationStatusRename("待對帳", "已確認")

        // Then
        let names = try await database.read { context throws(PersistenceError) in
            try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<ReconciliationStatusRecord>()).map(\.name)
            }
        }
        #expect(names.sorted() == ["已確認"])
        let stored = try #require(try await Self.fetchOrder(id: order.id, from: database))
        #expect(stored.reconciliationStatus == "已確認")
    }

    /// 開團改名替換訂單陣列中的每個相符名稱
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   未讀回改名後的訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameOrderCampaign_陣列含重複舊名稱_替換每個相符項目() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let order = Self.makeOrder(id: "ORDER-CAMPAIGN-RENAME", campaignNames: ["秋團", "其他", "秋團"])
        try await Self.seed([order], database: database)
        let service = Self.makeService(database: database)

        // When
        try await service.renameOrderCampaign("秋團", "秋季團")

        // Then
        let stored = try #require(try await Self.fetchOrder(id: order.id, from: database))
        #expect(stored.campaignNames == ["秋季團", "其他", "秋季團"])
    }
}
