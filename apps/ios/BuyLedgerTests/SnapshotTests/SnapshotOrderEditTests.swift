//
//  SnapshotOrderEditTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，以 TestStore 逐步驗證表單與區段出現時不啟動非預期服務
@MainActor
struct SnapshotOrderEditTests {

    /// 驗證訂單編輯快照首次或再次出現時，不讀取服務也不改變表單內容
    ///
    /// - Parameter shouldRepeatTask: 是否先送過一次表單出現事件
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    @Test(arguments: [false, true])
    func task_訂單編輯快照出現_不啟動服務(shouldRepeatTask: Bool) async throws {
        // Given
        let initialState = try SnapshotTestSupport.makeOrderEditSnapshotState(
            original: LedgerOrder.sampleOrders[0]
        )
        let store = TestDependencies.withFixedNow {
            TestStore(initialState: initialState) {
                OrderEditFeature()
            }
        }
        if shouldRepeatTask {
            await store.send(.view(.task))
        }

        // When
        await store.send(.view(.task))

        // Then
        await store.finish()
        #expect(store.state == initialState)
        #expect(store.state.photos.photoLoadPhase == .loaded)
    }

    /// 驗證訂單編輯快照的照片區段首次或再次出現時，不重新讀取照片服務
    ///
    /// - Parameter shouldRepeatTask: 是否先送過一次照片區段出現事件
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    @Test(arguments: [false, true])
    func photos_訂單編輯快照照片區段出現_不啟動服務(shouldRepeatTask: Bool) async throws {
        // Given
        let initialState = try SnapshotTestSupport.makeOrderEditSnapshotState(
            original: LedgerOrder.sampleOrders[0]
        )
        let store = TestDependencies.withFixedNow {
            TestStore(initialState: initialState) {
                OrderEditFeature()
            }
        }
        if shouldRepeatTask {
            await store.send(.photos(.view(.task)))
        }

        // When
        await store.send(.photos(.view(.task)))

        // Then
        await store.finish()
        #expect(store.state == initialState)
        #expect(store.state.photos.photoLoadPhase == .loaded)
    }
}
