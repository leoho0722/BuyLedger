//
//  OrdersFeatureEditDeductionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證無卡付款折抵金額的上限與儲存修正
@MainActor
struct OrdersFeatureEditDeductionTests {

    /// 驗證無卡存款的折抵大於實收金額時，儲存的折抵改為實收金額
    @Test
    func presentation_無卡折抵超過實收金額_夾限後儲存() async {
        // Given
        let original = OrdersFeatureTestSupport.makeOrder(
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
        // 折抵上限為實收金額，避免 `revenue` 變成負數
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

    /// 驗證既有訂單的折抵已超過實收金額時，再次儲存會寫入收斂後的折抵
    @Test
    func presentation_既有訂單折抵超過上限_下次儲存時修正() async {
        // Given
        let legacyOverCap = Self.withCardlessAmounts(
            OrdersFeatureTestSupport.makeOrder(
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

// MARK: - Private Method

private extension OrdersFeatureEditDeductionTests {

    /// 建立折抵上限測試所需的訂單複本
    ///
    /// - Parameters:
    ///   - order: 要複製的訂單
    ///   - chargedAmount: 客戶實付金額
    ///   - cardlessDeductionAmount: 無卡折抵金額
    ///   - paymentMethod: 付款方式
    /// - Returns: 套用新的實付金額、無卡折抵金額與付款方式後的訂單
    static func withCardlessAmounts(
        _ order: LedgerOrder,
        chargedAmount: Decimal,
        cardlessDeductionAmount: Decimal,
        paymentMethod: String
    ) -> LedgerOrder {
        LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: order.status,
            currency: order.currency,
            date: order.date,
            items: order.items,
            itemCost: order.itemCost,
            domesticShipping: order.domesticShipping,
            internationalShipping: order.internationalShipping,
            foreignDomesticShipping: order.foreignDomesticShipping,
            cardFeeRate: order.cardFeeRate,
            platformFeeRate: order.platformFeeRate,
            paymentFeeRate: order.paymentFeeRate,
            chargedAmount: chargedAmount,
            cardlessDeductionAmount: cardlessDeductionAmount,
            cardlessSupplementAmount: order.cardlessSupplementAmount,
            orderSource: order.orderSource,
            categories: order.categories,
            paymentMethod: paymentMethod,
            notes: order.notes,
            reconciliationStatus: order.reconciliationStatus,
            campaignNames: order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }
}
