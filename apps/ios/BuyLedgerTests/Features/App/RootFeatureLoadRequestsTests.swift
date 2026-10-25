//
//  RootFeatureLoadRequestsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 TestStore 驗證啟動與首次載入失敗後重試時，訂單載入請求如何送出，以及各頁如何同步
@MainActor
struct RootFeatureLoadRequestsTests {

    /// 驗證啟動時，訂單與開團各只收到一次載入請求，啟動後停在總覽分頁
    @Test
    func task_啟動根功能_送訂單與開團載入請求各一次() async {
        // Given
        var initial = RootFeatureTestSupport.makeIsolatedRootState()
        initial.more.catalog.hasLoaded = true
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
                    if case .orders(.rootRequest(.load)) = action {
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
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
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
        await RootFeatureTestSupport.receiveLaunchLoadRequests(in: store)
        currencyRelease.continuation.finish()
        await store.receive(\.launch.currencyCodesResponse.success, [])
        await store.finish()
        #expect(requests.value.sorted() == ["campaigns", "orders"])
        #expect(store.state.selectedTab == .dashboard)
    }

    /// 驗證總覽頁按下重試時，首次載入失敗後，根功能只向訂單功能送出一次載入請求，成功後同步所有頁面的訂單
    @Test
    func dashboard_首次載入失敗後重試_轉送一次載入並同步所有頁面() async {
        // Given
        let loaded = LedgerOrder.fixture(id: "RETRY-ORDER", date: TestDependencies.fixedNow)
        let initial = Self.makeOrdersLoadFailedState()
        let reads = LockIsolated(0)
        let release = AsyncStream<Void>.makeStream()
        let catalogRelease = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            Self.stubOrdersReload(
                &$0,
                loaded: loaded,
                reads: reads,
                release: release.stream,
                catalogRelease: catalogRelease.stream
            )
        }

        // When
        await store.send(.dashboard(.view(.retryTapped))) {
            $0.dashboard.dateContext = DashboardDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.dashboard.delegate.refresh)
        await Self.receiveOrdersReload(
            in: store,
            loaded: loaded,
            release: release.continuation,
            catalogRelease: catalogRelease.continuation
        )
        await store.finish()
        #expect(reads.value == 1)
        #expect(store.state.orders.orders == [loaded])
        #expect(store.state.campaigns.orders == [loaded])
        #expect(store.state.more.orders == [loaded])
        #expect(store.state.dashboard.orders == [loaded])
        #expect(store.state.insights.orders == [loaded])
    }

    /// 驗證分析頁按下重試時，首次載入失敗後，根功能只向訂單功能送出一次載入請求，成功後同步所有頁面的訂單
    @Test
    func insights_首次載入失敗後重試_轉送一次載入並同步所有頁面() async {
        // Given
        let loaded = LedgerOrder.fixture(id: "RETRY-ORDER", date: TestDependencies.fixedNow)
        let initial = Self.makeOrdersLoadFailedState()
        let reads = LockIsolated(0)
        let release = AsyncStream<Void>.makeStream()
        let catalogRelease = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            Self.stubOrdersReload(
                &$0,
                loaded: loaded,
                reads: reads,
                release: release.stream,
                catalogRelease: catalogRelease.stream
            )
        }

        // When
        await store.send(.insights(.view(.retryTapped))) {
            $0.insights.dateContext = InsightsDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.insights.delegate.refresh)
        await Self.receiveOrdersReload(
            in: store,
            loaded: loaded,
            release: release.continuation,
            catalogRelease: catalogRelease.continuation
        )
        await store.finish()
        #expect(reads.value == 1)
        #expect(store.state.orders.orders == [loaded])
        #expect(store.state.campaigns.orders == [loaded])
        #expect(store.state.more.orders == [loaded])
        #expect(store.state.dashboard.orders == [loaded])
        #expect(store.state.insights.orders == [loaded])
    }

    /// 驗證經「更多」推入的客戶頁首次載入失敗後按下重試，根功能只向訂單功能送出一次載入請求，成功後同步所有頁面的訂單
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
        let catalogRelease = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            Self.stubOrdersReload(
                &$0,
                loaded: loaded,
                reads: reads,
                release: release.stream,
                catalogRelease: catalogRelease.stream
            )
        }

        // When
        await store.send(.more(.path(.element(id: id, action: .customers(.view(.task))))))

        // Then
        await store.receive(\.more.path[id: id].customers.delegate.ordersLoadRequested)
        await store.receive(\.more.delegate.ordersLoadRequested)
        await Self.receiveOrdersReload(
            in: store,
            loaded: loaded,
            release: release.continuation,
            catalogRelease: catalogRelease.continuation
        )
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

