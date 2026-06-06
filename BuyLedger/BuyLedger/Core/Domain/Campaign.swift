//
//  Campaign.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation

/// 開團 (一次團購批次)。
///
/// 開團是有狀態的獨立實體：自帶生命週期狀態與開團／結單日期，並以 ``settledDate`` 記錄「結團」這個完成里程碑。訂單透過 ``LedgerOrder/campaignNames`` 以名稱字串歸屬到某個開團；分貨清單與結團結算則完全由歸屬訂單彙總而來，本型別不保存任何彙總值。
struct Campaign: Equatable, Identifiable, Sendable {

    // MARK: - Identifiable Properties

    /// 開團的穩定識別值 (UUID 字串)；與名稱解耦，供 upsert 與選取使用。
    let id: String

    // MARK: - Data Properties

    /// 開團名稱；同時是訂單 ``LedgerOrder/campaignNames`` 的歸屬鍵。
    var name: String

    /// 開團日期。
    var openDate: Date

    /// 結單日期；選填。設定後，當結單日早於「現在」時，狀態會自動由 ``CampaignStatus/ongoing`` 轉為 ``CampaignStatus/closed``。
    var closeDate: Date?

    /// 開團目前狀態。
    var status: CampaignStatus

    /// 結團 (結算封存) 日期；`nil` 代表尚未結團。結團不改變 ``status``，僅作為完成標記。
    var settledDate: Date?

    /// 開團備註；選填，無備註時為空字串。
    var notes: String

    // MARK: - Computed Properties

    /// 是否已結團。
    var isSettled: Bool {
        settledDate != nil
    }
}
