//
//  CampaignReminderLink.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation

/// 保存開團與系統行事曆事件之間的識別值和提醒時間
struct CampaignReminderLink: Equatable, Sendable {

    // MARK: - Properties

    /// 對應的系統行事曆事件識別碼
    let eventIdentifier: String

    /// 使用者選定的提醒日期與時間
    let reminderTimestamp: Date
}
