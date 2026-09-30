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

/// 以 TestStore 驗證設定狀態、持久化與系統服務互動
@MainActor
struct SettingsFeatureTests {

    // MARK: - Tests

    /// 初始設定狀態採用產品指定的語言、幣別與功能預設值
    @Test
    func init_產品預設設定_提供預設值() {
        // Given

        // When
        let state = SettingsFeature.State()

        // Then
        #expect(state.language == .traditionalChinese)
        #expect(state.defaultCurrency == .twd)
        #expect(state.isAISummaryEnabled == false)
        #expect(state.appVersion == "—")
        #expect(state.monthlyProfitGoalTWD == 80_000)
        #expect(state.aiSummaryModel == "gemma4:31b-cloud")
        #expect(state.appLock.isBiometricUnlockEnabled == false)
    }

    /// 每個持久化 binding 更新狀態並寫入對應的完整設定快照
    ///
    /// - Parameter binding: 要驗證的持久化欄位
    @Test(arguments: PersistedBinding.allCases)
    func binding_持久化欄位改變_同步儲存設定快照(binding: PersistedBinding) async {
        // Given
        let saved = LockIsolated<SettingsSnapshot?>(nil)
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.settingsService.save = {
                saved.setValue($0)
            }
        }

        // When
        await store.send(binding.action) {
            binding.apply(to: &$0)
        }

        // Then
        #expect(saved.value == binding.expectedSnapshot)
    }

    /// 連續修改目標金額時，每次 reducer 更新都依序保存
    @Test
    func binding_連續修改月度目標_依輸入順序儲存() async {
        // Given
        let saved = LockIsolated<[SettingsSnapshot]>([])
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.settingsService.save = { snapshot in
                saved.withValue {
                    $0.append(snapshot)
                }
            }
        }
        await store.send(\.binding.monthlyProfitGoalTWD, 1) {
            $0.monthlyProfitGoalTWD = 1
        }
        await store.send(\.binding.monthlyProfitGoalTWD, 12) {
            $0.monthlyProfitGoalTWD = 12
        }

        // When
        await store.send(\.binding.monthlyProfitGoalTWD, 120) {
            $0.monthlyProfitGoalTWD = 120
        }

        // Then
        #expect(saved.value.map(\.monthlyProfitGoalTWD) == [1, 12, 120])
    }

    /// 月度目標欄位的鍵盤焦點改變時只更新焦點狀態，不寫入設定
    ///
    /// - Note: `testValue` 的 `save` 為 `unimplemented`，非預期儲存會使測試失敗
    @Test
    func binding_鍵盤焦點改變_不儲存設定快照() async {
        // Given
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }

        // When
        await store.send(\.binding.isGoalFieldFocused, true) {
            $0.isGoalFieldFocused = true
        }

        // Then
        #expect(store.state.isGoalFieldFocused)
    }

    /// 選擇日圓時持久化事件解析後的日圓幣別
    ///
    /// - Throws: 設定快照未被保存時拋出錯誤
    @Test
    func defaultCurrencySelected_選擇日圓_儲存所選幣別() async throws {
        // Given
        let saved = LockIsolated<SettingsSnapshot?>(nil)
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.settingsService.save = {
                saved.setValue($0)
            }
        }

        // When
        await store.send(.view(.defaultCurrencySelected("JPY"))) {
            $0.defaultCurrency = .jpy
        }

        // Then
        let snapshot = try #require(saved.value)
        #expect(snapshot.defaultCurrency == .jpy)
    }

    /// 選擇摘要模型時將模型識別值保存至設定快照
    ///
    /// - Throws: 設定快照未被保存時拋出錯誤
    @Test
    func aiSummaryModelSelected_選擇摘要模型_儲存選取值() async throws {
        // Given
        let saved = LockIsolated<SettingsSnapshot?>(nil)
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.settingsService.save = {
                saved.setValue($0)
            }
        }

        // When
        await store.send(.view(.aiSummaryModelSelected("deepseek-v3.1:671b"))) {
            $0.aiSummaryModel = "deepseek-v3.1:671b"
        }

        // Then
        let snapshot = try #require(saved.value)
        #expect(snapshot.aiSummaryModel == "deepseek-v3.1:671b")
    }

    /// 幣別服務成功回傳時，載入清單並保留目前預設幣別
    @Test
    func task_載入可用幣別_保留預設幣別() async {
        // Given
        var state = SettingsFeature.State()
        state.defaultCurrency = .jpy
        state.availableCurrencies = [.twd]
        let store = TestStore(initialState: state) {
            SettingsFeature()
        } withDependencies: {
            $0.currencyMetadataService.fetchCodes = {
                [.usd, CurrencyCode(rawValue: "EUR")]
            }
        }

        // When
        await store.send(.view(.task))

        // Then
        await store.receive(\.currencyCodesResponse.success) {
            $0.availableCurrencies = [CurrencyCode(rawValue: "EUR"), .jpy, .usd]
        }
    }

    /// 畫面出現時讀取幣別主檔失敗，可選幣別維持原本的清單，不清空也不改寫
    @Test
    func task_載入幣別失敗_保留目前清單() async {
        // Given
        var state = SettingsFeature.State()
        state.availableCurrencies = [.twd, .jpy]
        let failingFetchCodes: CurrencyMetadataService.FetchCodes = {
            throw .persistence(
                .storage(
                    .fetchFailed(
                        underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
                    )
                )
            )
        }
        let store = TestStore(initialState: state) {
            SettingsFeature()
        } withDependencies: {
            $0.currencyMetadataService.fetchCodes = failingFetchCodes
        }

        // When
        await store.send(.view(.task))

        // Then
        await store.receive(\.currencyCodesResponse.failure)
        #expect(store.state.availableCurrencies == [.twd, .jpy])
    }

    /// 畫面出現時幣別主檔回傳空清單，不以空清單覆蓋，可選幣別維持原本的清單
    @Test
    func task_載入空幣別清單_保留目前清單() async {
        // Given
        var state = SettingsFeature.State()
        state.availableCurrencies = [.twd, .jpy]
        let store = TestStore(initialState: state) {
            SettingsFeature()
        } withDependencies: {
            $0.currencyMetadataService.fetchCodes = {
                []
            }
        }

        // When
        await store.send(.view(.task))

        // Then
        await store.receive(\.currencyCodesResponse.success)
        #expect(store.state.availableCurrencies == [.twd, .jpy])
    }

    /// 本機驗證成功後才儲存 App 鎖定設定
    @Test
    func appLock_啟用生物辨識且驗證成功_儲存設定() async {
        // Given
        let saved = LockIsolated<[SettingsSnapshot]>([])
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.settingsService.save = { snapshot in
                saved.withValue {
                    $0.append(snapshot)
                }
            }
            $0.biometricAuthService.isAvailable = {
                true
            }
            $0.biometricAuthService.authenticate = { _ in
                .success
            }
        }

        // When
        await store.send(.appLock(.enableToggled(true)))

        // Then
        await store.receive(\.appLock.enableAuthenticationFinished) {
            $0.appLock.isBiometricUnlockEnabled = true
        }
        #expect(saved.value.map(\.isBiometricUnlockEnabled) == [true])
    }

    /// 關閉 App 鎖定時立即儲存設定
    @Test
    func appLock_停用生物辨識_立即儲存設定() async {
        // Given
        let saved = LockIsolated<[SettingsSnapshot]>([])
        var state = SettingsFeature.State()
        state.appLock.isBiometricUnlockEnabled = true
        let store = TestStore(initialState: state) {
            SettingsFeature()
        } withDependencies: {
            $0.settingsService.save = { snapshot in
                saved.withValue {
                    $0.append(snapshot)
                }
            }
        }

        // When
        await store.send(.appLock(.enableToggled(false))) {
            $0.appLock.isBiometricUnlockEnabled = false
        }

        // Then
        #expect(saved.value.map(\.isBiometricUnlockEnabled) == [false])
    }

    /// 本機驗證失敗時不儲存 App 鎖定設定
    ///
    /// - Note: `testValue` 的 `save` 為 `unimplemented`，非預期儲存會使測試失敗
    @Test
    func appLock_啟用生物辨識但驗證失敗_不儲存設定() async {
        // Given
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.biometricAuthService.isAvailable = {
                true
            }
            $0.biometricAuthService.authenticate = { _ in
                .failure
            }
        }

        // When
        await store.send(.appLock(.enableToggled(true)))

        // Then
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
    }
}

