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

/// 驗證付款方式更正的規劃、確認與交易結果
@MainActor
struct PaymentMethodCorrectionFeatureTests {

    // MARK: - Properties

    /// 各只開一種分類的三組旗標，都和目錄裡的 `.none` 不同
    ///
    /// - Note: `nonisolated` 讓 `@Test(arguments:)` 在隔離測試方法前讀取案例
    nonisolated private static let changedFlags = [
        PaymentMethodFlags(isCardless: true, isBankTransfer: false, isCashOnDelivery: false),
        PaymentMethodFlags(isCardless: false, isBankTransfer: true, isCashOnDelivery: false),
        PaymentMethodFlags(isCardless: false, isBankTransfer: false, isCashOnDelivery: true),
    ]

    // MARK: - Tests

    /// 規劃更正時只處理引用原付款方式的訂單並要求確認
    @Test
    func requested_付款方式旗標已變更_正規化訂單並要求確認() async {
        await LookupCatalog.withIsolatedStorage {
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
            let store = Self.makeStore(
                catalog: Self.makeCatalog(name: "現金"),
                sourceOrders: [matchingOrder, unrelatedOrder]
            )

            // When
            await store.send(.requested(originalName: "現金", newName: "新名稱", flags: flags))

            // Then
            await store.receive(\.planResponse.success, plan) {
                $0.pendingPlan = plan
            }
            await store.receive(\.delegate.confirmationRequired, 1)
            await store.finish()
        }
    }

    /// 三種旗標變更各自產生正確的貨到付款訂單值並要求確認
    ///
    /// - Parameters:
    ///   - flags: 此案例送入更正流程的付款方式旗標
    ///   - expectedIsCashOnDelivery: 預期套用至訂單的貨到付款值
    @Test(arguments: zip(Self.changedFlags, [false, false, true]))
    func requested_三種旗標各自變更_要求使用者確認(
        flags: PaymentMethodFlags,
        expectedIsCashOnDelivery: Bool
    ) async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let sourceOrder = LedgerOrder.fixture(id: "PM-FLAG", paymentMethod: "原付款方式")
            let expectedOrder = LedgerOrder.fixture(
                id: "PM-FLAG",
                paymentMethod: "新付款方式",
                isCashOnDelivery: expectedIsCashOnDelivery
            )
            let plan = PaymentMethodEditPlan(
                originalName: "原付款方式",
                newName: "新付款方式",
                flags: flags,
                hasChangedFlags: true,
                affectedOrders: [expectedOrder]
            )
            let store = Self.makeStore(
                catalog: Self.makeCatalog(name: "原付款方式"),
                sourceOrders: [sourceOrder]
            )

            // When
            await store.send(.requested(originalName: "原付款方式", newName: "新付款方式", flags: flags))

