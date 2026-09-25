//
//  OrderPersistenceTests+LookupRenameFailures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/25.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

// MARK: - Tests

extension OrderPersistenceTests {

    /// 存檔失敗時商品類別與訂單都維持原值
    ///
    /// - Parameter example: 寫入前的主檔與訂單狀態
    /// - Throws: 建立測試容器或讀取持久化資料失敗時拋出錯誤
    @Test(arguments: OrderPersistenceTests.LookupRenameFailureExample.examples)
    func renameFailureRollsBack(example: LookupRenameFailureExample) async throws(any Error) {
        // Given
        let orders = example.orderCategories.enumerated().map { entry in
            Self.makeLookupRenameOrder(
                id: "LOOKUP-ROLLBACK-\(entry.offset)",
                categories: entry.element
            )
        }
        let persistence = try Self.makeUnsavablePersistence(
            shouldSeedExistingOrder: false,
            categoryNames: example.categoryNames,
            orders: orders
        )

        // When
        var didFail = false
        do throws(PersistenceError) {
            try await persistence.applyCategoryRename(from: "服飾", to: "衣著")
        } catch {
            didFail = true
        }

        // Then
        let sameContextCategories = try await persistence.fetchLookupNamesForTesting(
            of: CategoryRecord.self
        )
        let sameContextOrders = try await persistence.fetchAll()
        let reader = OrderPersistence(modelContainer: persistence.modelContainer)
        let newReaderCategories = try await reader.fetchLookupNamesForTesting(
            of: CategoryRecord.self
        )
        let newReaderOrders = try await reader.fetchAll()
        let expectedOrders = Dictionary(uniqueKeysWithValues: orders.map { order in
            (order.id, order.categories)
        })
        let sameContextOrderCategories = Dictionary(
            uniqueKeysWithValues: sameContextOrders.map { order in
                (order.id, order.categories)
            }
        )
        let newReaderOrderCategories = Dictionary(
            uniqueKeysWithValues: newReaderOrders.map { order in
                (order.id, order.categories)
            }
        )
        #expect(didFail)
        #expect(Set(sameContextCategories) == Set(example.categoryNames))
        #expect(Set(newReaderCategories) == Set(example.categoryNames))
        #expect(sameContextOrderCategories == expectedOrders)
        #expect(newReaderOrderCategories == expectedOrders)
    }
}