// MARK: - Nested Types

extension SettingsFeatureTests {

    /// 會由 binding 直接寫入的設定欄位
    enum PersistedBinding: CaseIterable, Sendable {

        /// 語言改為 `.english`
        case language

        /// 開啟 AI 總結
        case isAISummaryEnabled

        /// 月度目標改為 120,000
        case monthlyProfitGoalTWD

        /// 此案例送入 reducer 的 binding 動作
        var action: SettingsFeature.Action {
            switch self {
            case .language:
                .binding(.set(\.language, .english))

            case .isAISummaryEnabled:
                .binding(.set(\.isAISummaryEnabled, true))

            case .monthlyProfitGoalTWD:
                .binding(.set(\.monthlyProfitGoalTWD, 120_000))
            }
        }

        /// reducer 執行後應保存的完整快照
        var expectedSnapshot: SettingsSnapshot {
            switch self {
            case .language:
                SettingsSnapshot(
                    language: .english,
                    defaultCurrency: .twd,
                    monthlyProfitGoalTWD: 80_000,
                    isAISummaryEnabled: false,
                    aiSummaryModel: "gemma4:31b-cloud",
                    isBiometricUnlockEnabled: false
                )

            case .isAISummaryEnabled:
                SettingsSnapshot(
                    language: .traditionalChinese,
                    defaultCurrency: .twd,
                    monthlyProfitGoalTWD: 80_000,
                    isAISummaryEnabled: true,
                    aiSummaryModel: "gemma4:31b-cloud",
                    isBiometricUnlockEnabled: false
                )

            case .monthlyProfitGoalTWD:
                SettingsSnapshot(
                    language: .traditionalChinese,
                    defaultCurrency: .twd,
                    monthlyProfitGoalTWD: 120_000,
                    isAISummaryEnabled: false,
                    aiSummaryModel: "gemma4:31b-cloud",
                    isBiometricUnlockEnabled: false
                )
            }
        }

        /// 套用此案例送出後預期的狀態變化
        ///
        /// - Parameter state: 要更新的設定狀態
        func apply(to state: inout SettingsFeature.State) {
            switch self {
            case .language:
                state.language = .english

            case .isAISummaryEnabled:
                state.isAISummaryEnabled = true

            case .monthlyProfitGoalTWD:
                state.monthlyProfitGoalTWD = 120_000
            }
        }
    }
}
