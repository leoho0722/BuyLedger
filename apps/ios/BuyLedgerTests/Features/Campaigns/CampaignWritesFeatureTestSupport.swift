//
//  CampaignWritesFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation

@testable import BuyLedger

/// 提供開團寫入測試共用的固定資料
enum CampaignWritesFeatureTestSupport {

    // MARK: - Properties

    /// 固定的原始開團，供寫入與欄位隔離測試使用
    static let campaign = Campaign.fixture(
        id: "C1",
        name: "原團",
        openDate: Date(timeIntervalSince1970: 1_000),
        closeDate: Date(timeIntervalSince1970: 2_000),
        status: .ongoing,
        notes: "原備註"
    )

    /// 不參與本次寫入的另一開團，用來確認回應不改動其他資料列
    static let otherCampaign = Campaign.fixture(
        id: "OTHER",
        name: "其他團",
        openDate: Date(timeIntervalSince1970: 6_000),
        status: .ongoing,
        notes: "其他備註"
    )

    /// 儲存成功後必須原樣回報的提醒請求
    static let reminder = CampaignReminderRequest(
        campaignID: "C1",
        reconcile: .create,
        title: "「新團」訂購提醒",
        eventDate: Date(timeIntervalSince1970: 0),
        alarmOffset: 3_600,
        timestamp: Date(timeIntervalSince1970: 3_600)
    )
}
