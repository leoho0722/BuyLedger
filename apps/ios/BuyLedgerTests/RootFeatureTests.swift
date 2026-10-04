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

/// `RootFeature` 的單元測試：分頁導覽、深連結與跨功能同步
@MainActor
struct RootFeatureTests {

    /// 持久層開啟失敗時，根畫面一建立就呈現阻擋畫面
    @Test
    func init_持久化狀態降級_呈現阻擋畫面() {
        // Given

        // When
        let state = RootFeature.State(persistenceStatus: .degraded(reason: "Unable to open store"))

        // Then
        #expect(state.persistenceFailure?.phase == .blocked)
    }

    /// 持久層正常時，根畫面不呈現阻擋畫面
    @Test
    func init_持久化狀態正常_不呈現阻擋畫面() {
        // Given

        // When
        let state = RootFeature.State(persistenceStatus: .healthy)

        // Then
        #expect(state.persistenceFailure == nil)
    }

    /// 根 `State` 建立時，鎖定狀態與已保存的生物辨識設定一致
    ///
    /// - Parameters:
    ///   - isBiometricUnlockEnabled: 是否啟用生物辨識解鎖
    ///   - expectedIsLocked: 預期的初始鎖定狀態
    @Test(arguments: [(true, true), (false, false)])
    func init_生物辨識解鎖設定_鎖定狀態與設定一致(isBiometricUnlockEnabled: Bool, expectedIsLocked: Bool) {
        // Given
        var snapshot = SettingsSnapshot.default
        snapshot.isBiometricUnlockEnabled = isBiometricUnlockEnabled

        // When
        let state = RootFeature.State(preferences: snapshot)

        // Then
        #expect(state.appLock.isLocked == expectedIsLocked)
        #expect(state.appLock.isBiometricUnlockEnabled == isBiometricUnlockEnabled)
    }

    /// 根偏好與更多頁投影一建立就帶齊已保存值與版本
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

    /// 首頁第一幀就使用已儲存的 50,000 目標，不必等設定頁改值
    @Test
    func init_已保存月目標_總覽首幀使用該目標() {
        // Given
        var preferences = SettingsSnapshot.default
        preferences.monthlyProfitGoalTWD = 50_000

        // When
        let state = RootFeature.State(preferences: preferences)

        // Then
        #expect(state.preferences.monthlyProfitGoalTWD == 50_000)
        #expect(state.dashboard.monthlyProfitGoalTwd == 50_000)
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
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.currencyMetadataService.refreshIfStale = { ttl in
                refreshTTLs.withValue {
                    $0.append(ttl)
                }
                return false
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
