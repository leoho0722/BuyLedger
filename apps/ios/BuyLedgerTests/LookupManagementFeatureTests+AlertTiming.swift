//
//  LookupManagementFeatureTests+AlertTiming.swift
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

    /// 新增失敗在表單關閉前到達時先暫存提示
    @Test
    func addFailureBeforeFormSheetDismissalWaitsToPresentNotice() async {
        // Given
        await LookupCatalog.withIsolatedStorage {
            let state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock { $0.categories = ["服飾"] }
            let store = TestStore(
                initialState: state
            ) {
                LookupManagementFeature()
            } withDependencies: {
                $0[CategoryRepository.self].addCategory = { _ throws(PersistenceError) in
                    throw PersistenceError.saveFailed(
                        underlying: TestDependencies.makeUnderlyingError(message: "boom")
                    )
                }
            }

            // When
            await store.send(.view(.addButtonTapped)) {
                $0.destination = .add(LookupAddFormFeature.State(hasClassification: false))
            }
            await store.send(
                .destination(
                    .presented(.add(.view(.saveButtonTapped(name: "失敗類別", flags: .none))))
                )
            )
            await store.receive(\.destination.presented.add.delegate.saved) {
                $0.destination = nil
                $0.isFormSheetDismissing = true
            }
            await store.receive(\.addResponse.failure) {
                $0.pendingAlert = Self.failureNotice(message: "新增失敗，請稍後再試。")
            }

            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
                $0.pendingAlert = nil
                $0.destination = Self.failureNotice(message: "新增失敗，請稍後再試。")
            }
            // Then
            #expect(
                store.state.destination == Self.failureNotice(
                    message: "新增失敗，請稍後再試。"
                )
            )
            #expect(store.state.items == ["服飾"])
            #expect(store.state.pendingAlert == nil)
            await store.finish()
        }
    }

    /// 表單關閉後才到達的新增失敗立即顯示提示
    @Test
    func addFailureAfterFormSheetDismissalPresentsNoticeImmediately() async {
        // Given
        await LookupCatalog.withIsolatedStorage {
            var state = LookupManagementFeature.State(kind: .category)
            state.isFormSheetDismissing = true
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            }

            // When
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
            }
            let error = PersistenceError.saveFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "boom")
            )
            await store.send(.addResponse(.failure(error))) {
                $0.destination = Self.failureNotice(message: "新增失敗，請稍後再試。")
            }

            // Then
            #expect(store.state.pendingAlert == nil)
            #expect(
                store.state.destination == Self.failureNotice(
                    message: "新增失敗，請稍後再試。"
                )
            )
            await store.finish()
        }
    }

    /// 付款方式回溯確認在表單關閉後才呈現
    @Test
    func paymentMethodConfirmationWaitsForFormSheetDismissal() async {
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
            let state = LookupManagementFeature.State(kind: .paymentMethod)
            state.$catalog.withLock { catalog in
                catalog.paymentMethods = [PaymentMethodInfo(name: "現金", flags: originalFlags)]
            }
            let originalOrder = Self.makePaymentOrder(id: "PM-TIMING", paymentMethod: "現金")
            let expectedOrder = LedgerOrder.fixture(
                id: "PM-TIMING",
                chargedAmount: 40,
                cardlessDeductionAmount: 40,
                cardlessSupplementAmount: 0,
                paymentMethod: "新名稱",
                reconciliationStatus: "待對帳"
            )
            let plan = PaymentMethodEditPlan(
                originalName: "現金",
                newName: "新名稱",
                flags: newFlags,
                hasChangedFlags: true,
                affectedOrders: [expectedOrder]
            )
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[OrderRepository.self].fetchOrders = { [originalOrder] }
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

            // Then
            #expect(store.state.destination == Self.confirmationAlert(count: 1))
            await store.finish()
        }
    }

    /// 取消表單後收到關閉完成事件不會呈現 alert
    @Test
    func cancellingFormThenReceivingDismissalDoesNotPresentAlert() async {
        // Given
        await LookupCatalog.withIsolatedStorage {
            var state = LookupManagementFeature.State(kind: .category)
            state.destination = .add(LookupAddFormFeature.State(hasClassification: false))
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            }

            // When
            await store.send(.destination(.dismiss)) {
                $0.destination = nil
            }
            await store.send(.view(.formSheetDismissed))

            // Then
            #expect(store.state.destination == nil)
            #expect(store.state.pendingAlert == nil)
            #expect(store.state.isFormSheetDismissing == false)
            await store.finish()
        }
    }
}
