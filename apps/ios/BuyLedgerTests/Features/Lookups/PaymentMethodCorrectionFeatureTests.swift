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

/// 驗證付款方式更正的直接寫入、錯誤處理與測試替身
@MainActor
struct PaymentMethodCorrectionFeatureTests {

    // MARK: - Properties

    /// 各只開一種分類的三組旗標，都和目錄裡的 `.none` 不同
    ///
    /// - Note: `nonisolated` 讓 `@Test(arguments:)` 在隔離測試方法前讀取案例
    nonisolated static let changedFlags = [
        PaymentMethodFlags(isCardless: true, isBankTransfer: false, isCashOnDelivery: false),
        PaymentMethodFlags(isCardless: false, isBankTransfer: true, isCashOnDelivery: false),
        PaymentMethodFlags(isCardless: false, isBankTransfer: false, isCashOnDelivery: true),
    ]

    /// 付款方式旗標未變時不查詢訂單筆數，直接寫入更正並通知父層
    @Test
    func requested_旗標未變更_不查詢筆數直接寫入() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let catalog = Self.makeCatalog(name: "現金")
            let writes = LockIsolated<[PaymentMethodEditArguments]>([])
            let returnedOrder = LedgerOrder.fixture(id: "PM-1", paymentMethod: "新名稱")
            let store = Self.makeStore(
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
                    PaymentMethodEditArguments(oldName: "現金", newName: "新名稱", flags: .none),
                ]
            )
            await store.finish()
        }
    }

    /// 受影響訂單筆數為零時不需確認，直接寫入更正並通知父層
    @Test
    func requested_筆數為零_不需確認直接寫入() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let catalog = Self.makeCatalog(name: "現金")
            let changedFlags = PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: true
            )
            let writes = LockIsolated<[PaymentMethodEditArguments]>([])
            let store = Self.makeStore(
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
                    PaymentMethodEditArguments(oldName: "現金", newName: "新名稱", flags: changedFlags),
                ]
            )
            await store.finish()
        }
    }

    /// 主檔目錄缺少原項目且旗標未變時不查詢筆數，直接寫入更正
    @Test
    func requested_目錄缺項且旗標未變_不查詢筆數直接寫入() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let catalog = LookupCatalog()
            let writes = LockIsolated<[PaymentMethodEditArguments]>([])
            let returnedOrder = LedgerOrder.fixture(id: "PM-EMPTY", paymentMethod: "新名稱")
            let store = Self.makeStore(
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
                    PaymentMethodEditArguments(oldName: "目錄缺項", newName: "新名稱", flags: .none),
                ]
            )
            await store.finish()
        }
    }

    /// 讀取受影響訂單筆數失敗時回報失敗且保留原目錄
    @Test
    func requested_查詢筆數失敗_通知失敗且不寫入() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let catalog = Self.makeCatalog(name: "原付款方式")
            let flags = PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: false
            )
            let underlyingError = TestDependencies.makeUnderlyingError(message: "boom")
            let failingCountOrders: LookupService.CountOrders = { _ throws(PersistenceError) in
                throw .fetchFailed(underlying: underlyingError)
            }
            let store = Self.makeStore(catalog: catalog, failingCountOrders: failingCountOrders)

            // When
            await store.send(.requested(originalName: "原付款方式", newName: "新付款方式", flags: flags))

            // Then
            await store.receive(\.countResponse)
            await store.receive(\.delegate.failed)
            #expect(store.state.catalog == catalog)
            await store.finish()
        }
    }

    /// 寫入付款方式更正失敗時回報失敗且保留原目錄
    @Test
    func confirmed_付款方式更正寫入失敗_通知失敗() async {
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
            let attemptedWrites = LockIsolated<[PaymentMethodEditArguments]>([])
            let underlyingError = TestDependencies.makeUnderlyingError(message: "boom")
            let failingApplyEdit: LookupService.ApplyPaymentMethodEdit = { oldName, newName, flags throws(PersistenceError) in
                attemptedWrites.withValue {
                    $0.append(
                        PaymentMethodEditArguments(oldName: oldName, newName: newName, flags: flags)
                    )
                }
                throw .saveFailed(underlying: underlyingError)
            }
            let store = Self.makeStore(
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
                    PaymentMethodEditArguments(oldName: "原付款方式", newName: "新付款方式", flags: flags),
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
    }
}

// MARK: - Internal Method

extension PaymentMethodCorrectionFeatureTests {

    /// 建立含指定原付款方式的目錄
    ///
    /// - Parameter name: 原付款方式名稱
    /// - Returns: 含一筆無分類旗標付款方式的目錄
    static func makeCatalog(name: String) -> LookupCatalog {
        LookupCatalog(paymentMethods: [PaymentMethodInfo(name: name, flags: .none)])
    }

    /// 建立更正流程的 `TestStore`；未覆寫的 closure 維持 `unimplemented`
    ///
    /// - Parameters:
    ///   - catalog: 初始付款方式目錄
    ///   - pendingRequest: 初始待確認更正請求
    ///   - countOrdersResult: 查詢受影響筆數的回傳值
    ///   - failingCountOrders: 查詢筆數失敗時使用的替身
    ///   - writes: 傳入時記錄寫入參數並回傳指定訂單
    ///   - returnedOrders: 寫入成功時回傳的受影響訂單
    ///   - failingApplyEdit: 寫入失敗時使用的替身
    /// - Returns: 已設定初始目錄與依賴的 `TestStore`
    static func makeStore(
        catalog: LookupCatalog,
        pendingRequest: PaymentMethodCorrectionFeature.Request? = nil,
        countOrdersResult: Int? = nil,
        failingCountOrders: LookupService.CountOrders? = nil,
        writes: LockIsolated<[PaymentMethodEditArguments]>? = nil,
        returnedOrders: [LedgerOrder] = [],
        failingApplyEdit: LookupService.ApplyPaymentMethodEdit? = nil
    ) -> TestStoreOf<PaymentMethodCorrectionFeature> {
        var initialState = PaymentMethodCorrectionFeature.State()
        initialState.$catalog.withLock {
            $0 = catalog
        }
        initialState.pendingRequest = pendingRequest

        return TestStore(initialState: initialState) {
            PaymentMethodCorrectionFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            if let countOrdersResult {
                $0.lookupService.countOrders = { _ in
                    countOrdersResult
                }
            }
            if let failingCountOrders {
                $0.lookupService.countOrders = failingCountOrders
            }
            if let writes {
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
                    return returnedOrders
                }
            }
            if let failingApplyEdit {
                $0.lookupService.applyPaymentMethodEdit = failingApplyEdit
            }
        }
    }
}
