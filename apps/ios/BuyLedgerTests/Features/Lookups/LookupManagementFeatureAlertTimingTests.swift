//
//  LookupManagementFeatureAlertTimingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `LookupManagementFeature` 的單元測試，以 TestStore 逐步驗證表單關閉前後，失敗與確認提示的呈現時機
@MainActor
struct LookupManagementFeatureAlertTimingTests {

    /// 驗證新增失敗先回覆、表單關閉後，才呈現先前暫存的新增失敗提示
    @Test
    func formSheetDismissed_新增失敗先回覆_關閉後呈現通知() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var initialState = LookupManagementFeature.State(kind: .category)
            initialState.isFormSheetDismissing = true
            initialState.pendingAlert = LookupManagementFeatureTestSupport.writeFailureAlert(
                message: "orders.lookup.message.itemAddedTry"
            )
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            }

            // When
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
                $0.pendingAlert = nil
                $0.destination = LookupManagementFeatureTestSupport.writeFailureAlert(
                    message: "orders.lookup.message.itemAddedTry"
                )
            }

            // Then
            #expect(store.state.isFormSheetDismissing == false)
            #expect(
                store.state.destination
                    == LookupManagementFeatureTestSupport.writeFailureAlert(
                        message: "orders.lookup.message.itemAddedTry"
                    )
            )
            #expect(store.state.pendingAlert == nil)
            await store.finish()
        }
    }

    /// 驗證表單已先關閉時收到新增失敗，立即呈現新增失敗提示，不暫存
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
                $0.destination = LookupManagementFeatureTestSupport.writeFailureAlert(
                    message: "orders.lookup.message.itemAddedTry"
                )
            }

            // Then
            #expect(
                store.state.destination
                    == LookupManagementFeatureTestSupport.writeFailureAlert(
                        message: "orders.lookup.message.itemAddedTry"
                    )
            )
            #expect(store.state.pendingAlert == nil)
            await store.finish()
        }
    }

    /// 驗證表單關閉中收到新增失敗時，先暫存提示到 `pendingAlert`，不立即呈現
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
                $0.pendingAlert = LookupManagementFeatureTestSupport.writeFailureAlert(
                    message: "orders.lookup.message.itemAddedTry"
                )
            }

            // Then
            #expect(store.state.isFormSheetDismissing)
            #expect(
                store.state.pendingAlert
                    == LookupManagementFeatureTestSupport.writeFailureAlert(
                        message: "orders.lookup.message.itemAddedTry"
                    )
            )
            #expect(store.state.destination == nil)
            #expect(store.state.items == ["服飾"])
            await store.finish()
        }
    }

    /// 驗證付款方式需要回溯更正確認時，表單關閉後才呈現確認提示
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
            initialState.correction.pendingRequest = PaymentMethodCorrectionFeature.Request(
                originalName: "現金",
                newName: "新名稱",
                flags: newFlags,
                hasChangedFlags: true
            )
            initialState.pendingAlert = LookupManagementFeatureTestSupport
                .paymentMethodConfirmationAlert(count: 1)
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            }

            // When
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
                $0.pendingAlert = nil
                $0.destination = LookupManagementFeatureTestSupport.paymentMethodConfirmationAlert(
                    count: 1
                )
            }

            // Then
            #expect(store.state.isFormSheetDismissing == false)
            #expect(store.state.pendingAlert == nil)
            #expect(
                store.state.destination
                    == LookupManagementFeatureTestSupport.paymentMethodConfirmationAlert(count: 1)
            )
            await store.finish()
        }
    }

    /// 驗證取消表單時，`destination` 清為 `nil`，`isFormSheetDismissing` 維持 `false`，也不暫存提示
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
