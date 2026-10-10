//
//  OrdersLoadStateTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/20.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// 驗證訂單清單的載入狀態與重試結果
struct OrdersLoadStateTests {

    /// 已完成首次載入時，狀態解析為已載入內容
    @Test
    func loadState_訂單已載入_解析為內容狀態() {
        // Given
        let state = OrdersFeature.State()
        state.load.$hasLoaded.withLock {
            $0 = true
        }

        // When
        let loadState = state.loadState

        // Then
        #expect(loadState == .loaded)
    }

    /// 已載入狀態優先於殘留的錯誤訊息
    @Test
    func loadState_已載入但殘留錯誤訊息_仍解析為內容狀態() {
        // Given
        let state = OrdersFeature.State()
        state.load.$hasLoaded.withLock {
            $0 = true
        }
        state.load.$errorMessage.withLock {
            $0 = "訂單載入失敗，請稍後再試。"
        }

        // When
        let loadState = state.loadState

        // Then
        #expect(loadState == .loaded)
    }

    /// 尚未載入且有錯誤訊息時，狀態包含該失敗原因
    @Test
    func loadState_尚未載入且有錯誤_解析為失敗狀態() {
        // Given
        let state = OrdersFeature.State()
        state.load.$errorMessage.withLock {
            $0 = "訂單載入失敗，請稍後再試。"
        }

        // When
        let loadState = state.loadState

        // Then
        #expect(loadState == .failed("訂單載入失敗，請稍後再試。"))
    }

    /// 尚未載入且沒有錯誤訊息時，狀態解析為載入中
    @Test
    func loadState_尚未載入且沒有錯誤_解析為載入狀態() {
        // Given
        let state = OrdersFeature.State()

        // When
        let loadState = state.loadState

        // Then
        #expect(loadState == .loading)
    }

    /// 訂單請求失敗時停止載入並顯示失敗原因
    @Test
    @MainActor
    func load_訂單載入失敗_顯示失敗原因() async {
        // Given
        let initial = OrdersFeature.State()
        initial.load.$isLoading.withLock {
            $0 = true
        }
        let error = PersistenceError.fetchFailed(
            underlying: TestDependencies.makeUnderlyingError(message: "read")
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.load(.loadResponse(OrdersLoadFeature.Outcome(orders: .failure(error))))) {
            $0.load.$isLoading.withLock {
                $0 = false
            }
            $0.load.$errorMessage.withLock {
                $0 = "訂單載入失敗，請稍後再試。"
            }
        }

        // Then
        await store.receive(\.load.delegate.loadFailed)
        #expect(store.state.loadState == .failed("訂單載入失敗，請稍後再試。"))
    }

    /// 重試成功時載入回傳訂單並清除錯誤狀態
    @Test
    @MainActor
    func loadRequested_重新載入成功_恢復訂單內容() async {
        // Given
        let order = LedgerOrder.fixture(id: "RETRY-1")
        let store = TestStore(initialState: Self.makeRetryState()) {
            OrdersFeature()
        } withDependencies: {
            OrdersLoadFeatureTests.suppressLookups(&$0)
            $0.orderService.fetchOrders = {
                [order]
            }
        }

        // When
        await store.send(.loadRequested) {
            $0.load.$isLoading.withLock {
                $0 = true
            }
            $0.load.$errorMessage.withLock {
                $0 = nil
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
            $0.$orders.withLock {
                $0 = [order]
            }
        }
        await store.receive(\.load.loadResponse) {
            $0.list.selectedOrderID = "RETRY-1"
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "RETRY-1",
                orders: SharedReader($0.$orders)
            )
        }
        await store.finish()
        #expect(store.state.orders == [order])
        #expect(store.state.list.selectedOrderID == "RETRY-1")
        #expect(store.state.loadState == .loaded)
    }

    /// 已在失敗狀態時再收到相同失敗，保留錯誤且不自動重試
    ///
    /// - Note: `TestStore` 會要求測試接收每一個產生的 action，漏接的自動重試會使測試失敗
    @Test
    @MainActor
    func load_重複載入失敗_維持失敗狀態() async {
        // Given
        let initial = OrdersFeature.State()
        initial.load.$errorMessage.withLock {
            $0 = "訂單載入失敗，請稍後再試。"
        }
        let error = PersistenceError.fetchFailed(
            underlying: TestDependencies.makeUnderlyingError(message: "read")
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.load(.loadResponse(OrdersLoadFeature.Outcome(orders: .failure(error)))))

        // Then
        await store.receive(\.load.delegate.loadFailed)
        await store.finish()
        #expect(store.state.loadState == .failed("訂單載入失敗，請稍後再試。"))
        #expect(store.state.load.hasLoaded == false)
    }

    /// 載入失敗後切回訂單分頁，載入請求經容器再次讀取並顯示訂單
    @Test
    @MainActor
    func loadRequested_失敗後切回訂單分頁_重讀並顯示訂單() async {
        // Given
        let order = LedgerOrder.fixture(id: "RETRY-1")
        let responses = AsyncStream<Result<[LedgerOrder], PersistenceError>>.makeStream()
        let reads = LockIsolated(0)
        let fetch: OrderService.FetchOrders = {
            reads.withValue {
                $0 += 1
            }
            var iterator = responses.stream.makeAsyncIterator()
            guard let result = await iterator.next() else {
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "stream ended")
                )
            }
            return try result.get()
        }
        let store = TestStore(initialState: Self.makeRetryState()) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.fetchOrders = fetch
            OrdersLoadFeatureTests.suppressLookups(&$0)
        }

        // When
        await store.send(.loadRequested) {
            $0.load.$isLoading.withLock {
                $0 = true
            }
            $0.load.$errorMessage.withLock {
                $0 = nil
            }
        }

        // Then
        await store.receive(\.load.loadRequested)
        responses.continuation.yield(.success([order]))
        responses.continuation.finish()
        await store.receive(\.load.loadResponse) {
            $0.load.$isLoading.withLock {
                $0 = false
            }
            $0.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.$orders.withLock {
                $0 = [order]
            }
            $0.list.selectedOrderID = "RETRY-1"
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "RETRY-1",
                orders: SharedReader($0.$orders)
            )
        }
        await store.finish()
        #expect(reads.value == 1)
        #expect(store.state.orders == [order])
        #expect(store.state.list.selectedOrderID == "RETRY-1")
        #expect(store.state.loadState == .loaded)
    }
}

// MARK: - Private Method

private extension OrdersLoadStateTests {

    /// 建立已有載入錯誤的重試初值，供 `TestStore` 的重新載入測試使用
    ///
    /// - Returns: 尚未載入且含錯誤訊息的訂單容器
    static func makeRetryState() -> OrdersFeature.State {
        let state = OrdersFeature.State()
        state.load.$errorMessage.withLock {
            $0 = "訂單載入失敗，請稍後再試。"
        }
        return state
    }
}
