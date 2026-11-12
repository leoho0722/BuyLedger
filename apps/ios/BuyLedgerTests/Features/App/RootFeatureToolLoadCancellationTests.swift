//
//  RootFeatureToolLoadCancellationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/11.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `RootFeature` 設定深連結的取消語意測試，交給更多頁移除工具後不再接收該工具的匯率回應
///
/// - Note: 堆疊變更透過 `MoreFeature` 的請求 action 處理，讓已移除工具的讀取隨之取消
@MainActor
struct RootFeatureToolLoadCancellationTests {

    /// 驗證匯率頁讀取中從訂單要求 AI 設定時，切到更多頁並替換工具，已移除匯率頁不再收到回應
    @Test
    func orders_匯率頁讀取中要求人工智慧設定_取消已移除工具的讀取() async {
        // Given
        var initial = RootFeatureTestSupport.makeIsolatedRootState()
        initial.selectedTab = .orders
        initial.more.path.append(.fx(FxFeature.State()))
        let releaseRates = AsyncStream<Void>.makeStream()
        let rateStarted = AsyncStream<Void>.makeStream()
        let rateFinished = AsyncStream<Void>.makeStream()
        let hasReadBeenCancelled = LockIsolated(false)
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.currencyMetadataService.fetchCodes = {
                [.twd]
            }
            $0.exchangeRateService.fetchLatest = { _ throws(APIError) in
                rateStarted.continuation.yield(())
                var iterator = releaseRates.stream.makeAsyncIterator()
                _ = await iterator.next()
                hasReadBeenCancelled.withValue {
                    $0 = Task.isCancelled
                }
                rateFinished.continuation.finish()
                // 未取消時仍送出失敗回應，讓窮舉檢查能抓到已移除元素的遲到結果
                throw .http(statusCode: 503)
            }
        }
        await store.send(.more(.path(.element(id: 0, action: .fx(.view(.task)))))) {
            $0.more.path[id: 0, case: \.fx]?.isLoading = true
        }
        await store.receive(\.more.path[id: 0].fx.currencyCodesResponse.success, [.twd]) {
            $0.more.path[id: 0, case: \.fx]?.availableCurrencies = [.krw, .twd]
        }
        var startedIterator = rateStarted.stream.makeAsyncIterator()
        _ = await startedIterator.next()

        // When
        await store.send(.orders(.delegate(.aiSettingsRequested))) {
            $0.selectedTab = .more
        }

        // Then
        await store.receive(\.more.settingsRequested) {
            $0.more.path.removeAll()
            $0.more.path[id: 1] = .settings(
                SettingsFeature.State(
                    snapshot: .default,
                    appVersion: "—",
                    biometryType: .unavailable
                )
            )
        }
        releaseRates.continuation.finish()
        var finishedIterator = rateFinished.stream.makeAsyncIterator()
        _ = await finishedIterator.next()
        await store.finish()
        #expect(store.state.selectedTab == .more)
        #expect(store.state.more.path.count == 1)
        #expect(store.state.more.path[id: 0] == nil)
        #expect(store.state.more.path[id: 1, case: \.settings] != nil)
        #expect(hasReadBeenCancelled.value)
    }
}
