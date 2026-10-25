//
//  CampaignSavePlanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CampaignSavePlan` 的單元測試，涵蓋欄位組裝、改名連動與提醒請求的產生
struct CampaignSavePlanTests {

    // MARK: - Properties

    /// 含結算日期的原始開團，用來確認編輯時不清除結算日期
    private static let original = Campaign.fixture(
        id: "ORIGINAL",
        name: "原團",
        openDate: Date(timeIntervalSince1970: 1_000),
        closeDate: Date(timeIntervalSince1970: 2_000),
        status: .ongoing,
        settledDate: Date(timeIntervalSince1970: 3_000),
        notes: "原備註"
    )

    /// 驗證新增時採用呼叫端給的新識別值且沒有結算日期，名稱與備註去除頭尾空白後組入開團，不產生提醒請求
    ///
    /// - Throws: 無法建立 UTC 時區時丟出測試錯誤
    @Test
    func make_新增_組出新識別值與空結算日期() throws {
        // Given
        let calendar = try TestDependencies.makeUTCCalendar()
        let request = Self.makeEditedRequest(original: nil)
        let expected = Campaign(
            id: "NEW-ID",
            name: "新團",
            openDate: Date(timeIntervalSince1970: 4_000),
            closeDate: Date(timeIntervalSince1970: 5_000),
            status: .closed,
            settledDate: nil,
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

    /// 驗證編輯時保留原開團的識別值與結算日期，其餘欄位採用草稿內容，且不產生提醒請求
    ///
    /// - Throws: 無法建立 UTC 時區時丟出測試錯誤
    @Test
    func make_編輯_保留原識別值與結算日期() throws {
        // Given
        let calendar = try TestDependencies.makeUTCCalendar()
        let request = Self.makeEditedRequest(original: Self.original)
        let expected = Campaign(
            id: "ORIGINAL",
            name: "新團",
            openDate: Date(timeIntervalSince1970: 4_000),
            closeDate: Date(timeIntervalSince1970: 5_000),
            status: .closed,
            settledDate: Date(timeIntervalSince1970: 3_000),
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

    /// 驗證新增或原名未變時不產生改名連動，只有原開團改名才提供從原名到新名的連動
    ///
    /// - Parameter scenario: 原名稱、新名稱與獨立指定的改名連動
    /// - Throws: 無法建立 UTC 時區時丟出測試錯誤
    @Test(arguments: RenameCase.allCases)
    func make_原名有無變更_僅原開團改名時產生連動(scenario: RenameCase) throws {
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

    /// 驗證提醒意圖與既有連結的組合，需要調解時產生建立、重建或移除的完整提醒請求，無需調解時不產生請求
    ///
    /// - Parameter scenario: 提醒意圖、既有連結與獨立指定的預期調解
    /// - Throws: 無法建立 UTC 時區時丟出測試錯誤
    @Test(arguments: ReminderCase.allCases)
    func make_提醒意圖與既有連結_組出完整請求或略過(scenario: ReminderCase) throws {
        // Given
        let calendar = try TestDependencies.makeUTCCalendar()
        var draft = Self.draft(original: Self.original)
        draft.wantsReminder = scenario.isReminderWanted
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
                title: scenario.expectedTitle,
                eventDate: Date(timeIntervalSince1970: 0),
                alarmOffset: scenario.expectedAlarmOffset,
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
                isReminderWanted: true,
                hasLink: false,
                name: "原團",
                timestamp: Date(timeIntervalSince1970: 3_600),
                expected: .create,
                expectedTitle: "「原團」訂購提醒",
                expectedAlarmOffset: 3_600
            ),
            Self(
                isReminderWanted: false,
                hasLink: false,
                name: "原團",
                timestamp: Date(timeIntervalSince1970: 3_600),
                expected: nil,
                expectedTitle: "「原團」訂購提醒",
                expectedAlarmOffset: 3_600
            ),
            Self(
                isReminderWanted: true,
                hasLink: true,
                name: "原團",
                timestamp: Date(timeIntervalSince1970: 3_600),
                expected: nil,
                expectedTitle: "「原團」訂購提醒",
                expectedAlarmOffset: 3_600
            ),
            Self(
                isReminderWanted: true,
                hasLink: true,
                name: "新團",
                timestamp: Date(timeIntervalSince1970: 3_600),
                expected: .rebuild(oldEventIdentifier: "OLD"),
                expectedTitle: "「新團」訂購提醒",
                expectedAlarmOffset: 3_600
            ),
            Self(
                isReminderWanted: true,
                hasLink: true,
                name: "原團",
                timestamp: Date(timeIntervalSince1970: 7_200),
                expected: .rebuild(oldEventIdentifier: "OLD"),
                expectedTitle: "「原團」訂購提醒",
                expectedAlarmOffset: 7_200
            ),
            Self(
                isReminderWanted: false,
                hasLink: true,
                name: "原團",
                timestamp: Date(timeIntervalSince1970: 3_600),
                expected: .remove(eventIdentifier: "OLD"),
                expectedTitle: "「原團」訂購提醒",
                expectedAlarmOffset: 3_600
            ),
        ]

        /// 是否要保留提醒
        let isReminderWanted: Bool

        /// 是否已有事件連結
        let hasLink: Bool

        /// 送出的新名稱
        let name: String

        /// 使用者選定的提醒時間
        let timestamp: Date

        /// 獨立指定的預期調解；`nil` 表示沒有提醒請求
        let expected: CampaignReminderReconcile?

        /// 獨立指定的預期標題，沒有預期請求時不比對
        let expectedTitle: String

        /// 獨立指定的預期提醒偏移秒數，沒有預期請求時不比對
        let expectedAlarmOffset: TimeInterval
    }
}

// MARK: - Private Method

private extension CampaignSavePlanTests {

    /// 組出草稿已改成含空白的新名稱、日期、狀態與備註的儲存請求
    ///
    /// - Parameter original: 要編輯的原開團；`nil` 表示新增
    /// - Returns: 名稱與備註待去除頭尾空白的儲存請求
    static func makeEditedRequest(original: Campaign?) -> CampaignEditFeature.SaveRequest {
        var draft = Self.draft(original: original)
        draft.name = "  新團  "
        draft.openDate = Date(timeIntervalSince1970: 4_000)
        draft.closeDate = Date(timeIntervalSince1970: 5_000)
        draft.status = .closed
        draft.notes = "  新備註\n "
        return CampaignEditFeature.SaveRequest(original: original, name: "新團", draft: draft)
    }

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
