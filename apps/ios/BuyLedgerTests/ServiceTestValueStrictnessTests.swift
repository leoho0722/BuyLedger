//
//  ServiceTestValueStrictnessTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/30.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證 TestStore 中未覆寫的 `OrderService` closure 仍會回報未實作問題
@MainActor
struct ServiceTestValueStrictnessTests {

    // MARK: - Tests

    /// 訂單載入未覆寫 `fetchOrders` 時，測試會回報該 closure 的未實作問題
    @Test
    func task_未覆寫訂單讀取_回報未實作問題() async {
        await withKnownIssue {
            // Given
            let failingFetchOrderSources: OrderSourceService.FetchOrderSources = { () throws(PersistenceError) in
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
                )
            }
            let failingFetchCampaigns: CampaignService.FetchCampaigns = { () throws(PersistenceError) in
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
                )
            }
            let failingFetchCategories: CategoryService.FetchCategories = { () throws(PersistenceError) in
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
                )
            }
            let failingFetchPaymentMethodInfos: PaymentMethodService.FetchPaymentMethodInfos = { () throws(PersistenceError) in
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
                )
            }
            let failingFetchStatuses: ReconciliationStatusService.FetchReconciliationStatuses = { () throws(PersistenceError) in
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
                )
            }
            let store = TestStore(initialState: OrdersFeature.State()) {
                OrdersFeature()
            } withDependencies: {
                $0.orderSourceService.fetchOrderSources = failingFetchOrderSources
                $0.campaignService.fetchCampaigns = failingFetchCampaigns
                $0.categoryService.fetchCategories = failingFetchCategories
                $0.paymentMethodService.fetchPaymentMethodInfos = failingFetchPaymentMethodInfos
                $0.reconciliationStatusService.fetchReconciliationStatuses = failingFetchStatuses
            }

            // When
            await store.send(.task) {
                $0.isLoading = true
            }

            // Then
            await store.receive(\.ordersLoaded) {
                $0.isLoading = false
                $0.hasLoaded = true
            }
            await store.finish()
        } matching: {
            $0.description.contains("OrderService.fetchOrders")
        }
    }

    /// 確認刪除只覆寫 `saveOrder` 時，未覆寫的 `removeOrder` 仍回報未實作問題
    ///
    /// - Throws: 找不到測試訂單時由 `try #require` 丟出
    /// - Note: 沒有回傳值的 typed throws closure 未覆寫時，`unimplemented` 回報問題後無法丟出該
    ///   typed 錯誤，只能以 `Void` 繼續執行，所以刪除流程走成功路徑並送出 `orderDeleted`；
    ///   測試守的是問題訊息指名 `OrderService.removeOrder`
    @Test
    func deletionConfirmation_只覆寫儲存_刪除仍回報未實作問題() async throws {
        try await withKnownIssue {
            // Given
            let originalID = "BL-2604-018"
            let original = try #require(
                LedgerOrder.sampleOrders.first {
                    $0.id == originalID
                }
            )
            var initialState = OrdersFeature.State()
            initialState.orders = [original]
            initialState.deletionConfirmation = AlertState {
                TextState("刪除訂單")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete(originalID)) {
                    TextState("刪除")
                }
                ButtonState(role: .cancel) {
                    TextState("取消")
                }
            } message: {
                TextState("刪除「\(original.customer.name)」的這筆訂單後無法復原。")
            }
            let store = TestStore(initialState: initialState) {
                OrdersFeature()
            } withDependencies: {
                $0.orderService.saveOrder = { _ in
                }
            }

            // When
            await store.send(.deletionConfirmation(.presented(.confirmDelete(originalID)))) {
                $0.deletionConfirmation = nil
            }

            // Then
            await store.receive(\.orderDeleted) {
                $0.orders = []
            }
            await store.finish()
        } matching: {
            $0.description.contains("OrderService.removeOrder")
        }
    }
}
