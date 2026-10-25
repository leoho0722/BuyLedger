//
//  OrderWritesFeatureRequestsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderWritesFeature` 的單元測試，以 `TestStore` 逐步驗證付款方式旗標套用，以及收款切換不需寫入時保留訂單
@MainActor
struct OrderWritesFeatureRequestsTests {

    // MARK: - Properties

    /// 不需寫入時應維持不變的原訂單
    private static let original = OrderWritesFeatureTestSupport.original

    /// 不參與操作的另一筆訂單
    private static let other = OrderWritesFeatureTestSupport.other

    /// 驗證付款方式旗標套用時，已正規化的訂單覆寫共用清單中的現存訂單並原樣採用其中的數值，清單外的訂單不插入，且不呼叫寫入服務
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
        let initial = OrderWritesFeatureTestSupport.makeCascadeState(orders: [original, Self.other])
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

    /// 驗證收款切換的目標訂單不存在或收款狀態未變時，共用清單保持原樣，且不呼叫寫入服務
    ///
    /// - Parameter isMissing: 是否指定不存在的訂單
    @Test(arguments: [true, false])
    func receiptToggleRequested_不存在或收款未變_保留訂單且不寫入(isMissing: Bool) async {
        // Given
        let initial = OrderWritesFeatureTestSupport.makeState()
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        }

        // When
        await store.send(
            .receiptToggleRequested(id: isMissing ? "MISSING" : "O1", status: .pending)
        )

        // Then
        await store.finish()
        #expect(store.state.orders == [Self.original, Self.other])
    }
}
