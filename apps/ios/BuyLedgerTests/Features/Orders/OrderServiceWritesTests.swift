//
//  OrderServiceWritesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

/// `OrderService` 的單元測試，涵蓋單筆儲存、含照片儲存與刪除，且只影響指定的訂單
struct OrderServiceWritesTests {

    /// 驗證一般更新 (`saveOrder`) 帶入非空的新照片時，狀態與備註寫入，照片仍維持資料庫中的既有照片
    ///
    /// - Throws: 測試資料寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；讀回訂單不存在時由 `try #require` 丟出測試斷言錯誤
    @Test
    func saveOrder_新照片輸入不為空_保留既有照片() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let original = OrderServiceTestSupport.makeFullFieldOrder(
            id: "ORDER-SAVE",
            variant: .original
        )
        try await OrderServiceTestSupport.seed([original], database: database)
        let service = OrderServiceTestSupport.makeService(database: database)
        let changed = LedgerOrder.fixture(
            id: original.id,
            status: .shipping,
            notes: "更新",
            photos: [Data([0xA1, 0xA2])]
        )

        // When
        try await service.saveOrder(changed)

        // Then
        let stored = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: original.id, from: database)
        )
        #expect(stored.status == .shipping)
        #expect(stored.notes == "更新")
        #expect(try await service.fetchOrderPhotos(original.id) == original.photos)
    }

    /// 驗證 `saveOrderPersistingPhotos` 更新既有訂單時，所有欄位與照片都換成新值，且資料庫仍只有一筆
    ///
    /// - Throws: 測試資料寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；讀回訂單不存在時由 `try #require` 丟出測試斷言錯誤
    @Test
    func saveOrderPersistingPhotos_更新既有訂單_更新欄位照片且不新增重複列() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let original = OrderServiceTestSupport.makeFullFieldOrder(
            id: "ORDER-PHOTOS",
            variant: .original
        )
        try await OrderServiceTestSupport.seed([original], database: database)
        let service = OrderServiceTestSupport.makeService(database: database)
        let replacementPhotos = [Data([0x03, 0x04]), Data([0x05])]
        let replacement = OrderServiceTestSupport.makeFullFieldOrder(
            id: original.id,
            variant: .updated,
            photos: replacementPhotos
        )

        // When
        try await service.saveOrderPersistingPhotos(replacement)

        // Then
        let storedOrders = try await service.fetchOrders()
        #expect(storedOrders.count == 1)
        let stored = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: original.id, from: database)
        )
        #expect(
            LedgerOrder.normalizingItemIdentifiers(stored)
                == LedgerOrder.normalizingItemIdentifiers(replacement)
        )
        #expect(stored.photos == replacementPhotos)
    }

    /// 驗證 `saveOrderPersistingPhotos` 的編號不存在時，插入一筆含照片的新訂單，欄位與照片都與送入的相同
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；讀回訂單不存在時由 `try #require` 丟出測試斷言錯誤
    @Test
    func saveOrderPersistingPhotos_識別值不存在_插入含照片訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = OrderServiceTestSupport.makeService(database: database)
        let inserted = OrderServiceTestSupport.makeFullFieldOrder(
            id: "ORDER-PHOTOS-INSERT",
            variant: .updated
        )

        // When
        try await service.saveOrderPersistingPhotos(inserted)

        // Then
        let storedOrders = try await service.fetchOrders()
        #expect(storedOrders.count == 1)
        let stored = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: inserted.id, from: database)
        )
        #expect(
            LedgerOrder.normalizingItemIdentifiers(stored)
                == LedgerOrder.normalizingItemIdentifiers(inserted)
        )
        #expect(stored.photos == inserted.photos)
    }

    /// 驗證 `saveOrder` 的編號不存在時，插入一筆新訂單，對帳狀態與照片都與送入的相同
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；讀回訂單不存在時由 `try #require` 丟出測試斷言錯誤
    @Test
    func saveOrder_識別值不存在_插入含照片與對帳狀態() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = OrderServiceTestSupport.makeService(database: database)
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
        let stored = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: inserted.id, from: database)
        )
        #expect(stored.reconciliationStatus == "已對帳")
        #expect(
            LedgerOrder.normalizingItemIdentifiers(stored)
                == LedgerOrder.normalizingItemIdentifiers(inserted)
        )
        #expect(stored.photos == inserted.photos)
    }

    /// 驗證 `removeOrder` 只刪除指定編號的訂單，同批的其他訂單保留
    ///
    /// - Throws: 測試資料寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`
    @Test
    func removeOrder_識別值相符_刪除指定訂單並保留其他資料() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        try await OrderServiceTestSupport.seed(
            [
                OrderServiceTestSupport.makeOrder(id: "ORDER-DELETE"),
                OrderServiceTestSupport.makeOrder(id: "ORDER-KEEP"),
            ],
            database: database
        )
        let service = OrderServiceTestSupport.makeService(database: database)

        // When
        try await service.removeOrder("ORDER-DELETE")

        // Then
        let orders = try await service.fetchOrders()
        #expect(orders.map(\.id) == ["ORDER-KEEP"])
    }

    /// 驗證 `removeOrder` 的編號查無訂單時不丟出錯誤，既有訂單的欄位與照片都不變
    ///
    /// - Throws: 測試資料寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或
    ///   `.fetchFailed(underlying:)`；讀回訂單不存在時由 `try #require` 丟出測試斷言錯誤
    @Test
    func removeOrder_識別值不存在_不改變既有訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let original = OrderServiceTestSupport.makeFullFieldOrder(
            id: "ORDER-KEEP",
            variant: .original
        )
        try await OrderServiceTestSupport.seed([original], database: database)
        let service = OrderServiceTestSupport.makeService(database: database)

        // When
        try await service.removeOrder("ORDER-UNKNOWN")

        // Then
        let storedOrders = try await service.fetchOrders()
        #expect(storedOrders.count == 1)
        let stored = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: original.id, from: database)
        )
        #expect(
            LedgerOrder.normalizingItemIdentifiers(stored)
                == LedgerOrder.normalizingItemIdentifiers(original)
        )
    }
}
