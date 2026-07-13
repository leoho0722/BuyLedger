//
//  CampaignReminderPersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/11.
//

import Foundation
import SwiftData

/// SwiftData 上對「開團訂購提醒連結」做 CRUD 的背景 actor
///
/// 採用 `@ModelActor`，由 SwiftData 自動把 actor 綁到專屬 context。連結以 ``CampaignReminderRecord/campaignID`` 識別，upsert 即涵蓋新增與更新
@ModelActor
actor CampaignReminderPersistence {
}

// MARK: - Internal Method

extension CampaignReminderPersistence {

    /// 讀出全部連結，回傳 campaignID → 連結資料 (事件識別碼 + 提醒時間戳) 字典
    /// - Returns: 開團識別值對應 ``CampaignReminderLink`` 的字典
    func fetchAll() throws -> [String: CampaignReminderLink] {
        let records = try modelContext.fetch(FetchDescriptor<CampaignReminderRecord>())

        return Dictionary(
            records.map { ($0.campaignID, CampaignReminderLink(eventIdentifier: $0.eventIdentifier, reminderTimestamp: $0.reminderTimestamp)) }
        ) { _, latest in latest }
    }

    /// 寫入或更新單一連結 (依 campaignID upsert)
    /// - Parameters:
    ///   - campaignID: 開團識別值
    ///   - eventIdentifier: 行事曆事件識別碼
    ///   - reminderTimestamp: 提醒時間戳 (日期＋提示時間)
    func upsert(campaignID: String, eventIdentifier: String, reminderTimestamp: Date) throws {
        let wantedID = campaignID
        let descriptor = FetchDescriptor<CampaignReminderRecord>(
            predicate: #Predicate { $0.campaignID == wantedID }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.eventIdentifier = eventIdentifier
            existing.reminderTimestamp = reminderTimestamp
        } else {
            modelContext.insert(
                CampaignReminderRecord(campaignID: campaignID, eventIdentifier: eventIdentifier, reminderTimestamp: reminderTimestamp)
            )
        }

        try modelContext.save()
    }

    /// 刪除指定 campaignID 的連結；若不存在不視為錯誤
    /// - Parameter campaignID: 要刪除連結的開團識別值
    func delete(campaignID: String) throws {
        let wantedID = campaignID
        let descriptor = FetchDescriptor<CampaignReminderRecord>(
            predicate: #Predicate { $0.campaignID == wantedID }
        )

        let records = try modelContext.fetch(descriptor)
        for record in records {
            modelContext.delete(record)
        }

        try modelContext.save()
    }
}
