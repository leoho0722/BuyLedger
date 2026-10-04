//
//  RootFeatureTests+PaymentMethodCorrection.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 付款方式更正確認後，寫入相同的正規化訂單
    @Test
    func more_確認付款方式更正_轉送相同正規化訂單() async {
        // Given
        let original = LedgerOrder.fixture(
            id: "BL-PM-EDIT",
            chargedAmount: 5_000,
            cardlessDeductionAmount: 750,
            cardlessSupplementAmount: 250,
            paymentMethod: "匯款",
            reconciliationStatus: "待對帳",
            isCashOnDelivery: true
        )
        let normalized = LedgerOrder.fixture(
            id: "BL-PM-EDIT",
            chargedAmount: 5_000,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            paymentMethod: "銀行匯款",
            reconciliationStatus: "",
            isCashOnDelivery: false
        )
        let plan = PaymentMethodEditPlan(
            originalName: "匯款",
            newName: "銀行匯款",
            flags: .none,
            hasChangedFlags: true,
            affectedOrders: [normalized]
        )
        let updatedMaster = PaymentMethodInfo(name: "銀行匯款", flags: .none)
        let originalFlags = PaymentMethodFlags(
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        var state = Self.makeIsolatedRootState(lookupKind: .paymentMethod)
        state.orders.orders = [original]
        state.orders.$lookupCatalog.withLock {
            $0.paymentMethods = [PaymentMethodInfo(name: "匯款", flags: originalFlags)]
        }
        state.more.path[id: 0, case: \.lookupManagement]?.correction.pendingPlan = plan
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .retroactiveConfirmation(
            affectedOrderCount: 1
        )
        let writes = LockIsolated<[PaymentMethodEditCall]>([])
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.paymentMethodService.applyPaymentMethodEdit = { oldName, newName, flags, orders in
                writes.withValue {
                    $0.append(
                        PaymentMethodEditCall(
                            oldName: oldName,
                            newName: newName,
                            flags: flags,
                            orders: orders
                        )
                    )
                }
            }
        }

        // When
        await store.send(
            .more(
                .path(
                    .element(
                        id: 0,
                        action: .lookupManagement(
                            .destination(.presented(.alert(.confirmPaymentMethodEdit)))
                        )
                    )
                )
            )
        ) {
            $0.more.path[id: 0, case: \.lookupManagement]?.destination = nil
        }

        // Then
        await store.receive(\.more.path[id: 0].lookupManagement.correction.confirmed) {
            $0.more.path[id: 0, case: \.lookupManagement]?.correction.pendingPlan = nil
            $0.orders.$lookupCatalog.withLock {
                $0.paymentMethods = [updatedMaster]
            }
            $0.campaigns.$orders.withLock {
                $0 = [normalized]
            }
            $0.more.$orders.withLock {
                $0 = [normalized]
            }
        }
        await store.receive(
            \.more.path[id: 0].lookupManagement.correction.editResponse.success,
            plan
        )
        await store.receive(\.more.path[id: 0].lookupManagement.correction.delegate.edited, plan)
        await store.receive(\.more.path[id: 0].lookupManagement.delegate.paymentMethodEdited, plan)
        await store.receive(\.more.delegate.paymentMethodEdited, plan)
        await store.receive(\.orders.paymentMethodFlagsApplied) {
            $0.orders.orders = [normalized]
            $0.dashboard.orders = [normalized]
            $0.insights.orders = [normalized]
        }
        #expect(store.state.orders.orders == [normalized])
        #expect(store.state.orders.paymentMethodMaster == [updatedMaster])
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["銀行匯款"])
        #expect(
            writes.value == [
                PaymentMethodEditCall(
                    oldName: "匯款",
                    newName: "銀行匯款",
                    flags: .none,
                    orders: [normalized]
                ),
            ]
        )
        await store.finish()
    }

    /// 取消付款方式更正確認時，不寫入訂單或主檔
    ///
    /// - Note: `testValue` 的寫入 closure 為 `unimplemented`，非預期寫入會使測試失敗
    @Test
    func more_取消付款方式更正_保留訂單與主檔() async {
        // Given
        let original = LedgerOrder.fixture(id: "BL-PM-CANCEL", paymentMethod: "匯款")
        let correctedOrder = LedgerOrder.fixture(id: "BL-PM-CANCEL", paymentMethod: "銀行匯款")
        let plan = PaymentMethodEditPlan(
            originalName: "匯款",
            newName: "銀行匯款",
            flags: .none,
            hasChangedFlags: true,
            affectedOrders: [correctedOrder]
        )
        let originalFlags = PaymentMethodFlags(
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        let originalMaster = PaymentMethodInfo(name: "匯款", flags: originalFlags)
        var state = Self.makeIsolatedRootState(lookupKind: .paymentMethod)
        state.orders.orders = [original]
        state.orders.$lookupCatalog.withLock { $0.paymentMethods = [originalMaster] }
        state.more.path[id: 0, case: \.lookupManagement]?.correction.pendingPlan = plan
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .retroactiveConfirmation(
            affectedOrderCount: 1
        )
        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(
            .more(
                .path(
                    .element(
                        id: 0,
                        action: .lookupManagement(
                            .destination(.presented(.alert(.cancelPaymentMethodEdit)))
                        )
                    )
                )
            )
        ) {
            $0.more.path[id: 0, case: \.lookupManagement]?.destination = nil
        }

        // Then
        await store.receive(\.more.path[id: 0].lookupManagement.correction.cancelled) {
            $0.more.path[id: 0, case: \.lookupManagement]?.correction.pendingPlan = nil
        }
        #expect(store.state.orders.orders == [original])
        #expect(store.state.orders.paymentMethodMaster == [originalMaster])
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["匯款"])
        await store.finish()
    }

    /// 付款方式更正寫入失敗時，保留原訂單與主檔
    @Test
    func more_付款方式更正寫入失敗_保留訂單與主檔() async {
        // Given
        let original = LedgerOrder.fixture(id: "BL-PM-FAIL", paymentMethod: "匯款")
        let correctedOrder = LedgerOrder.fixture(id: "BL-PM-FAIL", paymentMethod: "銀行匯款")
        let plan = PaymentMethodEditPlan(
            originalName: "匯款",
            newName: "銀行匯款",
            flags: .none,
            hasChangedFlags: true,
            affectedOrders: [correctedOrder]
        )
        let originalFlags = PaymentMethodFlags(
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        let originalMaster = PaymentMethodInfo(name: "匯款", flags: originalFlags)
        var state = Self.makeIsolatedRootState(lookupKind: .paymentMethod)
        state.orders.orders = [original]
        state.orders.$lookupCatalog.withLock { $0.paymentMethods = [originalMaster] }
        state.more.path[id: 0, case: \.lookupManagement]?.correction.pendingPlan = plan
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .retroactiveConfirmation(
            affectedOrderCount: 1
        )
        let failingApply: PaymentMethodService.ApplyPaymentMethodEdit = { _, _, _, _ in
            throw .storage(
                .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
            )
        }
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.paymentMethodService.applyPaymentMethodEdit = failingApply
        }

        // When
        await store.send(
            .more(
                .path(
                    .element(
                        id: 0,
                        action: .lookupManagement(
                            .destination(.presented(.alert(.confirmPaymentMethodEdit)))
                        )
                    )
                )
            )
        ) {
            $0.more.path[id: 0, case: \.lookupManagement]?.destination = nil
        }

        // Then
        await store.receive(\.more.path[id: 0].lookupManagement.correction.confirmed) {
            $0.more.path[id: 0, case: \.lookupManagement]?.correction.pendingPlan = nil
        }
        await store.receive(\.more.path[id: 0].lookupManagement.correction.editResponse.failure)
        await store.receive(\.more.path[id: 0].lookupManagement.correction.delegate.failed) {
            $0.more.path[id: 0, case: \.lookupManagement]?.destination = .writeFailure(
                .paymentMethodEdit
            )
        }
        #expect(store.state.orders.orders == [original])
        #expect(store.state.orders.paymentMethodMaster == [originalMaster])
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["匯款"])
        await store.finish()
    }
}

// MARK: - Nested Types

private extension RootFeatureTests {

    /// 付款方式更正寫入時實際收到的一次呼叫參數，用來核對寫入內容
    struct PaymentMethodEditCall: Equatable, Sendable {

        /// 原付款方式名稱
        let oldName: String

        /// 新付款方式名稱
        let newName: String

        /// 寫入的付款方式旗標
        let flags: PaymentMethodFlags

        /// 傳入的正規化訂單
        let orders: [LedgerOrder]
    }
}
