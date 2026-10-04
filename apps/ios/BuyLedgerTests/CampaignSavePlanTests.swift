//
//  CampaignSavePlanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證儲存計畫的欄位組裝、改名與提醒，以及父層重名判斷
struct CampaignSavePlanTests {

    // MARK: - Properties

    /// 含結算日期的原始開團，驗證編輯時不清除封存資訊
    private static let original = Campaign.fixture(
        id: "ORIGINAL",
        name: "原團",
        openDate: Date(timeIntervalSince1970: 1_000),
        closeDate: Date(timeIntervalSince1970: 2_000),
        status: .ongoing,
        settledDate: Date(timeIntervalSince1970: 3_000),
        notes: "原備註"
    )

    /// 新增採呼叫端識別值，編輯保留原識別值與結算日期，並套用草稿及去空白備註
    ///
    /// - Parameter isEditing: 是否帶入原開團
    /// - Throws: 無法建立 UTC 時區時拋出測試錯誤
    @Test(arguments: [true, false])
    func make_新增或編輯_組出識別值草稿與原結算日期(isEditing: Bool) throws(any Error) {
        // Given
        let calendar = try TestDependencies.makeUTCCalendar()
        var draft = Self.draft(original: isEditing ? Self.original : nil)
        draft.name = "  新團  "
        draft.openDate = Date(timeIntervalSince1970: 4_000)
        draft.closeDate = Date(timeIntervalSince1970: 5_000)
        draft.status = .closed
        draft.notes = "  新備註\n "
        let request = CampaignEditFeature.SaveRequest(
            original: isEditing ? Self.original : nil,
            name: "新團",
            draft: draft
        )
        let expected = Campaign(
            id: isEditing ? "ORIGINAL" : "NEW-ID",
            name: "新團",
            openDate: Date(timeIntervalSince1970: 4_000),
            closeDate: Date(timeIntervalSince1970: 5_000),
            status: .closed,
            settledDate: isEditing ? Date(timeIntervalSince1970: 3_000) : nil,
            notes: "新備註"
        )

        // When
        let plan = CampaignSavePlan.make(
            request: request,
            existingLink: nil,
            newID: "NEW-ID",
            calendar: calendar
        )

        // Then
        #expect(plan.campaign == expected)
        #expect(plan.reminder == nil)
    }

    /// 新開團與原名未變不改訂單歸屬，原開團改名才提供完整前後名稱
    ///
    /// - Parameter scenario: 原名稱、新名稱與獨立指定的改名連動
    /// - Throws: 無法建立 UTC 時區時拋出測試錯誤
    @Test(arguments: RenameCase.allCases)
    func make_原名有無變更_僅原開團改名時產生連動(scenario: RenameCase) throws(any Error) {
        // Given
        let calendar = try TestDependencies.makeUTCCalendar()
        let original = scenario.originalName.map { name in
            var campaign = Self.original
            campaign.name = name
            return campaign
        }
        let request = CampaignEditFeature.SaveRequest(
            original: original,
            name: scenario.newName,
            draft: Self.draft(original: original)
        )

        // When
        let plan = CampaignSavePlan.make(
            request: request,
            existingLink: nil,
            newID: "NEW-ID",
            calendar: calendar
        )

        // Then
        #expect(plan.rename == scenario.expectedRename)
    }