private extension RootFeatureLoadRequestsTests {

    /// 建立訂單首次載入失敗的根狀態，總覽與分析頁都停在失敗畫面
    ///
    /// - Returns: 訂單載入失敗的根狀態
    static func makeOrdersLoadFailedState() -> RootFeature.State {
        var initial = RootFeatureTestSupport.makeIsolatedRootState()
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
    ///   - catalogRelease: 控制主檔讀取何時完成的串流
    static func stubOrdersReload(
        _ dependencies: inout DependencyValues,
        loaded: LedgerOrder,
        reads: LockIsolated<Int>,
        release: AsyncStream<Void>,
        catalogRelease: AsyncStream<Void>
    ) {
        dependencies.orderService.fetchOrders = {
            reads.withValue {
                $0 += 1
            }
            var iterator = release.makeAsyncIterator()
            _ = await iterator.next()
            return [loaded]
        }
        let fetchItems: LookupService.FetchItems = { _ in
            var iterator = catalogRelease.makeAsyncIterator()
            _ = await iterator.next()
            return LookupCatalog()
        }
        dependencies.lookupService.fetchItems = fetchItems
    }

    /// 接收根功能送出的訂單重新載入，確認總覽與分析頁回到載入中，釋放後接收載入成功的同步結果
    ///
    /// - Parameters:
    ///   - store: 已送出重試事件的測試 `store`
    ///   - loaded: 載入成功後同步到各頁的訂單
    ///   - release: 控制載入何時完成的 `continuation`
    ///   - catalogRelease: 控制主檔讀取何時完成的 `continuation`
    static func receiveOrdersReload(
        in store: TestStoreOf<RootFeature>,
        loaded: LedgerOrder,
        release: AsyncStream<Void>.Continuation,
        catalogRelease: AsyncStream<Void>.Continuation
    ) async {
        await store.receive(\.more.catalogLoadRequested)
        await store.receive(\.more.catalog.loadRequested) {
            $0.more.catalog.isLoading = true
        }
        catalogRelease.finish()
        await store.receive(
            \.more.catalog.catalogResponse,
            [
                .orderSource: LookupCatalog(
                    orderSources: [],
                    categories: [],
                    paymentMethods: [],
                    reconciliationStatuses: []
                ),
                .category: LookupCatalog(
                    orderSources: [],
                    categories: [],
                    paymentMethods: [],
                    reconciliationStatuses: []
                ),
                .paymentMethod: LookupCatalog(
                    orderSources: [],
                    categories: [],
                    paymentMethods: [],
                    reconciliationStatuses: []
                ),
                .reconciliationStatus: LookupCatalog(
                    orderSources: [],
                    categories: [],
                    paymentMethods: [],
                    reconciliationStatuses: []
                ),
            ]
        ) {
            $0.more.catalog.isLoading = false
            $0.more.catalog.hasLoaded = true
            $0.orders.load.$isLoading.withLock {
                $0 = true
            }
            $0.orders.load.$errorMessage.withLock {
                $0 = nil
            }
        }
        await store.receive(\.more.catalog.delegate.loadFinished)
        await store.receive(\.more.delegate.catalogLoadFinished)
        await store.receive(\.orders.rootRequest.load)
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
                orders: SharedReader(value: [loaded])
            )
            $0.dashboard.orders = [loaded]
            $0.dashboard.loadState = .loaded
            $0.insights.orders = [loaded]
            $0.insights.loadState = .loaded
        }
    }
}
