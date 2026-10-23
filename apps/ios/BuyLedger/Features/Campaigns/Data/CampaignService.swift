//
//  CampaignService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 開團主檔讀寫與刪除清理的操作入口；
/// 正式實作在 `liveValue`、Preview 在 `previewValue`、測試預設值在 `testValue`
struct CampaignService: Sendable {

    // MARK: - Properties

    /// 讀取目前所有開團，依開團日期由新到舊排序
    ///
    /// - Returns: 目前儲存的開團；沒有資料時為空陣列
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   資料解碼失敗時丟出 `PersistenceError.fetchFailed(underlying: RecordDecodingError)`
    var fetchCampaigns: FetchCampaigns

    /// 寫入或更新單一開團
    ///
    /// - Parameter campaign: 要寫入或更新的開團
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    var saveCampaign: SaveCampaign

    /// 刪除開團並清理訂單歸屬與提醒連結
    ///
    /// - Parameters:
    ///   - id: 開團編號
    ///   - name: 開團名稱，用來移除訂單上的歸屬
    /// - Returns: 被刪除的行事曆事件識別碼；沒有提醒連結時為 `nil`
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    var removeCampaign: RemoveCampaign

    /// 寫入或更新單一開團，並在同一次寫入內將所有訂單中的原開團名稱替換為新名稱
    ///
    /// - Parameters:
    ///   - campaign: 要寫入或更新的開團
    ///   - previousName: 改名前的開團名稱
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    var renameCampaign: RenameCampaign

    /// 讀取全部開團提醒連結
    ///
    /// - Returns: 以開團編號對應提醒連結的字典
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    var fetchReminderLinks: FetchReminderLinks

    /// 新增或更新單一開團提醒連結
    ///
    /// - Parameters:
    ///   - campaignID: 開團編號
    ///   - link: 對應的行事曆事件與提醒時間
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    var saveReminderLink: SaveReminderLink

    /// 刪除指定開團的提醒連結；不存在時不做任何事
    ///
    /// - Parameter campaignID: 要刪除連結的開團編號
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    var removeReminderLink: RemoveReminderLink
}

// MARK: - Nested Types

extension CampaignService {

    /// `fetchCampaigns` 的函式型別
    typealias FetchCampaigns = @Sendable () async throws(PersistenceError) -> [Campaign]

    /// `saveCampaign` 的函式型別
    typealias SaveCampaign = @Sendable (_ campaign: Campaign) async throws(PersistenceError) -> Void

    /// `removeCampaign` 的函式型別
    typealias RemoveCampaign = @Sendable (
        _ id: String,
        _ name: String
    ) async throws(PersistenceError) -> String?

    /// `renameCampaign` 的函式型別
    typealias RenameCampaign = @Sendable (
        _ campaign: Campaign,
        _ previousName: String
    ) async throws(PersistenceError) -> Void

    /// `fetchReminderLinks` 的函式型別
    typealias FetchReminderLinks = @Sendable () async throws(PersistenceError) -> [String: CampaignReminderLink]

    /// `saveReminderLink` 的函式型別
    typealias SaveReminderLink = @Sendable (
        _ campaignID: String,
        _ link: CampaignReminderLink
    ) async throws(PersistenceError) -> Void

    /// `removeReminderLink` 的函式型別
    typealias RemoveReminderLink = @Sendable (
        _ campaignID: String
    ) async throws(PersistenceError) -> Void
}

// MARK: - DependencyKey

extension CampaignService: DependencyKey {

    /// 以注入的資料庫執行開團操作，供正式 App 使用
    ///
    /// - Note: 必須是 computed property，測試才能用 `withDependencies` 換掉資料庫相依
    static var liveValue: Self {
        @Dependency(\.buyLedgerDatabase) var database
        return Self(
            fetchCampaigns: { () throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.fetchCampaigns(in: context)
                }
            },
            saveCampaign: { campaign throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.saveCampaign(campaign, in: context)
                }
            },
            removeCampaign: { id, name throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.removeCampaign(id: id, name: name, in: context)
                }
            },
            renameCampaign: { campaign, previousName throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.renameCampaign(campaign, previousName: previousName, in: context)
                }
            },
            fetchReminderLinks: { () throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.fetchReminderLinks(in: context)
                }
            },
            saveReminderLink: { campaignID, link throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.saveReminderLink(campaignID: campaignID, link: link, in: context)
                }
            },
            removeReminderLink: { campaignID throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.removeReminderLink(campaignID: campaignID, in: context)
                }
            }
        )
    }

    #if DEBUG

    /// Preview 使用各 Service 共用、只存在記憶體的資料庫執行開團操作
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "CampaignService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return liveValue
    }

    #endif

    /// 測試預設值；每個 closure 都必須由測試明確覆寫
    static var testValue: Self {
        Self(
            fetchCampaigns: unimplemented("CampaignService.fetchCampaigns", placeholder: []),
            saveCampaign: unimplemented("CampaignService.saveCampaign"),
            removeCampaign: unimplemented("CampaignService.removeCampaign", placeholder: nil),
            renameCampaign: unimplemented("CampaignService.renameCampaign"),
            fetchReminderLinks: unimplemented(
                "CampaignService.fetchReminderLinks",
                placeholder: [:]
            ),
            saveReminderLink: unimplemented("CampaignService.saveReminderLink"),
            removeReminderLink: unimplemented("CampaignService.removeReminderLink")
        )
    }
}

