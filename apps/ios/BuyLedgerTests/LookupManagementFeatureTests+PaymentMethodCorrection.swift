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
                newName: "銀行匯款",
                flags: newFlags,
                hasChangedFlags: true,
                affectedOrders: []
            )
            let expectedPaymentMethod = PaymentMethodInfo(name: "銀行匯款", flags: newFlags)
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

    /// 編輯付款方式表單後找出受影響訂單並暫存更正確認
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
            let sourceOrder = LedgerOrder.fixture(
                id: "PM-PARENT",
                chargedAmount: 40,
                cardlessDeductionAmount: 90,
                cardlessSupplementAmount: -5,
                paymentMethod: "現金",
                reconciliationStatus: "  待對帳  "
            )
            let expectedOrder = LedgerOrder.fixture(
                id: "PM-PARENT",
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
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            } withDependencies: {
                $0.orderService.fetchOrders = {
                    [sourceOrder]
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
            await store.receive(\.correction.planResponse.success, plan) {
                $0.correction.pendingPlan = plan
            }
            await store.receive(\.correction.delegate.confirmationRequired, 1) {
                $0.pendingAlert = Self.paymentMethodConfirmationAlert(count: 1)
            }
            #expect(store.state.correction.pendingPlan == plan)
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
            initialState.correction.pendingPlan = plan
            initialState.destination = Self.paymentMethodConfirmationAlert(count: 1)
            @Shared(.lookupCatalog) var sharedCatalog: LookupCatalog
            let expectedWrite = PaymentMethodCorrectionFeatureTests.PaymentMethodEditArguments(
                oldName: "現金",
                newName: "新名稱",
                flags: newFlags,
                orders: [expectedOrder]
            )
            let expectedPaymentMethod = PaymentMethodInfo(name: "新名稱", flags: newFlags)
            let writes = LockIsolated(
                [PaymentMethodCorrectionFeatureTests.PaymentMethodEditArguments]()
            )
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            } withDependencies: {
                $0.paymentMethodService.applyPaymentMethodEdit = { oldName, newName, flags, orders in
                    writes.withValue {
                        $0.append(
                            PaymentMethodCorrectionFeatureTests.PaymentMethodEditArguments(
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
            await store.send(.destination(.presented(.alert(.confirmPaymentMethodEdit)))) {
                $0.destination = nil
            }

            // Then
            await store.receive(\.correction.confirmed) {
                $0.correction.pendingPlan = nil
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
            let failingFetchOrders: OrderService.FetchOrders = { () throws(PersistenceError) in
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "fetch")
                )
            }
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            } withDependencies: {
                $0.orderService.fetchOrders = failingFetchOrders
            }

            // When
            await store.send(
                .correction(.requested(originalName: "信用卡", newName: "信用卡", flags: .none))
            )

            // Then
            await store.receive(\.correction.planResponse.failure)
            await store.receive(\.correction.delegate.failed) {
                $0.pendingAlert = Self.writeFailureAlert(message: "付款方式編輯失敗，請稍後再試。")
            }
            #expect(store.state.catalog == catalog)
            #expect(store.state.hasLoadFailed == false)
            #expect(store.state.pendingAlert == Self.writeFailureAlert(message: "付款方式編輯失敗，請稍後再試。"))
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
            let affectedOrder = LedgerOrder.fixture(
                id: "PM-FAIL",
                paymentMethod: "信用卡",
                isCashOnDelivery: true
            )
            let plan = PaymentMethodEditPlan(
                originalName: "信用卡",
                newName: "信用卡",
                flags: PaymentMethodFlags(
                    isCardless: false,
                    isBankTransfer: false,
                    isCashOnDelivery: true
                ),
                hasChangedFlags: true,
                affectedOrders: [affectedOrder]
            )
            var initialState = LookupManagementFeature.State(kind: .paymentMethod)
            initialState.$catalog.withLock {
                $0 = catalog
            }
            initialState.correction.pendingPlan = plan
            let underlyingError = TestDependencies.makeUnderlyingError(message: "write")
            let failingApplyEdit: PaymentMethodService.ApplyPaymentMethodEdit = { _, _, _, _ throws(PaymentMethodPersistenceError) in
                throw .storage(.saveFailed(underlying: underlyingError))
            }
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            } withDependencies: {
                $0.paymentMethodService.applyPaymentMethodEdit = failingApplyEdit
            }

            // When
            await store.send(.correction(.confirmed)) {
                $0.correction.pendingPlan = nil
            }

            // Then
            await store.receive(\.correction.editResponse.failure)
            await store.receive(\.correction.delegate.failed) {
                $0.destination = Self.writeFailureAlert(message: "付款方式編輯失敗，請稍後再試。")
            }
            #expect(store.state.catalog == catalog)
            #expect(store.state.hasLoadFailed == false)
            #expect(store.state.destination == Self.writeFailureAlert(message: "付款方式編輯失敗，請稍後再試。"))
            await store.finish()
        }
    }
}
