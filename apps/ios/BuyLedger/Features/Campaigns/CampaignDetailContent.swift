//
//  CampaignDetailContent.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation

/// 組合詳情頁需要的開團、彙總、可見分貨列與提醒連結
struct CampaignDetailContent: Equatable, Sendable {

    // MARK: - Properties

    /// 要顯示詳情的開團
    let campaign: Campaign

    /// 所有歸屬訂單的結算與分貨彙總，不受未收款篩選影響
    let summary: CampaignSummary

    /// 依只看未收款設定決定的可見客戶分貨列
    let distribution: [CampaignDistributionRow]

    /// 此開團連結的系統行事曆事件與提醒時間
    let reminderLink: CampaignReminderLink?
}

// MARK: - Computed Properties

extension CampaignDetailContent {

    /// 結團選單項目的標題；已結團的開團顯示已結團
    var settleActionTitle: LocalizedStringResource {
        campaign.isSettled ? "已結團" : "結團結算"
    }
}

// MARK: - Internal Method

extension CampaignDetailContent {

    /// 依開團識別值組出詳情內容，保留完整彙總並只篩選可見分貨列
    ///
    /// - Parameters:
    ///   - campaignID: 要顯示詳情的開團識別值
    ///   - campaigns: 目前的開團清單
    ///   - orders: 用來建立開團彙總的全部訂單
    ///   - links: 各開團對應的提醒連結
    ///   - isShowingUnpaidOnly: 是否只顯示尚未全部收款的客戶
    /// - Returns: 開團詳情內容；找不到開團時為 `nil`
    static func make(
        campaignID: Campaign.ID,
        campaigns: [Campaign],
        orders: [LedgerOrder],
        links: [Campaign.ID: CampaignReminderLink],
        isShowingUnpaidOnly: Bool
    ) -> Self? {
        guard let campaign = campaigns.first(where: { $0.id == campaignID }) else {
            return nil
        }
        let summary = CampaignSummary(campaignName: campaign.name, orders: orders)
        return Self(
            campaign: campaign,
            summary: summary,
            distribution: isShowingUnpaidOnly ? summary.unpaidDistribution : summary.distribution,
            reminderLink: links[campaignID]
        )
    }
}
