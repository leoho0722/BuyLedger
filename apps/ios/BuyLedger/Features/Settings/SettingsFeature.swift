//
//  SettingsFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// 決定設定頁的語言、預設幣別、月度目標、AI 總結與 App 鎖定設定的讀取與儲存
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

        /// 可供選擇的幣別清單；由 CurrencyMetadataRepository 提供
        var availableCurrencies: [CurrencyCode] = CurrencyCode.defaults

        /// 每月淨獲利目標 (TWD)；0 代表未設定
        var monthlyProfitGoalTWD: Decimal = 80_000

        /// 是否啟用 AI 商品明細總結
        var isAISummaryEnabled: Bool = false

        /// App 鎖定 (離開 App 即上鎖並要求驗證) 狀態
        var appLock = AppLockFeature.State()

        /// 月度目標金額欄位是否取得鍵盤焦點
        var isGoalFieldFocused: Bool = false

        /// AI 總結使用的 Ollama 模型名稱
        var aiSummaryModel: String = AISummaryModelCatalog.defaultModel

        /// App 版本與建置號顯示文字
        let appVersion: String

        /// 以持久化快照與版本文字建立設定狀態
        ///
        /// - Parameters:
        ///   - snapshot: 已載入的設定快照
        ///   - appVersion: App 版本與建置號顯示文字
        init(snapshot: SettingsSnapshot = .default, appVersion: String = "—") {
            language = snapshot.language
            defaultCurrency = snapshot.defaultCurrency
            monthlyProfitGoalTWD = snapshot.monthlyProfitGoalTWD
            isAISummaryEnabled = snapshot.isAISummaryEnabled
            aiSummaryModel = snapshot.aiSummaryModel
            self.appVersion = appVersion
            appLock.isBiometricUnlockEnabled = snapshot.isBiometricUnlockEnabled
        }
    }

    // MARK: - Action

    /// 設定頁事件
    @CasePathable
    enum Action: BindableAction {

        /// SwiftUI 雙向繫結
        ///
        /// - Parameter action: 要寫入設定狀態的繫結變更
        case binding(BindingAction<State>)

        /// 使用者可直接操作的設定頁事件
        ///
        /// - Parameter action: 使用者在設定頁執行的操作
        case view(View)

        /// App 鎖定事件
        ///
        /// - Parameter action: App 鎖定功能收到的事件
        case appLock(AppLockFeature.Action)

        /// 幣別主檔載入結果
        ///
        /// - Parameter result: 幣別主檔載入成功或失敗的結果
        case currencyCodesResponse(Result<[CurrencyCode], CurrencyMetadataRepositoryError>)

        /// 設定頁畫面事件
        @CasePathable
        enum View {

            /// 畫面出現時載入幣別主檔
            case task

            /// 使用者選定預設幣別；傳入 ISO code 字串
            ///
            /// - Parameter code: 使用者選定的 ISO code 字串
            case defaultCurrencySelected(String)

            /// 使用者選定 (或自訂) AI 總結模型
            ///
            /// - Parameter model: 使用者選定或輸入的模型名稱
            case aiSummaryModelSelected(String)
        }
    }

    // MARK: - Dependencies

    /// 偏好的讀寫介面
    @Dependency(SettingsStore.self) private var settingsStore

    /// 幣別主檔資料來源；用於畫面出現時載入最新清單
    @Dependency(CurrencyMetadataRepository.self) private var currencyMetadataRepository

    // MARK: - Body

    /// 設定 reducer
    var body: some Reducer<State, Action> {
        BindingReducer()

        Scope(state: \.appLock, action: \.appLock) {
            AppLockFeature()
        }

        Reduce(core)
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
            persist(state)
            return .none

        case .view(.task):
            return loadCurrencyCodes()

        case let .view(.defaultCurrencySelected(code)):
            state.defaultCurrency = CurrencyCode(rawValue: code)
            persist(state)
            return .none

        case let .view(.aiSummaryModelSelected(model)):
            state.aiSummaryModel = model
            persist(state)
            return .none

        case .appLock(.enableAuthenticationFinished(.success)), .appLock(.enableToggled(false)):
            persist(state)
            return .none

        case .appLock:
            return .none

        case let .currencyCodesResponse(.success(codes)):
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

    /// 載入幣別主檔並把成功或失敗合併成單一回應
    ///
    /// - Returns: 幣別主檔載入 effect
    func loadCurrencyCodes() -> Effect<Action> {
        let currencyMetadataRepository = currencyMetadataRepository
        return .run { send in
            do {
                let codes = try await currencyMetadataRepository.fetchCodes()
                await send(.currencyCodesResponse(.success(codes)))
            } catch {
                guard let error = error as? CurrencyMetadataRepositoryError else {
                    return
                }
                await send(.currencyCodesResponse(.failure(error)))
            }
        }
    }

    /// 將目前設定寫回持久化來源
    ///
    /// - Parameter state: 目前設定狀態
    func persist(_ state: State) {
        settingsStore.save(
            SettingsSnapshot(
                language: state.language,
                defaultCurrency: state.defaultCurrency,
                monthlyProfitGoalTWD: state.monthlyProfitGoalTWD,
                isAISummaryEnabled: state.isAISummaryEnabled,
                aiSummaryModel: state.aiSummaryModel,
                isBiometricUnlockEnabled: state.appLock.isBiometricUnlockEnabled
            )
        )
    }
}
