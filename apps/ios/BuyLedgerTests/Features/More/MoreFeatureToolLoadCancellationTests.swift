//
//  MoreFeatureToolLoadCancellationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/11.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `MoreFeature` 工具讀取取消語意的特性測試：返回入口或切換工具時，取消已移除元素的匯率讀取
///
/// - Note: 測試固定 TCA 1.26.2 的行為，TCA 改變取消語意時會轉紅
///   屆時重審 `.claude/rules/ios-navigation.md` 的 `.task` 規則
@MainActor
struct MoreFeatureToolLoadCancellationTests {

    /// 驗證匯率頁讀取中返回入口清單時，移除元素會取消讀取，放行替身後也沒有匯率回應
    @Test
    func entrySelected_匯率頁讀取中返回入口_取消讀取且不接收匯率回應() async {
        // Given
        let releaseRates = AsyncStream<Void>.makeStream()
        let rateStarted = AsyncStream<Void>.makeStream()
        let rateFinished = AsyncStream<Void>.makeStream()
        let hasReadBeenCancelled = LockIsolated(false)
        let initial = Self.makeInitialState(tool: .fx(FxFeature.State()))
        let store = TestStore(initialState: initial) {
            MoreFeature()
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
                // 未取消時仍送出失敗回應，讓窮舉檢查能抓到遲到的結果
                throw .http(statusCode: 503)
            }
        }
        await store.send(.path(.element(id: 0, action: .fx(.view(.task))))) {
            $0.path[id: 0, case: \.fx]?.isLoading = true
        }
        await store.receive(\.path[id: 0].fx.currencyCodesResponse.success, [.twd]) {
            $0.path[id: 0, case: \.fx]?.availableCurrencies = [.krw, .twd]
        }
        var startedIterator = rateStarted.stream.makeAsyncIterator()
        _ = await startedIterator.next()

        // When
        await store.send(.view(.entrySelected(nil))) {
            $0.path.removeAll()
        }

        // Then
        releaseRates.continuation.finish()
        var finishedIterator = rateFinished.stream.makeAsyncIterator()
        _ = await finishedIterator.next()
        await store.finish()
        #expect(store.state.path.isEmpty)
        #expect(hasReadBeenCancelled.value)
    }

    /// 驗證報價頁透過畫面事件啟動匯率讀取後，返回入口清單會取消子功能讀取且不接收匯率回應
    @Test
    func entrySelected_報價頁讀取中返回入口_取消讀取且不接收匯率回應() async {
        // Given
        let releaseRates = AsyncStream<Void>.makeStream()
        let rateStarted = AsyncStream<Void>.makeStream()
        let rateFinished = AsyncStream<Void>.makeStream()
        let hasReadBeenCancelled = LockIsolated(false)
        let initial = Self.makeInitialState(tool: .quote(QuoteFeature.State()))
        let store = TestStore(initialState: initial) {
            MoreFeature()
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
                // 未取消時仍送出失敗回應，讓窮舉檢查能抓到遲到的結果
                throw .http(statusCode: 503)
            }
        }
        await store.send(.path(.element(id: 0, action: .quote(.view(.task)))))
        await store.receive(\.path[id: 0].quote.rateSource.task) {
            $0.path[id: 0, case: \.quote]?.rateSource.isLoading = true
        }
        await store.receive(\.path[id: 0].quote.rateSource.currencyCodesResponse.success, [.twd]) {
            $0.path[id: 0, case: \.quote]?.rateSource.availableCurrencies = [.krw, .twd]
        }
        var startedIterator = rateStarted.stream.makeAsyncIterator()
        _ = await startedIterator.next()

        // When
        await store.send(.view(.entrySelected(nil))) {
            $0.path.removeAll()
        }

        // Then
        releaseRates.continuation.finish()
        var finishedIterator = rateFinished.stream.makeAsyncIterator()
        _ = await finishedIterator.next()
        await store.finish()
        #expect(store.state.path.isEmpty)
        #expect(hasReadBeenCancelled.value)
    }

    /// 驗證匯率頁讀取中改選報價時，取消已移除匯率元素的讀取，放行後也沒有遲到的匯率回應
    @Test
    func entrySelected_匯率頁讀取中改選報價_取消舊讀取且不接收匯率回應() async {
        // Given
        let releaseRates = AsyncStream<Void>.makeStream()
        let rateStarted = AsyncStream<Void>.makeStream()
        let rateFinished = AsyncStream<Void>.makeStream()
        let hasReadBeenCancelled = LockIsolated(false)
        let initial = Self.makeInitialState(tool: .fx(FxFeature.State()))
        let store = TestStore(initialState: initial) {
            MoreFeature()
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
                // 未取消時仍送出失敗回應，讓窮舉檢查能抓到遲到的結果
                throw .http(statusCode: 503)
            }
        }
        await store.send(.path(.element(id: 0, action: .fx(.view(.task))))) {
            $0.path[id: 0, case: \.fx]?.isLoading = true
        }
        await store.receive(\.path[id: 0].fx.currencyCodesResponse.success, [.twd]) {
            $0.path[id: 0, case: \.fx]?.availableCurrencies = [.krw, .twd]
        }
        var startedIterator = rateStarted.stream.makeAsyncIterator()
        _ = await startedIterator.next()

        // When
        await store.send(.view(.entrySelected(.quote))) {
            $0.path.removeAll()
            $0.path.append(.quote(QuoteFeature.State()))
        }

        // Then
        releaseRates.continuation.finish()
        var finishedIterator = rateFinished.stream.makeAsyncIterator()
        _ = await finishedIterator.next()
        await store.finish()
        #expect(store.state.path.count == 1)
        #expect(store.state.path[id: 0] == nil)
        #expect(store.state.path[id: 1, case: \.quote] == QuoteFeature.State())
        #expect(hasReadBeenCancelled.value)
    }
}

// MARK: - Private Method

private extension MoreFeatureToolLoadCancellationTests {

    /// 在獨立記憶體儲存建立已開啟指定工具的更多頁，避免影響其他測試的主檔目錄
    ///
    /// - Parameter tool: 初始堆疊中的工具，尚未啟動讀取
    /// - Returns: 只有指定工具且主檔目錄隔離的更多頁狀態
    static func makeInitialState(tool: MoreFeature.Path.State) -> MoreFeature.State {
        withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            var state = MoreFeature.State(appVersion: "1.7.0")
            state.path.append(tool)
            return state
        }
    }
}
