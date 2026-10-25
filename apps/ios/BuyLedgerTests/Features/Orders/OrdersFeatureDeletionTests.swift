//
//  OrdersFeatureDeletionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證訂單刪除確認與詳情路徑的移除
@MainActor
struct OrdersFeatureDeletionTests {

    /// 驗證清單請求刪除既有訂單時，先呈現含客戶名稱的刪除確認 alert，不會直接送出刪除
    @Test
    func list_點選既有訂單_呈現刪除確認() async {
        // Given
        var state = OrdersFeature.State(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "O1", category: "beauty"),
        ])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let expectedConfirmation = OrdersFeatureTestSupport.expectedDeletionConfirmation(
            orderID: "O1",
            customerName: "客戶"
        )
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }

        // When
        await store.send(.list(.delegate(.requested(.delete("O1"))))) {
            $0.presentation.destination = .alert(expectedConfirmation)
        }

        // Then
        #expect(store.state.presentation.destination?.alert == expectedConfirmation)
    }

    /// 驗證確認刪除正在看的訂單後，該訂單從共享清單移除、詳情路徑清空，並只呼叫一次刪除服務
    ///
    /// - Throws: 範例資料找不到該訂單時由 `#require` 丟出
    @Test
    func presentation_確認刪除訂單_移除詳情路徑() async throws {
        // Given
        let originalID = "BL-2604-018"
        let original = try #require(LedgerOrder.sampleOrders.first { $0.id == originalID })
        var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.detail.showDetail(orderID: originalID)
        state.presentation.destination = .alert(
            OrdersFeatureTestSupport.expectedDeletionConfirmation(
                orderID: originalID,
                customerName: original.customer.name
            )
        )

        let removedIDs = LockIsolated<[LedgerOrder.ID]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.removeOrder = { id in
                removedIDs.withValue {
                    $0.append(id)
                }
            }
        }

        // When
        await store.send(
            .presentation(.destination(.presented(.alert(.confirmDelete(originalID)))))
        ) {
            $0.presentation.destination = nil
        }

        // Then
        await store.receive(\.presentation.delegate.deleteConfirmed, originalID) {
            $0.$orders.withLock {
                $0.removeAll {
                    $0.id == originalID
                }
            }
        }
        await store.receive(\.writes.deleteRequested)
        await store.receive(\.writes.deleteResponse)
        await store.receive(\.writes.delegate.deleted) {
            $0.detail.path = StackState()
        }
        #expect(store.state.detail.path.isEmpty)
        #expect(removedIDs.value == [originalID])
    }
}
