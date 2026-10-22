//
//  InsightsDateContext.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

/// 分析出現、重試或 Root 刷新時記錄的現在時間與行事曆
struct InsightsDateContext: Equatable, Sendable {

    // MARK: - Properties

    /// 記錄當下注入的現在時間
    let now: Date

    /// 注入的行事曆 (含時區)
    let calendar: Calendar
}
