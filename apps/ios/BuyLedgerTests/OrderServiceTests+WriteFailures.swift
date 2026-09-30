//
//  OrderServiceTests+WriteFailures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import CoreData
import Foundation
import Testing

@testable import BuyLedger

// MARK: - Tests

extension OrderServiceTests {

    /// 建立操作存檔失敗時丟出保留 SwiftData 底層錯誤網域與代碼的儲存錯誤，且不留下新訂單
    ///
    /// - Throws: fixture 建立或讀取失敗時丟出底層檔案、SwiftData 或
    ///   `.fetchFailed(underlying:)` 錯誤；未捕捉到錯誤、錯誤不是 `.storage(_)` 或不是
    ///   `.saveFailed(underlying:)` 時由 `try #require` 丟出測試斷言錯誤
    @Test
    func createOrder_儲存失敗_不留下新增訂單() async throws {
        // Given
        let initial = Self.makeOrder(id: "ORDER-SAVE-FAIL-SEED")
        let (service, directoryURL) = try Self.makeSaveFailingService(orders: [initial])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: directoryURL)
        }
        var actualError: OrderPersistenceError?

        // When
        do throws(OrderPersistenceError) {
            try await service.createOrder(Self.makeOrder(id: "ORDER-SAVE-FAIL-CREATE"))
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

    /// 更新操作存檔失敗時不會留下不存在的訂單
    ///
    /// - Throws: fixture 建立或讀取失敗時丟出底層檔案、SwiftData 或
    ///   `.fetchFailed(underlying:)` 錯誤；未捕捉到寫入錯誤時由 `try #require` 丟出
    ///   測試斷言錯誤
    @Test
    func saveOrder_儲存失敗_不留下新增訂單() async throws {
        // Given
        let initial = Self.makeOrder(id: "ORDER-SAVE-FAIL-SEED")
        let (service, directoryURL) = try Self.makeSaveFailingService(orders: [initial])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: directoryURL)
        }
        var actualError: PersistenceError?

        // When
        do throws(PersistenceError) {
            try await service.saveOrder(Self.makeOrder(id: "ORDER-SAVE-FAIL-UPDATE"))
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

    /// 批次存檔失敗時不會留下新增訂單
    ///
    /// - Throws: fixture 建立或讀取失敗時丟出底層檔案、SwiftData 或
    ///   `.fetchFailed(underlying:)` 錯誤；未捕捉到寫入錯誤時由 `try #require` 丟出
    ///   測試斷言錯誤
    @Test
    func saveOrders_批次儲存失敗_不留下新增訂單() async throws {
        // Given
        let initial = Self.makeOrder(id: "ORDER-SAVE-FAIL-SEED")
        let (service, directoryURL) = try Self.makeSaveFailingService(orders: [initial])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: directoryURL)
        }
        var actualError: PersistenceError?

        // When
        do throws(PersistenceError) {
            try await service.saveOrders([Self.makeOrder(id: "ORDER-SAVE-FAIL-BATCH")])
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

    /// 含照片存檔失敗時不會留下新增訂單
    ///
    /// - Throws: fixture 建立或讀取失敗時丟出底層檔案、SwiftData 或
    ///   `.fetchFailed(underlying:)` 錯誤；未捕捉到寫入錯誤時由 `try #require` 丟出
    ///   測試斷言錯誤
    @Test
    func saveOrderPersistingPhotos_含照片儲存失敗_不留下新增訂單() async throws {
        // Given
        let initial = Self.makeOrder(id: "ORDER-SAVE-FAIL-SEED")
        let (service, directoryURL) = try Self.makeSaveFailingService(orders: [initial])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: directoryURL)
        }
        var actualError: PersistenceError?

        // When
        do throws(PersistenceError) {
            try await service.saveOrderPersistingPhotos(
                Self.makeOrder(id: "ORDER-SAVE-FAIL-PHOTOS", photos: [Data([0x01])])
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

// MARK: - Internal Method

extension OrderServiceTests {

    /// 建立會在交易主體完成後觸發真實存檔錯誤的 Service
    ///
    /// - Parameter orders: 存檔失敗前已寫入的訂單
    /// - Returns: Service 與需要在測試結束移除的暫存目錄
    /// - Throws: 暫存 fixture 建立時丟出檔案系統或 SwiftData 底層錯誤
    static func makeSaveFailingService(orders: [LedgerOrder]) throws -> (OrderService, URL) {
        let fixture = try ResidueProbeModels.makeDiskFixture(orders: orders)
        let database = BuyLedgerDatabaseTests.makeDatabase(with: fixture)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .saveFailureAfterBody
        return (Self.makeService(database: mock), fixture.directoryURL)
    }
}
