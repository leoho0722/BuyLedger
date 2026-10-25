//
//  OrderServiceWriteFailuresTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import CoreData
import Foundation
import Testing

@testable import BuyLedger

/// `OrderService` 的單元測試，涵蓋各種寫入遇到儲存失敗時，資料庫不留下新增的訂單
struct OrderServiceWriteFailuresTests {

    /// 驗證建立訂單存檔失敗時，回報寫入錯誤並保留底層 `NSError`，資料庫只剩原有訂單
    ///
    /// - Throws: fixture 建立或讀取失敗時丟出底層檔案、SwiftData 或
    ///   `.fetchFailed(underlying:)` 錯誤；未捕捉到錯誤、錯誤不是 `.storage(_)` 或不是
    ///   `.saveFailed(underlying:)` 時由 `try #require` 丟出測試斷言錯誤
    /// - Note: 底層錯誤保留 SwiftData 的網域與代碼
    @Test
    func createOrder_儲存失敗_不留下新增訂單() async throws {
        // Given
        let initial = OrderServiceTestSupport.makeOrder(id: "ORDER-SAVE-FAIL-SEED")
        let (service, directoryURL) = try OrderServiceTestSupport.makeSaveFailingService(orders: [
            initial,
        ])
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: directoryURL)
        }
        var actualError: OrderError?

        // When
        do {
            try await service.createOrder(
                OrderServiceTestSupport.makeOrder(id: "ORDER-SAVE-FAIL-CREATE")
            )
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let actualStorageError: PersistenceError?
        switch error {
        case .storage(let storageError):
            actualStorageError = storageError

        case .identifierCollision:
            actualStorageError = nil
        }
        let storageError = try #require(actualStorageError)
        let actualUnderlying: (any Error & Sendable)?
        switch storageError {
        case .saveFailed(let underlying):
            actualUnderlying = underlying

        case .fetchFailed, .containerCreationFailed:
            actualUnderlying = nil
        }
        let underlying = try #require(actualUnderlying) as NSError
        #expect(underlying.domain == NSCocoaErrorDomain)
        #expect(underlying.code == NSValidationRelationshipExceedsMaximumCountError)
        #expect(try await service.fetchOrders().map(\.id) == [initial.id])
    }

    /// 驗證 `saveOrder` 存檔失敗時丟出 `.saveFailed`，資料庫只剩原有的訂單，失敗時送入的新編號訂單不留下
    ///
    /// - Throws: fixture 建立或讀取失敗時丟出底層檔案、SwiftData 或
    ///   `.fetchFailed(underlying:)` 錯誤；未捕捉到寫入錯誤時由 `try #require` 丟出
    ///   測試斷言錯誤
    @Test
    func saveOrder_儲存失敗_不留下新增訂單() async throws {
        // Given
        let initial = OrderServiceTestSupport.makeOrder(id: "ORDER-SAVE-FAIL-SEED")
        let (service, directoryURL) = try OrderServiceTestSupport.makeSaveFailingService(orders: [
            initial,
        ])
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: directoryURL)
        }
        var actualError: PersistenceError?

        // When
        do {
            try await service.saveOrder(
                OrderServiceTestSupport.makeOrder(id: "ORDER-SAVE-FAIL-UPDATE")
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
        #expect(try await service.fetchOrders().map(\.id) == [initial.id])
    }

    /// 驗證 `saveOrders` 批次存檔失敗時丟出 `.saveFailed`，批次中的新訂單都不留下，資料庫只剩原有的訂單
    ///
    /// - Throws: fixture 建立或讀取失敗時丟出底層檔案、SwiftData 或
    ///   `.fetchFailed(underlying:)` 錯誤；未捕捉到寫入錯誤時由 `try #require` 丟出
    ///   測試斷言錯誤
    @Test
    func saveOrders_批次儲存失敗_不留下新增訂單() async throws {
        // Given
        let initial = OrderServiceTestSupport.makeOrder(id: "ORDER-SAVE-FAIL-SEED")
        let (service, directoryURL) = try OrderServiceTestSupport.makeSaveFailingService(orders: [
            initial,
        ])
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: directoryURL)
        }
        var actualError: PersistenceError?

        // When
        do {
            try await service.saveOrders([
                OrderServiceTestSupport.makeOrder(id: "ORDER-SAVE-FAIL-BATCH"),
            ])
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
        #expect(try await service.fetchOrders().map(\.id) == [initial.id])
    }

    /// 驗證 `saveOrderPersistingPhotos` 含照片的新訂單存檔失敗時丟出 `.saveFailed`，資料庫只剩原有的訂單，含照片的新訂單不留下
    ///
    /// - Throws: fixture 建立或讀取失敗時丟出底層檔案、SwiftData 或
    ///   `.fetchFailed(underlying:)` 錯誤；未捕捉到寫入錯誤時由 `try #require` 丟出
    ///   測試斷言錯誤
    @Test
    func saveOrderPersistingPhotos_含照片儲存失敗_不留下新增訂單() async throws {
        // Given
        let initial = OrderServiceTestSupport.makeOrder(id: "ORDER-SAVE-FAIL-SEED")
        let (service, directoryURL) = try OrderServiceTestSupport.makeSaveFailingService(orders: [
            initial,
        ])
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: directoryURL)
        }
        var actualError: PersistenceError?

        // When
        do {
            try await service.saveOrderPersistingPhotos(
                OrderServiceTestSupport.makeOrder(
                    id: "ORDER-SAVE-FAIL-PHOTOS",
                    photos: [Data([0x01])]
                )
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
        #expect(try await service.fetchOrders().map(\.id) == [initial.id])
    }
}
