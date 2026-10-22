//
//  RootFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試：分頁切換、跨頁跳轉與跨功能資料同步
@MainActor
struct RootFeatureTests {

    /// 資料庫無法開啟時，根畫面一建立就顯示阻擋畫面
    @Test
    func init_持久化狀態降級_呈現阻擋畫面() {
        // Given

        // When
        let state = RootFeature.State(persistenceStatus: .degraded(reason: "Unable to open store"))

        // Then
        #expect(state.persistenceFailure?.phase == .blocked)
    }

    /// 資料庫正常開啟時，根畫面不顯示阻擋畫面
    @Test
    func init_持久化狀態正常_不呈現阻擋畫面() {
        // Given

        // When
        let state = RootFeature.State(persistenceStatus: .healthy)

        // Then
        #expect(state.persistenceFailure == nil)
    }

    /// 建立根狀態時，App 鎖定狀態要與已保存的生物辨識解鎖設定一致
    ///
    /// - Parameters:
    ///   - isBiometricUnlockEnabled: 是否啟用生物辨識解鎖
    ///   - isExpectedLocked: 預期的初始鎖定狀態
    @Test(arguments: [(true, true), (false, false)])
    func init_生物辨識解鎖設定_鎖定狀態與設定一致(isBiometricUnlockEnabled: Bool, isExpectedLocked: Bool) {
        // Given
        var snapshot = SettingsSnapshot.default
        snapshot.isBiometricUnlockEnabled = isBiometricUnlockEnabled

        // When
        let state = RootFeature.State(preferences: snapshot)

        // Then
        #expect(state.appLock.isLocked == isExpectedLocked)
        #expect(state.appLock.isBiometricUnlockEnabled == isBiometricUnlockEnabled)
    }

    /// 根畫面與更多頁一建立就帶入已保存的設定與 App 版本
    @Test
    func init_注入已保存設定_殼層與更多頁持有偏好與版本() {
        // Given
        var snapshot = SettingsSnapshot.default
        snapshot.language = .english
        snapshot.defaultCurrency = .usd
        snapshot.monthlyProfitGoalTWD = 120_000

        // When
        let state = RootFeature.State(preferences: snapshot, appVersion: "1.7.0 (312)")

        // Then
        #expect(state.preferences == snapshot)
        #expect(state.more.preferences.language == .english)
        #expect(state.more.preferences.defaultCurrency == .usd)
        #expect(state.more.preferences.monthlyProfitGoalTWD == 120_000)
        #expect(state.more.appVersion == "1.7.0 (312)")
    }

    /// 總覽頁一開始就使用已保存的月目標 (50,000 元)，不必等設定頁改值
    @Test
    func init_已保存月目標_總覽首幀使用該目標() {
        // Given
        var preferences = SettingsSnapshot.default
        preferences.monthlyProfitGoalTWD = 50_000

        // When
        let state = RootFeature.State(preferences: preferences)

        // Then
        #expect(state.preferences.monthlyProfitGoalTWD == 50_000)
        #expect(state.dashboard.monthlyProfitGoalTWD == 50_000)
    }

    /// App 重新啟動時，根畫面一律從總覽分頁開始
    @Test
    func init_預設參數_選取總覽分頁() {
        // Given

        // When
        let state = RootFeature.State()

        // Then
        #expect(state.selectedTab == .dashboard)
    }

    /// App 啟動只以七天期限刷新幣別，不觸發設定或 App 鎖定動作
    @Test
    func task_啟動根功能_以七天期限刷新幣別快取() async {
        // Given
        let refreshTTLs = LockIsolated<[TimeInterval]>([])
        var initial = Self.makeIsolatedRootState()
        initial.campaigns.load.$hasLoaded.withLock {
            $0 = true
        }
        initial.orders.load.$hasLoaded.withLock {
            $0 = true
        }
        initial.more.catalog.hasLoaded = true
        let currencyRelease = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.currencyMetadataService.refreshIfStale = { ttl in
                var iterator = currencyRelease.stream.makeAsyncIterator()
                _ = await iterator.next()
                refreshTTLs.withValue {
                    $0.append(ttl)
                }
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
        #expect(refreshTTLs.value == [604_800])
    }

    /// iPhone 切換主要分頁時保留「更多」路徑
    @Test
    func tabSelected_更多路徑非空_保留路徑() async {
        // Given
        var state = Self.makeIsolatedRootState {
            var initial = RootFeature.State()
            initial.more.path.append(
                .lookupManagement(LookupManagementFeature.State(kind: .category))
            )
            return initial
        }
        state.selectedTab = .more

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.tabSelected(.orders))) {
            $0.selectedTab = .orders
        }

        // Then
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.more.path == state.more.path)
    }
}
