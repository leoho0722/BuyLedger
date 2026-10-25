//
//  CampaignReminderRequestTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CampaignReminderRequest` 的單元測試，涵蓋全天事件日期與分鐘提示位移
struct CampaignReminderRequestTests {

    /// 驗證以 UTC 時間戳組出請求時，事件日期取當日零點，提示位移取到分鐘、秒數不計入
    ///
    /// - Parameter scenario: 當日零點、下午或最後一分鐘的固定時間戳與以字面值指定的預期提示秒數
    /// - Throws: 無法建立 UTC 時區時丟出測試錯誤
    @Test(arguments: AlarmOffsetCase.allCases)
    func make_固定時間戳_組出當日起始與分鐘提示位移(scenario: AlarmOffsetCase) throws {
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
            timestamp: scenario.timestamp,
            calendar: calendar
        )

        // Then
        #expect(request.campaignID == "C1")
        #expect(request.reconcile == .rebuild(oldEventIdentifier: "OLD-EVENT"))
        #expect(request.title == "「四月團」訂購提醒")
        #expect(request.eventDate == Date(timeIntervalSince1970: 1_778_544_000))
        #expect(request.alarmOffset == scenario.expectedAlarmOffset)
        #expect(request.timestamp == scenario.timestamp)
    }
}

// MARK: - Nested Types

extension CampaignReminderRequestTests {

    /// 固定時間戳與預期的分鐘提示位移
    struct AlarmOffsetCase: Sendable {

        /// 當日零點、下午與最後一分鐘的三種時間戳，下午的秒數不計入位移
        static let allCases = [
            Self(timestamp: Date(timeIntervalSince1970: 1_778_544_000), expectedAlarmOffset: 0),
            Self(
                timestamp: Date(timeIntervalSince1970: 1_778_596_542),
                expectedAlarmOffset: 52_500
            ),
            Self(
                timestamp: Date(timeIntervalSince1970: 1_778_630_399),
                expectedAlarmOffset: 86_340
            ),
        ]

        /// 提醒的固定時間戳
        let timestamp: Date

        /// 以字面值指定的預期提示秒數
        let expectedAlarmOffset: TimeInterval
    }
}