// MARK: - Private Method

private extension CampaignService {

    /// 讀出開團並依日期由新到舊排序
    ///
    /// - Parameter context: 本次讀取使用的資料庫 `context`
    /// - Returns: 讀出的開團；沒有資料時為空陣列
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   資料解碼失敗時丟出 `PersistenceError.fetchFailed(underlying: RecordDecodingError)`
    static func fetchCampaigns(in context: ModelContext) throws(PersistenceError) -> [Campaign] {
        let descriptor = FetchDescriptor<CampaignRecord>(sortBy: [
            SortDescriptor(\.openDate, order: .reverse),
        ])
        let records = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }

        var campaigns: [Campaign] = []
        campaigns.reserveCapacity(records.count)
        for record in records {
            campaigns.append(try record.toDomain())
        }
        return campaigns
    }

    /// 依開團識別值新增或更新記錄
    ///
    /// - Parameters:
    ///   - campaign: 要寫入或更新的開團
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func saveCampaign(
        _ campaign: Campaign,
        in context: ModelContext
    ) throws(PersistenceError) {
        let id = campaign.id
        let descriptor = FetchDescriptor<CampaignRecord>(predicate: #Predicate { $0.id == id })
        let existing = try PersistenceError.mapFetch {
            try context.fetch(descriptor).first
        }
        if let existing {
            existing.apply(campaign)
        } else {
            context.insert(CampaignRecord(campaign: campaign))
        }
    }

    /// 在同一次寫入內刪除開團、訂單歸屬與提醒連結
    ///
    /// - Parameters:
    ///   - id: 要刪除的開團編號
    ///   - name: 要從訂單移除的開團名稱
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Returns: 被刪除提醒連結的行事曆事件識別碼；沒有連結時為 `nil`
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func removeCampaign(
        id: String,
        name: String,
        in context: ModelContext
    ) throws(PersistenceError) -> String? {
        let campaignDescriptor = FetchDescriptor<CampaignRecord>(
            predicate: #Predicate { $0.id == id }
        )
        let campaignRecords = try PersistenceError.mapFetch {
            try context.fetch(campaignDescriptor)
        }
        for record in campaignRecords {
            context.delete(record)
        }

        let orderRecords = try PersistenceError.mapFetch {
            try context.fetch(FetchDescriptor<OrderRecord>())
        }
        for record in orderRecords where record.campaignNames.contains(name) {
            record.campaignNames.removeAll { $0 == name }
        }

        let reminderDescriptor = FetchDescriptor<CampaignReminderRecord>(
            predicate: #Predicate { $0.campaignID == id }
        )
        let reminderRecords = try PersistenceError.mapFetch {
            try context.fetch(reminderDescriptor)
        }
        let eventIdentifier = reminderRecords.first?.eventIdentifier
        for record in reminderRecords {
            context.delete(record)
        }

        return eventIdentifier
    }

    /// 在同一次寫入內更新開團並改寫所有訂單內的開團名稱
    ///
    /// - Parameters:
    ///   - campaign: 要寫入或更新的開團
    ///   - previousName: 改名前的開團名稱
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func renameCampaign(
        _ campaign: Campaign,
        previousName: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        try saveCampaign(campaign, in: context)
        guard let normalizedNewName = normalizedRenameTarget(
            oldName: previousName,
            newName: campaign.name
        ) else {
            return
        }
        let descriptor = FetchDescriptor<OrderRecord>()
        let orderRecords = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }
        for record in orderRecords where record.campaignNames.contains(previousName) {
            record.campaignNames = record.campaignNames.map {
                $0 == previousName ? normalizedNewName : $0
            }
        }
    }

    /// 去除新名稱前後空白，並判斷這次改名需不需要執行訂單改寫
    ///
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 尚未去除前後空白的新名稱
    /// - Returns: 去除空白後的新名稱；新名稱為空白或與 `oldName` 相同時為 `nil`
    static func normalizedRenameTarget(oldName: String, newName: String) -> String? {
        let normalizedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty, normalizedName != oldName else {
            return nil
        }
        return normalizedName
    }

    /// 讀出全部提醒記錄並轉為開團提醒連結
    ///
    /// - Parameter context: 本次讀取使用的資料庫 `context`
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
    ///   - context: 本次寫入使用的資料庫 `context`
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
    ///   - context: 本次寫入使用的資料庫 `context`
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

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 reducer 以 `@Dependency(\.campaignService)` 取得的 Campaign Service
    var campaignService: CampaignService {
        get { self[CampaignService.self] }
        set { self[CampaignService.self] = newValue }
    }
}
