//
//  CampaignReminderPersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/11.
//

import Foundation
import SwiftData

/// SwiftData 上對「開團訂購提醒連結」做 CRUD 的背景 actor
@ModelActor
actor CampaignReminderPersistence {}

// MARK: - Internal Method

extension CampaignReminderPersistence {
    
    /// 讀取全部提醒連結
    /// - Returns: 開團識別值對應 ``CampaignReminderLink`` 的字典
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    func fetchAll() throws(PersistenceError) -> [String: CampaignReminderLink] {
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(FetchDescriptor<CampaignReminderRecord>())
        }
        
        return Dictionary(
            records.map {
                (
                    $0.campaignID,
                    CampaignReminderLink(
                        eventIdentifier: $0.eventIdentifier, reminderTimestamp: $0.reminderTimestamp
                    )
                )
            }
        ) { _, latest in latest }
    }
    
    /// 寫入或更新單一連結 (依 campaignID upsert)
    /// - Parameters:
    ///   - campaignID: 開團識別值
    ///   - link: 行事曆事件識別碼與提醒時間戳
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func upsert(
        campaignID: String,
        link: CampaignReminderLink
    )
    throws(PersistenceError)
    {
        let wantedID = campaignID
        let descriptor = FetchDescriptor<CampaignReminderRecord>(
            predicate: #Predicate { $0.campaignID == wantedID }
        )
        
        let existing = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor).first
        }
        if let existing {
            existing.eventIdentifier = link.eventIdentifier
            existing.reminderTimestamp = link.reminderTimestamp
        } else {
            modelContext.insert(
                CampaignReminderRecord(
                    campaignID: campaignID,
                    eventIdentifier: link.eventIdentifier,
                    reminderTimestamp: link.reminderTimestamp
                )
            )
        }
        
        do {
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw error
        }
    }
    
    /// 刪除指定 campaignID 的連結；若不存在不視為錯誤
    /// - Parameter campaignID: 要刪除連結的開團識別值
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func delete(campaignID: String) throws(PersistenceError) {
        let wantedID = campaignID
        let descriptor = FetchDescriptor<CampaignReminderRecord>(
            predicate: #Predicate { $0.campaignID == wantedID }
        )
        
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        for record in records {
            modelContext.delete(record)
        }
        
        do {
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
