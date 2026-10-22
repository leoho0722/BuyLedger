//
//  OrderWritesFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證訂單寫入請求的落盤順序、共用引用與失敗委派
@MainActor
struct OrderWritesFeatureTests {

    // MARK: - Properties

    /// 原訂單，用於驗證失敗時資料不變
    static let original = LedgerOrder.fixture(id: "O1", status: .confirmed, categories: ["美妝"])

    /// 不參與操作的另一筆訂單
    static let other = LedgerOrder.fixture(id: "OTHER", status: .shipping, categories: ["食品"])

    /// 直接要求已合併狀態時不落盤，並通知容器呈現拒絕原因
    @Test
    func statusChangeRequested_目標為已合併_拒絕且保留訂單() async {
        // Given
        let initial = Self.makeState()
        let calls = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { _ in
                calls.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.statusChangeRequested(id: "O1", status: .merged))

        // Then
        await store.receive(\.delegate, .failed(.mergedStatusRejected))
        await store.finish()
        #expect(calls.value == 0)
        #expect(store.state.orders == [Self.original, Self.other])
    }

    /// 找不到訂單或狀態相同時，不呼叫寫入服務
    ///
    /// - Parameter isMissing: 是否指定不存在的訂單
    @Test(arguments: [true, false])
    func statusChangeRequested_不存在或狀態未變_不寫入(isMissing: Bool) async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            OrderWritesFeature()
        }

        // When
        await store.send(
            .statusChangeRequested(id: isMissing ? "MISSING" : "O1", status: .confirmed)
        ) {
            $0.$orders.withLock {
                $0 = [Self.original, Self.other]
            }
        }

        // Then
        await store.finish()
        #expect(store.state.orders == [Self.original, Self.other])
    }

    /// 批次請求不能繞過已合併狀態的寫入守門
    @Test
    func batchStatusChangeRequested_含已合併目標_拒絕整批寫入() async {
        // Given
        let changed = LedgerOrder.fixture(id: "O1", status: .merged, categories: ["美妝"])
        let store = TestStore(initialState: Self.makeState()) {
            OrderWritesFeature()
        }

        // When
        await store.send(.batchStatusChangeRequested([changed])) {
            $0.$orders.withLock {
                $0 = [Self.original, Self.other]
            }
        }

        // Then
        await store.receive(\.delegate, .failed(.mergedStatusRejected))
        await store.finish()
        #expect(store.state.orders == [Self.original, Self.other])
    }

    /// 刪除回應抵達前目標已消失，不再發出刪除委派
    @Test
    func deleteResponse_目標已移除_保留清單且不發出委派() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            OrderWritesFeature()
        }

        // When
        await store.send(.deleteResponse(.success("MISSING"))) {
            $0.$orders.withLock {
                $0 = [Self.original, Self.other]
            }
        }

        // Then
        await store.finish()
        #expect(store.state.orders == [Self.original, Self.other])
    }
}

// MARK: - Internal Method

extension OrderWritesFeatureTests {

    /// 先設定共用初值，再以同一份引用建立寫入狀態
    ///
    /// - Returns: 含兩筆固定訂單的寫入狀態
    static func makeState() -> OrderWritesFeature.State {
        let orders = Shared<[LedgerOrder]>(value: [])
        orders.withLock {
            $0 = [Self.original, Self.other]
        }
        return OrderWritesFeature.State(orders: orders)
    }

    /// 建立編輯既有訂單的草稿與固定表單識別值
    ///
    /// - Returns: 僅修改備註的編輯狀態
    static func makeEdit() -> OrderEditFeature.State {
        var edit = OrderEditFeature.State(
            original: Self.original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        edit.draft.notes = "已修改"
        return edit
    }
}
