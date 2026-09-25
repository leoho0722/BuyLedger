//
//  LookupManagementFeatureTests+PaymentMethodCorrection.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

// MARK: - Tests

extension LookupManagementFeatureTests {

    /// 付款方式更正成功不會清除首次載入失敗狀態
    @Test
    func correctionSuccessKeepsTheInitialLoadFailureState() async {
        // Given
        await LookupCatalog.withIsolatedStorage {
            let originalFlags = PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            )
            let newFlags = PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: false
            )
            var state = LookupManagementFeature.State(kind: .paymentMethod)
            state.hasLoadFailed = true
            state.$catalog.withLock { catalog in
                catalog.paymentMethods = [PaymentMethodInfo(name: "匯款", flags: originalFlags)]
            }
            let plan = PaymentMethodEditPlan(
                originalName: "匯款",
                newName: "銀行匯款",
                flags: newFlags,
                hasChangedFlags: true,
                affectedOrders: []
            )
            let expectedPaymentMethod = PaymentMethodInfo(name: "銀行匯款", flags: newFlags)
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            }

            // When
            await store.send(.correction(.delegate(.edited(plan)))) {
                $0.$catalog.withLock { $0.paymentMethods = [expectedPaymentMethod] }
            }
            await store.receive(\.delegate.paymentMethodEdited, plan)

            // Then
            #expect(store.state.hasLoadFailed)
            await store.finish()
        }
    }

    /// 付款方式表單找出相關訂單、確認並一起寫入後更新主檔
    @Test
    func paymentMethodCorrectionFlowsFromFormThroughConfirmation() async {
        // Given
        await LookupCatalog.withIsolatedStorage {
            let state = LookupManagementFeature.State(kind: .paymentMethod)
            let originalFlags = PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            )
            state.$catalog.withLock { catalog in
                catalog.paymentMethods = [PaymentMethodInfo(name: "現金", flags: originalFlags)]
            }
            @Shared(.lookupCatalog) var sharedCatalog: LookupCatalog
            let originalOrder = Self.makePaymentOrder(id: "PM-PARENT", paymentMethod: "現金")
            let newFlags = PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: false
            )
            let expectedOrder = LedgerOrder.fixture(
                id: "PM-PARENT",
                chargedAmount: 40,
                cardlessDeductionAmount: 40,
                cardlessSupplementAmount: 0,
                paymentMethod: "新名稱",
                reconciliationStatus: "待對帳"
            )
            let expectedPaymentMethod = PaymentMethodInfo(name: "新名稱", flags: newFlags)
            let plan = PaymentMethodEditPlan(
                originalName: "現金",
                newName: "新名稱",
                flags: newFlags,
                hasChangedFlags: true,
                affectedOrders: [expectedOrder]
            )
            let writes = LockIsolated<[PaymentMethodEditPlan]>([])
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[OrderRepository.self].fetchOrders = { [originalOrder] }
                $0[PaymentMethodRepository.self].applyPaymentMethodEdit = { originalName, newName, flags, affectedOrders in
                    writes.withValue { plans in
                        plans.append(
                            PaymentMethodEditPlan(
                                originalName: originalName,
                                newName: newName,
                                flags: flags,
                                hasChangedFlags: true,
                                affectedOrders: affectedOrders
                            )
                        )
                    }
                }
            }

            // When
            await store.send(.view(.editButtonTapped(name: "現金"))) {
                $0.destination = .editPaymentMethod(
                    PaymentMethodEditFormFeature.State(
                        originalName: "現金",
                        flags: originalFlags
                    )
                )
            }
            await store.send(
                .destination(
                    .presented(
                        .editPaymentMethod(
                            .view(.saveButtonTapped(name: "新名稱", flags: newFlags))
                        )
                    )
                )
            )
            await store.receive(\.destination.presented.editPaymentMethod.delegate.saved) {
                $0.destination = nil
                $0.isFormSheetDismissing = true
            }
            await store.receive(\.correction.requested)

            await store.receive(\.correction.planResponse.success, plan) {
                $0.correction.pendingPlan = plan
            }
            await store.receive(\.correction.delegate.confirmationRequired, 1) {
                $0.pendingAlert = Self.confirmationAlert(count: 1)
            }
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
                $0.pendingAlert = nil
                $0.destination = Self.confirmationAlert(count: 1)
            }
            await store.send(
                .destination(.presented(.alert(.confirmPaymentMethodEdit)))
            ) {
                $0.destination = nil
            }
            await store.receive(\.correction.confirmed) {
                $0.correction.pendingPlan = nil
                $0.$catalog.withLock { $0.paymentMethods = [expectedPaymentMethod] }
            }
            await store.receive(\.correction.editResponse.success, plan)
            await store.receive(\.correction.delegate.edited, plan)
            await store.receive(\.delegate.paymentMethodEdited, plan)

            // Then
            #expect(writes.value == [plan])
            #expect(sharedCatalog.paymentMethods == [expectedPaymentMethod])
            #expect(store.state.destination == nil)
            await store.finish()
        }
    }

    /// 找出引用付款方式的訂單失敗時顯示可關閉的一次性提示
    @Test
    func correctionOrderFetchFailureShowsNoticeAndKeepsCatalog() async {
        // Given
        await LookupCatalog.withIsolatedStorage {
            var state = LookupManagementFeature.State(kind: .paymentMethod)
            let catalog = LookupCatalog(
                paymentMethods: [PaymentMethodInfo(name: "信用卡", flags: .none)]
            )
            state.$catalog.withLock { $0 = catalog }
            state.isFormSheetDismissing = true
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[OrderRepository.self].fetchOrders = { () throws(PersistenceError) in
                    throw PersistenceError.fetchFailed(
                        underlying: TestDependencies.makeUnderlyingError(message: "fetch")
                    )
                }
            }

            // When
            await store.send(
                .correction(
                    .requested(
                        originalName: "信用卡",
                        newName: "信用卡",
                        flags: .none
                    )
                )
            )
            await store.receive(\.correction.planResponse.failure)
            await store.receive(\.correction.delegate.failed) {
                $0.pendingAlert = Self.failureNotice(
                    message: "付款方式編輯失敗，請稍後再試。"
                )
            }
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
                $0.pendingAlert = nil
                $0.destination = Self.failureNotice(
                    message: "付款方式編輯失敗，請稍後再試。"
                )
            }
            await store.send(.destination(.dismiss)) {
                $0.destination = nil
            }

            // Then
            #expect(store.state.catalog == catalog)
            #expect(store.state.hasLoadFailed == false)
            #expect(store.state.destination == nil)
            await store.finish()
        }
    }

    /// 一起寫入付款方式與訂單失敗時顯示可關閉的一次性提示
    @Test
    func correctionWriteFailureShowsNoticeAndKeepsCatalog() async {
        // Given
        await LookupCatalog.withIsolatedStorage {
            var state = LookupManagementFeature.State(kind: .paymentMethod)
            let catalog = LookupCatalog(
                paymentMethods: [PaymentMethodInfo(name: "信用卡", flags: .none)]
            )
            state.$catalog.withLock { $0 = catalog }
            state.isFormSheetDismissing = true
            let plan = PaymentMethodEditPlan(
                originalName: "信用卡",
                newName: "信用卡",
                flags: PaymentMethodFlags(
                    isCardless: false,
                    isBankTransfer: false,
                    isCashOnDelivery: true
                ),
                hasChangedFlags: true,
                affectedOrders: [
                    LedgerOrder.fixture(
                        id: "PM-FAIL",
                        paymentMethod: "信用卡",
                        isCashOnDelivery: true
                    )
                ]
            )
            state.correction.pendingPlan = plan
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[PaymentMethodRepository.self].applyPaymentMethodEdit = { _, _, _, _ throws(PaymentMethodPersistenceError) in
                    throw .storage(
                        .saveFailed(
                            underlying: TestDependencies.makeUnderlyingError(message: "write")
                        )
                    )
                }
            }

            // When
            await store.send(.correction(.confirmed)) {
                $0.correction.pendingPlan = nil
            }
            await store.receive(\.correction.editResponse.failure)
            await store.receive(\.correction.delegate.failed) {
                $0.pendingAlert = Self.failureNotice(
                    message: "付款方式編輯失敗，請稍後再試。"
                )
            }
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
                $0.pendingAlert = nil
                $0.destination = Self.failureNotice(
                    message: "付款方式編輯失敗，請稍後再試。"
                )
            }
            await store.send(.destination(.dismiss)) {
                $0.destination = nil
            }

            // Then
            #expect(store.state.catalog == catalog)
            #expect(store.state.hasLoadFailed == false)
            #expect(store.state.destination == nil)
            await store.finish()
        }
    }
}
