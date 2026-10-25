//
//  PaymentMethodCorrectionFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `PaymentMethodCorrectionFeature` 的單元測試，涵蓋不需確認時的直接寫入，以及查詢筆數或確認後寫入失敗時的處理
@MainActor
struct PaymentMethodCorrectionFeatureTests {

    /// 驗證旗標未變的更正不查詢受影響筆數，直接寫入並送出 `delegate(.edited)`，計畫的 `hasChangedFlags` 為 `false`
    @Test
    func requested_旗標未變更_不查詢筆數直接寫入() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let catalog = PaymentMethodCorrectionFeatureTestSupport.makeCatalog(name: "現金")
            let writes = LockIsolated<
                [PaymentMethodCorrectionFeatureTestSupport.PaymentMethodEditArguments]
            >([])
            let returnedOrder = LedgerOrder.fixture(id: "PM-1", paymentMethod: "新名稱")
            let store = PaymentMethodCorrectionFeatureTestSupport.makeStore(
                catalog: catalog,
                writes: writes,
                returnedOrders: [returnedOrder]
            )

            // When
            await store.send(.requested(originalName: "現金", newName: "新名稱", flags: .none))

            // Then
            let expectedPlan = PaymentMethodEditPlan(
                originalName: "現金",
                newName: "新名稱",
                flags: .none,
                hasChangedFlags: false,
                affectedOrders: [returnedOrder]
            )
            await store.receive(\.editResponse.success, expectedPlan)
            await store.receive(\.delegate.edited, expectedPlan)
            #expect(
                writes.value == [
                    PaymentMethodCorrectionFeatureTestSupport.PaymentMethodEditArguments(
                        oldName: "現金",
                        newName: "新名稱",
                        flags: .none
                    ),
                ]
            )
            await store.finish()
        }
    }

    /// 驗證旗標有變但受影響筆數為零時，不需確認即直接寫入，並送出受影響訂單為空的 `delegate(.edited)`
    @Test
    func requested_筆數為零_不需確認直接寫入() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let catalog = PaymentMethodCorrectionFeatureTestSupport.makeCatalog(name: "現金")
            let changedFlags = PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: true
            )
            let writes = LockIsolated<
                [PaymentMethodCorrectionFeatureTestSupport.PaymentMethodEditArguments]
            >([])
            let store = PaymentMethodCorrectionFeatureTestSupport.makeStore(
                catalog: catalog,
                countOrdersResult: 0,
                writes: writes,
                returnedOrders: []
            )

            // When
            await store.send(.requested(originalName: "現金", newName: "新名稱", flags: changedFlags))

            // Then
            await store.receive(\.countResponse)
            let expectedPlan = PaymentMethodEditPlan(
                originalName: "現金",
                newName: "新名稱",
                flags: changedFlags,
                hasChangedFlags: true,
                affectedOrders: []
            )
            await store.receive(\.editResponse.success, expectedPlan)
            await store.receive(\.delegate.edited, expectedPlan)
            #expect(
                writes.value == [
                    PaymentMethodCorrectionFeatureTestSupport.PaymentMethodEditArguments(
                        oldName: "現金",
                        newName: "新名稱",
                        flags: changedFlags
                    ),
                ]
            )
            await store.finish()
        }
    }

    /// 驗證目錄中沒有原付款方式且旗標未變時，不查詢筆數，直接寫入更正並送出 `delegate(.edited)`
    @Test
    func requested_目錄缺項且旗標未變_不查詢筆數直接寫入() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let catalog = LookupCatalog()
            let writes = LockIsolated<
                [PaymentMethodCorrectionFeatureTestSupport.PaymentMethodEditArguments]
            >([])
            let returnedOrder = LedgerOrder.fixture(id: "PM-EMPTY", paymentMethod: "新名稱")
            let store = PaymentMethodCorrectionFeatureTestSupport.makeStore(
                catalog: catalog,
                writes: writes,
                returnedOrders: [returnedOrder]
            )

            // When
            await store.send(.requested(originalName: "目錄缺項", newName: "新名稱", flags: .none))

            // Then
            let expectedPlan = PaymentMethodEditPlan(
                originalName: "目錄缺項",
                newName: "新名稱",
                flags: .none,
                hasChangedFlags: false,
                affectedOrders: [returnedOrder]
            )
            await store.receive(\.editResponse.success, expectedPlan)
            await store.receive(\.delegate.edited, expectedPlan)
            #expect(
                writes.value == [
                    PaymentMethodCorrectionFeatureTestSupport.PaymentMethodEditArguments(
                        oldName: "目錄缺項",
                        newName: "新名稱",
                        flags: .none
                    ),
                ]
            )
            await store.finish()
        }
    }

    /// 驗證查詢受影響筆數失敗時，送出 `delegate(.failed)`、不進行寫入，目錄維持原樣
    @Test
    func requested_查詢筆數失敗_通知失敗且不寫入() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let catalog = PaymentMethodCorrectionFeatureTestSupport.makeCatalog(name: "原付款方式")
            let flags = PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: false
            )
            let underlyingError = TestDependencies.makeUnderlyingError(message: "boom")
            let failingCountOrders: LookupService.CountOrders = { _ throws(PersistenceError) in
                throw .fetchFailed(underlying: underlyingError)
            }
            let store = PaymentMethodCorrectionFeatureTestSupport.makeStore(
                catalog: catalog,
                failingCountOrders: failingCountOrders
            )

            // When
            await store.send(.requested(originalName: "原付款方式", newName: "新付款方式", flags: flags))

            // Then
            await store.receive(\.countResponse)
            await store.receive(\.delegate.failed)
            #expect(store.state.catalog == catalog)
            await store.finish()
        }
    }

    /// 驗證確認後寫入失敗時，清除 `pendingRequest`，送出 `delegate(.failed)`，目錄維持原樣
    @Test
    func confirmed_付款方式更正寫入失敗_通知失敗() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let catalog = PaymentMethodCorrectionFeatureTestSupport.makeCatalog(name: "原付款方式")
            let flags = PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: true
            )
            let request = PaymentMethodCorrectionFeature.Request(
                originalName: "原付款方式",
                newName: "新付款方式",
                flags: flags,
                hasChangedFlags: true
            )
            let attemptedWrites = LockIsolated<
                [PaymentMethodCorrectionFeatureTestSupport.PaymentMethodEditArguments]
            >([])
            let underlyingError = TestDependencies.makeUnderlyingError(message: "boom")
            let failingApplyEdit: LookupService.ApplyPaymentMethodEdit = { oldName, newName, flags throws(PersistenceError) in
                attemptedWrites.withValue {
                    $0.append(
                        PaymentMethodCorrectionFeatureTestSupport.PaymentMethodEditArguments(
                            oldName: oldName,
                            newName: newName,
                            flags: flags
                        )
                    )
                }
                throw .saveFailed(underlying: underlyingError)
            }
            let store = PaymentMethodCorrectionFeatureTestSupport.makeStore(
                catalog: catalog,
                pendingRequest: request,
                failingApplyEdit: failingApplyEdit
            )

            // When
            await store.send(.confirmed) {
                $0.pendingRequest = nil
            }

            // Then
            await store.receive(\.editResponse.failure)
            await store.receive(\.delegate.failed)
            #expect(store.state.catalog == catalog)
            #expect(
                attemptedWrites.value == [
                    PaymentMethodCorrectionFeatureTestSupport.PaymentMethodEditArguments(
                        oldName: "原付款方式",
                        newName: "新付款方式",
                        flags: flags
                    ),
                ]
            )
            await store.finish()
        }
    }
}