            // Then
            await store.receive(\.planResponse.success, plan) {
                $0.pendingPlan = plan
            }
            await store.receive(\.delegate.confirmationRequired, 1)
            await store.finish()
        }
    }

    /// 零筆訂單、旗標未變或目錄缺項時不要求確認，直接寫入並通知父層
    ///
    /// - Parameter scenario: 直接寫入的資料案例
    @Test(arguments: DirectScenario.allCases)
    func requested_不需確認的更正情境_直接寫入並通知(_ scenario: DirectScenario) async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let expectedPlan = scenario.expectedPlan
            let writes = LockIsolated<[PaymentMethodEditArguments]>([])
            let store = Self.makeStore(
                catalog: scenario.catalog,
                sourceOrders: scenario.sourceOrders,
                writes: writes
            )

            // When
            await store.send(
                .requested(
                    originalName: scenario.originalName,
                    newName: "新付款方式",
                    flags: scenario.flags
                )
            )

            // Then
            await store.receive(\.planResponse.success, expectedPlan)
            await store.receive(\.editResponse.success, expectedPlan)
            await store.receive(\.delegate.edited, expectedPlan)
            #expect(writes.value == [scenario.expectedWrite])
            await store.finish()
        }
    }

    /// 已有待確認方案通過確認後寫入精確參數並通知父層
    @Test
    func confirmed_有待確認方案_寫入並通知父層() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let order = LedgerOrder.fixture(
                id: "PM-CONFIRM",
                paymentMethod: "新付款方式",
                isCashOnDelivery: true
            )
            let plan = Self.makeDefaultPlan(orders: [order])
            let writes = LockIsolated<[PaymentMethodEditArguments]>([])
            let store = Self.makeStore(
                catalog: Self.makeCatalog(name: "原付款方式"),
                pendingPlan: plan,
                writes: writes
            )

            // When
            await store.send(.confirmed) {
                $0.pendingPlan = nil
            }

            // Then
            await store.receive(\.editResponse.success, plan)
            await store.receive(\.delegate.edited, plan)
            #expect(
                writes.value == [
                    PaymentMethodEditArguments(
                        oldName: "原付款方式",
                        newName: "新付款方式",
                        flags: PaymentMethodFlags(
                            isCardless: false,
                            isBankTransfer: false,
                            isCashOnDelivery: true
                        ),
                        orders: [order]
                    ),
                ]
            )
            await store.finish()
        }
    }

    /// 取消待確認方案時清除方案且不觸發持久化
    @Test
    func cancelled_取消待處理更正_清除方案且不寫入() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let catalog = Self.makeCatalog(name: "原付款方式")
            let order = LedgerOrder.fixture(
                id: "PM-CANCEL",
                paymentMethod: "新付款方式",
                isCashOnDelivery: true
            )
            let plan = Self.makeDefaultPlan(orders: [order])
            let store = Self.makeStore(catalog: catalog, pendingPlan: plan)

            // When
            await store.send(.cancelled) {
                $0.pendingPlan = nil
            }

            // Then
            #expect(store.state.pendingPlan == nil)
            #expect(store.state.catalog == catalog)
        }
    }

    /// 讀取相關訂單失敗時回報失敗且保留付款方式目錄
    @Test
    func requested_取得相關訂單失敗_通知失敗且不寫入() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let catalog = Self.makeCatalog(name: "原付款方式")
            let failingFetchOrders: OrderService.FetchOrders = { () throws(PersistenceError) in
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "boom")
                )
            }
            let store = Self.makeStore(catalog: catalog, failingFetchOrders: failingFetchOrders)

            // When
            await store.send(.requested(originalName: "原付款方式", newName: "新付款方式", flags: .none))

            // Then
            await store.receive(\.planResponse.failure)
            await store.receive(\.delegate.failed)
            #expect(store.state.catalog == catalog)
            await store.finish()
        }
    }

    /// 寫入付款方式與訂單失敗時回報失敗且保留原目錄
    @Test
    func confirmed_付款方式更正寫入失敗_通知失敗並保留目錄() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let catalog = Self.makeCatalog(name: "原付款方式")
            let order = LedgerOrder.fixture(
                id: "PM-WRITE-FAIL",
                paymentMethod: "新付款方式",
                isCashOnDelivery: true
            )
            let plan = Self.makeDefaultPlan(orders: [order])
            let attemptedWrites = LockIsolated<[PaymentMethodEditArguments]>([])
            let underlyingError = TestDependencies.makeUnderlyingError(message: "boom")
            let failingApplyEdit: PaymentMethodService.ApplyPaymentMethodEdit = { oldName, newName, flags, orders throws(PaymentMethodPersistenceError) in
                attemptedWrites.withValue {
                    $0.append(
                        PaymentMethodEditArguments(
                            oldName: oldName,
                            newName: newName,
                            flags: flags,
                            orders: orders
                        )
                    )
                }
                throw .storage(.saveFailed(underlying: underlyingError))
            }
            let store = Self.makeStore(
                catalog: catalog,
                pendingPlan: plan,
                failingApplyEdit: failingApplyEdit
            )

            // When
            await store.send(.confirmed) {
                $0.pendingPlan = nil
            }

            // Then
            await store.receive(\.editResponse.failure)
            await store.receive(\.delegate.failed)
            #expect(store.state.catalog == catalog)
            #expect(
                attemptedWrites.value == [
                    PaymentMethodEditArguments(
                        oldName: "原付款方式",
                        newName: "新付款方式",
                        flags: PaymentMethodFlags(
                            isCardless: false,
                            isBankTransfer: false,
                            isCashOnDelivery: true
                        ),
                        orders: [order]
                    ),
                ]
            )
            await store.finish()
        }
    }
}

