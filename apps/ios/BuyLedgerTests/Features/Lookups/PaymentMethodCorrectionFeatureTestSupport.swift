//
//  PaymentMethodCorrectionFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture

@testable import BuyLedger

/// 付款方式更正測試共用的寫入參數型別、目錄與 `TestStore` 工廠
enum PaymentMethodCorrectionFeatureTestSupport {}

// MARK: - Nested Types

extension PaymentMethodCorrectionFeatureTestSupport {

    /// `applyPaymentMethodEdit` 實際收到的一組更正參數，供測試比對寫入內容
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

extension PaymentMethodCorrectionFeatureTestSupport {

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
    @MainActor
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
