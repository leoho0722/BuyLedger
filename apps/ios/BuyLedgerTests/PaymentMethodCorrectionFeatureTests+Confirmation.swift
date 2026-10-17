//
//  PaymentMethodCorrectionFeatureTests+Confirmation.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension PaymentMethodCorrectionFeatureTests {

    /// 三種旗標各自變更時讀取受影響筆數並要求使用者確認
    ///
    /// - Parameters:
    ///   - flags: 此案例送入更正流程的付款方式旗標
    ///   - expectedCount: 預期查詢到的受影響訂單筆數
    @Test(arguments: zip(changedFlags, [1, 2, 3]))
    func requested_三種旗標各自變更_要求使用者確認(flags: PaymentMethodFlags, expectedCount: Int) async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let catalog = Self.makeCatalog(name: "原付款方式")
            let store = Self.makeStore(catalog: catalog, countOrdersResult: expectedCount)

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

    /// 已有待確認請求通過確認後寫入更正並通知父層
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
            let writes = LockIsolated<[PaymentMethodEditArguments]>([])
            let store = Self.makeStore(
                catalog: Self.makeCatalog(name: "原付款方式"),
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
                    PaymentMethodEditArguments(oldName: "原付款方式", newName: "新付款方式", flags: flags),
                ]
            )
            #expect(expectedPlan.affectedOrders == [expectedOrder])
            await store.finish()
        }
    }

    /// 取消待確認請求時清除請求且不觸發持久化
    @Test
    func cancelled_取消待處理更正_清除請求且不寫入() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let catalog = Self.makeCatalog(name: "原付款方式")
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
            let store = Self.makeStore(catalog: catalog, pendingRequest: request)

            // When
            await store.send(.cancelled) {
                $0.pendingRequest = nil
            }

            // Then
            #expect(store.state.pendingRequest == nil)
            #expect(store.state.catalog == catalog)
        }
    }

    /// 請求 A 讀取中送出請求 B 時，受控順序下 A 的零筆結果只寫入 A，B 仍要求確認且未經確認不寫入
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
            let requestA = PaymentMethodCorrectionFeature.Request(
                originalName: "方式A",
                newName: "新方式A",
                flags: flagsA,
                hasChangedFlags: true
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
            let writes = LockIsolated<[PaymentMethodEditArguments]>([])
            let responsesA = AsyncStream<Int>.makeStream()
            let responsesB = AsyncStream<Int>.makeStream()
            var initialState = PaymentMethodCorrectionFeature.State()
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
                            PaymentMethodEditArguments(
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
                    PaymentMethodEditArguments(oldName: "方式A", newName: "新方式A", flags: flagsA),
                ]
            )
            await store.finish()
        }
    }
}
