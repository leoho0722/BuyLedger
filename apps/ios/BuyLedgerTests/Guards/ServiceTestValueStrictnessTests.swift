//
//  ServiceTestValueStrictnessTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/30.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// Service 測試替身守門規則的單元測試，涵蓋未覆寫主檔與訂單 closure 時，TestStore 仍回報未實作問題
@MainActor
struct ServiceTestValueStrictnessTests {

    /// 驗證訂單載入未覆寫 `fetchOrders` 時，`TestStore` 回報 `OrderService.fetchOrders` 的未實作問題，載入仍會結束並標記為已載入
    @Test
    func rootRequest_載入未覆寫訂單讀取_回報未實作問題() async {
        await withKnownIssue {
            // Given
            let store = TestStore(initialState: OrdersFeature.State()) {
                OrdersFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
            }

            // When
            await store.send(.rootRequest(.load)) {
                $0.load.$isLoading.withLock {
                    $0 = true
                }
            }

            // Then
            await store.receive(\.load.loadRequested) {
                $0.load.$isLoading.withLock {
                    $0 = false
                }
                $0.load.$hasLoaded.withLock {
                    $0 = true
                }
            }
            await store.receive(\.load.loadResponse)
            await store.finish()
        } matching: {
            $0.description.contains("OrderService.fetchOrders")
        }
    }

    /// 驗證主檔讀取未覆寫時，TestStore 回報 `LookupService.fetchItems` 的未實作問題，載入仍會結束並通知主檔載入完成
    @Test
    func loadRequested_未覆寫主檔讀取_回報未實作問題() async {
        await withKnownIssue {
            // Given
            let initial = withDependencies {
                $0.defaultInMemoryStorage = InMemoryStorage()
            } operation: {
                LookupCatalogFeature.State()
            }
            let store = TestStore(initialState: initial) {
                LookupCatalogFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
            }

            // When
            await store.send(.loadRequested) {
                $0.isLoading = true
            }

            // Then
            await store.receive(\.catalogResponse) {
                $0.isLoading = false
                $0.hasLoaded = true
            }
            await store.receive(\.delegate, .loadFinished)
            await store.finish()
        } matching: {
            $0.description.contains("LookupService.fetchItems")
        }
    }

    /// 驗證確認刪除時 `removeOrder` 未覆寫，仍回報 `OrderService.removeOrder` 的未實作問題
    ///
    /// - Throws: 找不到測試訂單時由 `try #require` 丟出
    /// - Note: 沒有回傳值的 typed throws closure 未覆寫時，`unimplemented` 回報問題後無法丟出該 typed 錯誤
    /// - Note: 只能以 `Void` 繼續執行，所以刪除流程走成功路徑並送出 `writes.deleteResponse`
    /// - Note: 測試守的是問題訊息指名 `OrderService.removeOrder`
    @Test
    func presentation_確認刪除_刪除仍回報未實作問題() async throws {
        try await withKnownIssue {
            // Given
            let originalID = "BL-2604-018"
            let original = try #require(
                LedgerOrder.sampleOrders.first {
                    $0.id == originalID
                }
            )
            var initialState = OrdersFeature.State(orders: [original])
            initialState.presentation.destination = .alert(
                AlertState {
                    TextState("orders.detail.label.deleteOrder")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete(originalID)) {
                        TextState("common.action.button.delete")
                    }
                    ButtonState(role: .cancel) {
                        TextState("common.action.cancel")
                    }
                } message: {
                    TextState(
                        LocalizedStringResource(
                            "orders.detail.message.deleteUndoneNotice",
                            defaultValue: "\(original.customer.name)"
                        )
                    )
                }
            )
            let store = TestStore(initialState: initialState) {
                OrdersFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
            }

            // When
            await store.send(
                .presentation(.destination(.presented(.alert(.confirmDelete(originalID)))))
            ) {
                $0.presentation.destination = nil
            }

            // Then
            await store.receive(\.presentation.delegate.deleteConfirmed, originalID) {
                $0.$orders.withLock {
                    $0 = []
                }
            }
            await store.receive(\.writes.deleteRequested)
            await store.receive(\.writes.deleteResponse)
            await store.receive(\.writes.delegate, .deleted(originalID))
            await store.finish()
        } matching: {
            $0.description.contains("OrderService.removeOrder")
        }
    }
}
