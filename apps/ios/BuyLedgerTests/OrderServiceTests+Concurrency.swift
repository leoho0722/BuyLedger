//
//  OrderServiceTests+Concurrency.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Testing

@testable import BuyLedger

// MARK: - Tests

extension OrderServiceTests {

    /// 二十個並發建立同編號只成功一筆且其餘十九筆明確撞號
    ///
    /// - Throws: 讀取失敗時丟出 `.fetchFailed(underlying:)`
    @Test
    func createOrder_並行建立相同識別值_只成功一筆其餘明確撞號() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        let order = Self.makeOrder(id: "order-001")

        // When
        let results = await withTaskGroup(of: CreateAttemptResult.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    var actualError: OrderPersistenceError?
                    do throws(OrderPersistenceError) {
                        try await service.createOrder(order)
                    } catch {
                        actualError = error
                    }
                    guard let actualError else {
                        return .created
                    }
                    switch actualError {
                    case .identifierCollision(let id):
                        return id == order.id ? .collided : .unexpectedFailure

                    case .storage:
                        return .unexpectedFailure
                    }
                }
            }
            var collected: [CreateAttemptResult] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        // Then
        #expect(results.filter { $0 == .created }.count == 1)
        #expect(results.filter { $0 == .collided }.count == 19)
        #expect(results.filter { $0 == .unexpectedFailure }.isEmpty)
        let stored = try await service.fetchOrders().filter { $0.id == order.id }
        #expect(stored.count == 1)
    }
}

// MARK: - Nested Types

extension OrderServiceTests {

    /// 並發建立訂單的結果
    private enum CreateAttemptResult: Equatable, Sendable {

        /// 訂單已寫入資料庫
        case created

        /// 訂單編號已存在
        case collided

        /// 寫入失敗或撞號編號與送出的訂單不一致
        case unexpectedFailure
    }
}
