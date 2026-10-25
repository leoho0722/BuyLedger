//
//  OrderServiceMergeFailureMappingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// `OrderService` 的單元測試，涵蓋合併流程中來源查詢失敗如何包裝成持久層讀取錯誤
struct OrderServiceMergeFailureMappingTests {

    /// 驗證合併時查詢來源訂單失敗，回報持久層讀取錯誤並保留底層錯誤，且不寫入合併結果
    ///
    /// - Throws: 核對用的 `ModelContext` 查詢失敗時丟出 SwiftData 底層錯誤；未取得合併錯誤、錯誤不是
    ///   `.storage(.fetchFailed(underlying:))` 時由 `#require` 丟出測試斷言錯誤
    @Test
    func mergeOrders_來源查詢失敗_包裝為持久層讀取錯誤() throws {
        // Given
        let modelContainer = TestContainerCreationLock.withLock {
            PersistenceContainer.makeInMemory(for: .testing)
        }
        let context = ModelContext(modelContainer)
        let hasFetchedConsumedOrders = LockIsolated(false)
        var actualError: OrderError?

        // When
        do {
            try OrderService.mergeOrders(
                OrderServiceTestSupport.makeOrder(id: "ORDER-MERGE-FAIL-RESULT"),
                consumedIDs: ["ORDER-MERGE-FAIL-SOURCE"],
                in: context
            ) { _ throws(PersistenceError) in
                hasFetchedConsumedOrders.setValue(true)
                throw PersistenceError.fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "來源查詢失敗")
                )
            }
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        #expect(hasFetchedConsumedOrders.value)
        let actualStorageError: PersistenceError?
        switch error {
        case .storage(let storageError):
            actualStorageError = storageError

        case .identifierCollision:
            actualStorageError = nil
        }
        let storageError = try #require(actualStorageError)
        let actualFetchFailure: (any Error)?
        switch storageError {
        case .fetchFailed(let underlying):
            actualFetchFailure = underlying

        case .saveFailed, .containerCreationFailed:
            actualFetchFailure = nil
        }
        let fetchFailure = try #require(actualFetchFailure)
        #expect(fetchFailure.localizedDescription == "來源查詢失敗")
        let persistedIDs = try ModelContext(modelContainer)
            .fetch(FetchDescriptor<OrderRecord>())
            .map(\.id)
        #expect(persistedIDs.isEmpty, "static 合併方法不得自行 save 尚未完成的合併結果")
    }
}
