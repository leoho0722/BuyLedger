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

    /// 區段識別值，使用該區段的起始時刻 (start of day／month／year)
    let id: Date

    /// 頂層區段標題 (例如「今天」「2026年5月」「2026年」)
    let title: String

    /// 該區段下、依更細一級粒度切分的子群組
    let subgroups: [CampaignSubgroup]
}
