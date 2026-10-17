//
//  SettingsFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// 設定頁的語言、預設幣別、月度目標、AI 總結與 App 鎖定：使用者一改就存回，畫面出現時載入可選幣別
@Reducer
struct SettingsFeature {

    // MARK: - State

    /// 設定狀態
    @ObservableState
    struct State: Equatable, Sendable {

        /// App 介面語言偏好
        var language: AppLanguage = .traditionalChinese

        /// 預設訂單幣別
        var defaultCurrency: CurrencyCode = .twd

        /// 可供選擇的幣別清單；由 `CurrencyMetadataService` 提供
        var availableCurrencies: [CurrencyCode] = CurrencyCode.defaults

        /// 每月淨獲利目標 (TWD)；0 代表未設定
        var monthlyProfitGoalTWD: Decimal = 80_000

        /// 是否啟用 AI 商品明細總結
        var isAISummaryEnabled: Bool = false

        /// 是否已通過驗證並啟用 App 鎖定
        var isBiometricUnlockEnabled: Bool = false

        /// 啟用驗證失敗或裝置不支援時的呈現
        @Presents var destination: Destination.State?

        /// 月度目標金額欄位是否取得鍵盤焦點
        var isGoalFieldFocused: Bool = false

        /// AI 總結使用的 Ollama 模型名稱
        var aiSummaryModel: String = AISummaryModelCatalog.defaultModel

        /// App 版本與建置號顯示文字
        let appVersion: String

        /// 建構時帶入的裝置辨識類型，設定頁首幀即可顯示對應文案
        let biometryType: BiometricAuthService.BiometryKind

        /// 目前可持久化並回報給根功能的完整偏好
        var snapshot: SettingsSnapshot {
            SettingsSnapshot(
                language: language,
                defaultCurrency: defaultCurrency,
                monthlyProfitGoalTWD: monthlyProfitGoalTWD,
                isAISummaryEnabled: isAISummaryEnabled,
                aiSummaryModel: aiSummaryModel,
                isBiometricUnlockEnabled: isBiometricUnlockEnabled
            )
        }

        /// 以持久化快照、版本文字與辨識類型建立設定狀態
        ///
        /// - Parameters:
        ///   - snapshot: 已載入的設定快照
        ///   - appVersion: App 版本與建置號顯示文字
        ///   - biometryType: 根功能帶入的裝置辨識類型
        init(
            snapshot: SettingsSnapshot = .default,
            appVersion: String = "—",
            biometryType: BiometricAuthService.BiometryKind = .unavailable
        ) {
            language = snapshot.language
            defaultCurrency = snapshot.defaultCurrency
            monthlyProfitGoalTWD = snapshot.monthlyProfitGoalTWD
            isAISummaryEnabled = snapshot.isAISummaryEnabled
            aiSummaryModel = snapshot.aiSummaryModel
            self.appVersion = appVersion
            isBiometricUnlockEnabled = snapshot.isBiometricUnlockEnabled
            self.biometryType = biometryType
        }
    }

    // MARK: - Action

    /// 設定頁事件
    enum Action: BindableAction {

        /// SwiftUI 雙向繫結
        ///
        /// - Parameter action: 要寫入設定狀態的繫結變更
        case binding(BindingAction<State>)

        /// 使用者可直接操作的設定頁事件
        ///
        /// - Parameter action: 畫面出現、選定預設幣別、選定 AI 總結模型或切換 App 鎖定
        case view(View)

        /// 設定寫入完成後交給根功能的偏好
        ///
        /// - Parameter action: 已保存的完整偏好
        case delegate(Delegate)

        /// 啟用 App 鎖定失敗說明的呈現事件
        ///
        /// - Parameter action: 呈現的 alert 事件
        case destination(PresentationAction<Destination.Action>)

        /// 啟用 App 鎖定前的驗證結果
        ///
        /// - Parameter result: 成功、失敗或取消的驗證結果
        case appLockAuthenticationResponse(BiometricAuthService.AuthenticationResult)

        /// 幣別主檔載入結果
        ///
        /// - Parameter result: 成功帶回幣別清單，失敗帶回錯誤
        case currencyCodesResponse(Result<[CurrencyCode], CurrencyMetadataServiceError>)

        /// 設定頁畫面事件
        @CasePathable
        enum View {

            /// 畫面出現時載入幣別主檔
            case task

            /// 使用者選定預設幣別
            ///
            /// - Parameter code: 使用者選定的 ISO code 字串
            case defaultCurrencySelected(String)

            /// 使用者選定 (或自訂) AI 總結模型
            ///
            /// - Parameter model: 使用者選定或輸入的模型名稱
            case aiSummaryModelSelected(String)

