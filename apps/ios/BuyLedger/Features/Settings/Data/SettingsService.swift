//
//  SettingsService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/27.
//

import ComposableArchitecture
import Foundation

/// 讀取與儲存使用者設定快照，供 App 啟動、設定畫面與 AI 摘要共用；
/// 正式實作在 `liveValue`、Preview 假資料在 `previewValue`、測試預設值在 `testValue`
struct SettingsService: Sendable {

    // MARK: - Properties

    /// 讀取目前的設定快照
    ///
    /// - Returns: 各項設定的目前值；未曾儲存的項目為預設值
    var load: Load

    /// 將設定快照寫回偏好儲存
    ///
    /// - Parameter snapshot: 要儲存的設定快照
    var save: Save
}

// MARK: - Nested Types

extension SettingsService {

    /// `load` 的函式型別
    typealias Load = @Sendable () -> SettingsSnapshot

    /// `save` 的函式型別
    typealias Save = @Sendable (_ snapshot: SettingsSnapshot) -> Void

    /// `UserDefaults` 使用的設定 key
    private enum Keys {

        /// App 介面語言偏好的 key
        static let language = "settings.language"

        /// 預設幣別的 key
        static let defaultCurrency = "settings.defaultCurrency"

        /// 月度淨獲利目標的 key
        static let monthlyProfitGoalTWD = "settings.monthlyProfitGoalTwd"

        /// AI 摘要開關的 key
        static let isAISummaryEnabled = "settings.useAiSummary"

        /// AI 摘要模型名稱的 key
        static let aiSummaryModel = "settings.aiSummaryModel"

        /// App 鎖定開關的 key
        static let isBiometricUnlockEnabled = "settings.isBiometricUnlockEnabled"
    }
}

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

    #if DEBUG

    /// Preview 使用預設設定；在正式 App 中誤用時偵錯版會立刻中止
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "SettingsService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return Self(
            load: { .default },
            save: { _ in }
        )
    }

    #endif

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
