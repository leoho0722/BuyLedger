//
//  SettingsService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/27.
//

/// 讀取與儲存使用者設定快照，供 App 啟動、設定畫面與 AI 摘要共用；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 假資料在 `previewValue`
struct SettingsService: Sendable {

    // MARK: - Properties

    /// 讀取目前的設定快照
    ///
    /// - Returns: 目前的設定快照
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
