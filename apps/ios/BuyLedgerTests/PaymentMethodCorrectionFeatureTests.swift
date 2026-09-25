//
//  PaymentMethodCorrectionFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 付款方式更正流程的單元測試
@MainActor
struct PaymentMethodCorrectionFeatureTests {

    // MARK: - Properties

    /// 驗證付款方式更正時使用的三種旗標
    nonisolated private static let changedFlags = [ // @Test 引數在 actor 隔離外求值
        PaymentMethodFlags(isCardless: true, isBankTransfer: false, isCashOnDelivery: false),
        PaymentMethodFlags(isCardless: false, isBankTransfer: true, isCashOnDelivery: false),
        PaymentMethodFlags(isCardless: false, isBankTransfer: false, isCashOnDelivery: true),
    ]

    // MARK: - Tests

    /// 驗證只找出引用原付款方式的訂單並依旗標正規化後要求確認
    @Test
    func requestedFiltersAndNormalizesOrdersBeforeConfirmation() async {
        // Given
        let flags = Self.changedFlags[0]
        let matchingOrder = LedgerOrder.fixture(
            id: "PM-MATCH",
            chargedAmount: 40,
            cardlessDeductionAmount: 90,
            cardlessSupplementAmount: -5,
            paymentMethod: "現金",
            reconciliationStatus: "  待對帳  "
        )
        let unrelatedOrder = LedgerOrder.fixture(id: "PM-OTHER", paymentMethod: "信用卡")
        let expectedOrder = LedgerOrder.fixture(
            id: "PM-MATCH",
            chargedAmount: 40,
            cardlessDeductionAmount: 40,
            cardlessSupplementAmount: 0,
            paymentMethod: "新名稱",
            reconciliationStatus: "待對帳"
        )
        let plan = PaymentMethodEditPlan(
            originalName: "現金",
            newName: "新名稱",
            flags: flags,
            hasChangedFlags: true,
            affectedOrders: [expectedOrder]
        )

        // When
        await withStore(
            catalog: makeCatalog(name: "現金", flags: .none),
            orders: [matchingOrder, unrelatedOrder]
        ) { store, writeCount in
            await store.send(.requested(originalName: "現金", newName: "新名稱", flags: flags))

            // Then
            await store.receive(\.planResponse.success, plan) {
                $0.pendingPlan = plan
            }
            await store.receive(\.delegate.confirmationRequired, 1)
            #expect(writeCount.withValue { $0 } == 0)
        }
    }

    /// 驗證三種付款方式旗標變更都會要求確認
    ///
    /// - Parameter flags: 這次選取的付款方式旗標
    @Test(arguments: Self.changedFlags)
    func requestedWithChangedFlagsRequiresConfirmation(_ flags: PaymentMethodFlags) async {
        // Given
        let sourceOrder = LedgerOrder.fixture(id: "PM-FLAG", paymentMethod: "原付款方式")
        let expectedOrder = LedgerOrder.fixture(
            id: "PM-FLAG",
            paymentMethod: "新付款方式",
            isCashOnDelivery: flags.isCashOnDelivery
        )
        let plan = PaymentMethodEditPlan(
            originalName: "原付款方式",
            newName: "新付款方式",
            flags: flags,
            hasChangedFlags: true,
            affectedOrders: [expectedOrder]
        )

        // When
        await withStore(
            catalog: makeCatalog(name: "原付款方式", flags: .none),
            orders: [sourceOrder]
        ) { store, writeCount in
            await store.send(.requested(originalName: "原付款方式", newName: "新付款方式", flags: flags))

            // Then
            await store.receive(\.planResponse.success, plan) {
                $0.pendingPlan = plan
            }
            await store.receive(\.delegate.confirmationRequired, 1)
            #expect(writeCount.withValue { $0 } == 0)
        }
    }

