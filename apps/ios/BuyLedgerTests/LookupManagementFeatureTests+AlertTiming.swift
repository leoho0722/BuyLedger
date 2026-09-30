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

    /// 關閉表單後才呈現先前暫存的新增失敗提示
    @Test
    func formSheetDismissed_新增失敗先回覆_關閉後呈現通知() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var initialState = LookupManagementFeature.State(kind: .category)
            initialState.isFormSheetDismissing = true
            initialState.pendingAlert = Self.writeFailureAlert(message: "新增失敗，請稍後再試。")
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            }

            // When
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
                $0.pendingAlert = nil
                $0.destination = Self.writeFailureAlert(message: "新增失敗，請稍後再試。")
            }

            // Then
            #expect(store.state.isFormSheetDismissing == false)
            #expect(store.state.destination == Self.writeFailureAlert(message: "新增失敗，請稍後再試。"))
            #expect(store.state.pendingAlert == nil)
            await store.finish()
        }
    }

    /// 表單已關閉後收到新增失敗時立即呈現提示
    @Test
    func addResponse_表單已先關閉_立即呈現新增失敗通知() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let initialState = LookupManagementFeature.State(kind: .category)
            let error = PersistenceError.saveFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "boom")
            )
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            }

            // When
            await store.send(.addResponse(.failure(error))) {
                $0.destination = Self.writeFailureAlert(message: "新增失敗，請稍後再試。")
            }

            // Then
            #expect(store.state.destination == Self.writeFailureAlert(message: "新增失敗，請稍後再試。"))
            #expect(store.state.pendingAlert == nil)
            await store.finish()
        }
    }

    /// 表單關閉中收到新增失敗時先暫存提示
    @Test
    func addResponse_表單關閉中_暫存新增失敗通知() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var initialState = LookupManagementFeature.State(kind: .category)
            initialState.isFormSheetDismissing = true
            initialState.$catalog.withLock {
                $0.categories = ["服飾"]
            }
            let error = PersistenceError.saveFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "boom")
            )
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            }

            // When
            await store.send(.addResponse(.failure(error))) {
                $0.pendingAlert = Self.writeFailureAlert(message: "新增失敗，請稍後再試。")
            }

            // Then
            #expect(store.state.isFormSheetDismissing)
            #expect(store.state.pendingAlert == Self.writeFailureAlert(message: "新增失敗，請稍後再試。"))
            #expect(store.state.destination == nil)
            #expect(store.state.items == ["服飾"])
            await store.finish()
        }
    }

    /// 表單關閉後才顯示付款方式回溯更正確認
    @Test
    func formSheetDismissed_付款方式需要確認_關閉後呈現確認() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let newFlags = PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: false
            )
            var initialState = LookupManagementFeature.State(kind: .paymentMethod)
            initialState.isFormSheetDismissing = true
            initialState.correction.pendingPlan = PaymentMethodEditPlan(
                originalName: "現金",
                newName: "新名稱",
                flags: newFlags,
                hasChangedFlags: true,
                affectedOrders: [
                    LedgerOrder.fixture(
                        id: "PM-TIMING",
                        chargedAmount: 40,
                        cardlessDeductionAmount: 40,
                        cardlessSupplementAmount: 0,
                        paymentMethod: "新名稱",
                        reconciliationStatus: "待對帳"
                    ),
                ]
            )
            initialState.pendingAlert = Self.paymentMethodConfirmationAlert(count: 1)
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            }

            // When
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
                $0.pendingAlert = nil
                $0.destination = Self.paymentMethodConfirmationAlert(count: 1)
            }

            // Then
            #expect(store.state.isFormSheetDismissing == false)
            #expect(store.state.pendingAlert == nil)
            #expect(store.state.destination == Self.paymentMethodConfirmationAlert(count: 1))
            await store.finish()
        }
    }

    /// 取消表單時不會將表單標記為關閉中
    @Test
    func destination_取消表單_不標記表單關閉中() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var initialState = LookupManagementFeature.State(kind: .category)
            initialState.destination = .add(LookupAddFormFeature.State(hasClassification: false))
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            }

            // When
            await store.send(.destination(.dismiss)) {
                $0.destination = nil
            }

            // Then
            #expect(store.state.destination == nil)
            #expect(store.state.pendingAlert == nil)
            #expect(store.state.isFormSheetDismissing == false)
            await store.finish()
        }
    }
}
