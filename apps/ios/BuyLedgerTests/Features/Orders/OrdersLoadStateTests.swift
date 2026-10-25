//
//  OrdersLoadStateTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/20.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrdersFeature.State` 的單元測試，涵蓋 `loadState` 與重試流程
struct OrdersLoadStateTests {

    /// 驗證 `hasLoaded` 為真時，`loadState` 解析為 `loaded`
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

    /// 驗證 `hasLoaded` 為真且 `errorMessage` 仍有殘留時，`loadState` 解析為 `loaded`，已載入優先於錯誤
    @Test
    func loadState_已載入但殘留錯誤訊息_仍解析為內容狀態() {
        // Given
        let state = OrdersFeature.State()
        state.load.$hasLoaded.withLock {
            $0 = true
        }
        state.load.$errorMessage.withLock {
            $0 = "orders.general.message.ordersLoadedTry"
        }

        // When
        let loadState = state.loadState

        // Then
        #expect(loadState == .loaded)
    }

    /// 驗證尚未載入且 `errorMessage` 有值時，`loadState` 解析為 `failed`，並帶著該錯誤訊息
    @Test
    func loadState_尚未載入且有錯誤_解析為失敗狀態() {
        // Given
        let state = OrdersFeature.State()
        state.load.$errorMessage.withLock {
            $0 = "orders.general.message.ordersLoadedTry"
        }

        // When
        let loadState = state.loadState

        // Then
        #expect(loadState == .failed("orders.general.message.ordersLoadedTry"))
    }

    /// 驗證尚未載入且 `errorMessage` 為 `nil` 時，`loadState` 解析為 `loading`
    @Test
    func loadState_尚未載入且沒有錯誤_解析為載入狀態() {
        // Given
        let state = OrdersFeature.State()

        // When
        let loadState = state.loadState

        // Then
        #expect(loadState == .loading)
    }

    /// 驗證載入失敗時停止載入、顯示失敗原因並回報失敗通知，`loadState` 解析為 `failed`
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
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.load(.loadResponse(OrdersLoadFeature.Outcome(orders: .failure(error))))) {
            $0.load.$isLoading.withLock {
                $0 = false
            }
            $0.load.$errorMessage.withLock {
                $0 = "orders.general.message.ordersLoadedTry"
            }
        }

        // Then
        await store.receive(\.load.delegate.loadFailed)
        #expect(store.state.loadState == .failed("orders.general.message.ordersLoadedTry"))
    }

    /// 驗證根功能要求重新載入且讀取成功時，錯誤訊息清除，訂單換成讀回的結果並選取 RETRY-1，`loadState` 解析為 `loaded`
    @Test
    @MainActor
    func rootRequest_重新載入成功_恢復訂單內容() async {
        // Given
        let order = LedgerOrder.fixture(id: "RETRY-1")
        let initial = Self.makeRetryState()
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.fetchOrders = {
                [order]
            }
        }

        // When
        await store.send(.rootRequest(.load)) {
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
                orders: SharedReader(initial.$orders)
            )
        }
        await store.finish()
        #expect(store.state.orders == [order])
        #expect(store.state.list.selectedOrderID == "RETRY-1")
        #expect(store.state.loadState == .loaded)
    }

    /// 驗證已在失敗狀態時再收到相同的載入失敗，`errorMessage` 保留、`hasLoaded` 維持 `false`，且不自動重試
    ///
    /// - Note: `TestStore` 會要求測試接收每一個產生的 action，漏接的自動重試會使測試失敗
    @Test
    @MainActor
    func load_重複載入失敗_維持失敗狀態() async {
        // Given
        let initial = OrdersFeature.State()
        initial.load.$errorMessage.withLock {
            $0 = "orders.general.message.ordersLoadedTry"
        }
        let error = PersistenceError.fetchFailed(
            underlying: TestDependencies.makeUnderlyingError(message: "read")
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.load(.loadResponse(OrdersLoadFeature.Outcome(orders: .failure(error)))))

        // Then
        await store.receive(\.load.delegate.loadFailed)
        await store.finish()
        #expect(store.state.loadState == .failed("orders.general.message.ordersLoadedTry"))
        #expect(store.state.load.hasLoaded == false)
    }

    /// 驗證失敗後根功能要求重新載入，讀取只執行一次，讀回的訂單更新到列表並選取 RETRY-1，`loadState` 解析為 `loaded`
    @Test
    @MainActor
    func rootRequest_失敗後切回訂單分頁_重讀並顯示訂單() async {
        // Given
        let order = LedgerOrder.fixture(id: "RETRY-1")
        let responses = AsyncStream<Result<[LedgerOrder], PersistenceError>>.makeStream()
        let reads = LockIsolated(0)
        let fetch: OrderService.FetchOrders = { () throws(PersistenceError) in
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
        let initial = Self.makeRetryState()
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.fetchOrders = fetch
        }

        // When
        await store.send(.rootRequest(.load)) {
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
                orders: SharedReader(initial.$orders)
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
    /// - Returns: 尚未載入且含錯誤訊息的訂單分頁狀態
    static func makeRetryState() -> OrdersFeature.State {
        let state = OrdersFeature.State()
        state.load.$errorMessage.withLock {
            $0 = "orders.general.message.ordersLoadedTry"
        }
        return state
    }
}
