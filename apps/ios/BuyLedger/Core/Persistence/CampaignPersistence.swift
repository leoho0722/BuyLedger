//
//  CampaignPersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation
import SwiftData

/// SwiftData 上對開團 (Campaign) 做 CRUD 的背景 actor
@ModelActor
actor CampaignPersistence {}

// MARK: - Internal Method

extension CampaignPersistence {
    
    /// 讀出全部開團，依開團日期由新到舊排序
    /// - Returns: 領域型別陣列
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    func fetchAll() throws(PersistenceError) -> [Campaign] {
        let descriptor = FetchDescriptor<CampaignRecord>(
            sortBy: [SortDescriptor(\.openDate, order: .reverse)]
        )
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        
        return records.map { $0.toDomain() }
    }
    
    /// 寫入或更新單一開團 (依 id upsert)
    /// - Parameter campaign: 來源領域開團
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func upsert(_ campaign: Campaign) throws(PersistenceError) {
        let id = campaign.id
        let descriptor = FetchDescriptor<CampaignRecord>(
            predicate: #Predicate { $0.id == id }
        )
        
        let existing = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor).first
        }
        if let existing {
            existing.apply(campaign)
        } else {
            modelContext.insert(CampaignRecord(campaign: campaign))
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
    
    /// 刪除指定 id 的開團，並在同一交易內連帶清除訂單歸屬與提醒連結
    /// - Parameters:
    ///   - id: 要刪除的開團識別值
    ///   - name: 該開團的名稱，用於剝除訂單歸屬
    /// - Returns: 被刪除的提醒連結事件識別碼；不存在提醒連結時為 `nil`
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func delete(id: String, name: String) throws(PersistenceError) -> String? {
        let wantedID = id
        let campaignDescriptor = FetchDescriptor<CampaignRecord>(
            predicate: #Predicate { $0.id == wantedID }
        )
        let campaignRecords = try PersistenceError.mapFetch {
            try modelContext.fetch(campaignDescriptor)
        }
        for record in campaignRecords {
            modelContext.delete(record)
        }
        
        let orderRecords = try PersistenceError.mapFetch {
            try modelContext.fetch(FetchDescriptor<OrderRecord>())
        }
        for record in orderRecords where record.campaignNames.contains(name) {
            record.campaignNames.removeAll { $0 == name }
        }
        
        let reminderDescriptor = FetchDescriptor<CampaignReminderRecord>(
            predicate: #Predicate { $0.campaignID == wantedID }
        )
        let reminderRecords = try PersistenceError.mapFetch {
            try modelContext.fetch(reminderDescriptor)
        }
        let eventIdentifier = reminderRecords.first?.eventIdentifier
        for record in reminderRecords {
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
        return eventIdentifier
    }
}
