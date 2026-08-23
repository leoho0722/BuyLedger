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
    /// - Returns: 目前的設定快照
    var load: @Sendable () -> SettingsSnapshot
    
    /// 將設定快照寫回 `UserDefaults`
    /// - Parameter snapshot: 欲寫入的設定快照
    var save: @Sendable (_ snapshot: SettingsSnapshot) -> Void
}

// MARK: - Nested Types

private extension SettingsStorage {
    
    /// UserDefaults 使用的 key 名稱
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
        
        /// App 鎖定開關的 key
        nonisolated static let isBiometricUnlockEnabled = "settings.isBiometricUnlockEnabled"
    }
}

// MARK: - Dependency Values

extension SettingsStorage: DependencyKey {
    
    /// App 執行時實際讀寫 `UserDefaults.standard`
    nonisolated static let liveValue: SettingsStorage = SettingsStorage(
        load: {
            let defaults = UserDefaults.standard
            let language = AppLanguage(
                storedValue: defaults.string(forKey: SettingsStorageKeys.language)
            )
            let storedCurrency = defaults.string(forKey: SettingsStorageKeys.defaultCurrency) ?? ""
            let currency: CurrencyCode =
            storedCurrency.isEmpty ? .twd : CurrencyCode(rawValue: storedCurrency)
            // 未寫入時使用每月目標預設值
            // 寫入過 `0` 也尊重使用者意圖 (代表「不設目標」)
            let raw = defaults.double(forKey: SettingsStorageKeys.monthlyProfitGoalTwd)
            let goalValue = Decimal(raw)
            let useAiSummary = defaults.bool(forKey: SettingsStorageKeys.useAiSummary)
            let storedModel = defaults.string(forKey: SettingsStorageKeys.aiSummaryModel) ?? ""
            let aiSummaryModel = storedModel.isEmpty ? SettingsSnapshot.default.aiSummaryModel : storedModel
            let isBiometricUnlockEnabled = defaults.bool(
                forKey: SettingsStorageKeys.isBiometricUnlockEnabled
            )
            
            return SettingsSnapshot(
                language: language,
                defaultCurrency: currency,
                monthlyProfitGoalTwd: goalValue,
                useAiSummary: useAiSummary,
                aiSummaryModel: aiSummaryModel,
                isBiometricUnlockEnabled: isBiometricUnlockEnabled
            )
        },
        save: { snapshot in
            let defaults = UserDefaults.standard
            defaults.set(
                snapshot.language.rawValue,
                forKey: SettingsStorageKeys.language
            )
            defaults.set(
                snapshot.defaultCurrency.rawValue,
                forKey: SettingsStorageKeys.defaultCurrency
            )
            defaults.set(
                NSDecimalNumber(
                    decimal: snapshot.monthlyProfitGoalTwd
                ).doubleValue,
                forKey: SettingsStorageKeys.monthlyProfitGoalTwd
            )
            defaults.set(
                snapshot.useAiSummary,
                forKey: SettingsStorageKeys.useAiSummary
            )
            defaults.set(
                snapshot.aiSummaryModel,
                forKey: SettingsStorageKeys.aiSummaryModel
            )
            defaults.set(
                snapshot.isBiometricUnlockEnabled,
                forKey: SettingsStorageKeys.isBiometricUnlockEnabled
            )
        }
    )
    
    /// 測試用版本；讀取預設值，寫入不作用
    nonisolated static let testValue: SettingsStorage = SettingsStorage(
        load: { SettingsSnapshot.testDefault },
        save: { _ in }
    )
    
    /// Preview 使用測試值
    nonisolated static let previewValue: SettingsStorage = testValue
}
