//
//  CampaignSectionTitle.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation

/// 開團列表區段與子群組的標題內容，畫面再依現在時間與 locale 格式化成文字
enum CampaignSectionTitle: Equatable, Sendable {

    /// 以日為單位的標題，與現在同一天或前一天時呈現為相對日期
    ///
    /// - Parameter date: 該日的起始時刻
    case day(Date)

    /// 以月為單位的頂層標題，顯示年與月
    ///
    /// - Parameter date: 該月的起始時刻
    case yearMonth(Date)

    /// 以年為單位的頂層標題，只顯示年
    ///
    /// - Parameter date: 該年的起始時刻
    case year(Date)

    /// 年分組下的子標題，只顯示月份
    ///
    /// - Parameter date: 該月的起始時刻
    case month(Date)
}
