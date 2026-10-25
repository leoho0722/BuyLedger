//
//  Campaign+Fixture.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation

@testable import BuyLedger

// MARK: - Internal Method

extension Campaign {

    /// 建立測試用開團，未指定的欄位取固定預設值，開團日期預設為 2026 年 4 月 1 日零點 (UTC)
    ///
    /// - Parameters:
    ///   - id: 開團識別值
    ///   - name: 訂單歸屬使用的開團名稱
    ///   - openDate: 開團日期
    ///   - closeDate: 結單日期；`nil` 表示沒有設定
    ///   - status: 開團狀態
    ///   - settledDate: 結團日期；`nil` 表示尚未結團
    ///   - notes: 開團備註
    /// - Returns: 套用參數後的開團，其餘欄位為固定值
    static func fixture(
        id: Campaign.ID = "fixture-campaign-id",
        name: String = "測試開團",
        openDate: Date = Date(timeIntervalSince1970: 1_775_001_600),
        closeDate: Date? = nil,
        status: CampaignStatus = .ongoing,
        settledDate: Date? = nil,
        notes: String = ""
    ) -> Campaign {
        Campaign(
            id: id,
            name: name,
            openDate: openDate,
            closeDate: closeDate,
            status: status,
            settledDate: settledDate,
            notes: notes
        )
    }
}
