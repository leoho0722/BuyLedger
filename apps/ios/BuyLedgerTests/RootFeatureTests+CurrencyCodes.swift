//
//  RootFeatureTests+CurrencyCodes.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 啟動後依序刷新與讀取快取，將三種幣別寫入共用清單
    @Test
    func task_快取包含三種幣別_共用清單更新為快取內容() async {
        // Given
        let calls = LockIsolated<[String]>([])
        let initial = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            RootFeature.State()
        }
        initial.campaigns.load.$hasLoaded.withLock {
            $0 = true
        }
        initial.orders.load.$hasLoaded.withLock {
            $0 = true
        }
        let currencyRelease = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.currencyMetadataService.refreshIfStale = { _ in
                var iterator = currencyRelease.stream.makeAsyncIterator()
                _ = await iterator.next()
                calls.withValue {
                    $0.append("refresh")
                }
                return false
            }
            $0.currencyMetadataService.fetchCodes = {
                calls.withValue {
                    $0.append("fetch")
                }
                return [.twd, .jpy, CurrencyCode(rawValue: "EUR")]
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
        await store.receive(\.launch.currencyCodesResponse.success) {
            $0.launch.$currencyCodes.withLock {
                $0 = [.twd, .jpy, CurrencyCode(rawValue: "EUR")]
            }
        }
        await store.finish()
        #expect(store.state.launch.currencyCodes == [.twd, .jpy, CurrencyCode(rawValue: "EUR")])
        #expect(calls.value == ["refresh", "fetch"])
    }

    /// 讀取快取失敗時仍收到失敗回應，原有共用幣別不變
    @Test
    func task_幣別快取讀取失敗_共用清單維持原值() async {
        // Given
        let underlying = NSError(domain: "CurrencyCacheTests", code: 1)
        let failingFetch: CurrencyMetadataService.FetchCodes = { () throws(CurrencyMetadataServiceError) in
            throw .persistence(.storage(.fetchFailed(underlying: underlying)))
        }
        let initial = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            RootFeature.State()
        }
        initial.launch.$currencyCodes.withLock {
            $0 = [.usd]
        }
        initial.campaigns.load.$hasLoaded.withLock {
            $0 = true
        }
        initial.orders.load.$hasLoaded.withLock {
            $0 = true
        }
        let currencyRelease = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.currencyMetadataService.refreshIfStale = { _ in
                var iterator = currencyRelease.stream.makeAsyncIterator()
                _ = await iterator.next()
                return false
            }
            $0.currencyMetadataService.fetchCodes = failingFetch
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
        await store.receive(\.launch.currencyCodesResponse.failure)
        await store.finish()
        #expect(store.state.launch.currencyCodes == [.usd])
    }

    /// 快取沒有幣別資料時保留原有的非空共用清單
    @Test
    func task_幣別快取回傳空清單_共用清單維持原值() async {
        // Given
        let initial = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            RootFeature.State()
        }
        initial.launch.$currencyCodes.withLock {
            $0 = [.usd]
        }
        initial.campaigns.load.$hasLoaded.withLock {
            $0 = true
        }
        initial.orders.load.$hasLoaded.withLock {
            $0 = true
        }
        let currencyRelease = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            RootFeature()
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
        #expect(store.state.launch.currencyCodes == [.usd])
    }

    /// 遠端刷新失敗後仍讀取一次既有快取，並替換原有共用清單
    @Test
    func task_幣別刷新失敗_仍讀取既有快取並更新共用清單() async {
        // Given
        let calls = LockIsolated<[String]>([])
        let failingRefresh: CurrencyMetadataService.RefreshIfStale = { _ throws(CurrencyMetadataServiceError) in
            calls.withValue {
                $0.append("refresh")
            }
            throw .api(.http(statusCode: 503))
        }
        let initial = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            RootFeature.State()
        }
        initial.launch.$currencyCodes.withLock {
            $0 = [.usd]
        }
        initial.campaigns.load.$hasLoaded.withLock {
            $0 = true
        }
        initial.orders.load.$hasLoaded.withLock {
            $0 = true
        }
        let currencyRelease = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.currencyMetadataService.refreshIfStale = { ttl throws(CurrencyMetadataServiceError) in
                var iterator = currencyRelease.stream.makeAsyncIterator()
                _ = await iterator.next()
                return try await failingRefresh(ttl)
            }
            $0.currencyMetadataService.fetchCodes = {
                calls.withValue {
                    $0.append("fetch")
                }
                return [.twd, .jpy, CurrencyCode(rawValue: "EUR")]
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
        await store.receive(\.launch.currencyCodesResponse.success) {
            $0.launch.$currencyCodes.withLock {
                $0 = [.twd, .jpy, CurrencyCode(rawValue: "EUR")]
            }
        }
        await store.finish()
        #expect(store.state.launch.currencyCodes == [.twd, .jpy, CurrencyCode(rawValue: "EUR")])
        #expect(calls.value == ["refresh", "fetch"])
    }
}
