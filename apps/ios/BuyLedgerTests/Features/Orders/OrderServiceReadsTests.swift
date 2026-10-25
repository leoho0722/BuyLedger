//
//  OrderServiceReadsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

/// `OrderService` 的單元測試，涵蓋訂單清單與照片的讀取順序、照片延遲載入，以及讀取失敗的錯誤型別
struct OrderServiceReadsTests {

    /// 驗證資料庫沒有任何訂單時，`fetchOrders` 回傳空清單，不丟出錯誤
    ///
    /// - Throws: 資料庫讀取失敗時丟出 `.fetchFailed(underlying:)`
    @Test
    func fetchOrders_全新資料庫_回傳空清單() async throws {
        // Given
        let service = OrderServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )

        // When
        let orders = try await service.fetchOrders()

        // Then
        #expect(orders.isEmpty)
    }

    /// 驗證多筆訂單依日期由新到舊排列，排序與識別值的字典序無關 (字典序最後的 ORDER-Z 最新，排第一)
    ///
    /// - Throws: 測試資料寫入失敗時丟出 `.saveFailed(underlying:)`；資料庫讀取失敗時丟出
    ///   `.fetchFailed(underlying:)`
    @Test
    func fetchOrders_多筆訂單_依日期由新到舊排序() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let older = OrderServiceTestSupport.makeOrder(
            id: "ORDER-OLDER",
            date: Date(timeIntervalSince1970: 1)
        )
        let newer = OrderServiceTestSupport.makeOrder(
            id: "ORDER-NEWER",
            date: Date(timeIntervalSince1970: 2)
        )
        let alphabeticallyLastNewest = OrderServiceTestSupport.makeOrder(
            id: "ORDER-Z",
            date: Date(timeIntervalSince1970: 3)
        )
        try await OrderServiceTestSupport.seed(
            [older, newer, alphabeticallyLastNewest],
            database: database
        )
        let service = OrderServiceTestSupport.makeService(database: database)

        // When
        let orders = try await service.fetchOrders()

        // Then
        #expect(orders.map(\.id) == ["ORDER-Z", "ORDER-NEWER", "ORDER-OLDER"])
    }

    /// 驗證讀取訂單清單時不載入照片位元組，`photos` 為空陣列，照片需另以 `fetchOrderPhotos` 取得
    ///
    /// - Throws: 測試資料寫入失敗時丟出 `.saveFailed(underlying:)`；資料庫讀取失敗時丟出
    ///   `.fetchFailed(underlying:)`；未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func fetchOrders_讀取清單_不載入照片位元組() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let photos = [Data([0x01, 0x02]), Data([0x03])]
        try await OrderServiceTestSupport.seed(
            [OrderServiceTestSupport.makeOrder(id: "ORDER-PHOTO", photos: photos)],
            database: database
        )
        let service = OrderServiceTestSupport.makeService(database: database)

        // When
        let orders = try await service.fetchOrders()

        // Then
        #expect(orders.count == 1)
        let first = try #require(orders.first)
        #expect(first.photos.isEmpty)
        #expect(try await service.fetchOrderPhotos("ORDER-PHOTO") == photos)
    }

    /// 驗證多張照片經 `fetchOrderPhotos` 讀回時，順序與儲存時相同
    ///
    /// - Throws: 測試資料寫入失敗時丟出 `.saveFailed(underlying:)`；資料庫讀取失敗時丟出 `.fetchFailed(underlying:)`
    @Test
    func fetchOrderPhotos_多張照片_保留儲存順序() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let photos = [Data([0x10]), Data([0x20, 0x21])]
        try await OrderServiceTestSupport.seed(
            [OrderServiceTestSupport.makeOrder(id: "ORDER-PHOTO", photos: photos)],
            database: database
        )
        let service = OrderServiceTestSupport.makeService(database: database)

        // When
        let fetchedPhotos = try await service.fetchOrderPhotos("ORDER-PHOTO")

        // Then
        #expect(fetchedPhotos == photos)
    }

    /// 驗證指定編號查無訂單時，`fetchOrderPhotos` 回傳空陣列，不丟出錯誤
    ///
    /// - Throws: 資料庫讀取失敗時丟出 `.fetchFailed(underlying:)`
    @Test
    func fetchOrderPhotos_查無訂單_回傳空陣列() async throws {
        // Given
        let service = OrderServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )

        // When
        let photos = try await service.fetchOrderPhotos("ORDER-MISSING")

        // Then
        #expect(photos.isEmpty)
    }

    /// 驗證資料庫讀取失敗時，`fetchOrders` 以共用的 `PersistenceError.fetchFailed` 丟出，底層錯誤的網域、代碼與說明原樣保留，且只讀取一次
    ///
    /// - Throws: 未取得讀取錯誤或錯誤不是 `.fetchFailed(underlying:)` 時由 `#require` 丟出測試斷言錯誤
    @Test
    func fetchOrders_資料庫讀取失敗_保留持久化錯誤型別() async throws {
        // Given
        let mock = MockBuyLedgerDatabase(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )
        let injectedError = NSError(
            domain: "com.leoho.BuyLedger.order-read-test",
            code: 7,
            userInfo: [NSLocalizedDescriptionKey: "read failure"]
        )
        mock.mode = .readFailure(
            call: 1,
            error: PersistenceError.fetchFailed(underlying: injectedError)
        )
        let service = OrderServiceTestSupport.makeService(database: mock)
        var actualError: PersistenceError?

        // When
        do {
            _ = try await service.fetchOrders()
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
