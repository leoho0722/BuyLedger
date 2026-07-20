//
//  SettingsStorage.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/31.
//

import ComposableArchitecture
import Foundation

/// 把設定偏好讀寫到 `UserDefaults` 的依賴介面
struct SettingsStorage: Sendable {

    // MARK: - Dependency Properties

    /// 從 `UserDefaults` 讀取一份設定快照
    var load: @Sendable () -> SettingsSnapshot

    /// 將設定快照寫回 `UserDefaults`
    /// - Parameter snapshot: 欲寫入的設定快照
    var save: @Sendable (_ snapshot: SettingsSnapshot) -> Void
}

// MARK: - Nested Types

private extension SettingsStorage {

    /// `UserDefaults` 讀寫所使用的 key 名稱；各 key 以 `nonisolated static` 宣告，可在 `@Sendable` closure 中安全引用
    enum SettingsStorageKeys {

        // MARK: - Static Properties

        /// App 介面語言偏好的 key
        nonisolated static let language = "settings.language"

        /// 預設幣別的 key
        nonisolated static let defaultCurrency = "settings.defaultCurrency"

        /// 月度淨獲利目標的 key
        nonisolated static let monthlyProfitGoalTwd = "settings.monthlyProfitGoalTwd"

        /// AI 總結開關的 key
        nonisolated static let useAiSummary = "settings.useAiSummary"

        /// AI 總結模型名稱的 key
        nonisolated static let aiSummaryModel = "settings.aiSummaryModel"

        /// 上次選取分頁的 key
        nonisolated static let lastSelectedTab = "settings.lastSelectedTab"
    }
}

// MARK: - Dependency Values

extension SettingsStorage: DependencyKey {

    /// App 執行時實際讀寫 `UserDefaults.standard`
    ///
    /// `UserDefaults` 為執行緒安全，但 Swift 6 strict concurrency 並不認可；因此 closure 內每次都從
    /// `.standard` 取得引用，而非透過捕獲傳遞，避免 `Sendable` 報錯
    nonisolated static let liveValue: SettingsStorage = SettingsStorage(
        load: {
            let defaults = UserDefaults.standard
            let language = AppLanguage(
                storedValue: defaults.string(forKey: SettingsStorageKeys.language)
            )
            let storedCurrency = defaults.string(forKey: SettingsStorageKeys.defaultCurrency) ?? ""
            let currency: CurrencyCode = storedCurrency.isEmpty ? .twd : CurrencyCode(rawValue: storedCurrency)
            // 從未寫入時 `object(forKey:)` 為 nil，預設帶入 `SettingsSnapshot.default.monthlyProfitGoalTwd`；
            // 寫入過 `0` 也尊重使用者意圖 (代表「不設目標」)
            let goalValue: Decimal = {
                guard let raw = defaults.object(forKey: SettingsStorageKeys.monthlyProfitGoalTwd) as? Double else {
                    return SettingsSnapshot.default.monthlyProfitGoalTwd
                }
                return Decimal(raw)
            }()
            let useAiSummary = defaults.object(forKey: SettingsStorageKeys.useAiSummary) as? Bool ?? false
            let storedModel = defaults.string(forKey: SettingsStorageKeys.aiSummaryModel) ?? ""
            let aiSummaryModel = storedModel.isEmpty ? SettingsSnapshot.default.aiSummaryModel : storedModel
            let storedTab = defaults.string(forKey: SettingsStorageKeys.lastSelectedTab) ?? ""
            let lastSelectedTab = RootTab(rawValue: storedTab) ?? SettingsSnapshot.default.lastSelectedTab

            return SettingsSnapshot(
                language: language,
                defaultCurrency: currency,
                monthlyProfitGoalTwd: goalValue,
                useAiSummary: useAiSummary,
                aiSummaryModel: aiSummaryModel,
                lastSelectedTab: lastSelectedTab
            )
        },
        save: { snapshot in
            let defaults = UserDefaults.standard
            defaults.set(snapshot.language.rawValue, forKey: SettingsStorageKeys.language)
            defaults.set(snapshot.defaultCurrency.rawValue, forKey: SettingsStorageKeys.defaultCurrency)
            defaults.set(NSDecimalNumber(decimal: snapshot.monthlyProfitGoalTwd).doubleValue, forKey: SettingsStorageKeys.monthlyProfitGoalTwd)
            defaults.set(snapshot.useAiSummary, forKey: SettingsStorageKeys.useAiSummary)
            defaults.set(snapshot.aiSummaryModel, forKey: SettingsStorageKeys.aiSummaryModel)
            defaults.set(snapshot.lastSelectedTab.rawValue, forKey: SettingsStorageKeys.lastSelectedTab)
        }
    )

    /// 測試時使用的版本：load 永遠回傳預設值，save 為 no-op，避免污染 `.standard`
    nonisolated static let testValue: SettingsStorage = SettingsStorage(
        load: { SettingsSnapshot.testDefault },
        save: { _ in }
    )

    /// SwiftUI Preview 直接沿用測試值即可
    nonisolated static let previewValue: SettingsStorage = testValue
}