// MARK: - Nested Types

extension PaymentMethodCorrectionFeatureTests {

    /// 持久化 Service 實際收到的一組付款方式更正參數
    struct PaymentMethodEditArguments: Equatable, Sendable {

        /// 原付款方式名稱
        let oldName: String

        /// 新付款方式名稱
        let newName: String

        /// 寫入的分類旗標
        let flags: PaymentMethodFlags

        /// 寫入的正規化訂單
        let orders: [LedgerOrder]
    }

    /// 不需使用者確認即可直接寫入的案例
    enum DirectScenario: CaseIterable, Equatable, Sendable {

        /// 沒有訂單引用原付款方式
        case zeroAffectedOrders

        /// 付款方式旗標沒有改變
        case unchangedFlags

        /// 目錄中沒有原付款方式
        case missingCatalogEntry

        /// 此案例的原付款方式名稱
        var originalName: String {
            switch self {
            case .zeroAffectedOrders, .unchangedFlags:
                "原付款方式"

            case .missingCatalogEntry:
                "目錄缺項"
            }
        }

        /// 此案例送入更正的旗標
        var flags: PaymentMethodFlags {
            switch self {
            case .zeroAffectedOrders:
                PaymentMethodFlags(isCardless: true, isBankTransfer: false, isCashOnDelivery: false)

            case .unchangedFlags, .missingCatalogEntry:
                .none
            }
        }

        /// 此案例讀取訂單時回傳的訂單
        var sourceOrders: [LedgerOrder] {
            switch self {
            case .zeroAffectedOrders:
                []

            case .unchangedFlags, .missingCatalogEntry:
                [LedgerOrder.fixture(id: "PM-DIRECT", paymentMethod: originalName)]
            }
        }

        /// 此案例的初始付款方式目錄
        var catalog: LookupCatalog {
            switch self {
            case .zeroAffectedOrders, .unchangedFlags:
                LookupCatalog(paymentMethods: [PaymentMethodInfo(name: originalName, flags: .none)])

            case .missingCatalogEntry:
                LookupCatalog()
            }
        }

        /// 此案例送入計畫的旗標是否和主檔不同
        var hasChangedFlags: Bool {
            switch self {
            case .zeroAffectedOrders:
                true

            case .unchangedFlags, .missingCatalogEntry:
                false
            }
        }

        /// 此案例的預期編輯計畫
        var expectedPlan: PaymentMethodEditPlan {
            let affectedOrders: [LedgerOrder]
            switch self {
            case .zeroAffectedOrders:
                affectedOrders = []

            case .unchangedFlags, .missingCatalogEntry:
                affectedOrders = [LedgerOrder.fixture(id: "PM-DIRECT", paymentMethod: "新付款方式")]
            }
            return PaymentMethodEditPlan(
                originalName: originalName,
                newName: "新付款方式",
                flags: flags,
                hasChangedFlags: hasChangedFlags,
                affectedOrders: affectedOrders
            )
        }

