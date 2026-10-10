//
//  OrdersSharedStateTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// 驗證訂單容器複製時共用引用，個別建立的容器保持獨立
@MainActor
struct OrdersSharedStateTests {

    /// 容器複本的批次寫入同步反映到原容器持有的訂單
    @Test
    func writes_寫入容器複本_原容器同步更新訂單() async {
        // Given
        let original = LedgerOrder.fixture(id: "O1", status: .confirmed)
        let updated = LedgerOrder.fixture(id: "O1", status: .arrived)
        let source = OrdersFeature.State(orders: [original])
        let copy = source
        let store = TestStore(initialState: copy) {
            OrdersFeature()
        }

        // When
        await store.send(.writes(.batchStatusResponse(.success([updated])))) {
            $0.$orders.withLock {
                $0 = [updated]
            }
        }

        // Then
        #expect(source.orders == [updated])
        #expect(copy.orders == [updated])
    }

    /// 個別建立的容器不共用訂單儲存，寫入其中一個不影響另一個
    @Test
    func writes_寫入獨立容器_其他容器保留初值() async {
        // Given
        let original = LedgerOrder.fixture(id: "O1", status: .confirmed)
        let updated = LedgerOrder.fixture(id: "O1", status: .arrived)
        let first = OrdersFeature.State(orders: [original])
        let second = OrdersFeature.State(orders: [original])
        let store = TestStore(initialState: first) {
            OrdersFeature()
        }

        // When
        await store.send(.writes(.batchStatusResponse(.success([updated])))) {
            $0.$orders.withLock {
                $0 = [updated]
            }
        }

        // Then
        #expect(first.orders == [updated])
        #expect(second.orders == [original])
    }
}
