//
//  OrderServiceTests+Reads.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

// MARK: - Tests

extension OrderServiceTests {

    /// 空資料庫讀取回傳空訂單清單
    ///
    /// - Throws: 資料庫讀取失敗時丟出 `.fetchFailed(underlying:)`
    @Test
    func fetchOrders_全新資料庫_回傳空清單() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())

        // When
        let orders = try await service.fetchOrders()

        // Then
        #expect(orders.isEmpty)
    }

    /// 訂單依日期由新到舊排序
    ///
    /// - Throws: 測試資料寫入失敗時丟出 `.saveFailed(underlying:)`；資料庫讀取失敗時丟出
    ///   `.fetchFailed(underlying:)`
    @Test
    func fetchOrders_多筆訂單_依日期由新到舊排序() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let older = Self.makeOrder(id: "ORDER-OLDER", date: Date(timeIntervalSince1970: 1))
        let newer = Self.makeOrder(id: "ORDER-NEWER", date: Date(timeIntervalSince1970: 2))
        let alphabeticallyLastNewest = Self.makeOrder(
            id: "ORDER-Z",
            date: Date(timeIntervalSince1970: 3)
        )
        try await Self.seed([older, newer, alphabeticallyLastNewest], database: database)
        let service = Self.makeService(database: database)

        // When
        let orders = try await service.fetchOrders()

        // Then
        #expect(orders.map(\.id) == ["ORDER-Z", "ORDER-NEWER", "ORDER-OLDER"])
    }

    /// 訂單清單不讀取照片位元組
    ///
    /// - Throws: 測試資料寫入失敗時丟出 `.saveFailed(underlying:)`；資料庫讀取失敗時丟出
    ///   `.fetchFailed(underlying:)`；未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func fetchOrders_讀取清單_不載入照片位元組() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let photos = [Data([0x01, 0x02]), Data([0x03])]
        try await Self.seed([Self.makeOrder(id: "ORDER-PHOTO", photos: photos)], database: database)
        let service = Self.makeService(database: database)

        // When
        let orders = try await service.fetchOrders()

        // Then
        #expect(orders.count == 1)
        let first = try #require(orders.first)
        #expect(first.photos.isEmpty)
        #expect(try await service.fetchOrderPhotos("ORDER-PHOTO") == photos)
    }

    /// 照片讀取保留儲存順序
    ///
    /// - Throws: 測試資料寫入失敗時丟出 `.saveFailed(underlying:)`；資料庫讀取失敗時丟出 `.fetchFailed(underlying:)`
    @Test
    func fetchOrderPhotos_多張照片_保留儲存順序() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let photos = [Data([0x10]), Data([0x20, 0x21])]
        try await Self.seed([Self.makeOrder(id: "ORDER-PHOTO", photos: photos)], database: database)
        let service = Self.makeService(database: database)

        // When
        let fetchedPhotos = try await service.fetchOrderPhotos("ORDER-PHOTO")

        // Then
        #expect(fetchedPhotos == photos)
    }

    /// 查無訂單時照片讀取回傳空陣列
    ///
    /// - Throws: 資料庫讀取失敗時丟出 `.fetchFailed(underlying:)`
    @Test
    func fetchOrderPhotos_查無訂單_回傳空陣列() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())

        // When
        let photos = try await service.fetchOrderPhotos("ORDER-MISSING")

        // Then
        #expect(photos.isEmpty)
    }

    /// 資料庫讀取失敗會保留共同持久化錯誤型別，以及底層錯誤的網域、代碼與說明
    ///
    /// - Throws: 未取得讀取錯誤或錯誤不是 `.fetchFailed(underlying:)` 時由 `#require` 丟出測試斷言錯誤
    @Test
    func fetchOrders_資料庫讀取失敗_保留持久化錯誤型別() async throws {
        // Given
        let mock = MockBuyLedgerDatabase(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        let injectedError = NSError(
            domain: "com.leoho.BuyLedger.order-read-test",
            code: 7,
            userInfo: [NSLocalizedDescriptionKey: "read failure"]
        )
        mock.mode = .readFailure(
            call: 1,
            error: PersistenceError.fetchFailed(underlying: injectedError)
        )
        let service = Self.makeService(database: mock)
        var actualError: PersistenceError?

        // When
        do throws(PersistenceError) {
            try await service.fetchOrders()
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
        let fetchFailure = try #require(actualFetchFailure) as NSError
        #expect(fetchFailure.domain == "com.leoho.BuyLedger.order-read-test")
        #expect(fetchFailure.code == 7)
        #expect(fetchFailure.localizedDescription == "read failure")
        #expect(mock.readCallCount == 1)
    }
}
