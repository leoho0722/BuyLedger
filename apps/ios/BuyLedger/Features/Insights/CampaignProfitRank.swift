//
//  CampaignProfitRank.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

/// 每團毛利排行的單列資料
struct CampaignProfitRank: Identifiable, Equatable {

    // MARK: - Properties

    /// 對應開團的識別值
    let id: Campaign.ID

    /// 名次 (由 1 起算，依毛利由高到低)
    let rank: Int

    /// 開團名稱
    let campaignName: String

    /// 該團毛利
    let profit: Decimal

    /// 相對於最高毛利團的比例 (0...1)，供進度條呈現
    let ratio: Double
}