            /// 使用者要求啟用或關閉 App 鎖定
            ///
            /// - Parameter isEnabled: 使用者希望設定的啟用值
            case appLockToggled(Bool)
        }

        /// 設定頁交給根功能的已保存資料
        @CasePathable
        enum Delegate: Equatable {

            /// 完整偏好已寫入持久層
            ///
            /// - Parameter snapshot: 此次實際保存的快照
            case preferencesChanged(SettingsSnapshot)
        }
    }

    // MARK: - Dependencies

    /// 把設定快照寫回儲存的 Service
    @Dependency(\.settingsService) private var settingsService

    /// 幣別主檔資料來源；用於畫面出現時載入最新清單
    @Dependency(\.currencyMetadataService) private var currencyMetadataService

    /// 啟用 App 鎖定前檢查裝置支援與要求本機驗證的 Service
    @Dependency(\.biometricAuthService) private var biometricAuthService

    // MARK: - Body

    /// 只負責組合 reducer，設定頁自己的邏輯在 `core(state:action:)`
    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce(core)
            .ifLet(\.$destination, action: \.destination)
    }
}

// MARK: - Private Method

private extension SettingsFeature {

    /// 依收到的事件更新設定狀態，並回傳要執行的 Effect
    ///
    /// - Parameters:
    ///   - state: 目前的設定狀態，直接就地修改
    ///   - action: 這次收到的設定頁事件
    /// - Returns: 接下來要執行的 Effect，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding(\.isGoalFieldFocused):
            // 焦點屬短暫 UI 狀態，變動不觸發設定存檔
            return .none

        case .binding:
            return persist(state)

        case .view(.task):
            return loadCurrencyCodes()

        case .view(.defaultCurrencySelected(let code)):
            state.defaultCurrency = CurrencyCode(rawValue: code)
            return persist(state)

        case .view(.aiSummaryModelSelected(let model)):
            state.aiSummaryModel = model
            return persist(state)

        case .view(.appLockToggled(false)):
            state.isBiometricUnlockEnabled = false
            return persist(state)

        case .view(.appLockToggled(true)):
            return enableAppLock(state: &state)

        case .delegate, .destination:
            return .none

        case .appLockAuthenticationResponse(.success):
            state.isBiometricUnlockEnabled = true
            return persist(state)

        case .appLockAuthenticationResponse(.failure), .appLockAuthenticationResponse(.cancelled):
            state.destination = .authenticationFailedAlert
            return .none

        case .currencyCodesResponse(.success(let codes)):
            guard !codes.isEmpty else {
                return .none
            }
            var merged = Set(codes)
            merged.insert(state.defaultCurrency)
            state.availableCurrencies = merged.sorted { lhs, rhs in
                lhs.rawValue.localizedStandardCompare(rhs.rawValue) == .orderedAscending
            }
            return .none

        case .currencyCodesResponse(.failure):
            return .none
        }
    }

    /// 保存目前偏好並回報同一份快照
    ///
    /// - Parameter state: 目前設定狀態
    /// - Returns: 送出已保存偏好的委派
    func persist(_ state: State) -> Effect<Action> {
        let snapshot = state.snapshot
        settingsService.save(snapshot)
        return .send(.delegate(.preferencesChanged(snapshot)))
    }

    /// 載入幣別主檔並把成功或失敗合併成單一回應
    ///
    /// - Returns: 載入幣別主檔的 `Effect`
    func loadCurrencyCodes() -> Effect<Action> {
        let currencyMetadataService = currencyMetadataService
        return .run { send in
            do throws(CurrencyMetadataServiceError) {
                let codes = try await currencyMetadataService.fetchCodes()
                await send(.currencyCodesResponse(.success(codes)))
            } catch {
                await send(.currencyCodesResponse(.failure(error)))
            }
        }
    }

    /// 啟用 App 鎖定前先確認裝置支援，支援時才要求本機驗證
    ///
    /// - Parameter state: 目前設定狀態，裝置不支援時就地改為呈現不支援說明
    /// - Returns: 要求本機驗證並以 `appLockAuthenticationResponse` 送回結果的 Effect，裝置不支援時為 `.none`
    func enableAppLock(state: inout State) -> Effect<Action> {
        if !biometricAuthService.isAvailable() {
            state.destination = .unsupportedDeviceAlert
            return .none
        }
        let biometricAuthService = biometricAuthService
        return .run { send in
            let result = await biometricAuthService.authenticate(String(localized: "settings.preference.label.authenticateUnlockApp"))
            await send(.appLockAuthenticationResponse(result))
        }
    }
}