    /// 驗證零筆訂單、旗標未變與目錄缺項都直接寫入
    ///
    /// - Parameter scenario: 這次要驗證的直接寫入情境
    @Test(arguments: DirectScenario.allCases)
    func requestedDirectScenariosWriteWithoutConfirmation(_ scenario: DirectScenario) async {
        // Given
        let isCatalogEntryMissing = scenario == .missingCatalogEntry
        let hasNoAffectedOrders = scenario == .zeroAffectedOrders
        let originalName = isCatalogEntryMissing ? "目錄缺項" : "原付款方式"
        let flags: PaymentMethodFlags = hasNoAffectedOrders ? Self.changedFlags[0] : .none
        let sourceOrder = LedgerOrder.fixture(id: "PM-DIRECT", paymentMethod: originalName)
        let expectedOrders = hasNoAffectedOrders
            ? []
            : [LedgerOrder.fixture(id: "PM-DIRECT", paymentMethod: "新付款方式")]
        let catalog = isCatalogEntryMissing
            ? LookupCatalog()
            : makeCatalog(name: originalName, flags: .none)
        let plan = PaymentMethodEditPlan(
            originalName: originalName,
            newName: "新付款方式",
            flags: flags,
            hasChangedFlags: hasNoAffectedOrders,
            affectedOrders: expectedOrders
        )

        // When
        await withStore(
            catalog: catalog,
            orders: hasNoAffectedOrders ? [] : [sourceOrder]
        ) { store, writeCount in
            await store.send(.requested(originalName: originalName, newName: "新付款方式", flags: flags))

            // Then
            await store.receive(\.planResponse.success, plan)
            await store.receive(\.editResponse.success, plan)
            await store.receive(\.delegate.edited, plan)
            #expect(writeCount.withValue { $0 } == 1)
        }
    }

    /// 確認付款方式更正後寫入並通知完成
    @Test
    func confirmedPaymentMethodEditWritesAndNotifiesDelegate() async {
        // Given
        let order = LedgerOrder.fixture(id: "PM-CONFIRM", paymentMethod: "新付款方式")
        let plan = makeDefaultPlan(orders: [order])

        // When
        await withStore(
            catalog: makeCatalog(name: "原付款方式", flags: .none),
            pendingPlan: plan
        ) { store, writeCount in
            await store.send(.confirmed) {
                $0.pendingPlan = nil
            }

            // Then
            await store.receive(\.editResponse.success, plan)
            await store.receive(\.delegate.edited, plan)
            #expect(writeCount.withValue { $0 } == 1)
        }
    }

    /// 取消付款方式更正後清除待確認資料且不寫入
    @Test
    func cancelledPaymentMethodEditClearsPendingPlanWithoutWriting() async {
        // Given
        let catalog = makeCatalog(name: "原付款方式", flags: .none)
        let order = LedgerOrder.fixture(id: "PM-FAIL", paymentMethod: "新付款方式")
        let plan = makeDefaultPlan(orders: [order])

        // When
        await withStore(
            catalog: catalog,
            pendingPlan: plan
        ) { store, writeCount in
            await store.send(.cancelled) {
                $0.pendingPlan = nil
            }

            // Then
            #expect(store.state.pendingPlan == nil)
            #expect(store.state.catalog == catalog)
            #expect(writeCount.withValue { $0 } == 0)
        }
    }

    /// 找出引用原付款方式的訂單失敗時通知父層且不改目錄
    @Test
    func fetchingOrdersFailureNotifiesFailureAndKeepsCatalog() async {
        // Given
        let catalog = makeCatalog(name: "原付款方式", flags: .none)

        // When
        await withStore(catalog: catalog, shouldFailFetch: true) { store, writeCount in
            await store.send(.requested(originalName: "原付款方式", newName: "新付款方式", flags: .none))

            // Then
            await store.receive(\.planResponse.failure)
            await store.receive(\.delegate.failed)
            #expect(store.state.catalog == catalog)
            #expect(writeCount.withValue { $0 } == 0)
        }
    }

