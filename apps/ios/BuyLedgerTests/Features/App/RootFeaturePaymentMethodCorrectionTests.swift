//
//  RootFeaturePaymentMethodCorrectionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 TestStore 驗證付款方式更正的確認、取消與寫入失敗
@MainActor
struct RootFeaturePaymentMethodCorrectionTests {

    /// 驗證確認付款方式更正後，服務寫入並回傳正規化的訂單，各頁與訂單都換成同一份訂單
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
        let normalized = RootFeatureTestSupport.rebuiltOrder(
            original,
            paymentMethod: "orders.edit.label.bankTransfer",
            reconciliationStatus: "",
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            isCashOnDelivery: false
        )
        let plan = PaymentMethodEditPlan(
            originalName: "匯款",
            newName: "orders.edit.label.bankTransfer",
            flags: .none,
            hasChangedFlags: true,
            affectedOrders: [normalized]
        )
        let request = PaymentMethodCorrectionFeature.Request(
            originalName: "匯款",
            newName: "orders.edit.label.bankTransfer",
            flags: .none,
            hasChangedFlags: true
        )
        let updatedMaster = PaymentMethodInfo(name: "orders.edit.label.bankTransfer", flags: .none)
        let originalFlags = PaymentMethodFlags(
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        var state = RootFeatureTestSupport.makeIsolatedRootState(lookupKind: .paymentMethod)
        state.orders.$orders.withLock {
            $0 = [original]
        }
        state.more.catalog.$catalog.withLock {
            $0.paymentMethods = [PaymentMethodInfo(name: "匯款", flags: originalFlags)]
        }
        state.more.path[id: 0, case: \.lookupManagement]?.correction.pendingRequest = request
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .retroactiveConfirmation(
            affectedOrderCount: 1
        )
        let writes = LockIsolated<[PaymentMethodEditCall]>([])
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.lookupService.applyPaymentMethodEdit = { oldName, newName, flags in
                writes.withValue {
                    $0.append(
                        PaymentMethodEditCall(oldName: oldName, newName: newName, flags: flags)
                    )
                }
                return [normalized]
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
            $0.more.path[id: 0, case: \.lookupManagement]?.correction.pendingRequest = nil
            $0.more.catalog.$catalog.withLock {
                $0.paymentMethods = [updatedMaster]
            }
            $0.campaigns.$orders.withLock {
                $0 = [normalized]
            }
            $0.more.$orders.withLock {
                $0 = [normalized]
            }
            $0.orders.$orders.withLock {
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
        await store.receive(\.orders.rootRequest.paymentMethodFlagsApply, [normalized])
        await store.receive(\.orders.writes.paymentMethodFlagsApplyRequested, [normalized]) {
            $0.dashboard.orders = [normalized]
            $0.insights.orders = [normalized]
        }
        #expect(store.state.orders.orders == [normalized])
        #expect(store.state.orders.lookupCatalog.paymentMethods == [updatedMaster])
        #expect(
            store.state.more.path[id: 0, case: \.lookupManagement]?.items
                == ["orders.edit.label.bankTransfer"]
        )
        #expect(
            writes.value == [
                PaymentMethodEditCall(
                    oldName: "匯款",
                    newName: "orders.edit.label.bankTransfer",
                    flags: .none
                ),
            ]
        )
        await store.finish()
    }

    /// 驗證取消付款方式更正時，訂單與付款方式清單都保持原樣，不寫入任何變更
    ///
    /// - Note: 未覆寫付款方式寫入的依賴，若被呼叫會使測試失敗
    @Test
    func more_取消付款方式更正_保留訂單與主檔() async {
        // Given
        let original = LedgerOrder.fixture(id: "BL-PM-CANCEL", paymentMethod: "匯款")
        let request = PaymentMethodCorrectionFeature.Request(
            originalName: "匯款",
            newName: "orders.edit.label.bankTransfer",
            flags: .none,
            hasChangedFlags: true
        )
        let originalFlags = PaymentMethodFlags(
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        let originalMaster = PaymentMethodInfo(name: "匯款", flags: originalFlags)
        var state = RootFeatureTestSupport.makeIsolatedRootState(lookupKind: .paymentMethod)
        state.orders.$orders.withLock {
            $0 = [original]
        }
        state.more.catalog.$catalog.withLock { $0.paymentMethods = [originalMaster] }
        state.more.path[id: 0, case: \.lookupManagement]?.correction.pendingRequest = request
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .retroactiveConfirmation(
            affectedOrderCount: 1
        )
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
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
            $0.more.path[id: 0, case: \.lookupManagement]?.correction.pendingRequest = nil
        }
        #expect(store.state.orders.orders == [original])
        #expect(store.state.orders.lookupCatalog.paymentMethods == [originalMaster])
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["匯款"])
        await store.finish()
    }

    /// 驗證付款方式更正寫入失敗時，訂單與付款方式清單都保留原樣，並顯示寫入失敗的提示
    @Test
    func more_付款方式更正寫入失敗_保留訂單與主檔() async {
        // Given
        let original = LedgerOrder.fixture(id: "BL-PM-FAIL", paymentMethod: "匯款")
        let request = PaymentMethodCorrectionFeature.Request(
            originalName: "匯款",
            newName: "orders.edit.label.bankTransfer",
            flags: .none,
            hasChangedFlags: true
        )
        let originalFlags = PaymentMethodFlags(
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        let originalMaster = PaymentMethodInfo(name: "匯款", flags: originalFlags)
        var state = RootFeatureTestSupport.makeIsolatedRootState(lookupKind: .paymentMethod)
        state.orders.$orders.withLock {
            $0 = [original]
        }
        state.more.catalog.$catalog.withLock { $0.paymentMethods = [originalMaster] }
        state.more.path[id: 0, case: \.lookupManagement]?.correction.pendingRequest = request
        state.more.path[id: 0, case: \.lookupManagement]?.destination = .retroactiveConfirmation(
            affectedOrderCount: 1
        )
        let failingApply: LookupService.ApplyPaymentMethodEdit = { _, _, _ throws(PersistenceError) in
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.lookupService.applyPaymentMethodEdit = failingApply
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
            $0.more.path[id: 0, case: \.lookupManagement]?.correction.pendingRequest = nil
        }
        await store.receive(\.more.path[id: 0].lookupManagement.correction.editResponse.failure)
        await store.receive(\.more.path[id: 0].lookupManagement.correction.delegate.failed) {
            $0.more.path[id: 0, case: \.lookupManagement]?.destination = .writeFailure(
                .paymentMethodEdit
            )
        }
        #expect(store.state.orders.orders == [original])
        #expect(store.state.orders.lookupCatalog.paymentMethods == [originalMaster])
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.items == ["匯款"])
        await store.finish()
    }
}

// MARK: - Nested Types

private extension RootFeaturePaymentMethodCorrectionTests {

    /// 付款方式更正寫入時實際收到的一次呼叫參數，用來核對寫入內容
    struct PaymentMethodEditCall: Equatable, Sendable {

        /// 原付款方式名稱
        let oldName: String

        /// 新付款方式名稱
        let newName: String

        /// 寫入的付款方式旗標
        let flags: PaymentMethodFlags
    }
}