        /// 此案例預期的持久化參數
        var expectedWrite: PaymentMethodEditArguments {
            switch self {
            case .zeroAffectedOrders:
                PaymentMethodEditArguments(
                    oldName: "原付款方式",
                    newName: "新付款方式",
                    flags: PaymentMethodFlags(
                        isCardless: true,
                        isBankTransfer: false,
                        isCashOnDelivery: false
                    ),
                    orders: []
                )

            case .unchangedFlags:
                PaymentMethodEditArguments(
                    oldName: "原付款方式",
                    newName: "新付款方式",
                    flags: .none,
                    orders: [LedgerOrder.fixture(id: "PM-DIRECT", paymentMethod: "新付款方式")]
                )

            case .missingCatalogEntry:
                PaymentMethodEditArguments(
                    oldName: "目錄缺項",
                    newName: "新付款方式",
                    flags: .none,
                    orders: [LedgerOrder.fixture(id: "PM-DIRECT", paymentMethod: "新付款方式")]
                )
            }
        }
    }
}

// MARK: - Private Method

private extension PaymentMethodCorrectionFeatureTests {

    /// 建立更正流程的 `TestStore`；沒傳入的替身維持 `testValue` 的 `unimplemented`，被呼叫就讓測試失敗
    ///
    /// - Parameters:
    ///   - catalog: 初始付款方式目錄
    ///   - pendingPlan: 初始待確認更正計畫
    ///   - sourceOrders: 訂單讀取成功時回傳的訂單
    ///   - failingFetchOrders: 訂單讀取失敗時使用的替身
    ///   - writes: 傳入時付款方式寫入一律成功，並記錄每次收到的參數
    ///   - failingApplyEdit: 付款方式交易失敗時使用的替身
    /// - Returns: 已設定初始目錄與待確認計畫 (未傳入時為 `nil`) 的 `TestStore`
    static func makeStore(
        catalog: LookupCatalog,
        pendingPlan: PaymentMethodEditPlan? = nil,
        sourceOrders: [LedgerOrder]? = nil,
        failingFetchOrders: OrderService.FetchOrders? = nil,
        writes: LockIsolated<[PaymentMethodEditArguments]>? = nil,
        failingApplyEdit: PaymentMethodService.ApplyPaymentMethodEdit? = nil
    ) -> TestStoreOf<PaymentMethodCorrectionFeature> {
        var initialState = PaymentMethodCorrectionFeature.State()
        initialState.$catalog.withLock {
            $0 = catalog
        }
        initialState.pendingPlan = pendingPlan

        return TestStore(initialState: initialState) {
            PaymentMethodCorrectionFeature()
        } withDependencies: {
            if let sourceOrders {
                $0.orderService.fetchOrders = {
                    sourceOrders
                }
            }
            if let failingFetchOrders {
                $0.orderService.fetchOrders = failingFetchOrders
            }
            if let writes {
                $0.paymentMethodService.applyPaymentMethodEdit = { oldName, newName, flags, orders in
                    writes.withValue {
                        $0.append(
                            PaymentMethodEditArguments(
                                oldName: oldName,
                                newName: newName,
                                flags: flags,
                                orders: orders
                            )
                        )
                    }
                }
            }
            if let failingApplyEdit {
                $0.paymentMethodService.applyPaymentMethodEdit = failingApplyEdit
            }
        }
    }

    /// 建立含指定原付款方式的目錄
    ///
    /// - Parameter name: 原付款方式名稱
    /// - Returns: 含一筆無分類旗標付款方式的目錄
    static func makeCatalog(name: String) -> LookupCatalog {
        LookupCatalog(paymentMethods: [PaymentMethodInfo(name: name, flags: .none)])
    }

    /// 建立使用固定名稱與已變更旗標的待確認計畫
    ///
    /// - Parameter orders: 更正後的受影響訂單
    /// - Returns: 固定付款方式名稱並啟用貨到付款的計畫
    static func makeDefaultPlan(orders: [LedgerOrder]) -> PaymentMethodEditPlan {
        PaymentMethodEditPlan(
            originalName: "原付款方式",
            newName: "新付款方式",
            flags: PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: true
            ),
            hasChangedFlags: true,
            affectedOrders: orders
        )
    }
}
