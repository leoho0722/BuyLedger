//
//  RootFeatureCustomersLoadStateTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/11.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 TestStore 驗證訂單載入結果同步到更多頁與已推入的客戶頁
@MainActor
struct RootFeatureCustomersLoadStateTests {

    /// 驗證訂單讀取失敗時，更多頁投影與已推入的客戶頁在同次回應中讀到相同的失敗原因
    @Test
    func orders_訂單讀取失敗_已推入客戶頁同步失敗狀態() async {
        // Given
        let initial = Self.makeInitialState()
        let error = PersistenceError.fetchFailed(
            underlying: TestDependencies.makeUnderlyingError(message: "orders")
        )
        let outcome = OrdersLoadFeature.Outcome(orders: .failure(error))
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.orders(.load(.loadResponse(outcome)))) {
            $0.orders.load.$isLoading.withLock {
                $0 = false
            }
            $0.orders.load.$errorMessage.withLock {
                $0 = "orders.general.message.ordersLoadedTry"
            }
            $0.more.$ordersLoadState.withLock {
                $0 = .failed("orders.general.message.ordersLoadedTry")
            }
            $0.dashboard.loadState = .failed("orders.general.message.ordersLoadedTry")
            $0.insights.loadState = .failed("orders.general.message.ordersLoadedTry")
        }

        // Then
        await store.receive(\.orders.load.delegate.loadFailed)
        await store.finish()
        #expect(
            store.state.more.ordersLoadState == .failed("orders.general.message.ordersLoadedTry")
        )
        #expect(
            store.state.more.path[id: 0, case: \.customers]?.loadState
                == .failed("orders.general.message.ordersLoadedTry")
        )
        #expect(store.state.more.path.count == 1)
    }

    /// 驗證訂單讀取成功且沒有資料時，更多頁與原本的客戶頁都改為已載入，讓空名單只在成功後顯示
    @Test
    func orders_訂單讀取成功_已推入客戶頁同步已載入狀態() async {
        // Given
        let initial = Self.makeInitialState()
        let outcome = OrdersLoadFeature.Outcome(orders: .success([]))
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.orders(.load(.loadResponse(outcome)))) {
            $0.orders.load.$isLoading.withLock {
                $0 = false
            }
            $0.orders.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.more.$ordersLoadState.withLock {
                $0 = .loaded
            }
            $0.dashboard.loadState = .loaded
            $0.insights.loadState = .loaded
        }

        // Then
        await store.finish()
        #expect(store.state.more.ordersLoadState == .loaded)
        #expect(store.state.more.path[id: 0, case: \.customers]?.loadState == .loaded)
        #expect(store.state.more.path[id: 0, case: \.customers]?.screenState == .empty)
        #expect(store.state.more.path.count == 1)
    }
}

// MARK: - Private Method

private extension RootFeatureCustomersLoadStateTests {

    /// 以既有隔離 helper 建立訂單載入中且客戶頁已推入的根狀態，兩份唯讀投影均指向更多頁來源
    ///
    /// - Returns: 訂單載入中、客戶頁元素識別值為 0 的獨立根狀態
    static func makeInitialState() -> RootFeature.State {
        RootFeatureTestSupport.makeIsolatedRootState {
            var state = RootFeature.State()
            state.orders.load.$isLoading.withLock {
                $0 = true
            }
            state.more.path.append(
                .customers(
                    CustomersFeature.State(
                        orders: SharedReader(state.more.$orders),
                        loadState: SharedReader(state.more.$ordersLoadState)
                    )
                )
            )
            return state
        }
    }
}
