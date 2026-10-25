//
//  OrderServiceDecodingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import SwiftData
import Testing

@testable import BuyLedger

/// `OrderService` 的單元測試，涵蓋讀取時收款狀態的解碼與無法解碼時的錯誤回報
struct OrderServiceDecodingTests {

    /// 驗證收款狀態無法解析時，回報讀取失敗並保留 `RecordDecodingError` 的診斷欄位
    ///
    /// - Parameter rawValue: 要寫入記錄的非法狀態字串
    /// - Throws: 測試資料寫入失敗時丟出 `.saveFailed(underlying:)`；
    ///   未取得讀取錯誤或錯誤未保留 `RecordDecodingError` 時由 `#require` 丟出測試斷言錯誤
    /// - Note: 非法狀態包含 legacy-status 與空字串，診斷欄位包含實體、識別值、欄位名與原始值
    @Test(arguments: ["legacy-status", ""])
    func fetchOrders_收款狀態無法解碼_保留診斷欄位並回報錯誤(rawValue: String) async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        try await database.write { context throws(PersistenceError) in
            let record = OrderRecord(order: OrderServiceTestSupport.makeOrder(id: "order-001"))
            record.paymentReceiptStatus = rawValue
            context.insert(record)
        }
        let service = OrderServiceTestSupport.makeService(database: database)
        var actualError: PersistenceError?

        // When
        do {
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

    /// 驗證收款狀態的合法 raw value (`pending`、`received`) 讀回後，還原成對應的領域值
    ///
    /// - Throws: 測試資料寫入或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`
    @Test
    func fetchOrders_合法收款狀態值_還原相同領域值() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        try await database.write { context throws(PersistenceError) in
            let pending = OrderRecord(order: OrderServiceTestSupport.makeOrder(id: "ORDER-PENDING"))
            pending.paymentReceiptStatus = "pending"
            let received = OrderRecord(
                order: OrderServiceTestSupport.makeOrder(id: "ORDER-RECEIVED")
            )
            received.paymentReceiptStatus = "received"
            context.insert(pending)
            context.insert(received)
        }
        let service = OrderServiceTestSupport.makeService(database: database)

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
