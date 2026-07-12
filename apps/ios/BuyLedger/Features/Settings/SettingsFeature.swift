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

        /// 介面外觀模式偏好
        var appearance: AppearancePreference = .system

        /// 是否開啟通知
        var notificationsEnabled: Bool = true

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

        /// 是否顯示幣別選擇 sheet
        var showsCurrencySheet: Bool = false

        /// 是否顯示 AI 模型選擇 sheet (僅 DEBUG 建置使用)
        var showsModelSheet: Bool = false
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
                state.appearance = snapshot.appearance
                state.notificationsEnabled = snapshot.notificationsEnabled
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

            case .binding(\.showsCurrencySheet), .binding(\.showsModelSheet):
                // sheet 呈現屬短暫 UI 狀態，切換時不觸發設定存檔
                return .none

            case .binding:
                storage.save(
                    SettingsSnapshot(
                        appearance: state.appearance,
                        notificationsEnabled: state.notificationsEnabled,
                        defaultCurrency: state.defaultCurrency,
                        monthlyProfitGoalTwd: state.monthlyProfitGoalTwd,
                        useAiSummary: state.useAiSummary,
                        aiSummaryModel: state.aiSummaryModel
                    )
                )
                return .none
            }
        }
    }
}
