//
//  CampaignReminderService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData

/// 開團提醒連結的操作入口；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 假資料在 `previewValue`
struct CampaignReminderService: Sendable {

    // MARK: - Properties

    /// 讀取全部開團提醒連結
    ///
    /// - Returns: 以開團編號對應提醒連結的字典
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    var fetchLinks: FetchLinks

    /// 新增或更新單一開團提醒連結
    ///
    /// - Parameters:
    ///   - campaignID: 開團編號
    ///   - link: 對應的行事曆事件與提醒時間
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    var saveLink: SaveLink

    /// 刪除指定開團的提醒連結；不存在時不做任何事
    ///
    /// - Parameter campaignID: 要刪除連結的開團編號
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    var removeLink: RemoveLink
}

// MARK: - Nested Types

extension CampaignReminderService {

    /// `fetchLinks` 的函式型別
    typealias FetchLinks = @Sendable () async throws(PersistenceError) -> [String: CampaignReminderLink]

    /// `saveLink` 的函式型別
    typealias SaveLink = @Sendable (
        _ campaignID: String,
        _ link: CampaignReminderLink
    ) async throws(PersistenceError) -> Void

    /// `removeLink` 的函式型別
    typealias RemoveLink = @Sendable (_ campaignID: String) async throws(PersistenceError) -> Void
}

// MARK: - Internal Method

extension CampaignReminderService {

    /// 讀出全部提醒記錄並轉為開團提醒連結
    ///
    /// - Parameter context: 本次讀取使用的持久化 context
    /// - Returns: 以開團編號對應提醒連結的字典
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchLinks(
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
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func saveLink(
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
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func removeLink(campaignID: String, in context: ModelContext) throws(PersistenceError) {
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
