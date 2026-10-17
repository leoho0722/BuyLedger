//
//  SettingsService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/27.
//

import ComposableArchitecture
import Foundation

// MARK: - DependencyKey

extension SettingsService: DependencyKey {

    /// 正式 App 透過 `UserDefaultsStore` 讀寫使用者設定
    static var liveValue: Self {
        @Dependency(\.userDefaultsStore) var userDefaultsStore
        return Self(
            load: { [userDefaultsStore] in
                let language = AppLanguage(
                    storedValue: userDefaultsStore.string(forKey: Keys.language)
                )
                let storedCurrency = userDefaultsStore.string(forKey: Keys.defaultCurrency) ?? ""
                let defaultCurrency: CurrencyCode = storedCurrency.isEmpty
                    ? .twd
                    : CurrencyCode(rawValue: storedCurrency)
                let monthlyProfitGoalTWD: Decimal
                if userDefaultsStore.hasValue(forKey: Keys.monthlyProfitGoalTWD) {
                    monthlyProfitGoalTWD = Decimal(
                        userDefaultsStore.double(forKey: Keys.monthlyProfitGoalTWD)
                    )
                } else {
                    monthlyProfitGoalTWD = SettingsSnapshot.default.monthlyProfitGoalTWD
                }
                let isAISummaryEnabled = userDefaultsStore.bool(forKey: Keys.isAISummaryEnabled)
                let storedModel = userDefaultsStore.string(forKey: Keys.aiSummaryModel) ?? ""
                let aiSummaryModel = storedModel.isEmpty
                    ? SettingsSnapshot.default.aiSummaryModel
                    : storedModel
                let isBiometricUnlockEnabled = userDefaultsStore.bool(
                    forKey: Keys.isBiometricUnlockEnabled
                )

                return SettingsSnapshot(
                    language: language,
                    defaultCurrency: defaultCurrency,
                    monthlyProfitGoalTWD: monthlyProfitGoalTWD,
                    isAISummaryEnabled: isAISummaryEnabled,
                    aiSummaryModel: aiSummaryModel,
                    isBiometricUnlockEnabled: isBiometricUnlockEnabled
                )
            },
            save: { [userDefaultsStore] snapshot in
                userDefaultsStore.set(snapshot.language.rawValue, forKey: Keys.language)
                userDefaultsStore.set(
                    snapshot.defaultCurrency.rawValue,
                    forKey: Keys.defaultCurrency
                )
                userDefaultsStore.set(
                    NSDecimalNumber(decimal: snapshot.monthlyProfitGoalTWD).doubleValue,
                    forKey: Keys.monthlyProfitGoalTWD
                )
                userDefaultsStore.set(snapshot.isAISummaryEnabled, forKey: Keys.isAISummaryEnabled)
                userDefaultsStore.set(snapshot.aiSummaryModel, forKey: Keys.aiSummaryModel)
                userDefaultsStore.set(
                    snapshot.isBiometricUnlockEnabled,
                    forKey: Keys.isBiometricUnlockEnabled
                )
            }
        )
    }

    /// 測試用預設值；呼叫未覆寫的操作會回報未實作 issue
    static var testValue: Self {
        Self(
            load: unimplemented("SettingsService.load", placeholder: SettingsSnapshot.default),
            save: unimplemented("SettingsService.save")
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 `BuyLedgerApp` 與功能 reducer 取得使用者設定操作
    var settingsService: SettingsService {
        get { self[SettingsService.self] }
        set { self[SettingsService.self] = newValue }
    }
}
