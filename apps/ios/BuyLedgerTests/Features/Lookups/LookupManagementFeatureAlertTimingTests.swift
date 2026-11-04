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

/// `LookupManagementFeature` 的單元測試，以 TestStore 逐步驗證表單關閉前後，寫入失敗通知與確認框的呈現時機
@MainActor
struct LookupManagementFeatureAlertTimingTests {

    /// 驗證新增失敗先回覆、表單關閉後，才把先前暫存的新增失敗通知放進通知狀態
    @Test
    func formSheetDismissed_新增失敗先回覆_關閉後呈現通知() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var initialState = LookupManagementFeature.State(kind: .category)
            initialState.isFormSheetDismissing = true
            initialState.pendingNotice = .add
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            }

            // When
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
                $0.pendingNotice = nil
                $0.notice = LookupManagementFeatureTestSupport.writeFailureAlert(
                    message: "orders.lookup.message.itemAddedTry"
                )
            }

            // Then
            #expect(store.state.isFormSheetDismissing == false)
            #expect(
                store.state.notice
                    == LookupManagementFeatureTestSupport.writeFailureAlert(
                        message: "orders.lookup.message.itemAddedTry"
                    )
            )
            #expect(store.state.destination == nil)
            #expect(store.state.pendingNotice == nil)
            await store.finish()
        }
    }

    /// 驗證表單已先關閉時收到新增失敗，立即放進通知狀態，不暫存也不佔用目的地
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
                $0.notice = LookupManagementFeatureTestSupport.writeFailureAlert(
                    message: "orders.lookup.message.itemAddedTry"
                )
            }

            // Then
            #expect(
                store.state.notice
                    == LookupManagementFeatureTestSupport.writeFailureAlert(
                        message: "orders.lookup.message.itemAddedTry"
                    )
            )
            #expect(store.state.destination == nil)
            #expect(store.state.pendingNotice == nil)
            await store.finish()
        }
    }

    /// 驗證表單關閉中收到新增失敗時，先暫存到 `pendingNotice`，不立即呈現
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
                $0.pendingNotice = .add
            }

            // Then
            #expect(store.state.isFormSheetDismissing)
            #expect(store.state.pendingNotice == .add)
            #expect(store.state.notice == nil)
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
            #expect(store.state.pendingNotice == nil)
            #expect(store.state.isFormSheetDismissing == false)
            await store.finish()
        }
    }

    /// 驗證刪除確認框仍開啟時收到刪除失敗，失敗通知先暫存，不設進通知狀態
    @Test
    func deleteResponse_確認框開啟中收到刪除失敗_暫存通知() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var initialState = LookupManagementFeature.State(kind: .category)
            initialState.$catalog.withLock {
                $0.categories = ["服飾", "美妝"]
            }
            initialState.destination = LookupManagementFeatureTestSupport.deleteConfirmationAlert(
                name: "美妝"
            )
            let error = PersistenceError.saveFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "boom")
            )
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            }

            // When
            await store.send(.deleteResponse(.failure(error))) {
                $0.pendingNotice = .delete
            }

            // Then
            #expect(store.state.notice == nil)
            #expect(store.state.pendingNotice == .delete)
            #expect(
                store.state.destination
                    == LookupManagementFeatureTestSupport.deleteConfirmationAlert(name: "美妝")
            )
            #expect(store.state.items == ["服飾", "美妝"])
            await store.finish()
        }
    }

    /// 驗證確認框關閉且已有暫存的刪除失敗通知時，清空目的地後把通知放進通知狀態
    @Test
    func destination_確認框關閉且有暫存_放進通知狀態() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var initialState = LookupManagementFeature.State(kind: .category)
            initialState.$catalog.withLock {
                $0.categories = ["服飾", "美妝"]
            }
            initialState.destination = LookupManagementFeatureTestSupport.deleteConfirmationAlert(
                name: "美妝"
            )
            initialState.pendingNotice = .delete
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            }

            // When
            await store.send(.destination(.dismiss)) {
                $0.destination = nil
                $0.pendingNotice = nil
                $0.notice = LookupManagementFeatureTestSupport.writeFailureAlert(
                    message: "orders.lookup.message.itemDeletedTry"
                )
            }

            // Then
            #expect(store.state.destination == nil)
            #expect(store.state.pendingNotice == nil)
            #expect(
                store.state.notice
                    == LookupManagementFeatureTestSupport.writeFailureAlert(
                        message: "orders.lookup.message.itemDeletedTry"
                    )
            )
            #expect(store.state.isFormSheetDismissing == false)
            await store.finish()
        }
    }
}
