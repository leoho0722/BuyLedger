//
//  CampaignPersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation
import SwiftData

/// SwiftData 上對開團 (Campaign) 做 CRUD 的背景 actor
///
/// 採用 `@ModelActor`，由 SwiftData 自動把 actor 綁到專屬 context；領域層的 ``Campaign`` 與持久層的 ``CampaignRecord`` 在 actor 內互轉。開團以 ``Campaign/id`` (UUID 字串) 識別，upsert 即可同時涵蓋新增、改名與狀態變更，因此不需另設以名稱為鍵的 rename
@ModelActor
actor CampaignPersistence {

    // MARK: - View Method

    /// 讀出全部開團，依開團日期由新到舊排序
    /// - Returns: 領域型別陣列
    func fetchAll() throws -> [Campaign] {
        let descriptor = FetchDescriptor<CampaignRecord>(
            sortBy: [SortDescriptor(\.openDate, order: .reverse)]
        )
        let records = try modelContext.fetch(descriptor)

        return records.map { $0.toDomain() }
    }

    /// 寫入或更新單一開團 (依 id upsert)
    /// - Parameter campaign: 來源領域開團
    func upsert(_ campaign: Campaign) throws {
        let id = campaign.id
        let descriptor = FetchDescriptor<CampaignRecord>(
            predicate: #Predicate { $0.id == id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(campaign)
        } else {
            modelContext.insert(CampaignRecord(campaign: campaign))
        }

        try modelContext.save()
    }

    /// 刪除指定 id 的開團；若不存在不視為錯誤
    /// - Parameter id: 要刪除的開團識別值
    func delete(id: String) throws {
        let descriptor = FetchDescriptor<CampaignRecord>(
            predicate: #Predicate { $0.id == id }
        )

        let records = try modelContext.fetch(descriptor)
        for record in records {
            modelContext.delete(record)
        }

        try modelContext.save()
    }
}
