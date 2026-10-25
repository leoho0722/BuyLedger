//
//  PaymentMethodCorrectionFeatureConfirmationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `PaymentMethodCorrectionFeature` 的單元測試，涵蓋需要使用者確認的情境，以 TestStore 逐步驗證請求、確認、取消與交錯請求
@MainActor
struct PaymentMethodCorrectionFeatureConfirmationTests {

    // MARK: - Properties

    /// 只開一種分類、與目錄中 `.none` 不同的三組旗標與預期受影響筆數
    ///
    /// - Note: `nonisolated` 讓 `@Test(arguments:)` 在隔離測試方法前讀取案例
    nonisolated static let changedFlagScenarios: [ChangedFlagScenario] = [
        ChangedFlagScenario(
            flags: PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: false
            ),
            expectedCount: 1
        ),
        ChangedFlagScenario(
            flags: PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            ),
            expectedCount: 2
        ),
        ChangedFlagScenario(
            flags: PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: true
            ),
            expectedCount: 3
        ),
    ]

    /// 驗證三種旗標各自變更時，更正請求暫存為 `pendingRequest`，並回報需要確認及案例預期的受影響訂單筆數
    ///
    /// - Parameter scenario: 送入更正流程的付款方式旗標與預期查詢到的受影響訂單筆數
    @Test(arguments: changedFlagScenarios)
    func requested_三種旗標各自變更_要求使用者確認(scenario: ChangedFlagScenario) async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let flags = scenario.flags
            let expectedCount = scenario.expectedCount
            let catalog = PaymentMethodCorrectionFeatureTestSupport.makeCatalog(name: "原付款方式")
            let store = PaymentMethodCorrectionFeatureTestSupport.makeStore(
                catalog: catalog,
                countOrdersResult: expectedCount
            )

            // When
            await store.send(.requested(originalName: "原付款方式", newName: "新付款方式", flags: flags))

            // Then
            let expectedRequest = PaymentMethodCorrectionFeature.Request(
                originalName: "原付款方式",
                newName: "新付款方式",
                flags: flags,
                hasChangedFlags: true
            )
            await store.receive(\.countResponse) {
                $0.pendingRequest = expectedRequest
            }
            await store.receive(\.delegate.confirmationRequired, expectedCount)
            #expect(store.state.pendingRequest == expectedRequest)
            await store.finish()
        }
    }

    /// 驗證確認已暫存的請求時，清除 `pendingRequest`、只寫入一次更正，並把含受影響訂單的結果送給父層
    @Test
    func confirmed_有待確認請求_寫入並通知父層() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
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
            let expectedOrder = LedgerOrder.fixture(
                id: "PM-CONFIRM",
                paymentMethod: "新付款方式",
                isCashOnDelivery: true
            )
            let writes = LockIsolated<
                [PaymentMethodCorrectionFeatureTestSupport.PaymentMethodEditArguments]
            >([])
            let store = PaymentMethodCorrectionFeatureTestSupport.makeStore(
                catalog: PaymentMethodCorrectionFeatureTestSupport.makeCatalog(name: "原付款方式"),
                pendingRequest: request,
                writes: writes,
                returnedOrders: [expectedOrder]
            )

            // When
            await store.send(.confirmed) {
                $0.pendingRequest = nil
            }

            // Then
            let expectedPlan = PaymentMethodEditPlan(
                originalName: "原付款方式",
                newName: "新付款方式",
                flags: flags,
                hasChangedFlags: true,
                affectedOrders: [expectedOrder]
            )
            await store.receive(\.editResponse.success, expectedPlan)
            await store.receive(\.delegate.edited, expectedPlan)
            #expect(
                writes.value == [
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

    /// 驗證取消待確認的更正時，清除 `pendingRequest`，主檔維持原樣且不寫入
    @Test
    func cancelled_取消待處理更正_清除請求且不寫入() async {
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
            let store = PaymentMethodCorrectionFeatureTestSupport.makeStore(
                catalog: catalog,
                pendingRequest: request
            )

            // When
            await store.send(.cancelled) {
                $0.pendingRequest = nil
            }

            // Then
            #expect(store.state.pendingRequest == nil)
            #expect(store.state.catalog == catalog)
        }
    }

    /// 驗證請求 A 尚在查詢時送出請求 B，B 的回應先到時，A 因零筆受影響而直接寫入，B 停在待確認狀態、未經確認不寫入
    @Test
    func requested_交錯更正請求_零筆結果只寫入相符請求且未確認請求不寫入() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let catalog = LookupCatalog(paymentMethods: [
                PaymentMethodInfo(name: "方式A", flags: .none),
                PaymentMethodInfo(name: "方式B", flags: .none),
            ])
            let flagsA = PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: false
            )
            let flagsB = PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: true
            )
            let requestB = PaymentMethodCorrectionFeature.Request(
                originalName: "方式B",
                newName: "新方式B",
                flags: flagsB,
                hasChangedFlags: true
            )
            let orderA = LedgerOrder.fixture(
                id: "PM-A",
                cardlessDeductionAmount: 50,
                paymentMethod: "新方式A"
            )
            let writes = LockIsolated<
                [PaymentMethodCorrectionFeatureTestSupport.PaymentMethodEditArguments]
            >([])
            let responsesA = AsyncStream<Int>.makeStream()
            let responsesB = AsyncStream<Int>.makeStream()
            let initialState = PaymentMethodCorrectionFeature.State()
            initialState.$catalog.withLock {
                $0 = catalog
            }
            let store = TestStore(initialState: initialState) {
                PaymentMethodCorrectionFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
                $0.lookupService.countOrders = { name in
                    if name == "方式A" {
                        var iterator = responsesA.stream.makeAsyncIterator()
                        return await iterator.next() ?? 0
                    }
                    if name == "方式B" {
                        var iterator = responsesB.stream.makeAsyncIterator()
                        return await iterator.next() ?? 0
                    }
                    return 0
                }
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
                    if oldName == "方式A" {
                        return [orderA]
                    }
                    return []
                }
            }
            await store.send(.requested(originalName: "方式A", newName: "新方式A", flags: flagsA))

            // When
            await store.send(.requested(originalName: "方式B", newName: "新方式B", flags: flagsB))

            // Then
            responsesB.continuation.yield(2)
            responsesB.continuation.finish()
            await store.receive(\.countResponse) {
                $0.pendingRequest = requestB
            }
            await store.receive(\.delegate.confirmationRequired, 2)
            responsesA.continuation.yield(0)
            responsesA.continuation.finish()
            await store.receive(\.countResponse)
            let planA = PaymentMethodEditPlan(
                originalName: "方式A",
                newName: "新方式A",
                flags: flagsA,
                hasChangedFlags: true,
                affectedOrders: [orderA]
            )
            await store.receive(\.editResponse.success, planA)
            await store.receive(\.delegate.edited, planA)
            #expect(store.state.pendingRequest == requestB)
            #expect(
                writes.value == [
                    PaymentMethodCorrectionFeatureTestSupport.PaymentMethodEditArguments(
                        oldName: "方式A",
                        newName: "新方式A",
                        flags: flagsA
                    ),
                ]
            )
            await store.finish()
        }
    }
}

// MARK: - Nested Types

extension PaymentMethodCorrectionFeatureConfirmationTests {

    /// 旗標變更測試的參數案例，帶入送入更正流程的旗標與預期受影響訂單筆數
    nonisolated struct ChangedFlagScenario: Sendable {

        /// 送入更正流程的付款方式旗標
        let flags: PaymentMethodFlags

        /// 預期查詢到的受影響訂單筆數
        let expectedCount: Int
    }
}
