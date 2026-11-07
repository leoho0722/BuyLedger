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

/// `OrdersFeature` 的單元測試，涵蓋超額折抵的儲存守門與調整後寫入
@MainActor
struct OrdersFeatureEditDeductionTests {

    /// 驗證改成無卡付款並輸入超額折抵時，按儲存不寫入也不關閉表單
    @Test
    func presentation_無卡折抵超過實付_不送出存檔() async {
        // Given
        let original = OrdersFeatureTestSupport.makeOrder(
            id: "O-CAP-1",
            categories: ["測試"],
            status: .shipping,
            paymentMethod: "信用卡"
        )
        var edit = Self.makeEditState(original: original)
        edit.draft.paymentMethod = "無卡存款"
        edit.draft.chargedAmount = 1_000
        edit.draft.cardlessDeductionAmount = 50_000
        let initial = Self.makeOrdersState(original: original, edit: edit)
        let saveCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { _ in
                saveCount.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.finish()
        #expect(store.state == initial)
        #expect(store.state.presentation.destination?.edit?.hasRequiredFields == true)
        #expect(store.state.presentation.destination?.edit?.canSave == false)
        #expect(store.state.presentation.destination?.edit?.draft.cardlessDeductionAmount == 50_000)
        #expect(saveCount.value == 0)
    }

    /// 驗證開啟時已超額的無卡訂單按儲存，仍保留原草稿且不呼叫寫入
    @Test
    func presentation_既有訂單折抵超過上限_不送出存檔() async {
        // Given
        let original = Self.withCardlessAmounts(
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
        let edit = Self.makeEditState(original: original)
        let initial = Self.makeOrdersState(original: original, edit: edit)
        let saveCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { _ in
                saveCount.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.finish()
        #expect(store.state == initial)
        #expect(store.state.presentation.destination?.edit?.draft.cardlessDeductionAmount == 1_500)
        #expect(store.state.presentation.destination?.edit?.isDirty == false)
        #expect(store.state.presentation.destination?.edit?.canSave == false)
        #expect(saveCount.value == 0)
    }

    /// 驗證既有超額訂單把折抵調低為 800 後才可儲存，寫入採用調整後的金額
    @Test
    func presentation_既有訂單折抵超過上限_調低後才儲存() async {
        // Given
        let original = Self.withCardlessAmounts(
            OrdersFeatureTestSupport.makeOrder(
                id: "O-CAP-3",
                categories: ["測試"],
                status: .shipping,
                paymentMethod: "無卡存款"
            ),
            chargedAmount: 1_000,
            cardlessDeductionAmount: 1_500,
            paymentMethod: "無卡存款"
        )
        var edit = Self.makeEditState(original: original)
        edit.draft.cardlessDeductionAmount = 800
        let initial = Self.makeOrdersState(original: original, edit: edit)
        let expectedOrder = Self.withCardlessAmounts(
            original,
            chargedAmount: 1_000,
            cardlessDeductionAmount: 800,
            paymentMethod: "無卡存款"
        )
        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: initial) {
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
        await store.receive(\.presentation.delegate.saveRequested, edit)
        await store.receive(\.writes.saveRequested)
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveResponse)
        await store.receive(\.writes.delegate.saved)
        await store.finish()
        #expect(savedOrders.value == [expectedOrder])
        #expect(savedOrders.value.first?.cardlessDeductionAmount == 800)
        #expect(store.state.presentation.destination?.edit == nil)
    }
}

// MARK: - Private Method

private extension OrdersFeatureEditDeductionTests {

    /// 以既有訂單建立包含無卡付款分類的表單
    ///
    /// - Parameter original: 要編輯的原始訂單
    /// - Returns: 保留原始金額的編輯表單
    static func makeEditState(original: LedgerOrder) -> OrderEditFeature.State {
        OrderEditFeature.State(
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
    }

    /// 建立持有原訂單並呈現編輯表單的訂單頁狀態
    ///
    /// - Parameters:
    ///   - original: 清單中的原始訂單
    ///   - edit: 要呈現的表單草稿
    /// - Returns: 日期固定且表單已呈現的訂單頁狀態
    static func makeOrdersState(
        original: LedgerOrder,
        edit: OrderEditFeature.State
    ) -> OrdersFeature.State {
        var state = OrdersFeature.State(orders: [original])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .edit(edit)
        return state
    }

    /// 建立指定實付、折抵與付款方式的訂單複本
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
