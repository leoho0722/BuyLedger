//
//  CampaignDateSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/29.
//

import Foundation

/// 開團列表的頂層日期區段 (依目前分組粒度：日／月／年)
struct CampaignDateSection: Equatable, Identifiable, Sendable {

    // MARK: - Properties

    /// 區段識別值，使用該區段的起始時刻 (當日、當月或當年的起點)
    let id: Date

    /// 尚未格式化的頂層區段標題內容
    let title: CampaignSectionTitle

    /// 該區段下、依更細一級粒度切分的子群組
    let subgroups: [CampaignSubgroup]
}
