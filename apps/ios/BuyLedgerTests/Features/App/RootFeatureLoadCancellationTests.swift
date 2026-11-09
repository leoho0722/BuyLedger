//
//  RootFeatureLoadCancellationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `RootFeature` 取消語意的特性測試：`.task` 被取消時，連帶取消共用的訂單讀取並遺失讀取結果
///
/// - Note: 測試固定 TCA 1.26.2 的行為，TCA 改變取消語意時會轉紅，屆時重審 `.claude/rules/ios-navigation.md` 的 `.task` 規則
@MainActor
struct RootFeatureLoadCancellationTests {

    /// 驗證分析頁發起的共用訂單讀取被取消後，載入旗標仍為載入中，之後再次重新整理也不會再發起讀取
    @Test
    func insights_發起讀取的task被取消_載入旗標卡住且之後請求不再讀取() async {
        // Given
        var initial = RootFeatureTestSupport.makeIsolatedRootState()
        initial.more.catalog.hasLoaded = true
        initial.orders.load.$errorMessage.withLock {
            $0 = "orders.general.message.ordersLoadedTry"
        }
        initial.dashboard.loadState = .failed("orders.general.message.ordersLoadedTry")
        initial.insights.loadState = .failed("orders.general.message.ordersLoadedTry")
        let reads = LockIsolated(0)
        // 刻意不放行，讀取只在 effect 被取消時結束
        let neverReleased = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.fetchOrders = {
                reads.withValue {
                    $0 += 1
                }
                var iterator = neverReleased.stream.makeAsyncIterator()
                _ = await iterator.next()
                return []
            }
        }
        let task = await store.send(.insights(.view(.task))) {
            $0.insights.dateContext = InsightsDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.orders.load.$isLoading.withLock {
                $0 = true
            }
            $0.orders.load.$errorMessage.withLock {
                $0 = nil
            }
        }
        await store.receive(\.insights.delegate.refresh)
        await store.receive(\.more.catalogLoadRequested)
        await store.receive(\.more.catalog.loadRequested)
        await store.receive(\.more.catalog.delegate.loadFinished)
        await store.receive(\.more.delegate.catalogLoadFinished)
        await store.receive(\.orders.rootRequest.load)
        await store.receive(\.orders.load.loadRequested) {
            $0.dashboard.loadState = .loading
            $0.insights.loadState = .loading
        }
        await task.cancel()

        // When
        await store.send(.insights(.view(.retryTapped)))

        // Then
        await store.receive(\.insights.delegate.refresh)
        await store.receive(\.more.catalogLoadRequested)
        await store.receive(\.more.catalog.loadRequested)
        await store.receive(\.more.catalog.delegate.loadFinished)
        await store.receive(\.more.delegate.catalogLoadFinished)
        await store.receive(\.orders.rootRequest.load)
        await store.receive(\.orders.load.loadRequested)
        #expect(store.state.orders.load.isLoading)
        await store.finish()
        #expect(reads.value == 1)
    }
}
