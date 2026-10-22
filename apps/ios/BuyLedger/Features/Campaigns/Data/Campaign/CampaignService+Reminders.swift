//
//  CampaignService+Reminders.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import SwiftData

// MARK: - Internal Method

extension CampaignService {

    /// 讀出全部提醒記錄並轉為開團提醒連結
    ///
    /// - Parameter context: 本次讀取使用的持久化 `context`
    /// - Returns: 以開團編號對應提醒連結的字典
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchReminderLinks(
        in context: ModelContext
    ) throws(PersistenceError) -> [String: CampaignReminderLink] {
        let records = try PersistenceError.mapFetch {
            try context.fetch(FetchDescriptor<CampaignReminderRecord>())
        }

        return records.reduce(into: [String: CampaignReminderLink]()) { links, record in
            links[record.campaignID] = CampaignReminderLink(
                eventIdentifier: record.eventIdentifier,
                reminderTimestamp: record.reminderTimestamp
            )
        }
    }

    /// 依開團編號新增或更新提醒連結
    ///
    /// - Parameters:
    ///   - campaignID: 開團編號
    ///   - link: 要儲存的行事曆事件與提醒時間
    ///   - context: 本次交易使用的持久化 `context`
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func saveReminderLink(
        campaignID: String,
        link: CampaignReminderLink,
        in context: ModelContext
    ) throws(PersistenceError) {
        let descriptor = FetchDescriptor<CampaignReminderRecord>(
            predicate: #Predicate { $0.campaignID == campaignID }
        )
        let existing = try PersistenceError.mapFetch {
            try context.fetch(descriptor).first
        }
        if let existing {
            existing.eventIdentifier = link.eventIdentifier
            existing.reminderTimestamp = link.reminderTimestamp
        } else {
            context.insert(
                CampaignReminderRecord(
                    campaignID: campaignID,
                    eventIdentifier: link.eventIdentifier,
                    reminderTimestamp: link.reminderTimestamp
                )
            )
        }
    }

    /// 刪除符合開團編號的全部提醒記錄
    ///
    /// - Parameters:
    ///   - campaignID: 要刪除連結的開團編號
    ///   - context: 本次交易使用的持久化 `context`
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func removeReminderLink(
        campaignID: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        let descriptor = FetchDescriptor<CampaignReminderRecord>(
            predicate: #Predicate { $0.campaignID == campaignID }
        )
        let records = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }
        for record in records {
            context.delete(record)
        }
    }
}
