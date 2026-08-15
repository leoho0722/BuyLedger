//
//  Campaign.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 一次團購批次，包含開團、結單與結團狀態
struct Campaign: Codable, Equatable, Identifiable, Sendable {

    // MARK: - Data Properties

    /// 開團的穩定識別值 (UUID 字串)
    let id: String

    /// 開團名稱，也是訂單歸屬的依據
    var name: String

    /// 開團日期
    var openDate: Date

    /// 結單日期；未設定表示持續收單
    var closeDate: Date?

    /// 開團目前狀態
    var status: CampaignStatus

    /// 結團日期；未設定表示尚未結團
    var settledDate: Date?

    /// 開團備註；沒有備註時為空字串
    var notes: String

    // MARK: - Init

    /// 建立 Campaign
    init(
        id: String,
        name: String,
        openDate: Date,
        closeDate: Date? = nil,
        status: CampaignStatus,
        settledDate: Date? = nil,
        notes: String
    ) {
        self.id = id
        self.name = name
        self.openDate = openDate
        self.closeDate = closeDate
        self.status = status
        self.settledDate = settledDate
        self.notes = notes
    }
}
