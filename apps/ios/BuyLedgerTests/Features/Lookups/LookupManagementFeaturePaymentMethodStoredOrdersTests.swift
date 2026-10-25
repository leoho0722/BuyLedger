//
//  LookupManagementFeaturePaymentMethodStoredOrdersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/17.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `LookupManagementFeature` 的單元測試，以 TestStore 搭配測試資料庫，確認付款方式更正的筆數與重算取自資料庫
@MainActor
struct LookupManagementFeaturePaymentMethodStoredOrdersTests {

    /// 驗證訂單尚未載入記憶體時，為信用卡開啟貨到付款並確認後，確認筆數與重算都取自資料庫，兩筆訂單的貨到付款運費為 825 且主檔更新為貨到付款
    ///
    /// - Throws: 預先寫入或讀回資料庫失敗時丟出錯誤；讀不到訂單時由 `#require` 丟出
    /// - Note: 對應規格範例「orders not yet loaded into memory」
    /// - Note: 資料庫有 A、B 兩筆信用卡訂單，信用卡本身沒有任何旗標
    /// - Note: 主檔管理不持有訂單，記憶體內的訂單尚未載入
    /// - Note: 編輯表單只開啟貨到付款旗標、名稱不變
    /// - Note: 確認框顯示 2 筆，由使用者確認後才寫入
    /// - Note: 前置由真實資料庫計數並開啟確認框，才能驗證顯示筆數到確認後寫入的完整流程
    @Test
    func destination_訂單未載入時為信用卡開啟貨到付款_確認兩筆後重算並更新主檔() async throws {
        try await LookupCatalog.withIsolatedStorage {
            // Given
            let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
            let service = LookupServiceTestSupport.makeService(database: database)
            let codFlags = PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: true
            )
            try await OrderServiceTestSupport.seed(
                [
                    LookupServiceTestSupport.makePaymentOrder(
                        id: "A",
                        paymentMethod: "信用卡",
                        isCashOnDelivery: false
                    ),
                    LookupServiceTestSupport.makePaymentOrder(
                        id: "B",
                        paymentMethod: "信用卡",
                        isCashOnDelivery: false
                    ),
                ],
                paymentMethods: [PaymentMethodInfo(name: "信用卡", flags: .none)],
                database: database
            )
            var initialState = LookupManagementFeature.State(kind: .paymentMethod)
            initialState.$catalog.withLock {
                $0.paymentMethods = [PaymentMethodInfo(name: "信用卡", flags: .none)]
            }
            initialState.destination = .editPaymentMethod(
                PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: .none)
            )
            @Shared(.lookupCatalog) var sharedCatalog: LookupCatalog
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            } withDependencies: {
                $0.lookupService.countOrders = service.countOrders
                $0.lookupService.applyPaymentMethodEdit = service.applyPaymentMethodEdit
            }
            await store.send(
                .destination(
                    .presented(
                        .editPaymentMethod(.view(.saveButtonTapped(name: "信用卡", flags: codFlags)))
                    )
                )
            )
            await store.receive(\.destination.presented.editPaymentMethod.delegate.saved) {
                $0.destination = nil
                $0.isFormSheetDismissing = true
            }
            await store.receive(\.correction.requested)
            await store.receive(\.correction.countResponse) {
                $0.correction.pendingRequest = PaymentMethodCorrectionFeature.Request(
                    originalName: "信用卡",
                    newName: "信用卡",
                    flags: codFlags,
                    hasChangedFlags: true
                )
            }
            await store.receive(\.correction.delegate.confirmationRequired, 2) {
                $0.pendingAlert = LookupManagementFeatureTestSupport.paymentMethodConfirmationAlert(
                    count: 2
                )
            }
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
                $0.pendingAlert = nil
                $0.destination = LookupManagementFeatureTestSupport.paymentMethodConfirmationAlert(
                    count: 2
                )
            }

            // When
            await store.send(.destination(.presented(.alert(.confirmPaymentMethodEdit)))) {
                $0.destination = nil
            }

            // Then
            await store.receive(\.correction.confirmed) {
                $0.correction.pendingRequest = nil
                $0.$catalog.withLock {
                    $0.paymentMethods = [PaymentMethodInfo(name: "信用卡", flags: codFlags)]
                }
            }
            await store.receive(\.correction.editResponse.success)
            await store.receive(\.correction.delegate.edited)
            await store.receive(\.delegate.paymentMethodEdited)
            await store.finish()
            #expect(
                sharedCatalog.paymentMethods == [PaymentMethodInfo(name: "信用卡", flags: codFlags)]
            )
            let storedMethods = try await service.fetchItems(.paymentMethod).paymentMethods
            #expect(storedMethods == [PaymentMethodInfo(name: "信用卡", flags: codFlags)])
            for id in ["A", "B"] {
                let stored = try #require(
                    try await LookupServiceTestSupport.fetchOrder(id: id, from: database)
                )
                #expect(stored.paymentMethod == "信用卡")
                #expect(stored.isCashOnDelivery == true)
                #expect(OrderSummary(order: stored).codShippingCost == 825)
            }
        }
    }
}
