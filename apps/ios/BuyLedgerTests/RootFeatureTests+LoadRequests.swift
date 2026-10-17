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
        var initial = Self.makeIsolatedRootState()
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

    /// 分析頁的重試按鈕在首次載入失敗後，只由根功能轉送一次載入請求，成功後同步所有頁面的訂單
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
