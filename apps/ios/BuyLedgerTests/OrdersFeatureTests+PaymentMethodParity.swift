//
//  OrdersFeatureTests+PaymentMethodParity.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 改付款方式後儲存，寫入的訂單只改付款相關欄位，其餘欄位維持原值
    ///
    /// - Throws: 沒有寫入任何訂單時由 `#require` 丟出
    @Test
    func presentation_手動編輯與回溯更正付款方式_訂單欄位一致() async throws {
        // Given
        let original = LedgerOrder(
            id: "O-PARITY",
            customer: LedgerCustomer(name: "對照測試", initials: "PT", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [
                LedgerOrderItem(
                    id: UUID(0),
                    name: "測試商品",
                    quantity: 1,
                    unitPrice: 5_000
                ),
            ],
            itemCost: 3_000,
            domesticShipping: 125,
            internationalShipping: 275,
            foreignDomesticShipping: 425,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 5_000,
            cardlessDeductionAmount: 750,
            cardlessSupplementAmount: 250,
            orderSource: "來源",
            categories: ["測試"],
            paymentMethod: "舊付款",
            notes: "orders.detail.label.notes",
            reconciliationStatus: " 待對帳 ",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        let newPaymentMethod = PaymentMethodInfo(
            name: "新付款",
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: true
        )
        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            options: OrderEditOptions(
                paymentMethods: [newPaymentMethod],
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.paymentMethod = newPaymentMethod.name
        draft.draft.reconciliationStatus = original.reconciliationStatus
        let expectedOrder = Self.withPaymentFields(
            original,
            paymentMethod: "新付款",
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            reconciliationStatus: "待對帳",
            isCashOnDelivery: true
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
                $0 = [expectedOrder]
            }
        }
        await store.receive(\.presentation.delegate.saveRequested)
        await store.receive(\.writes.saveRequested)
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveResponse)
        await store.receive(\.writes.delegate.saved)
        let manual = try #require(savedOrders.value.first)
        #expect(manual == expectedOrder)
        #expect(manual.paymentMethod == "新付款")
        #expect(manual.cardlessDeductionAmount == 0)
        #expect(manual.cardlessSupplementAmount == 0)
        #expect(manual.reconciliationStatus == "待對帳")
        #expect(manual.isCashOnDelivery)
        #expect(savedOrders.value.count == 1)
    }
}

// MARK: - Private Method

private extension OrdersFeatureTests {

    /// 以訂單為底只替換付款相關欄位，其餘欄位保持原值
    ///
    /// - Parameters:
    ///   - order: 作為底稿的訂單
    ///   - paymentMethod: 付款方式名稱
    ///   - cardlessDeductionAmount: 無卡折抵金額
    ///   - cardlessSupplementAmount: 無卡補款金額
    ///   - reconciliationStatus: 對帳狀態
    ///   - isCashOnDelivery: 是否為貨到付款
    /// - Returns: 替換付款相關欄位後的訂單
    static func withPaymentFields(
        _ order: LedgerOrder,
        paymentMethod: String,
        cardlessDeductionAmount: Decimal,
        cardlessSupplementAmount: Decimal,
        reconciliationStatus: String,
        isCashOnDelivery: Bool
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
            chargedAmount: order.chargedAmount,
            cardlessDeductionAmount: cardlessDeductionAmount,
            cardlessSupplementAmount: cardlessSupplementAmount,
            orderSource: order.orderSource,
            categories: order.categories,
            paymentMethod: paymentMethod,
            notes: order.notes,
            reconciliationStatus: reconciliationStatus,
            campaignNames: order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }
}
