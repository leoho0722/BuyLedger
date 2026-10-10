//
//  OrdersFeatureTests+EditDeduction.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 無卡存款的折抵大於實收金額時，儲存的折抵改為實收金額
    @Test
    func presentation_無卡折抵超過實收金額_夾限後儲存() async {
        // Given
        let original = Self.makeOrder(
            id: "O-CAP-1",
            categories: ["測試"],
            status: .shipping,
            paymentMethod: "信用卡"
        )

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            options: OrderEditOptions(
                paymentMethods: [
                    PaymentMethodInfo(
                        name: "無卡存款",
                        isCardless: true,
                        isBankTransfer: false,
                        isCashOnDelivery: false
                    ),
                ],
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.paymentMethod = "無卡存款"
        draft.draft.chargedAmount = 1_000
        // 折抵上限為實付金額，避免 `revenue` 變成負數
        draft.draft.cardlessDeductionAmount = 50_000  // 遠大於實付金額
        let expectedOrder = Self.withCardlessAmounts(
            original,
            chargedAmount: 1_000,
            cardlessDeductionAmount: 1_000,  // 收斂為實收金額，不是輸入的 50_000
            paymentMethod: "無卡存款"
        )

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

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$orders.withLock {
                $0[0] = expectedOrder
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
        await store.finish()
    }

    /// 既有訂單的折抵已超過實收金額時，再次儲存會寫入收斂後的折抵
    @Test
    func presentation_既有訂單折抵超過上限_下次儲存時修正() async {
        // Given
        let legacyOverCap = Self.withCardlessAmounts(
            Self.makeOrder(
                id: "O-CAP-2",
                categories: ["測試"],
                status: .shipping,
                paymentMethod: "無卡存款"
            ),
            chargedAmount: 1_000,
            cardlessDeductionAmount: 1_500,
            paymentMethod: "無卡存款"
        )

        let draft = OrderEditFeature.State(
            original: legacyOverCap,
            id: UUID(0),
            options: OrderEditOptions(
                paymentMethods: [
                    PaymentMethodInfo(
                        name: "無卡存款",
                        isCardless: true,
                        isBankTransfer: false,
                        isCashOnDelivery: false
                    ),
                ],
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )
        let expectedOrder = Self.withCardlessAmounts(
            legacyOverCap,
            chargedAmount: 1_000,
            cardlessDeductionAmount: 1_000,
            paymentMethod: "無卡存款"
        )

        var state = OrdersFeature.State(orders: [legacyOverCap])
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

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$orders.withLock {
                $0[0] = expectedOrder
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
        await store.finish()
    }
}
