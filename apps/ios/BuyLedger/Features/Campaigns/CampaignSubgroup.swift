//
//  CampaignSubgroup.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/29.
//

import Foundation

/// 頂層日期區段下的次級分組
struct CampaignSubgroup: Equatable, Identifiable, Sendable {

    // MARK: - Properties

    /// 子群組識別值，使用該子群組的起始時刻
    let id: Date

    /// 依 locale 格式化的子標題；最細粒度時為 `nil`
    let title: String?

    /// 該子群組內的開團，依開團日期由新到舊排序 (同日再依名稱)
    let campaigns: [Campaign]
}
