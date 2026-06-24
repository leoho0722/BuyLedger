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

    /// 介面外觀模式偏好
    var appearance: AppearancePreference

    /// 是否開啟通知
    var notificationsEnabled: Bool

    /// 預設訂單幣別
    var defaultCurrency: CurrencyCode

    /// 每月淨獲利目標 (TWD)
    var monthlyProfitGoalTwd: Decimal

    /// 是否啟用 AI 商品明細總結
    var useAiSummary: Bool

    /// AI 總結使用的 Ollama 模型名稱
    var aiSummaryModel: String

    // MARK: - Static Properties

    /// 預設設定
    static let `default` = SettingsSnapshot(
        appearance: .system,
        notificationsEnabled: true,
        defaultCurrency: .twd,
        monthlyProfitGoalTwd: 80_000,
        useAiSummary: false,
        aiSummaryModel: AISummaryModelCatalog.defaultModel
    )

    /// 測試與 preview 用的預設快照 (與 `default` 內容相同，但宣告為 `nonisolated` 方便在 `@Sendable` closure 中安全引用)
    nonisolated static let testDefault = SettingsSnapshot(
        appearance: .system,
        notificationsEnabled: true,
        defaultCurrency: .twd,
        monthlyProfitGoalTwd: 80_000,
        useAiSummary: false,
        aiSummaryModel: AISummaryModelCatalog.defaultModel
    )
}
