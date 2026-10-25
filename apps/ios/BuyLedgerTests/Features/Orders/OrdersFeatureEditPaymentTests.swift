//
//  OrdersFeatureEditPaymentTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證付款方式變更後的對帳狀態處理
@MainActor
struct OrdersFeatureEditPaymentTests {

    /// 驗證付款方式改成銀行匯款後儲存，已填寫的對帳狀態會保留並寫入訂單
    @Test
    func presentation_銀行匯款訂單儲存_保留對帳狀態() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1", categories: ["美妝"])

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            options: OrderEditOptions(
                paymentMethods: [
                    PaymentMethodInfo(
                        name: "orders.edit.label.bankTransfer",
                        isCardless: false,
                        isBankTransfer: true,
                        isCashOnDelivery: false
                    ),
                ],
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.paymentMethod = "orders.edit.label.bankTransfer"
        draft.draft.reconciliationStatus = "待對帳"

        var state = OrdersFeature.State(orders: [original])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .edit(draft)

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(
            id: "order-1",
            categories: ["美妝"],
            paymentMethod: "orders.edit.label.bankTransfer",
            reconciliationStatus: "待對帳"
        )

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$orders.withLock {
                $0 = [expectedOrder]
            }
        }
        await store.receive(\.presentation.delegate.saveRequested, draft)
        await store.receive(\.writes.saveRequested)
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveResponse)
        await store.receive(\.writes.delegate.saved)
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 驗證付款方式從銀行匯款改成信用卡後儲存，原本的對帳狀態會清空後寫入
    @Test
    func presentation_改用不需對帳付款方式_清除對帳狀態() async {
        // Given
        let original = LedgerOrder.fixture(
            id: "order-1",
            categories: ["美妝"],
            paymentMethod: "orders.edit.label.bankTransfer",
            reconciliationStatus: "待對帳"
        )

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            options: OrderEditOptions(
                paymentMethods: [
                    PaymentMethodInfo(
                        name: "orders.edit.label.bankTransfer",
                        isCardless: false,
                        isBankTransfer: true,
                        isCashOnDelivery: false
                    ),
                    PaymentMethodInfo(
                        name: "信用卡",
                        isCardless: false,
                        isBankTransfer: false,
                        isCashOnDelivery: false
                    ),
                ],
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.paymentMethod = "信用卡"

        var state = OrdersFeature.State(orders: [original])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .edit(draft)

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(
            id: "order-1",
            categories: ["美妝"],
            paymentMethod: "信用卡",
            reconciliationStatus: ""
        )

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$orders.withLock {
                $0 = [expectedOrder]
            }
        }
        await store.receive(\.presentation.delegate.saveRequested, draft)
        await store.receive(\.writes.saveRequested)
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveResponse)
        await store.receive(\.writes.delegate.saved)
        #expect(savedOrders.value == [expectedOrder])
    }
}
