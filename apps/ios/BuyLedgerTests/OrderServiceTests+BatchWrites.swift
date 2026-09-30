//
//  OrderServiceTests+BatchWrites.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

// MARK: - Tests

extension OrderServiceTests {

    /// 更新會寫入每個訂單欄位但保留既有照片
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   未讀回原訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func saveOrder_完整欄位更新_保留原有照片() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let original = Self.makeFullFieldOrder(id: "ORDER-FULL-FIELDS", variant: .original)
        try await Self.seed([original], database: database)
        let service = Self.makeService(database: database)
        let updated = LedgerOrder.fixture(
            id: original.id,
            customer: LedgerCustomer(name: "更新客戶", initials: "UP", tier: .vip),
            status: .delivered,
            currency: .jpy,
            date: Date(timeIntervalSince1970: 1_800_000_000),
            items: [LedgerOrderItem(name: "新商品", quantity: 5, unitPrice: 300)],
            itemCost: 2_400,
            domesticShipping: 120,
            internationalShipping: 450,
            foreignDomesticShipping: 160,
            cardFeeRate: 0.03,
            platformFeeRate: 0.08,
            paymentFeeRate: 0.02,
            chargedAmount: 8_000,
            cardlessDeductionAmount: 200,
            cardlessSupplementAmount: 75,
            orderSource: "露天",
            categories: ["3C"],
            paymentMethod: "銀行匯款",
            notes: "更新備註",
            reconciliationStatus: "對帳完成",
            campaignNames: ["夏季團"],
            paymentReceiptStatus: .received,
            isCashOnDelivery: true,
            mergedSourceIDs: ["ORDER-SOURCE-A", "ORDER-SOURCE-B"]
        )
        let expected = LedgerOrder.fixture(
            id: original.id,
            customer: LedgerCustomer(name: "更新客戶", initials: "UP", tier: .vip),
            status: .delivered,
            currency: .jpy,
            date: Date(timeIntervalSince1970: 1_800_000_000),
            items: [LedgerOrderItem(name: "新商品", quantity: 5, unitPrice: 300)],
            itemCost: 2_400,
            domesticShipping: 120,
            internationalShipping: 450,
            foreignDomesticShipping: 160,
            cardFeeRate: 0.03,
            platformFeeRate: 0.08,
            paymentFeeRate: 0.02,
            chargedAmount: 8_000,
            cardlessDeductionAmount: 200,
            cardlessSupplementAmount: 75,
            orderSource: "露天",
            categories: ["3C"],
            paymentMethod: "銀行匯款",
            notes: "更新備註",
            reconciliationStatus: "對帳完成",
            campaignNames: ["夏季團"],
            paymentReceiptStatus: .received,
            isCashOnDelivery: true,
            photos: original.photos,
            mergedSourceIDs: ["ORDER-SOURCE-A", "ORDER-SOURCE-B"]
        )

        // When
        try await service.saveOrder(updated)

