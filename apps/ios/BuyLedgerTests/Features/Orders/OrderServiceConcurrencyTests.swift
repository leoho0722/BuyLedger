//
//  OrderServiceConcurrencyTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Testing

@testable import BuyLedger

/// `OrderService` 的單元測試，以 `withTaskGroup` 同時送出建立請求
struct OrderServiceConcurrencyTests {

    /// 驗證二十個並發建立同一編號的訂單時，只有一筆成功，其餘十九筆丟出撞號錯誤，資料庫最後只保留一筆
    ///
    /// - Throws: 讀取失敗時丟出 `.fetchFailed(underlying:)`
    @Test
    func createOrder_並行建立相同識別值_只成功一筆其餘明確撞號() async throws {
        // Given
        let service = OrderServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )
        let order = OrderServiceTestSupport.makeOrder(id: "order-001")

        // When
        let results = await withTaskGroup(of: OrderError?.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    var actualError: OrderError?
                    do throws(OrderError) {
                        try await service.createOrder(order)
                    } catch {
                        actualError = error
                    }
                    return actualError
                }
            }
            var collected: [OrderError?] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        // Then
        let successfulAttempts = results.filter { $0 == nil }.count
        let collidingResults = results.filter { actualError in
            if case .identifierCollision(let id)? = actualError, id == order.id {
                return true
            }
            return false
        }
        let collisions = collidingResults.count
        #expect(successfulAttempts == 1)
        #expect(collisions == 19)
        let stored = try await service.fetchOrders().filter { $0.id == order.id }
        #expect(stored.count == 1)
    }
}
