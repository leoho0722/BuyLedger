//
//  RootFeatureTests+LoadRequests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 啟動時只向訂單與開團各送出一次載入請求，不觸發子畫面出現的事件
    @Test
    func task_啟動根功能_送訂單與開團載入請求各一次() async {
        // Given
        let initial = Self.makeIsolatedRootState()
        initial.orders.load.$hasLoaded.withLock {
            $0 = true
        }
        initial.campaigns.load.$hasLoaded.withLock {
            $0 = true
        }
        let requests = LockIsolated<[String]>([])
        let currencyRelease = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            CombineReducers {
                RootFeature()
                Reduce { _, action in
                    if case .orders(.loadRequested) = action {
                        requests.withValue {
                            $0.append("orders")
                        }
                    }
                    if case .campaigns(.loadRequested) = action {
                        requests.withValue {
                            $0.append("campaigns")
                        }
                    }
                    return .none
                }
            }
        } withDependencies: {
            $0.currencyMetadataService.refreshIfStale = { _ in
                var iterator = currencyRelease.stream.makeAsyncIterator()
                _ = await iterator.next()
                return false
            }
            $0.currencyMetadataService.fetchCodes = {
                []
            }
            $0.significantTimeChangeService.changes = {
                AsyncStream {
                    $0.finish()
                }
            }
        }

        // When
        await store.send(.view(.task))

        // Then
        await Self.receiveLaunchLoadRequests(in: store)
        currencyRelease.continuation.finish()
        await store.receive(\.launch.currencyCodesResponse.success, [])
        await store.finish()
        #expect(requests.value.sorted() == ["campaigns", "orders"])
        #expect(store.state.selectedTab == .dashboard)
    }

    /// 總覽頁的重試按鈕在首次載入失敗後，只由根功能轉送一次載入請求，成功後同步所有頁面的訂單
    @Test
    func dashboard_首次載入失敗後重試_轉送一次載入並同步所有頁面() async {
        // Given
        let loaded = LedgerOrder.fixture(id: "RETRY-ORDER", date: TestDependencies.fixedNow)
        let initial = Self.makeOrdersLoadFailedState()
        let reads = LockIsolated(0)
        let release = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            Self.stubOrdersReload(
                &$0,
                loaded: loaded,
                reads: reads,
                release: release.stream
            )
        }

        // When
        await store.send(.dashboard(.view(.retryTapped))) {
            $0.orders.load.$isLoading.withLock {
                $0 = true
            }
            $0.orders.load.$errorMessage.withLock {
                $0 = nil
            }
        }

        // Then
        await store.receive(\.dashboard.delegate.refresh)
        await Self.receiveOrdersReload(in: store, loaded: loaded, release: release.continuation)
        await store.finish()
        #expect(reads.value == 1)
        #expect(store.state.orders.orders == [loaded])
        #expect(store.state.campaigns.orders == [loaded])
        #expect(store.state.more.orders == [loaded])
        #expect(store.state.dashboard.orders == [loaded])
        #expect(store.state.insights.orders == [loaded])
    }

    /// 分析頁的重試按鈕在首次載入失敗後，只由根功能轉送一次載入請求，成功後同步所有頁面的訂單
    @Test
    func insights_首次載入失敗後重試_轉送一次載入並同步所有頁面() async {
        // Given
        let loaded = LedgerOrder.fixture(id: "RETRY-ORDER", date: TestDependencies.fixedNow)
        let initial = Self.makeOrdersLoadFailedState()
        let reads = LockIsolated(0)
        let release = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            Self.stubOrdersReload(
                &$0,
                loaded: loaded,
                reads: reads,
                release: release.stream
            )
        }

        // When
        await store.send(.insights(.view(.retryTapped))) {
            $0.orders.load.$isLoading.withLock {
                $0 = true
            }
            $0.orders.load.$errorMessage.withLock {
                $0 = nil
            }
        }

        // Then
        await store.receive(\.insights.delegate.refresh)
        await Self.receiveOrdersReload(in: store, loaded: loaded, release: release.continuation)
        await store.finish()
        #expect(reads.value == 1)
        #expect(store.state.orders.orders == [loaded])
        #expect(store.state.campaigns.orders == [loaded])
        #expect(store.state.more.orders == [loaded])
        #expect(store.state.dashboard.orders == [loaded])
        #expect(store.state.insights.orders == [loaded])
    }

    /// 經「更多」呈現的客戶頁在首次載入失敗後重試，只由根功能轉送一次載入請求，成功後同步所有頁面的訂單
    ///
    /// - Throws: 客戶頁沒有推入「更多」路徑時由 `try #require` 丟出
    @Test
    func more_客戶頁首次載入失敗後重試_轉送一次載入並同步所有頁面() async throws {
        // Given
        let loaded = LedgerOrder.fixture(id: "RETRY-ORDER", date: TestDependencies.fixedNow)
        var initial = Self.makeOrdersLoadFailedState()
        initial.selectedTab = .more
        initial.more.path.append(
            .customers(CustomersFeature.State(orders: SharedReader(initial.more.$orders)))
        )
        let id = try #require(initial.more.path.ids.first)
        let reads = LockIsolated(0)
        let release = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            Self.stubOrdersReload(
                &$0,
                loaded: loaded,
                reads: reads,
                release: release.stream
            )
        }

        // When
        await store.send(.more(.path(.element(id: id, action: .customers(.view(.task)))))) {
            $0.orders.load.$isLoading.withLock {
                $0 = true
            }
            $0.orders.load.$errorMessage.withLock {
                $0 = nil
            }
        }

        // Then
        await store.receive(\.more.path[id: id].customers.delegate.ordersLoadRequested)
        await store.receive(\.more.delegate.ordersLoadRequested)
        await Self.receiveOrdersReload(in: store, loaded: loaded, release: release.continuation)
        await store.finish()
        #expect(reads.value == 1)
        #expect(store.state.orders.orders == [loaded])
        #expect(store.state.campaigns.orders == [loaded])
        #expect(store.state.more.orders == [loaded])
        #expect(store.state.dashboard.orders == [loaded])
        #expect(store.state.insights.orders == [loaded])
    }
}

