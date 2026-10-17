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

extension LookupManagementFeatureTests {

    /// 收到付款方式更正結果後更新目錄且保留既有載入錯誤
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

    /// 編輯付款方式表單後查詢受影響訂單筆數並暫存更正確認
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
                $0.pendingAlert = Self.paymentMethodConfirmationAlert(count: 1)
            }
            #expect(store.state.correction.pendingRequest == expectedRequest)
            #expect(store.state.pendingAlert == Self.paymentMethodConfirmationAlert(count: 1))
            await store.finish()
        }
    }

    /// 待確認付款方式更正通過後一起寫入訂單並更新共用目錄
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
            initialState.destination = Self.paymentMethodConfirmationAlert(count: 1)
            @Shared(.lookupCatalog) var sharedCatalog: LookupCatalog
            let expectedWrite = PaymentMethodCorrectionFeatureTests.PaymentMethodEditArguments(
                oldName: "現金",
                newName: "新名稱",
                flags: newFlags
            )
            let expectedPaymentMethod = PaymentMethodInfo(name: "新名稱", flags: newFlags)
            let writes = LockIsolated(
                [PaymentMethodCorrectionFeatureTests.PaymentMethodEditArguments]()
            )
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            } withDependencies: {
                $0.lookupService.applyPaymentMethodEdit = { oldName, newName, flags in
                    writes.withValue {
                        $0.append(
                            PaymentMethodCorrectionFeatureTests.PaymentMethodEditArguments(
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

    /// 查詢付款方式相關訂單失敗時暫存通知並保留主檔
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
                $0.pendingAlert = Self.writeFailureAlert(
                    message: "orders.lookup.message.paymentMethodEdit"
                )
            }
            #expect(store.state.catalog == catalog)
            #expect(store.state.hasLoadFailed == false)
            #expect(
                store.state.pendingAlert
                    == Self.writeFailureAlert(message: "orders.lookup.message.paymentMethodEdit")
            )
            #expect(store.state.destination == nil)
            await store.finish()
        }
    }

    /// 寫入付款方式與訂單失敗時通知失敗且保留主檔
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
                $0.destination = Self.writeFailureAlert(
                    message: "orders.lookup.message.paymentMethodEdit"
                )
            }
            #expect(store.state.catalog == catalog)
            #expect(store.state.hasLoadFailed == false)
            #expect(
                store.state.destination
                    == Self.writeFailureAlert(message: "orders.lookup.message.paymentMethodEdit")
            )
            await store.finish()
        }
    }
}
