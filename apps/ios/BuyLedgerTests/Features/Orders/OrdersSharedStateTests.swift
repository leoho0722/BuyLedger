//
//  OrdersSharedStateTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證複製的狀態共用同一份訂單，個別建立的狀態互不影響
@MainActor
struct OrdersSharedStateTests {

    /// 驗證複製的狀態收到批次寫入回應後，O1 的狀態改為 `arrived`，原本的狀態也同步看到新訂單
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

    /// 驗證個別建立的狀態不共用訂單儲存，寫入 `first` 的批次回應後，`second` 仍保留原本的 O1 (`confirmed`)
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
