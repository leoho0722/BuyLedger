//
//  SnapshotTests+OrderEdit.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension SnapshotTests {

    /// 訂單編輯快照首次或再次出現時，不讀取服務或改變表單內容
    ///
    /// - Parameter shouldRepeatTask: 是否先送過一次表單出現事件
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    @Test(arguments: [false, true])
    func task_訂單編輯快照出現_不啟動服務(shouldRepeatTask: Bool) async throws {
        // Given
        let initialState = try Self.makeOrderEditSnapshotState(
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

    /// 訂單編輯快照的照片區段首次或再次出現時，不重新讀取照片服務
    ///
    /// - Parameter shouldRepeatTask: 是否先送過一次照片區段出現事件
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    @Test(arguments: [false, true])
    func photos_訂單編輯快照照片區段出現_不啟動服務(shouldRepeatTask: Bool) async throws {
        // Given
        let initialState = try Self.makeOrderEditSnapshotState(
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

// MARK: - Internal Method

extension SnapshotTests {

    /// 建立內容固定且照片已載入的訂單編輯快照，避免區段出現時啟動讀取
    ///
    /// - Parameter original: 快照要顯示的既有訂單
    /// - Returns: 沿用訂單內容、固定時間與已載入照片的表單狀態
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    static func makeOrderEditSnapshotState(original: LedgerOrder) throws -> OrderEditFeature.State {
        var state = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            options: OrderEditOptions(calendar: try makeOrderEditCalendar()),
            currentDate: TestDependencies.fixedNow
        )
        // key window 渲染可能觸發照片區段的載入，快照只呈現已備妥的內容
        state.photos.photoLoadPhase = .loaded
        return state
    }
}

// MARK: - Private Method

private extension SnapshotTests {

    /// 建立時區固定為 `Asia/Taipei` 的西曆，供表單的完整時間格式化使用
    ///
    /// - Returns: 時區明確設為 `Asia/Taipei` 的西曆
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    static func makeOrderEditCalendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Taipei"))
        return calendar
    }
}
