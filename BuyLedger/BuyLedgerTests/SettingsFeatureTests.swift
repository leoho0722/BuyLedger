//
//  SettingsFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/2.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct SettingsFeatureTests {
    
    // MARK: - Tests
    
    @Test func defaultStateMatchesProductDefaults() {
        let state = SettingsFeature.State()
        
        #expect(state.appearance == .system)
        #expect(state.notificationsEnabled == true)
        #expect(state.defaultCurrency == .twd)
    }
    
    @Test func bindingUpdatesAppearance() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
        
        await store.send(\.binding.appearance, .dark) {
            $0.appearance = .dark
        }
    }
    
    @Test func bindingUpdatesNotificationsToggle() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
        
        await store.send(\.binding.notificationsEnabled, false) {
            $0.notificationsEnabled = false
        }
    }
    
    @Test func bindingUpdatesDefaultCurrency() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
        
        await store.send(\.binding.defaultCurrency, .jpy) {
            $0.defaultCurrency = .jpy
        }
    }
    
    @Test func appearancePreferenceTitleIsLocalized() {
        #expect(AppearancePreference.system.title == "自動")
        #expect(AppearancePreference.light.title == "淺色")
        #expect(AppearancePreference.dark.title == "深色")
    }
    
    @Test func taskLoadsFromInjectedStorage() async {
        let stored = SettingsSnapshot(
            appearance: .dark,
            notificationsEnabled: false,
            defaultCurrency: .jpy,
            monthlyProfitGoalTwd: 50_000
        )
        
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStorage.self] = SettingsStorage(
                load: { stored },
                save: { _ in }
            )
        }
        
        await store.send(.task) {
            $0.appearance = .dark
            $0.notificationsEnabled = false
            $0.defaultCurrency = .jpy
            $0.monthlyProfitGoalTwd = 50_000
        }
    }
    
    @Test func bindingTriggersStorageSave() async {
        let saved = SnapshotBox()
        
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStorage.self] = SettingsStorage(
                load: { .default },
                save: { snapshot in saved.value = snapshot }
            )
        }
        
        await store.send(\.binding.appearance, .light) {
            $0.appearance = .light
        }
        
        #expect(saved.value?.appearance == .light)
        #expect(saved.value?.notificationsEnabled == true)
        #expect(saved.value?.defaultCurrency == .twd)
    }
}

/// 簡易的 `@unchecked Sendable` 容器，避免引入 `ConcurrencyExtras.LockIsolated` 在測試 target 中遭遇連結問題。
private final class SnapshotBox: @unchecked Sendable {
    
    // MARK: - Data Properties
    
    /// 由 closure 寫入並由測試讀取的快照。
    var value: SettingsSnapshot?
    
    // MARK: - Init
    
    init() {
        self.value = nil
    }
}
