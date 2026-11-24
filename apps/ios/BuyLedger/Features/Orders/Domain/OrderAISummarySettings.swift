//
//  OrderAISummarySettings.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

/// 根偏好單向同步給訂單容器的 AI 摘要開關、供應商與模型
struct OrderAISummarySettings: Equatable, Sendable {

    // MARK: - Properties

    /// 是否允許開啟 AI 摘要
    let isEnabled: Bool

    /// 摘要請求使用的供應商
    let provider: AISummaryProvider

    /// 摘要請求使用的模型名稱，屬於 `provider`
    let model: String
}
