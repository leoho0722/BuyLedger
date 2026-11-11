//
//  RootLaunchFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `RootLaunchFeature` 的單元測試，涵蓋啟動時的幣別快取寫入，以及系統時間變更的通知
@MainActor
struct RootLaunchFeatureTests {

    /// 驗證啟動載入時以七天期限刷新幣別，接著讀取快取並回報結果，刷新在讀取之前進行
    @Test
    func loadRequested_啟動載入_以七天期限刷新後讀取快取() async {
        // Given
        let refreshTTLs = LockIsolated<[TimeInterval]>([])
        let calls = LockIsolated<[String]>([])
        let initial = Self.makeIsolatedLaunchState()
        let store = TestStore(initialState: initial) {
            RootLaunchFeature()
        } withDependencies: {
            $0.currencyMetadataService.refreshIfStale = { ttl in
                refreshTTLs.withValue {
                    $0.append(ttl)
                }
                calls.withValue {
                    $0.append("refresh")
                }
                return false
            }
            $0.currencyMetadataService.fetchCodes = {
                calls.withValue {
                    $0.append("fetch")
                }
                return []
            }
            $0.significantTimeChangeService.changes = {
                AsyncStream {
                    $0.finish()
                }
            }
        }

        // When
        await store.send(.loadRequested)

        // Then
        await store.receive(\.currencyCodesResponse.success, [])
        await store.finish()
        #expect(refreshTTLs.value == [604_800])
        #expect(calls.value == ["refresh", "fetch"])
    }

    /// 驗證收到系統的重大時間變更時，送出時間變更通知，之後才回報幣別讀取結果
    @Test
    func loadRequested_收到重大時間變更_送出時間變更委派() async {
        // Given
        let timeChanges = AsyncStream<Void>.makeStream()
        let currencyRelease = AsyncStream<Void>.makeStream()
        let initial = Self.makeIsolatedLaunchState()
        let store = TestStore(initialState: initial) {
            RootLaunchFeature()
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
                timeChanges.stream
            }
        }

        // When
        await store.send(.loadRequested)

        // Then
        timeChanges.continuation.yield(())
        timeChanges.continuation.finish()
        await store.receive(\.delegate.significantTimeChanged)
        currencyRelease.continuation.finish()
        await store.receive(\.currencyCodesResponse.success, [])
        await store.finish()
    }

    /// 驗證連續請求載入時取代前一次時間監聽，系統廣播一次變更只送出一次委派
    @Test(.timeLimit(.minutes(1)))
    func loadRequested_連續送出兩次_只保留最後一次時間監聽() async {
        // Given
        let subscriptions = LockIsolated<[AsyncStream<Void>.Continuation]>([])
        let hasTerminated = LockIsolated<[Bool]>([])
        let subscriptionStarted = AsyncStream<Int>.makeStream()
        var subscriptionIterator = subscriptionStarted.stream.makeAsyncIterator()
        let initial = Self.makeIsolatedLaunchState()
        let store = TestStore(initialState: initial) {
            RootLaunchFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.currencyMetadataService.refreshIfStale = { _ in
                false
            }
            $0.currencyMetadataService.fetchCodes = {
                []
            }
            $0.significantTimeChangeService.changes = {
                let timeChanges = AsyncStream<Void>.makeStream()
                let subscriptionIndex = subscriptions.withValue {
                    let index = $0.count
                    $0.append(timeChanges.continuation)
                    return index
                }
                hasTerminated.withValue {
                    $0.append(false)
                }
                timeChanges.continuation.onTermination = { _ in
                    hasTerminated.withValue {
                        $0[subscriptionIndex] = true
                    }
                }
                subscriptionStarted.continuation.yield(subscriptionIndex)
                return timeChanges.stream
            }
        }
        await store.send(.loadRequested)
        await store.receive(\.currencyCodesResponse.success, [])
        let firstSubscription = await subscriptionIterator.next()
        #expect(firstSubscription == 0)

        // When
        await store.send(.loadRequested)

        // Then
        await store.receive(\.currencyCodesResponse.success, [])
        let secondSubscription = await subscriptionIterator.next()
        #expect(secondSubscription == 1)
        #expect(subscriptions.value.count == 2)
        #expect(hasTerminated.value == [true, false])
        for continuation in subscriptions.value {
            continuation.yield(())
        }
        await store.receive(\.delegate.significantTimeChanged)
        for continuation in subscriptions.value {
            continuation.finish()
        }
        subscriptionStarted.continuation.finish()
        await store.finish()
        #expect(hasTerminated.value == [true, true])
    }

    /// 驗證快取回傳非空清單時，共用幣別清單改為快取內容
    @Test
    func currencyCodesResponse_成功且非空_寫入共用幣別清單() async {
        // Given
        let initial = Self.makeIsolatedLaunchState()
        initial.$currencyCodes.withLock {
            $0 = [.usd]
        }
        let store = TestStore(initialState: initial) {
            RootLaunchFeature()
        }

        // When
        await store.send(
            .currencyCodesResponse(.success([.twd, .jpy, CurrencyCode(rawValue: "EUR")]))
        ) {
            $0.$currencyCodes.withLock {
                $0 = [.twd, .jpy, CurrencyCode(rawValue: "EUR")]
            }
        }

        // Then
        #expect(store.state.currencyCodes == [.twd, .jpy, CurrencyCode(rawValue: "EUR")])
    }

    /// 驗證快取回傳空清單時，保留原有的非空共用清單
    @Test
    func currencyCodesResponse_成功但為空_保留原共用清單() async {
        // Given
        let initial = Self.makeIsolatedLaunchState()
        initial.$currencyCodes.withLock {
            $0 = [.usd]
        }
        let store = TestStore(initialState: initial) {
            RootLaunchFeature()
        }

        // When
        await store.send(.currencyCodesResponse(.success([])))

        // Then
        #expect(store.state.currencyCodes == [.usd])
    }

    /// 驗證快取讀取失敗時，保留原有的非空共用清單
    @Test
    func currencyCodesResponse_讀取失敗_保留原共用清單() async {
        // Given
        let initial = Self.makeIsolatedLaunchState()
        initial.$currencyCodes.withLock {
            $0 = [.usd]
        }
        let store = TestStore(initialState: initial) {
            RootLaunchFeature()
        }

        // When
        await store.send(.currencyCodesResponse(.failure(.api(.http(statusCode: 503)))))

        // Then
        #expect(store.state.currencyCodes == [.usd])
    }
}

// MARK: - Private Method

private extension RootLaunchFeatureTests {

    /// 建立使用獨立記憶體儲存的啟動狀態，避免改寫幣別清單影響同批次的其他測試
    ///
    /// - Returns: 幣別清單為空的啟動狀態
    static func makeIsolatedLaunchState() -> RootLaunchFeature.State {
        withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            RootLaunchFeature.State()
        }
    }
}
