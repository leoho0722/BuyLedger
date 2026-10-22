//
//  CampaignDateContext.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation

/// 列表出現時記錄的現在時間與行事曆，供區段標題判斷「今天」「昨天」
struct CampaignDateContext: Equatable, Sendable {

    // MARK: - Properties

    /// 列表出現當下注入的現在時間
    let now: Date

    /// 注入的行事曆 (含時區)，與日期分桶使用同一份
    let calendar: Calendar
}
