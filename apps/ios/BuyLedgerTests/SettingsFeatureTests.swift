//
//  SettingsFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/2.
//

import ComposableArchitecture
import Foundation
import SwiftUI
import Testing

@testable import BuyLedger

/// 驗證設定功能
@MainActor
struct SettingsFeatureTests {

    // MARK: - Tests

    /// 驗證設定狀態使用產品預設值
    @Test func defaultStateMatchesProductDefaults() {
        // Given
        let state = SettingsFeature.State()

        // When
        let language = state.language
        let defaultCurrency = state.defaultCurrency
        let isAISummaryEnabled = state.isAISummaryEnabled
        let appVersion = state.appVersion

        // Then
        #expect(language == .traditionalChinese)
        #expect(defaultCurrency == .twd)
        #expect(isAISummaryEnabled == false)
        #expect(appVersion == "—")
        #expect(state.aiSummaryModel == "gemma4:31b-cloud")
        #expect(state.appLock.isBiometricUnlockEnabled == false)
    }

    /// 驗證會持久化的 binding 欄位都同步寫入快照
    @Test(arguments: PersistedBinding.allCases)
    func persistedBindingSavesSnapshot(binding: PersistedBinding) async throws {
        // Given
        let saved = LockIsolated<SettingsSnapshot?>(nil)
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStore.self] = SettingsStore(
                load: { .default },
                save: { saved.setValue($0) }
            )
        }

        // When
        switch binding {
        case .language:
            await store.send(\.binding.language, .english) {
                $0.language = .english
            }

        case .isAISummaryEnabled:
            await store.send(\.binding.isAISummaryEnabled, true) {
                $0.isAISummaryEnabled = true
            }

        case .monthlyProfitGoalTWD:
            await store.send(\.binding.monthlyProfitGoalTWD, 120_000) {
                $0.monthlyProfitGoalTWD = 120_000
            }
        }

        // Then
        let snapshot = try #require(saved.value)
        switch binding {
        case .language:
            #expect(snapshot.language == .english)

        case .isAISummaryEnabled:
            #expect(snapshot.isAISummaryEnabled)

        case .monthlyProfitGoalTWD:
            #expect(snapshot.monthlyProfitGoalTWD == 120_000)
        }
    }

    /// 驗證月度目標輸入的連續 binding 會依編輯順序存檔
    @Test func monthlyGoalBindingsPreserveSaveOrder() async {
        // Given
        let saved = LockIsolated<[SettingsSnapshot]>([])
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStore.self] = SettingsStore(
                load: { .default },
                save: { snapshot in
                    saved.withValue { $0.append(snapshot) }
                }
            )
        }

        // When
        await store.send(\.binding.monthlyProfitGoalTWD, 1) {
            $0.monthlyProfitGoalTWD = 1
        }
        await store.send(\.binding.monthlyProfitGoalTWD, 12) {
            $0.monthlyProfitGoalTWD = 12
        }
        await store.send(\.binding.monthlyProfitGoalTWD, 120) {
            $0.monthlyProfitGoalTWD = 120
        }

        // Then
        #expect(saved.value.map(\.monthlyProfitGoalTWD) == [1, 12, 120])
        #expect(saved.value.last?.monthlyProfitGoalTWD == 120)
    }

    /// 驗證鍵盤焦點 binding 不會觸發設定存檔
    @Test func focusBindingDoesNotSaveSnapshot() async {
        // Given
        let saved = LockIsolated<SettingsSnapshot?>(nil)
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStore.self] = SettingsStore(
                load: { .default },
                save: { saved.setValue($0) }
            )
        }

        // When
        await store.send(\.binding.isGoalFieldFocused, true) {
            $0.isGoalFieldFocused = true
        }

        // Then
        #expect(saved.value == nil)
    }

    /// 驗證畫面事件會儲存預設幣別
    @Test func defaultCurrencySelectionSavesSnapshot() async throws {
        // Given
        let saved = LockIsolated<SettingsSnapshot?>(nil)
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStore.self] = SettingsStore(
                load: { .default },
                save: { saved.setValue($0) }
            )
        }

        // When
        await store.send(.view(.defaultCurrencySelected("JPY"))) {
            $0.defaultCurrency = .jpy
        }

        // Then
        let snapshot = try #require(saved.value)
        #expect(snapshot.defaultCurrency == .jpy)
    }

    /// 驗證畫面事件會儲存 AI 模型
    @Test func aiSummaryModelSelectionSavesSnapshot() async throws {
        // Given
        let saved = LockIsolated<SettingsSnapshot?>(nil)
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStore.self] = SettingsStore(
                load: { .default },
                save: { saved.setValue($0) }
            )
        }

        // When
        await store.send(.view(.aiSummaryModelSelected("deepseek-v3.1:671b"))) {
            $0.aiSummaryModel = "deepseek-v3.1:671b"
        }

        // Then
        let snapshot = try #require(saved.value)
        #expect(snapshot.aiSummaryModel == "deepseek-v3.1:671b")
    }

    /// 驗證成功載入的幣別清單會保留目前預設幣別
    @Test func currencyLoadMergesDefaultCurrency() async {
        // Given
        var state = SettingsFeature.State()
        state.defaultCurrency = .jpy
        state.availableCurrencies = [.twd, .jpy]
        let store = TestStore(initialState: state) {
            SettingsFeature()
        } withDependencies: {
            $0[CurrencyMetadataRepository.self] = CurrencyMetadataRepository(
                fetchCodes: { [.usd, CurrencyCode(rawValue: "EUR")] },
                refreshIfStale: { _ in false },
                forceRefresh: {}
            )
        }

        // When
        await store.send(.view(.task))
        await store.receive(\.currencyCodesResponse.success) {
            $0.availableCurrencies = [CurrencyCode(rawValue: "EUR"), .jpy, .usd]
        }

        // Then
        #expect(
            store.state.availableCurrencies
                == [CurrencyCode(rawValue: "EUR"), .jpy, .usd]
        )
    }

    /// 驗證幣別清單載入失敗時保留目前清單
    @Test func failedCurrencyLoadKeepsCurrentCurrencies() async {
        // Given
        var state = SettingsFeature.State()
        state.availableCurrencies = [.twd, .jpy]
        let originalCurrencies = state.availableCurrencies
        let store = TestStore(initialState: state) {
            SettingsFeature()
        } withDependencies: {
            $0[CurrencyMetadataRepository.self] = CurrencyMetadataRepository(
                fetchCodes: {
                    () async throws(CurrencyMetadataRepositoryError) -> [CurrencyCode] in
                    throw CurrencyMetadataRepositoryError.persistence(
                        .storage(
                            .fetchFailed(
                                underlying: TestDependencies.makeUnderlyingError(
                                    message: "suppressed"
                                )
                            )
                        )
                    )
                },
                refreshIfStale: { _ in false },
                forceRefresh: {}
            )
        }

        // When
        await store.send(.view(.task))
        await store.receive(\.currencyCodesResponse.failure)

        // Then
        #expect(store.state.availableCurrencies == originalCurrencies)
    }

    /// 驗證幣別清單為空時保留目前清單
    @Test func emptyCurrencyLoadKeepsCurrentCurrencies() async {
        // Given
        var state = SettingsFeature.State()
        state.availableCurrencies = [.twd, .jpy]
        let originalCurrencies = state.availableCurrencies
        let store = TestStore(initialState: state) {
            SettingsFeature()
        } withDependencies: {
            $0[CurrencyMetadataRepository.self] = CurrencyMetadataRepository(
                fetchCodes: { [] },
                refreshIfStale: { _ in false },
                forceRefresh: {}
            )
        }

        // When
        await store.send(.view(.task))
        await store.receive(\.currencyCodesResponse.success)

        // Then
        #expect(store.state.availableCurrencies == originalCurrencies)
    }

    /// 驗證 App 鎖定只在驗證成功後寫入
    @Test func enablingAppLockPersistsOnlyAfterAuthenticationSucceeds() async throws {
        // Given
        let saved = LockIsolated<SettingsSnapshot?>(nil)
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStore.self] = SettingsStore(
                load: { .default },
                save: { saved.setValue($0) }
            )
            $0[BiometricAuthClient.self] = BiometricAuthClient(
                isAvailable: { true },
                authenticate: { _ in .success },
                biometryType: { .faceID }
            )
        }

        // When
        await store.send(.appLock(.enableToggled(true)))
        await store.receive(\.appLock.enableAuthenticationFinished) {
            $0.appLock.isBiometricUnlockEnabled = true
        }

        // Then
        let snapshot = try #require(saved.value)
        #expect(snapshot.isBiometricUnlockEnabled)
    }

    /// 驗證關閉 App 鎖定會立即寫入
    @Test func disablingAppLockPersistsImmediately() async throws {
        // Given
        let saved = LockIsolated<SettingsSnapshot?>(nil)
        var state = SettingsFeature.State()
        state.appLock.isBiometricUnlockEnabled = true
        let store = TestStore(initialState: state) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStore.self] = SettingsStore(
                load: { .default },
                save: { saved.setValue($0) }
            )
        }

        // When
        await store.send(.appLock(.enableToggled(false))) {
            $0.appLock.isBiometricUnlockEnabled = false
        }

        // Then
        let snapshot = try #require(saved.value)
        #expect(snapshot.isBiometricUnlockEnabled == false)
    }

    /// 驗證 App 鎖定驗證失敗時不會寫入
    @Test func failedAppLockAuthenticationDoesNotPersist() async {
        // Given
        let saved = LockIsolated<SettingsSnapshot?>(nil)
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0[SettingsStore.self] = SettingsStore(
                load: { .default },
                save: { saved.setValue($0) }
            )
            $0[BiometricAuthClient.self] = BiometricAuthClient(
                isAvailable: { true },
                authenticate: { _ in .failure },
                biometryType: { .faceID }
            )
        }

        // When
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

        // Then
        #expect(saved.value == nil)
        #expect(store.state.appLock.isBiometricUnlockEnabled == false)
    }
}

// MARK: - Nested Types

extension SettingsFeatureTests {

    /// 會由 binding 直接寫入的設定欄位
    enum PersistedBinding: CaseIterable {

        /// App 語言
        case language

        /// AI 總結開關
        case isAISummaryEnabled

        /// 月度目標
        case monthlyProfitGoalTWD
    }
}
