//
//  SettingsStore.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/31.
//

import ComposableArchitecture
import Foundation

/// 把設定偏好讀寫到 `UserDefaults` 的依賴介面
struct SettingsStore: Sendable {

    // MARK: - Properties

    /// 從 `UserDefaults` 讀取一份設定快照
    ///
    /// - Returns: 目前的設定快照
    var load: @Sendable () -> SettingsSnapshot

    /// 將設定快照寫回 `UserDefaults`
    ///
    /// - Parameter snapshot: 欲寫入的設定快照
    var save: @Sendable (_ snapshot: SettingsSnapshot) -> Void
}

// MARK: - Nested Types

private extension SettingsStore {

    /// UserDefaults 使用的 key 名稱
    enum Keys {

        /// App 介面語言偏好的 key
        static let language = "settings.language"

        /// 預設幣別的 key
        static let defaultCurrency = "settings.defaultCurrency"

        /// 月度淨獲利目標的 key
        static let monthlyProfitGoalTWD = "settings.monthlyProfitGoalTwd"

        /// AI 總結開關的 key
        static let isAISummaryEnabled = "settings.useAiSummary"

        /// AI 總結模型名稱的 key
        static let aiSummaryModel = "settings.aiSummaryModel"

        /// App 鎖定開關的 key
        static let isBiometricUnlockEnabled = "settings.isBiometricUnlockEnabled"
    }
}

// MARK: - Internal Method

extension SettingsStore {

    /// 從指定的 UserDefaults 讀取設定快照
    ///
    /// - Parameter defaults: 提供設定值的 UserDefaults
    /// - Returns: 目前的設定快照
    static func snapshot(from defaults: UserDefaults) -> SettingsSnapshot {
        let language = AppLanguage(
            storedValue: defaults.string(forKey: Keys.language)
        )
        let storedCurrency = defaults.string(forKey: Keys.defaultCurrency) ?? ""
        let currency: CurrencyCode = storedCurrency.isEmpty
            ? .twd
            : CurrencyCode(rawValue: storedCurrency)
        let goalValue: Decimal
        if defaults.object(forKey: Keys.monthlyProfitGoalTWD) == nil {
            goalValue = SettingsSnapshot.default.monthlyProfitGoalTWD
        } else {
            goalValue = Decimal(defaults.double(forKey: Keys.monthlyProfitGoalTWD))
        }
        let isAISummaryEnabled = defaults.bool(forKey: Keys.isAISummaryEnabled)
        let storedModel = defaults.string(forKey: Keys.aiSummaryModel) ?? ""
        let aiSummaryModel = storedModel.isEmpty
            ? SettingsSnapshot.default.aiSummaryModel
            : storedModel
        let isBiometricUnlockEnabled = defaults.bool(
            forKey: Keys.isBiometricUnlockEnabled
        )

        return SettingsSnapshot(
            language: language,
            defaultCurrency: currency,
            monthlyProfitGoalTWD: goalValue,
            isAISummaryEnabled: isAISummaryEnabled,
            aiSummaryModel: aiSummaryModel,
            isBiometricUnlockEnabled: isBiometricUnlockEnabled
        )
    }

    /// 將設定快照寫入指定的 UserDefaults
    ///
    /// - Parameters:
    ///   - snapshot: 欲寫入的設定快照
    ///   - defaults: 接收設定值的 UserDefaults
    static func save(_ snapshot: SettingsSnapshot, to defaults: UserDefaults) {
        defaults.set(
            snapshot.language.rawValue,
            forKey: Keys.language
        )
        defaults.set(
            snapshot.defaultCurrency.rawValue,
            forKey: Keys.defaultCurrency
        )
        defaults.set(
            NSDecimalNumber(
                decimal: snapshot.monthlyProfitGoalTWD
            ).doubleValue,
            forKey: Keys.monthlyProfitGoalTWD
        )
        defaults.set(
            snapshot.isAISummaryEnabled,
            forKey: Keys.isAISummaryEnabled
        )
        defaults.set(
            snapshot.aiSummaryModel,
            forKey: Keys.aiSummaryModel
        )
        defaults.set(
            snapshot.isBiometricUnlockEnabled,
            forKey: Keys.isBiometricUnlockEnabled
        )
    }
}

// MARK: - DependencyKey

extension SettingsStore: DependencyKey {

    /// App 執行時實際讀寫 `UserDefaults.standard`
    static let liveValue: SettingsStore = SettingsStore(
        load: {
            SettingsStore.snapshot(from: .standard)
        },
        save: { snapshot in
            SettingsStore.save(snapshot, to: .standard)
        }
    )

    /// 測試用版本；讀取預設值，寫入不作用
    static let testValue: SettingsStore = SettingsStore(
        load: { .default },
        save: { _ in }
    )

    /// Preview 使用測試值
    static let previewValue: SettingsStore = testValue
}
