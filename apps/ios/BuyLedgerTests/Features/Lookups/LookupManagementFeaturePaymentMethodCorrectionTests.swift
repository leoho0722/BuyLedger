//
//  LookupManagementFeaturePaymentMethodCorrectionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `LookupManagementFeature` 的單元測試，以 TestStore 逐步驗證付款方式編輯後的筆數查詢、確認與更正寫入
@MainActor
struct LookupManagementFeaturePaymentMethodCorrectionTests {

    /// 驗證付款方式更正成功的結果送達時，目錄改為新付款方式並送出 `delegate(.paymentMethodEdited)`，既有的載入失敗狀態保留
    @Test
    func correction_付款方式更正成功_保留初始載入失敗狀態() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
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
            var initialState = LookupManagementFeature.State(kind: .paymentMethod)
            initialState.hasLoadFailed = true
            initialState.$catalog.withLock {
                $0.paymentMethods = [PaymentMethodInfo(name: "匯款", flags: originalFlags)]
            }
            let plan = PaymentMethodEditPlan(
                originalName: "匯款",
                newName: "orders.edit.label.bankTransfer",
                flags: newFlags,
                hasChangedFlags: true,
                affectedOrders: []
            )
            let expectedPaymentMethod = PaymentMethodInfo(
                name: "orders.edit.label.bankTransfer",
                flags: newFlags
            )
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            }

            // When
            await store.send(.correction(.delegate(.edited(plan)))) {
                $0.$catalog.withLock {
                    $0.paymentMethods = [expectedPaymentMethod]
                }
            }

            // Then
            await store.receive(\.delegate.paymentMethodEdited, plan)
            #expect(store.state.hasLoadFailed)
            await store.finish()
        }
    }

    /// 驗證編輯付款方式且影響 1 筆訂單時，更正請求存入 `pendingRequest`，確認框暫存為 `pendingAlert` 且尚未呈現
    @Test
    func destination_編輯付款方式且影響訂單_暫存更正確認() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
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
            var initialState = LookupManagementFeature.State(kind: .paymentMethod)
            initialState.$catalog.withLock {
                $0.paymentMethods = [PaymentMethodInfo(name: "現金", flags: originalFlags)]
            }
            initialState.destination = .editPaymentMethod(
                PaymentMethodEditFormFeature.State(originalName: "現金", flags: originalFlags)
            )
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            } withDependencies: {
                $0.lookupService.countOrders = { _ in
                    1
                }
            }

            // When
            await store.send(
                .destination(
                    .presented(
                        .editPaymentMethod(.view(.saveButtonTapped(name: "新名稱", flags: newFlags)))
                    )
                )
            )

            // Then
            await store.receive(\.destination.presented.editPaymentMethod.delegate.saved) {
                $0.destination = nil
                $0.isFormSheetDismissing = true
            }
            await store.receive(\.correction.requested)
            let expectedRequest = PaymentMethodCorrectionFeature.Request(
                originalName: "現金",
                newName: "新名稱",
                flags: newFlags,
                hasChangedFlags: true
            )
            await store.receive(\.correction.countResponse) {
                $0.correction.pendingRequest = expectedRequest
            }
            await store.receive(\.correction.delegate.confirmationRequired, 1) {
                $0.pendingAlert = LookupManagementFeatureTestSupport.paymentMethodConfirmationAlert(
                    count: 1
                )
            }
            #expect(store.state.correction.pendingRequest == expectedRequest)
            #expect(
                store.state.pendingAlert
                    == LookupManagementFeatureTestSupport.paymentMethodConfirmationAlert(count: 1)
            )
            await store.finish()
        }
    }

    /// 驗證確認更正時，服務以新名稱與旗標寫入一次，目錄與共享目錄改為新付款方式，並以服務回傳的受影響訂單送出 `delegate(.paymentMethodEdited)`
    @Test
    func destination_確認更正付款方式_一起寫入並更新主檔() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
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
            let expectedOrder = LedgerOrder.fixture(
                id: "PM-PARENT",
                chargedAmount: 40,
                cardlessDeductionAmount: 40,
                cardlessSupplementAmount: 0,
                paymentMethod: "新名稱",
                reconciliationStatus: "待對帳"
            )
            let request = PaymentMethodCorrectionFeature.Request(
                originalName: "現金",
                newName: "新名稱",
                flags: newFlags,
                hasChangedFlags: true
            )
            let plan = PaymentMethodEditPlan(
                originalName: "現金",
                newName: "新名稱",
                flags: newFlags,
                hasChangedFlags: true,
                affectedOrders: [expectedOrder]
            )
            var initialState = LookupManagementFeature.State(kind: .paymentMethod)
            initialState.$catalog.withLock {
                $0.paymentMethods = [PaymentMethodInfo(name: "現金", flags: originalFlags)]
            }
            initialState.correction.pendingRequest = request
            initialState.destination = LookupManagementFeatureTestSupport
                .paymentMethodConfirmationAlert(count: 1)
            @Shared(.lookupCatalog) var sharedCatalog: LookupCatalog
            let expectedWrite = PaymentMethodCorrectionFeatureTestSupport.PaymentMethodEditArguments(
                oldName: "現金",
                newName: "新名稱",
                flags: newFlags
            )
            let expectedPaymentMethod = PaymentMethodInfo(name: "新名稱", flags: newFlags)
            let writes = LockIsolated(
                [PaymentMethodCorrectionFeatureTestSupport.PaymentMethodEditArguments]()
            )
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            } withDependencies: {
                $0.lookupService.applyPaymentMethodEdit = { oldName, newName, flags in
                    writes.withValue {
                        $0.append(
                            PaymentMethodCorrectionFeatureTestSupport.PaymentMethodEditArguments(
                                oldName: oldName,
                                newName: newName,
                                flags: flags
                            )
                        )
                    }
                    return [expectedOrder]
                }
            }

            // When
            await store.send(.destination(.presented(.alert(.confirmPaymentMethodEdit)))) {
                $0.destination = nil
            }

            // Then
            await store.receive(\.correction.confirmed) {
                $0.correction.pendingRequest = nil
                $0.$catalog.withLock {
                    $0.paymentMethods = [expectedPaymentMethod]
                }
            }
            await store.receive(\.correction.editResponse.success, plan)
            await store.receive(\.correction.delegate.edited, plan)
            await store.receive(\.delegate.paymentMethodEdited, plan)
            #expect(store.state.destination == nil)
            #expect(writes.value == [expectedWrite])
            #expect(sharedCatalog.paymentMethods == [expectedPaymentMethod])
            await store.finish()
        }
    }

    /// 驗證查詢受影響訂單筆數失敗時，主檔維持原狀且不標記為載入失敗，寫入失敗提示暫存為 `pendingAlert`，表單關閉前不呈現
    @Test
    func correction_取得相關訂單失敗_暫存通知並保留主檔() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let paymentMethod = PaymentMethodInfo(name: "信用卡", flags: .none)
            let catalog = LookupCatalog(paymentMethods: [paymentMethod])
            var initialState = LookupManagementFeature.State(kind: .paymentMethod)
            initialState.$catalog.withLock {
                $0 = catalog
            }
            initialState.isFormSheetDismissing = true
            let changedFlags = PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: false
            )
            let failingCountOrders: LookupService.CountOrders = { _ throws(PersistenceError) in
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "fetch")
                )
            }
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            } withDependencies: {
                $0.lookupService.countOrders = failingCountOrders
            }

            // When
            await store.send(
                .correction(.requested(originalName: "信用卡", newName: "信用卡", flags: changedFlags))
            )

            // Then
            await store.receive(\.correction.countResponse)
            await store.receive(\.correction.delegate.failed) {
                $0.pendingAlert = LookupManagementFeatureTestSupport.writeFailureAlert(
                    message: "orders.lookup.message.paymentMethodEdit"
                )
            }
            #expect(store.state.catalog == catalog)
            #expect(store.state.hasLoadFailed == false)
            #expect(
                store.state.pendingAlert
                    == LookupManagementFeatureTestSupport.writeFailureAlert(
                        message: "orders.lookup.message.paymentMethodEdit"
                    )
            )
            #expect(store.state.destination == nil)
            await store.finish()
        }
    }

    /// 驗證確認更正寫入失敗時，主檔維持原狀且不標記為載入失敗，寫入失敗提示直接呈現在 `destination`
    @Test
    func correction_更正寫入失敗_顯示通知並保留主檔() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let paymentMethod = PaymentMethodInfo(name: "信用卡", flags: .none)
            let catalog = LookupCatalog(paymentMethods: [paymentMethod])
            let flags = PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: true
            )
            let request = PaymentMethodCorrectionFeature.Request(
                originalName: "信用卡",
                newName: "信用卡",
                flags: flags,
                hasChangedFlags: true
            )
            var initialState = LookupManagementFeature.State(kind: .paymentMethod)
            initialState.$catalog.withLock {
                $0 = catalog
            }
            initialState.correction.pendingRequest = request
            let underlyingError = TestDependencies.makeUnderlyingError(message: "write")
            let failingApplyEdit: LookupService.ApplyPaymentMethodEdit = { _, _, _ throws(PersistenceError) in
                throw .saveFailed(underlying: underlyingError)
            }
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            } withDependencies: {
                $0.lookupService.applyPaymentMethodEdit = failingApplyEdit
            }

            // When
            await store.send(.correction(.confirmed)) {
                $0.correction.pendingRequest = nil
            }

            // Then
            await store.receive(\.correction.editResponse.failure)
            await store.receive(\.correction.delegate.failed) {
                $0.destination = LookupManagementFeatureTestSupport.writeFailureAlert(
                    message: "orders.lookup.message.paymentMethodEdit"
                )
            }
            #expect(store.state.catalog == catalog)
            #expect(store.state.hasLoadFailed == false)
            #expect(
                store.state.destination
                    == LookupManagementFeatureTestSupport.writeFailureAlert(
                        message: "orders.lookup.message.paymentMethodEdit"
                    )
            )
            await store.finish()
        }
    }
}
