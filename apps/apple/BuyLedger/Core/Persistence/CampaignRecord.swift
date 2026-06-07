//
//  CampaignRecord.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation
import SwiftData

/// SwiftData 持久化的「開團 (Campaign)」記錄。
///
/// 與領域型別 ``Campaign`` 一一對應。沿用 ``OrderSourceRecord`` 的設計準則：不使用 `@Attribute(.unique)` (CloudKit 不支援)，由 ``CampaignPersistence`` 在 upsert／rename 時自行檢查避免重複。狀態以 ``statusRaw`` (String rawValue) 儲存，避免日後改動 ``CampaignStatus`` 時破壞 schema 指紋。
@Model
final class CampaignRecord {

    // MARK: - Data Properties

    /// 開團的穩定識別值 (UUID 字串)；同時作為 upsert 識別值。
    var id: String

    /// 開團名稱。
    var name: String

    /// 開團日期。
    var openDate: Date

    /// 結單日期；選填。
    var closeDate: Date?

    /// 開團狀態的 rawValue (開團中／已收單)。
    var statusRaw: String = CampaignStatus.ongoing.rawValue

    /// 結團 (結算封存) 日期；`nil` 代表尚未結團。
    var settledDate: Date?

    /// 開團備註。
    var notes: String = ""

    // MARK: - Init

    /// 依領域型別 ``Campaign`` 建立持久化記錄。
    /// - Parameter campaign: 對應的領域開團。
    init(campaign: Campaign) {
        self.id = campaign.id
        self.name = campaign.name
        self.openDate = campaign.openDate
        self.closeDate = campaign.closeDate
        self.statusRaw = campaign.status.rawValue
        self.settledDate = campaign.settledDate
        self.notes = campaign.notes
    }
}

// MARK: - View Method

extension CampaignRecord {

    // MARK: - Mapping

    /// 將 SwiftData 記錄轉回領域型別。
    /// - Returns: 對應的 ``Campaign``。
    func toDomain() -> Campaign {
        Campaign(
            id: id,
            name: name,
            openDate: openDate,
            closeDate: closeDate,
            status: CampaignStatus(rawValue: statusRaw) ?? .ongoing,
            settledDate: settledDate,
            notes: notes
        )
    }

    /// 將領域型別的內容套用到本記錄 (用於 upsert 流程的更新分支)。
    /// - Parameter campaign: 來源 ``Campaign``。
    func apply(_ campaign: Campaign) {
        self.name = campaign.name
        self.openDate = campaign.openDate
        self.closeDate = campaign.closeDate
        self.statusRaw = campaign.status.rawValue
        self.settledDate = campaign.settledDate
        self.notes = campaign.notes
    }
}
