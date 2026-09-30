//
//  OrderServiceTests+Decoding.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import SwiftData
import Testing

@testable import BuyLedger

// MARK: - Tests

extension OrderServiceTests {

    /// 無法解析的收款狀態 raw value 會保留診斷欄位並使讀取失敗
    ///
    /// - Parameter rawValue: 要寫入記錄的非法狀態字串
    /// - Throws: 測試資料寫入失敗時丟出 `.saveFailed(underlying:)`；
    ///   未取得讀取錯誤或錯誤未保留 `RecordDecodingError` 時由 `#require` 丟出測試斷言錯誤
    @Test(arguments: ["legacy-status", ""])
    func fetchOrders_收款狀態無法解碼_保留診斷欄位並回報錯誤(rawValue: String) async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        try await database.write { context throws(PersistenceError) in
            let record = OrderRecord(order: Self.makeOrder(id: "order-001"))
            record.paymentReceiptStatus = rawValue
            context.insert(record)
        }
        let service = Self.makeService(database: database)
        var actualError: PersistenceError?

        // When
        do throws(PersistenceError) {
            _ = try await service.fetchOrders()
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let actualDecodingError: RecordDecodingError?
        switch error {
        case .fetchFailed(let underlying):
            actualDecodingError = underlying as? RecordDecodingError

        case .saveFailed, .containerCreationFailed:
            actualDecodingError = nil
        }
        let decodingError = try #require(actualDecodingError)
        #expect(decodingError.entity == "OrderRecord")
        #expect(decodingError.identifier == "order-001")
        #expect(decodingError.field == "paymentReceiptStatus")
        #expect(decodingError.rawValue == rawValue)
    }

    /// 合法收款狀態 raw value 讀回相同領域值
    ///
    /// - Throws: 測試資料寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`
    @Test
    func fetchOrders_合法收款狀態值_還原相同領域值() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        try await database.write { context throws(PersistenceError) in
            let pending = OrderRecord(order: Self.makeOrder(id: "ORDER-PENDING"))
            pending.paymentReceiptStatus = PaymentReceiptStatus.pending.rawValue
            let received = OrderRecord(order: Self.makeOrder(id: "ORDER-RECEIVED"))
            received.paymentReceiptStatus = PaymentReceiptStatus.received.rawValue
            context.insert(pending)
            context.insert(received)
        }
        let service = Self.makeService(database: database)

        // When
        let orders = try await service.fetchOrders()
        let statuses = Dictionary(
            uniqueKeysWithValues: orders.map { ($0.id, $0.paymentReceiptStatus) }
        )

        // Then
        #expect(statuses["ORDER-PENDING"] == .pending)
        #expect(statuses["ORDER-RECEIVED"] == .received)
    }
}
