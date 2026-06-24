//
//  Campaign.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 開團 (一次團購批次)
///
/// 開團是有狀態的獨立實體：自帶生命週期狀態與開團／結單日期，並以 settledDate 記錄「結團」這個完成里程碑。訂單透過名稱字串歸屬到某個開團；分貨清單與結團結算完全由歸屬訂單彙總而來，本型別不保存任何彙總值
struct Campaign: Equatable, Identifiable, Sendable {

    // MARK: - Data Properties

    /// 開團的穩定識別值 (UUID 字串)；與名稱解耦，供建立／更新與選取使用
    let id: String

    /// 開團名稱；同時是訂單歸屬到開團的鍵
    var name: String

    /// 開團日期
    var openDate: Date

    /// 結單日期；選填。設定後，當結單日早於「現在」時，狀態會自動由開團中 (ongoing) 轉為已收單 (closed)
    var closeDate: Date?

    /// 開團目前狀態
    var status: CampaignStatus

    /// 結團 (結算封存) 日期；未設定代表尚未結團。結團不改變 status，僅作為完成標記
    var settledDate: Date?

    /// 開團備註；選填，無備註時為空字串
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
