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

/// `SettingsFeature` 的單元測試，以 TestStore 逐步驗證設定狀態、保存與系統服務互動
struct SettingsFeatureTests {

    /// 驗證未帶參數建立的設定狀態採用產品指定的語言、幣別與功能預設值，版本號為占位字元
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
        #expect(state.isBiometricUnlockEnabled == false)
    }

    /// 驗證每個持久化欄位的 binding 改變時，狀態更新，並同步保存完整的設定快照
    ///
    /// - Parameter binding: 要驗證的持久化欄位
    @Test(arguments: PersistedBinding.allCases)
    @MainActor
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
        await store.receive(\.delegate.preferencesChanged, binding.expectedSnapshot)
        #expect(saved.value == binding.expectedSnapshot)
    }

    /// 驗證連續修改月度目標 (依序為 1、12、120) 時，每次改動都同步保存，且保存順序與輸入順序相同
    ///
    /// - Note: 以同步的連續輸入驗證保存順序，延後到非同步效果才寫入時也會失敗
    @Test
    @MainActor
    func binding_連續修改月度目標_依輸入順序儲存() {
        // Given
        let initialSnapshot = SettingsSnapshot(
            language: .traditionalChinese,
            defaultCurrency: .twd,
            monthlyProfitGoalTWD: 80_000,
            isAISummaryEnabled: false,
            aiSummaryModel: "gemma4:31b-cloud",
            isBiometricUnlockEnabled: false
        )
        var firstSnapshot = initialSnapshot
        firstSnapshot.monthlyProfitGoalTWD = 1
        var secondSnapshot = initialSnapshot
        secondSnapshot.monthlyProfitGoalTWD = 12
        var thirdSnapshot = initialSnapshot
        thirdSnapshot.monthlyProfitGoalTWD = 120
        let saved = LockIsolated<[SettingsSnapshot]>([])
        let store = Store(initialState: SettingsFeature.State(snapshot: initialSnapshot)) {
            SettingsFeature()
        } withDependencies: {
            $0.settingsService.save = { snapshot in
                saved.withValue {
                    $0.append(snapshot)
                }
            }
        }

        // When
        store.send(.binding(.set(\.monthlyProfitGoalTWD, 1)))
        store.send(.binding(.set(\.monthlyProfitGoalTWD, 12)))
        store.send(.binding(.set(\.monthlyProfitGoalTWD, 120)))

        // Then
        #expect(saved.value == [firstSnapshot, secondSnapshot, thirdSnapshot])
        #expect(store.monthlyProfitGoalTWD == 120)
    }

    /// 驗證月度目標欄位的鍵盤焦點改變時，只更新焦點狀態，不寫入設定
    ///
    /// - Note: `testValue` 的 `save` 為 `unimplemented`，非預期儲存會使測試失敗
    @Test
    @MainActor
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

    /// 驗證選擇日圓時，預設幣別改為日圓，並保存幣別為日圓的設定快照
    ///
    /// - Throws: 設定快照未被保存時丟出錯誤
    @Test
    @MainActor
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
        await store.receive(\.delegate.preferencesChanged)
        let snapshot = try #require(saved.value)
        #expect(snapshot.defaultCurrency == .jpy)
    }

    /// 驗證選擇摘要模型時，模型識別值更新為所選值，並寫入設定快照
    ///
    /// - Throws: 設定快照未被保存時丟出錯誤
    @Test
    @MainActor
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
        await store.receive(\.delegate.preferencesChanged)
        let snapshot = try #require(saved.value)
        #expect(snapshot.aiSummaryModel == "deepseek-v3.1:671b")
    }

    /// 驗證幣別服務成功回傳時，可選幣別換成排序後的新清單，清單並納入目前的預設幣別，預設幣別不變
    @Test
    @MainActor
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

    /// 驗證讀取幣別主檔失敗時，可選幣別維持原本的清單，不清空也不改寫
    @Test
    @MainActor
    func task_載入幣別失敗_保留目前清單() async {
        // Given
        var state = SettingsFeature.State()
        state.availableCurrencies = [.twd, .jpy]
        let failingFetchCodes: CurrencyMetadataService.FetchCodes = { () throws(CurrencyMetadataServiceError) in
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

    /// 驗證幣別主檔回傳空清單時，不以空清單覆蓋既有清單，可選幣別維持原本的內容
    @Test
    @MainActor
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
