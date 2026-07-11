//
//  CampaignReminderRecord.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/11.
//

import Foundation
import SwiftData

/// SwiftData 持久化的「開團訂購提醒連結」記錄
///
/// 記錄某開團 (``campaignID``) 對應到系統行事曆事件 (``eventIdentifier``) 的連結。行事曆事件識別碼是 iOS 裝置本機資料，故獨立於跨平台 ``Campaign`` 型別另存一表。比照 ``CampaignRecord`` 不使用 `@Attribute(.unique)` (CloudKit 不支援)，由 ``CampaignReminderPersistence`` 依 campaignID upsert 避免重複
@Model
final class CampaignReminderRecord {

    // MARK: - Data Properties

    /// 開團的穩定識別值 (UUID 字串)；同時作為 upsert 識別值
    var campaignID: String

    /// 對應的系統行事曆事件識別碼
    var eventIdentifier: String

    /// 提醒時間戳 (使用者選定的日期＋提示時間)；帶預設值供 V14 → V15 lightweight 遷移回填
    var reminderTimestamp: Date = Date(timeIntervalSince1970: 0)

    // MARK: - Init

    /// 建立連結記錄
    /// - Parameters:
    ///   - campaignID: 開團識別值
    ///   - eventIdentifier: 行事曆事件識別碼
    ///   - reminderTimestamp: 提醒時間戳 (日期＋提示時間)
    init(campaignID: String, eventIdentifier: String, reminderTimestamp: Date) {
        self.campaignID = campaignID
        self.eventIdentifier = eventIdentifier
        self.reminderTimestamp = reminderTimestamp
    }
}
