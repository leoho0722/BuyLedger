//
//  OrderWritesFeatureTests+Requests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderWritesFeatureTests {

    /// 套用已正規化的付款方式訂單，不重新計算旗標或插入不存在的訂單
    @Test
    func paymentMethodFlagsApplyRequested_已正規化快照_只覆寫現存訂單且不落盤() async {
        // Given
        let original = LedgerOrder.fixture(
            id: "O1",
            chargedAmount: 100,
            cardlessDeductionAmount: 50,
            paymentMethod: "舊付款",
            reconciliationStatus: "待對帳",
            isCashOnDelivery: true
        )
        let normalized = LedgerOrder.fixture(
            id: "O1",
            chargedAmount: 100,
            cardlessDeductionAmount: 20,
            paymentMethod: "新付款",
            reconciliationStatus: "權威值",
            isCashOnDelivery: false
        )
        let removed = LedgerOrder.fixture(id: "REMOVED", paymentMethod: "新付款")
        let initial = Self.makeCascadeState(orders: [original, Self.other])
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        }

        // When
        await store.send(.paymentMethodFlagsApplyRequested([removed, normalized])) {
            $0.$orders.withLock {
                $0 = [normalized, Self.other]
            }
        }

        // Then
        await store.finish()
        #expect(initial.orders == [normalized, Self.other])
        #expect(store.state.orders == [normalized, Self.other])
    }

    /// 找不到訂單或收款狀態相同時，不呼叫寫入服務
    ///
    /// - Parameter isMissing: 是否指定不存在的訂單
    @Test(arguments: [true, false])
    func receiptToggleRequested_不存在或收款未變_保留訂單且不寫入(isMissing: Bool) async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            OrderWritesFeature()
        }

        // When
        await store.send(
            .receiptToggleRequested(id: isMissing ? "MISSING" : "O1", status: .pending)
        ) {
            $0.$orders.withLock {
                $0 = [Self.original, Self.other]
            }
        }

        // Then
        await store.finish()
        #expect(store.state.orders == [Self.original, Self.other])
    }
}