    /// 一起寫入付款方式與訂單失敗時通知父層且不改目錄
    @Test
    func writingPaymentMethodEditFailureNotifiesFailureAndKeepsCatalog() async {
        // Given
        let catalog = makeCatalog(name: "原付款方式", flags: .none)
        let order = LedgerOrder.fixture(id: "PM-FAIL", paymentMethod: "新付款方式")
        let plan = makeDefaultPlan(orders: [order])

        // When
        await withStore(
            catalog: catalog,
            pendingPlan: plan,
            shouldFailWrite: true
        ) { store, writeCount in
            await store.send(.confirmed) {
                $0.pendingPlan = nil
            }

            // Then
            await store.receive(\.editResponse.failure)
            await store.receive(\.delegate.failed)
            #expect(store.state.catalog == catalog)
            #expect(writeCount.withValue { $0 } == 1)
        }
    }
}

// MARK: - Nested Types

extension PaymentMethodCorrectionFeatureTests {

    /// 無需確認即可寫入的情境
    enum DirectScenario: CaseIterable, Equatable, Sendable {

        /// 沒有訂單引用原付款方式
        case zeroAffectedOrders

        /// 付款方式旗標沒有變更
        case unchangedFlags

        /// 目錄中沒有原付款方式
        case missingCatalogEntry
    }
}

// MARK: - Private Method

private extension PaymentMethodCorrectionFeatureTests {

    /// 建立隔離目錄與測試 store 後執行操作
    ///
    /// - Parameters:
    ///   - catalog: 測試使用的付款方式目錄
    ///   - pendingPlan: 等待確認的付款方式更正資料
    ///   - orders: 要回傳的相關訂單
    ///   - shouldFailFetch: 是否讓訂單讀取失敗
    ///   - shouldFailWrite: 是否讓付款方式與訂單一起寫入失敗
    ///   - operation: 要在測試 store 上執行的步驟與寫入計數器
    func withStore(
        catalog: LookupCatalog,
        pendingPlan: PaymentMethodEditPlan? = nil,
        orders: [LedgerOrder] = [],
        shouldFailFetch: Bool = false,
        shouldFailWrite: Bool = false,
        operation: @MainActor (
            TestStoreOf<PaymentMethodCorrectionFeature>,
            LockIsolated<Int>
        ) async -> Void
    ) async {
        await LookupCatalog.withIsolatedStorage {
            var state = PaymentMethodCorrectionFeature.State()
            state.$catalog.withLock { $0 = catalog }
            state.pendingPlan = pendingPlan
            let writeCount = LockIsolated(0)
            let store = TestStore(initialState: state) {
                PaymentMethodCorrectionFeature()
            } withDependencies: {
                $0[OrderRepository.self].fetchOrders = { () throws(PersistenceError) in
                    if shouldFailFetch {
                        throw PersistenceError.fetchFailed(
                            underlying: TestDependencies.makeUnderlyingError(message: "boom")
                        )
                    }
                    return orders
                }
                $0[PaymentMethodRepository.self].applyPaymentMethodEdit = { _, _, _, _ throws(PaymentMethodPersistenceError) in
                    writeCount.withValue { $0 += 1 }
                    if shouldFailWrite {
                        throw PaymentMethodPersistenceError.storage(
                            .saveFailed(
                                underlying: TestDependencies.makeUnderlyingError(
                                    message: "boom"
                                )
                            )
                        )
                    }
                }
            }
            await operation(store, writeCount)
        }
    }

    /// 建立含指定付款方式的隔離目錄
    ///
    /// - Parameters:
    ///   - name: 付款方式名稱
    ///   - flags: 付款方式分類旗標
    /// - Returns: 含指定付款方式的目錄
    func makeCatalog(name: String, flags: PaymentMethodFlags) -> LookupCatalog {
        var catalog = LookupCatalog()
        catalog.paymentMethods = [PaymentMethodInfo(name: name, flags: flags)]
        return catalog
    }

    /// 建立使用預設名稱與旗標的付款方式編輯計畫
    ///
    /// - Parameter orders: 更正後的受影響訂單
    /// - Returns: 固定的付款方式編輯計畫
    func makeDefaultPlan(orders: [LedgerOrder]) -> PaymentMethodEditPlan {
        PaymentMethodEditPlan(
            originalName: "原付款方式",
            newName: "新付款方式",
            flags: .none,
            hasChangedFlags: true,
            affectedOrders: orders
        )
    }
}