    /// 儲存計畫保留提醒調解與完整事件參數，無需調解時沒有提醒請求
    ///
    /// - Parameter scenario: 提醒意圖、既有連結與獨立指定的預期調解
    /// - Throws: 無法建立 UTC 時區時拋出測試錯誤
    @Test(arguments: ReminderCase.allCases)
    func make_提醒意圖與既有連結_組出完整請求或略過(scenario: ReminderCase) throws(any Error) {
        // Given
        let calendar = try TestDependencies.makeUTCCalendar()
        var draft = Self.draft(original: Self.original)
        draft.wantsReminder = scenario.wantsReminder
        draft.reminderTimestamp = scenario.timestamp
        let request = CampaignEditFeature.SaveRequest(
            original: Self.original,
            name: scenario.name,
            draft: draft
        )
        let existingLink = CampaignReminderLink(
            eventIdentifier: "OLD",
            reminderTimestamp: Date(timeIntervalSince1970: 3_600)
        )
        let link = scenario.hasLink ? existingLink : nil
        let expectedRequest = scenario.expected.map {
            CampaignReminderRequest(
                campaignID: "ORIGINAL",
                reconcile: $0,
                title: scenario.name == "新團" ? "「新團」訂購提醒" : "「原團」訂購提醒",
                eventDate: Date(timeIntervalSince1970: 0),
                alarmOffset: scenario.timestamp == Date(timeIntervalSince1970: 3_600)
                    ? 3_600 : 7_200,
                timestamp: scenario.timestamp
            )
        }

        // When
        let plan = CampaignSavePlan.make(
            request: request,
            existingLink: link,
            newID: "NEW-ID",
            calendar: calendar
        )

        // Then
        #expect(plan.reminder == expectedRequest)
    }
}

// MARK: - Nested Types

extension CampaignSavePlanTests {

    /// 原名有無變更與預期的訂單改名連動
    struct RenameCase: Sendable {

        /// 新增、原名未變與改名三種情境的訂單改名連動預期
        static let allCases = [
            Self(originalName: nil, newName: "新團", expectedRename: nil),
            Self(originalName: "原團", newName: "原團", expectedRename: nil),
            Self(
                originalName: "原團",
                newName: "新團",
                expectedRename: CampaignSavePlan.Rename(from: "原團", to: "新團")
            ),
        ]

        /// 原開團名稱；`nil` 表示新增
        let originalName: String?

        /// 送出的已去空白名稱
        let newName: String

        /// 獨立指定的改名連動；`nil` 表示不改名
        let expectedRename: CampaignSavePlan.Rename?
    }

    /// 提醒意圖、連結與名稱或時間差異的組合
    struct ReminderCase: Sendable {

        /// 提醒意圖、連結與名稱或時間差異對應的建立、移除、重建或略過結果
        static let allCases = [
            Self(
                wantsReminder: true,
                hasLink: false,
                name: "原團",
                timestamp: Date(timeIntervalSince1970: 3_600),
                expected: .create
            ),
            Self(
                wantsReminder: false,
                hasLink: false,
                name: "原團",
                timestamp: Date(timeIntervalSince1970: 3_600),
                expected: nil
            ),
            Self(
                wantsReminder: true,
                hasLink: true,
                name: "原團",
                timestamp: Date(timeIntervalSince1970: 3_600),
                expected: nil
            ),
            Self(
                wantsReminder: true,
                hasLink: true,
                name: "新團",
                timestamp: Date(timeIntervalSince1970: 3_600),
                expected: .rebuild(oldEventIdentifier: "OLD")
            ),
            Self(
                wantsReminder: true,
                hasLink: true,
                name: "原團",
                timestamp: Date(timeIntervalSince1970: 7_200),
                expected: .rebuild(oldEventIdentifier: "OLD")
            ),
            Self(
                wantsReminder: false,
                hasLink: true,
                name: "原團",
                timestamp: Date(timeIntervalSince1970: 3_600),
                expected: .remove(eventIdentifier: "OLD")
            ),
        ]

        /// 是否要保留提醒
        let wantsReminder: Bool

        /// 是否已有事件連結
        let hasLink: Bool

        /// 送出的新名稱
        let name: String

        /// 使用者選定的提醒時間
        let timestamp: Date

        /// 獨立指定的預期調解
        let expected: CampaignReminderReconcile?
    }
}

// MARK: - Private Method

private extension CampaignSavePlanTests {

    /// 建立無提醒意圖的固定草稿
    ///
    /// - Parameter original: 草稿的原開團；`nil` 表示新增
    /// - Returns: 使用固定日期與提醒時間的草稿
    static func draft(original: Campaign?) -> CampaignDraft {
        CampaignDraft(
            original: original,
            currentDate: Date(timeIntervalSince1970: 0),
            wantsReminder: false,
            reminderTimestamp: Date(timeIntervalSince1970: 3_600)
        )
    }
}
