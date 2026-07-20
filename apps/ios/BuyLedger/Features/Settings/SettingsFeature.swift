//
//  SettingsFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// 設定頁狀態
///
/// 偏好透過 ``SettingsStorage`` 依賴持久化到 `UserDefaults`；測試時注入 ``SettingsStorage/testValue`` 即可避免污染 `.standard`
@Reducer
struct SettingsFeature {

    // MARK: - State

    /// 設定狀態
    @ObservableState
    struct State: Equatable, @unchecked Sendable {

        /// App 介面語言偏好
        var language: AppLanguage = .traditionalChinese

        /// 介面外觀模式偏好
        var appearance: AppearancePreference = .system

        /// 預設訂單幣別
        var defaultCurrency: CurrencyCode = .twd

        /// 可供選擇的幣別清單；由 ``CurrencyMetadataRepository`` 提供
        var availableCurrencies: [CurrencyCode] = CurrencyCode.defaults

        /// 每月淨獲利目標 (TWD)；Dashboard hero 卡的目標進度條讀此值。`0` 代表使用者尚未設定，UI 應隱藏進度條
        var monthlyProfitGoalTwd: Decimal = 80_000

        /// 是否啟用 AI 商品明細總結
        var useAiSummary: Bool = false

        /// AI 總結使用的 Ollama 模型名稱
        var aiSummaryModel: String = AISummaryModelCatalog.defaultModel

    }

    // MARK: - Action

    /// 設定頁事件
    @CasePathable
    enum Action: BindableAction, Equatable {

        /// SwiftUI 雙向繫結
        case binding(BindingAction<State>)

        /// 畫面出現時觸發從持久化來源載入
        case task

        /// 從 ``CurrencyMetadataRepository`` 取回最新幣別主檔
        case availableCurrenciesLoaded([CurrencyCode])

        /// 使用者選定預設幣別；傳入 ISO code 字串，由 reducer 建構 ``CurrencyCode``
        case defaultCurrencySelected(String)

        /// 使用者選定 (或自訂) AI 總結模型
        case aiSummaryModelSelected(String)
    }

    // MARK: - Dependency Properties

    /// 偏好的讀寫介面
    @Dependency(SettingsStorage.self) private var storage

    /// 幣別主檔資料來源；用於 `.task` 從 cache 拉最新清單
    @Dependency(CurrencyMetadataRepository.self) private var currencyMetadataRepository

    // MARK: - Reducer Body

    /// 設定 reducer
    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .task:
                let snapshot = storage.load()
                state.language = snapshot.language
                state.appearance = snapshot.appearance
                state.defaultCurrency = snapshot.defaultCurrency
                state.monthlyProfitGoalTwd = snapshot.monthlyProfitGoalTwd
                state.useAiSummary = snapshot.useAiSummary
                state.aiSummaryModel = snapshot.aiSummaryModel

                let currencyMetadataRepository = currencyMetadataRepository
                return .run { send in
                    if let codes = try? await currencyMetadataRepository.fetchCodes(), !codes.isEmpty {
                        await send(.availableCurrenciesLoaded(codes))
                    }
                }

            case let .availableCurrenciesLoaded(codes):
                var merged = Set(codes)
                merged.insert(state.defaultCurrency)
                state.availableCurrencies = merged.sorted {
                    $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending
                }
                return .none

            case let .defaultCurrencySelected(code):
                state.defaultCurrency = CurrencyCode(rawValue: code)
                persist(state)
                return .none

            case let .aiSummaryModelSelected(model):
                state.aiSummaryModel = model
                persist(state)
                return .none

            case .binding:
                persist(state)
                return .none
            }
        }
    }
}

// MARK: - Private Method

private extension SettingsFeature {

    /// 將目前設定狀態寫回持久化來源；供 `.binding` 與各設定選定 action 共用同一條存檔路徑
    /// - Parameter state: 目前設定狀態
    func persist(_ state: State) {
        storage.save(
            SettingsSnapshot(
                language: state.language,
                appearance: state.appearance,
                defaultCurrency: state.defaultCurrency,
                monthlyProfitGoalTwd: state.monthlyProfitGoalTwd,
                useAiSummary: state.useAiSummary,
                aiSummaryModel: state.aiSummaryModel
            )
        )
    }
}
