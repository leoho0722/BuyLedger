//
//  OrdersFeatureTests+Deletion.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 點選刪除既有訂單時，先呈現含客戶名稱的刪除確認
    @Test
    func list_點選既有訂單_呈現刪除確認() async {
        // Given
        var state = OrdersFeature.State(orders: [Self.makeOrder(id: "O1", category: "beauty")])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let expectedConfirmation = Self.expectedDeletionConfirmation(
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

    /// 確認刪除後，正在看的該筆訂單詳情一併關閉
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
            Self.expectedDeletionConfirmation(
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