        // Then
        let stored = try #require(try await Self.fetchOrder(id: original.id, from: database))
        #expect(
            LedgerOrder.normalizingItemIdentifiers(stored)
                == LedgerOrder.normalizingItemIdentifiers(expected)
        )
        #expect(stored.photos == original.photos)
    }

    /// 批次更新只改指定訂單並保留未更新訂單的照片
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   未讀回更新或未指定的訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func saveOrders_部分訂單更新_不動未指定訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let target = Self.makeOrder(id: "ORDER-BATCH-TARGET")
        let unrelated = Self.makeOrder(id: "ORDER-BATCH-OTHER", photos: [Data([0x20])])
        try await Self.seed([target, unrelated], database: database)
        let service = Self.makeService(database: database)

        // When
        try await service.saveOrders([LedgerOrder.fixture(id: target.id, status: .shipping)])

        // Then
        let targetAfter = try #require(try await Self.fetchOrder(id: target.id, from: database))
        let unrelatedAfter = try #require(
            try await Self.fetchOrder(id: unrelated.id, from: database)
        )
        #expect(targetAfter.status == .shipping)
        #expect(unrelatedAfter.status == unrelated.status)
        #expect(unrelatedAfter.photos == unrelated.photos)
    }

    /// 批次更新只改三筆，完整保留其餘訂單狀態並抽樣確認照片
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   未讀回指定訂單或照片抽樣訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func saveOrders_大型批次只指定三筆_完整保留其餘狀態並抽樣照片() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x41])
        let originals = (0..<500).map {
            LedgerOrder.fixture(
                id: String(format: "ORDER-LARGE-%03d", $0),
                status: .quoting,
                photos: [photo]
            )
        }
        try await service.saveOrders(originals)
        let targetIDs = ["ORDER-LARGE-010", "ORDER-LARGE-250", "ORDER-LARGE-499"]
        let changed = targetIDs.map {
            LedgerOrder.fixture(id: $0, status: .confirmed, photos: [photo])
        }

        // When
        try await service.saveOrders(changed)

        // Then
        let stored = try await service.fetchOrders()
        #expect(stored.count == 500)
        for id in targetIDs {
            let updated = try #require(stored.first { $0.id == id })
            #expect(updated.status == .confirmed)
        }
        let untouchedIDs = originals.map(\.id).filter { !targetIDs.contains($0) }
        let storedUntouched = stored.filter { !targetIDs.contains($0.id) }
        #expect(storedUntouched.count == 497)
        for untouched in storedUntouched {
            #expect(untouched.status == .quoting)
        }
        for index in stride(from: 0, to: untouchedIDs.count, by: 25) {
            let id = untouchedIDs[index]
            let untouched = try #require(try await Self.fetchOrder(id: id, from: database))
            #expect(untouched.photos == [photo])
        }
    }

    /// 三百筆大型批次可完整更新每筆訂單
    ///
    /// - Throws: 資料庫寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`
    @Test
    func saveOrders_三百筆識別值_完整更新所有訂單() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        let seeded = (0..<300).map {
            LedgerOrder.fixture(id: String(format: "BL-LARGEBATCH-%03d", $0), status: .quoting)
        }
        try await service.saveOrders(seeded)
        let changed = (0..<300).map {
            LedgerOrder.fixture(id: String(format: "BL-LARGEBATCH-%03d", $0), status: .confirmed)
        }

        // When
        try await service.saveOrders(changed)

        // Then
        let stored = try await service.fetchOrders()
        #expect(stored.count == 300)
        #expect(stored.allSatisfy { $0.status == .confirmed })
    }

    /// 建立訂單會以 byte 級內容完整保存多張大型照片
    ///
    /// - Throws: 建立時以 `OrderPersistenceError` 丟出 `.identifierCollision(id:)`、
    ///   `.storage(.fetchFailed(underlying:))` 或
    ///   `.storage(.saveFailed(underlying:))`；讀取照片失敗時丟出 `.fetchFailed(underlying:)`
    @Test
    func createOrder_多張大型照片_保存每張照片位元組() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        let tags: [UInt8] = [0xA1, 0xB2, 0xC3]
        let photos = tags.map { tag in
            var bytes = [UInt8](repeating: tag, count: 300_000)
            bytes[0] = 0xFF
            bytes[1] = 0xD8
            bytes[2] = 0xFF
            return Data(bytes)
        }
        let order = Self.makeOrder(id: "ORDER-LARGE-PHOTOS", photos: photos)

        // When
        try await service.createOrder(order)

        // Then
        #expect(try await service.fetchOrderPhotos(order.id) == photos)
    }

    /// 批次更新兩筆既有訂單並新增一筆訂單且保留照片
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   未讀回批次中的訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func saveOrders_批次包含既有與新訂單_更新新增並保留照片() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let original = Self.makeOrder(id: "ORDER-BATCH-UPDATE", photos: [Data([0x41])])
        let secondOriginal = Self.makeOrder(id: "ORDER-BATCH-UPDATE-SECOND", photos: [Data([0x43])])
        try await Self.seed([original, secondOriginal], database: database)
        let service = Self.makeService(database: database)
        let updated = LedgerOrder.fixture(id: original.id, status: .shipping)
        let secondUpdated = LedgerOrder.fixture(id: secondOriginal.id, status: .shipping)
        let inserted = LedgerOrder.fixture(
            id: "ORDER-BATCH-INSERT",
            status: .shipping,
            photos: [Data([0x42])]
        )

        // When
        try await service.saveOrders([updated, secondUpdated, inserted])

        // Then
        let stored = try await service.fetchOrders()
        #expect(stored.count == 3)
        #expect(stored.map(\.id).sorted() == [original.id, secondOriginal.id, inserted.id].sorted())
        let updatedOrder = try #require(stored.first { $0.id == original.id })
        let secondUpdatedOrder = try #require(stored.first { $0.id == secondOriginal.id })
        let insertedOrder = try #require(stored.first { $0.id == inserted.id })
        #expect(updatedOrder.status == .shipping)
        #expect(secondUpdatedOrder.status == .shipping)
        #expect(insertedOrder.status == .shipping)
        #expect(try await service.fetchOrderPhotos(original.id) == original.photos)
        #expect(try await service.fetchOrderPhotos(secondOriginal.id) == secondOriginal.photos)
        #expect(try await service.fetchOrderPhotos(inserted.id) == inserted.photos)
    }

    /// 空批次不改變既有訂單
    ///
    /// - Throws: 寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   未讀回原訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func saveOrders_輸入為空_不改變既有訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let original = Self.makeFullFieldOrder(id: "ORDER-BATCH-EMPTY", variant: .original)
        try await Self.seed([original], database: database)
        let service = Self.makeService(database: database)

        // When
        try await service.saveOrders([])

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
