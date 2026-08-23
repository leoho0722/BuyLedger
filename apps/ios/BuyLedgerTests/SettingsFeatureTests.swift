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

/// 驗證設定功能
@MainActor
struct SettingsFeatureTests {
    
    // MARK: - Tests
    
    @Test func defaultStateMatchesProductDefaults() {
        let state = SettingsFeature.State()
        
        #expect(state.language == .traditionalChinese)
        #expect(state.defaultCurrency == .twd)
        #expect(state.useAiSummary == false)
        #expect(state.aiSummaryModel == "gemma4:31b-cloud")
        #expect(state.appLock.isBiometricUnlockEnabled == false)
    }
    
    @Test func appLanguageUsesSupportedLocaleIdentifiers() {
        #expect(AppLanguage.traditionalChinese.localeIdentifier == "zh-Hant")
        #expect(AppLanguage.english.localeIdentifier == "en")
    }
    
    @Test func appLanguageProvidesMatchingLocale() {
        #expect(AppLanguage.traditionalChinese.locale.identifier == "zh-Hant")
        #expect(AppLanguage.english.locale.identifier == "en")
    }
    
    @Test func appLanguageTitlesUseLocalizedResources() {
        #expect(String(localized: AppLanguage.traditionalChinese.title) == "正體中文")
        #expect(String(localized: AppLanguage.english.title) == "English")
    }
    
    @Test func appLanguageStoredValueFallsBackToTraditionalChinese() {
        #expect(AppLanguage(storedValue: nil) == .traditionalChinese)
        #expect(AppLanguage(storedValue: "") == .traditionalChinese)
        #expect(AppLanguage(storedValue: "unsupported") == .traditionalChinese)
        #expect(AppLanguage(storedValue: "english") == .english)
    }
    
    @Test func bindingUpdatesLanguageAndSaves() async {
        let saved = SnapshotBox()
        
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStorage.self] = SettingsStorage(
                load: { .default },
                save: { snapshot in saved.value = snapshot }
            )
        }
        
        await store.send(\.binding.language, .english) {
            $0.language = .english
        }
        
        #expect(saved.value?.language == .english)
    }
    
    @Test func bindingUpdatesDefaultCurrency() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
        
        await store.send(\.binding.defaultCurrency, .jpy) {
            $0.defaultCurrency = .jpy
        }
    }
    
    @Test func taskLoadsFromInjectedStorage() async {
        let stored = SettingsSnapshot(
            language: .english,
            defaultCurrency: .jpy,
            monthlyProfitGoalTwd: 50_000,
            useAiSummary: true,
            aiSummaryModel: "gpt-oss:120b",
            isBiometricUnlockEnabled: true
        )
        
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStorage.self] = SettingsStorage(
                load: { stored },
                save: { _ in }
            )
        }
        // `.task` 會從 `CurrencyMetadataRepository` 並行載入幣別清單並 dispatch
        // 等待 `availableCurrenciesLoaded`，只驗證 storage 套用流程。
        // 故保留關閉窮舉以隔離這條並行效果
        store.exhaustivity = .off
        
        await store.send(.task) {
            $0.language = .english
            $0.defaultCurrency = .jpy
            $0.monthlyProfitGoalTwd = 50_000
            $0.useAiSummary = true
            $0.aiSummaryModel = "gpt-oss:120b"
            $0.appLock.isBiometricUnlockEnabled = true
        }
    }
    
    @Test func bindingTogglesUseAiSummaryAndSaves() async {
        let saved = SnapshotBox()
        
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStorage.self] = SettingsStorage(
                load: { .default },
                save: { snapshot in saved.value = snapshot }
            )
        }
        
        await store.send(\.binding.useAiSummary, true) {
            $0.useAiSummary = true
        }
        
        #expect(saved.value?.useAiSummary == true)
        #expect(saved.value?.aiSummaryModel == "gemma4:31b-cloud")
    }
    
    @Test func bindingUpdatesAiSummaryModelAndSaves() async {
        let saved = SnapshotBox()
        
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStorage.self] = SettingsStorage(
                load: { .default },
                save: { snapshot in saved.value = snapshot }
            )
        }
        
        await store.send(\.binding.aiSummaryModel, "deepseek-v3.1:671b") {
            $0.aiSummaryModel = "deepseek-v3.1:671b"
        }
        
        #expect(saved.value?.aiSummaryModel == "deepseek-v3.1:671b")
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
        
        await store.send(\.binding.useAiSummary, true) {
            $0.useAiSummary = true
        }
        
        #expect(saved.value?.useAiSummary == true)
        #expect(saved.value?.defaultCurrency == .twd)
    }
    
    @Test func enablingAppLockPersistsOnlyAfterAuthenticationSucceeds() async {
        let saved = SnapshotBox()
        
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStorage.self] = SettingsStorage(
                load: { .default },
                save: { snapshot in saved.value = snapshot }
            )
            $0[BiometricAuthClient.self] = BiometricAuthClient(
                isAvailable: { true },
                authenticate: { _ in .success },
                biometryType: { .faceID }
            )
        }
        
        // 驗證成功後才寫入持久層，避免依賴 effect 的執行時序
        await store.send(.appLock(.enableToggled(true)))
        await store.receive(\.appLock.enableAuthenticationFinished) {
            $0.appLock.isBiometricUnlockEnabled = true
        }
        
        #expect(saved.value?.isBiometricUnlockEnabled == true)
    }
    
    @Test func disablingAppLockPersistsImmediatelyWithoutAuthentication() async {
        let saved = SnapshotBox()
        var state = SettingsFeature.State()
        state.appLock.isBiometricUnlockEnabled = true
        
        let store = TestStore(initialState: state) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStorage.self] = SettingsStorage(
                load: { .default },
                save: { snapshot in saved.value = snapshot }
            )
        }
        
        await store.send(.appLock(.enableToggled(false))) {
            $0.appLock.isBiometricUnlockEnabled = false
        }
        
        #expect(saved.value?.isBiometricUnlockEnabled == false)
    }
    
    @Test func failedAppLockAuthenticationDoesNotPersist() async {
        let saved = SnapshotBox()
        
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStorage.self] = SettingsStorage(
                load: { .default },
                save: { snapshot in saved.value = snapshot }
            )
            $0[BiometricAuthClient.self] = BiometricAuthClient(
                isAvailable: { true },
                authenticate: { _ in .failure },
                biometryType: { .faceID }
            )
        }
        
        await store.send(.appLock(.enableToggled(true)))
        await store.receive(\.appLock.enableAuthenticationFinished) {
            $0.appLock.enableFailureAlert = AlertState {
                TextState("無法啟用 App 鎖定")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("關閉")
                }
            } message: {
                TextState("身份驗證失敗或已取消，App 鎖定未啟用。")
            }
        }
        
        #expect(saved.value == nil)
        #expect(store.state.appLock.isBiometricUnlockEnabled == false)
    }
}

/// 簡易 Sendable 容器
private final class SnapshotBox: @unchecked Sendable {
    
    // MARK: - Data Properties
    
    /// 由 closure 寫入並由測試讀取的快照
    var value: SettingsSnapshot?
}
