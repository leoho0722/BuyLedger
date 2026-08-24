//
//  SettingsSnapshot.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/31.
//

import Foundation

/// 設定持久化的最小快照，方便一次寫入或讀出全部欄位
struct SettingsSnapshot: Equatable, Sendable {
    
    // MARK: - Data Properties
    
    /// App 介面語言偏好
    var language: AppLanguage
    
    /// 預設訂單幣別
    var defaultCurrency: CurrencyCode
    
    /// 每月淨獲利目標 (TWD)
    var monthlyProfitGoalTwd: Decimal
    
    /// 是否啟用 AI 商品明細總結
    var useAiSummary: Bool
    
    /// AI 總結使用的 Ollama 模型名稱
    var aiSummaryModel: String
    
    /// 是否啟用 App 鎖定；離開 App 後需驗證解鎖
    var isBiometricUnlockEnabled: Bool
    
    // MARK: - Static Properties
    
    /// 預設設定
    static let `default` = SettingsSnapshot(
        language: .traditionalChinese,
        defaultCurrency: .twd,
        monthlyProfitGoalTwd: 80_000,
        useAiSummary: false,
        aiSummaryModel: AISummaryModelCatalog.defaultModel,
        isBiometricUnlockEnabled: false
    )
    
    /// 測試與 Preview 使用的預設設定快照
    nonisolated static let testDefault = SettingsSnapshot(
        language: .traditionalChinese,
        defaultCurrency: .twd,
        monthlyProfitGoalTwd: 80_000,
        useAiSummary: false,
        aiSummaryModel: AISummaryModelCatalog.defaultModel,
        isBiometricUnlockEnabled: false
    )
}
