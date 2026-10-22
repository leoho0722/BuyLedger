//
//  LookupManagementFeatureTests+PaymentMethodStoredOrders.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/17.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension LookupManagementFeatureTests {

    /// 規格範例「orders not yet loaded into memory」：確認筆數與重算都取自資料庫，不依賴記憶體內的訂單
    ///
    /// - Throws: 預先寫入或讀回資料庫失敗時丟出錯誤；讀不到訂單時由 `#require` 丟出
    /// - Note: 資料庫有 A、B 兩筆信用卡訂單，信用卡沒有任何旗標；主檔管理沒有持有訂單，對應記憶體內訂單尚未載入
    /// - Note: 編輯表單只開啟貨到付款旗標、名稱不變，確認框顯示 2 筆後由使用者確認
    @Test
    func destination_訂單未載入時為信用卡開啟貨到付款_確認兩筆後重算並更新主檔() async throws {
        try await LookupCatalog.withIsolatedStorage {
            // Given
            let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
            let service = LookupServiceTests.makeService(database: database)
            let codFlags = PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: true
            )
            try await OrderServiceTests.seed(
                [
                    LookupServiceTests.makePaymentOrder(
                        id: "A",
                        paymentMethod: "信用卡",
                        isCashOnDelivery: false
                    ),
                    LookupServiceTests.makePaymentOrder(
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
                $0.lookupService = service
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
                $0.pendingAlert = Self.paymentMethodConfirmationAlert(count: 2)
            }
            await store.send(.view(.formSheetDismissed)) {
                $0.isFormSheetDismissing = false
                $0.pendingAlert = nil
                $0.destination = Self.paymentMethodConfirmationAlert(count: 2)
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
                    try await LookupServiceTests.fetchOrder(id: id, from: database)
                )
                #expect(stored.paymentMethod == "信用卡")
                #expect(stored.isCashOnDelivery == true)
                #expect(OrderSummary(order: stored).codShippingCost == 825)
            }
        }
    }
}