// MARK: - Private Method

private extension RootFeatureTests {

    /// 建立訂單首次載入失敗的根狀態，總覽與分析頁都停在失敗畫面
    ///
    /// - Returns: 訂單載入失敗的根狀態
    static func makeOrdersLoadFailedState() -> RootFeature.State {
        var initial = Self.makeIsolatedRootState()
        initial.orders.load.$errorMessage.withLock {
            $0 = "orders.general.message.ordersLoadedTry"
        }
        initial.dashboard.loadState = .failed("orders.general.message.ordersLoadedTry")
        initial.insights.loadState = .failed("orders.general.message.ordersLoadedTry")
        return initial
    }

    /// 讓訂單重新載入先停在 `release`，釋放後回傳 `loaded`，並記下實際讀取次數
    ///
    /// - Parameters:
    ///   - dependencies: 本測試的依賴集合
    ///   - loaded: 載入成功時回傳的訂單
    ///   - reads: 記錄訂單讀取次數
    ///   - release: 控制載入何時完成的串流
    static func stubOrdersReload(
        _ dependencies: inout DependencyValues,
        loaded: LedgerOrder,
        reads: LockIsolated<Int>,
        release: AsyncStream<Void>
    ) {
        dependencies.orderService.fetchOrders = {
            reads.withValue {
                $0 += 1
            }
            var iterator = release.makeAsyncIterator()
            _ = await iterator.next()
            return [loaded]
        }
        dependencies.orderSourceService.fetchOrderSources = {
            []
        }
        dependencies.categoryService.fetchCategories = {
            []
        }
        dependencies.paymentMethodService.fetchPaymentMethodInfos = {
            []
        }
        dependencies.reconciliationStatusService.fetchReconciliationStatuses = {
            []
        }
    }

    /// 接收根功能轉送的訂單重新載入，確認總覽與分析頁回到載入中，釋放後接收載入成功的同步結果
    ///
    /// - Parameters:
    ///   - store: 已送出重試事件的測試 `store`
    ///   - loaded: 載入成功後同步到各頁的訂單
    ///   - release: 控制載入何時完成的 `continuation`
    static func receiveOrdersReload(
        in store: TestStoreOf<RootFeature>,
        loaded: LedgerOrder,
        release: AsyncStream<Void>.Continuation
    ) async {
        await store.receive(\.orders.loadRequested)
        await store.receive(\.orders.load.loadRequested) {
            $0.dashboard.loadState = .loading
            $0.insights.loadState = .loading
        }
        release.finish()
        await store.receive(\.orders.load.loadResponse) {
            $0.orders.load.$isLoading.withLock {
                $0 = false
            }
            $0.orders.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.orders.$orders.withLock {
                $0 = [loaded]
            }
            $0.campaigns.$orders.withLock {
                $0 = [loaded]
            }
            $0.more.$orders.withLock {
                $0 = [loaded]
            }
            $0.orders.list.selectedOrderID = "RETRY-ORDER"
            $0.orders.detail.regularDetail = OrderDetailFeature.State(
                orderID: "RETRY-ORDER",
                orders: SharedReader($0.orders.$orders)
            )
            $0.dashboard.orders = [loaded]
            $0.dashboard.loadState = .loaded
            $0.insights.orders = [loaded]
            $0.insights.loadState = .loaded
        }
    }
}
