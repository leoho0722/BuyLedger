//
//  CampaignReminderRequestTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證提醒請求的全天事件日期與分鐘提示位移
struct CampaignReminderRequestTests {

    /// 固定 UTC 時間戳換算成當日零點與分鐘提示位移，秒數不計入位移
    ///
    /// - Parameters:
    ///   - timestamp: 當日零點、下午或最後一分鐘的固定時間戳
    ///   - expectedAlarmOffset: 以字面值指定的預期提示秒數
    /// - Throws: 無法建立 UTC 時區時拋出測試錯誤
    @Test(arguments: [
        (Date(timeIntervalSince1970: 1_778_544_000), TimeInterval(0)),
        (Date(timeIntervalSince1970: 1_778_596_542), TimeInterval(52_500)),
        (Date(timeIntervalSince1970: 1_778_630_399), TimeInterval(86_340)),
    ])
    func make_固定時間戳_組出當日起始與分鐘提示位移(
        timestamp: Date,
        expectedAlarmOffset: TimeInterval
    ) throws(any Error) {
        // Given
        let calendar = try TestDependencies.makeUTCCalendar()
        let campaign = Campaign.fixture(
            id: "C1",
            name: "四月團",
            openDate: Date(timeIntervalSince1970: 0),
            closeDate: Date(timeIntervalSince1970: 1_779_235_200),
            status: .ongoing,
            notes: ""
        )

        // When
        let request = CampaignReminderRequest.make(
            campaign: campaign,
            reconcile: .rebuild(oldEventIdentifier: "OLD-EVENT"),
            timestamp: timestamp,
            calendar: calendar
        )

        // Then
        #expect(request.campaignID == "C1")
        #expect(request.reconcile == .rebuild(oldEventIdentifier: "OLD-EVENT"))
        #expect(request.title == "「四月團」訂購提醒")
        #expect(request.eventDate == Date(timeIntervalSince1970: 1_778_544_000))
        #expect(request.alarmOffset == expectedAlarmOffset)
        #expect(request.timestamp == timestamp)
    }
}
