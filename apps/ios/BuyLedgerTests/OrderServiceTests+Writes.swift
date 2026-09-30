//
//  OrderServiceTests+Writes.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

// MARK: - Tests

extension OrderServiceTests {

    /// 一般更新以非空新照片輸入時仍保留既有照片
    ///
    /// - Throws: 測試資料寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；讀回訂單不存在時由 `try #require` 丟出測試斷言錯誤
    @Test
    func saveOrder_新照片輸入不為空_保留既有照片() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let original = Self.makeFullFieldOrder(id: "ORDER-SAVE", variant: .original)
        try await Self.seed([original], database: database)
        let service = Self.makeService(database: database)
        let changed = LedgerOrder.fixture(
            id: original.id,
            status: .shipping,
            notes: "更新",
            photos: [Data([0xA1, 0xA2])]
        )

        // When
        try await service.saveOrder(changed)

        // Then
        let stored = try #require(try await Self.fetchOrder(id: original.id, from: database))
        #expect(stored.status == .shipping)
        #expect(stored.notes == "更新")
        #expect(try await service.fetchOrderPhotos(original.id) == original.photos)
    }

    /// 照片專用更新覆蓋所有欄位、照片且不新增重複列
    ///
    /// - Throws: 測試資料寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；讀回訂單不存在時由 `try #require` 丟出測試斷言錯誤
    @Test
    func saveOrderPersistingPhotos_更新既有訂單_更新欄位照片且不新增重複列() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let original = Self.makeFullFieldOrder(id: "ORDER-PHOTOS", variant: .original)
        try await Self.seed([original], database: database)
        let service = Self.makeService(database: database)
        let replacementPhotos = [Data([0x03, 0x04]), Data([0x05])]
        let replacement = Self.makeFullFieldOrder(
            id: original.id,
            variant: .updated,
            photos: replacementPhotos
        )

        // When
        try await service.saveOrderPersistingPhotos(replacement)

        // Then
        let storedOrders = try await service.fetchOrders()
        #expect(storedOrders.count == 1)
        let stored = try #require(try await Self.fetchOrder(id: original.id, from: database))
        #expect(
            LedgerOrder.normalizingItemIdentifiers(stored)
                == LedgerOrder.normalizingItemIdentifiers(replacement)
        )
        #expect(stored.photos == replacementPhotos)
    }

    /// 照片專用更新會在編號不存在時插入含照片的新訂單
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；讀回訂單不存在時由 `try #require` 丟出測試斷言錯誤
    @Test
    func saveOrderPersistingPhotos_識別值不存在_插入含照片訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let inserted = Self.makeFullFieldOrder(id: "ORDER-PHOTOS-INSERT", variant: .updated)

        // When
        try await service.saveOrderPersistingPhotos(inserted)

        // Then
        let storedOrders = try await service.fetchOrders()
        #expect(storedOrders.count == 1)
        let stored = try #require(try await Self.fetchOrder(id: inserted.id, from: database))
        #expect(
            LedgerOrder.normalizingItemIdentifiers(stored)
                == LedgerOrder.normalizingItemIdentifiers(inserted)
        )
        #expect(stored.photos == inserted.photos)
    }

    /// 一般更新在編號不存在時插入含照片的新訂單並保存對帳狀態
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；讀回訂單不存在時由 `try #require` 丟出測試斷言錯誤
    @Test
    func saveOrder_識別值不存在_插入含照片與對帳狀態() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let inserted = LedgerOrder.fixture(
            id: "ORDER-SAVE-INSERT-PHOTOS",
            reconciliationStatus: "已對帳",
            photos: [Data([0x31, 0x32])]
        )

        // When
        try await service.saveOrder(inserted)

        // Then
        let storedOrders = try await service.fetchOrders()
        #expect(storedOrders.count == 1)
        let stored = try #require(try await Self.fetchOrder(id: inserted.id, from: database))
        #expect(stored.reconciliationStatus == "已對帳")
        #expect(
            LedgerOrder.normalizingItemIdentifiers(stored)
                == LedgerOrder.normalizingItemIdentifiers(inserted)
        )
        #expect(stored.photos == inserted.photos)
    }

    /// 刪除會移除指定訂單並保留其他資料
    ///
    /// - Throws: 測試資料寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`
    @Test
    func removeOrder_識別值相符_刪除指定訂單並保留其他資料() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        try await Self.seed(
            [Self.makeOrder(id: "ORDER-DELETE"), Self.makeOrder(id: "ORDER-KEEP")],
            database: database
        )
        let service = Self.makeService(database: database)

        // When
        try await service.removeOrder("ORDER-DELETE")

        // Then
        let orders = try await service.fetchOrders()
        #expect(orders.map(\.id) == ["ORDER-KEEP"])
    }

    /// 刪除不存在的編號不改變既有訂單
    ///
    /// - Throws: 測試資料寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；讀回訂單不存在時由 `try #require` 丟出測試斷言錯誤
    @Test
    func removeOrder_識別值不存在_不改變既有訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let original = Self.makeFullFieldOrder(id: "ORDER-KEEP", variant: .original)
        try await Self.seed([original], database: database)
        let service = Self.makeService(database: database)

        // When
        try await service.removeOrder("ORDER-UNKNOWN")

        // Then
        let storedOrders = try await service.fetchOrders()
        #expect(storedOrders.count == 1)
        let stored = try #require(try await Self.fetchOrder(id: original.id, from: database))
        #expect(
            LedgerOrder.normalizingItemIdentifiers(stored)
                == LedgerOrder.normalizingItemIdentifiers(original)
        )
    }
}
