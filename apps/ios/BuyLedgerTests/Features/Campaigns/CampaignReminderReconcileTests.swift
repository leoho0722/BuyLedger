//
//  CampaignReminderReconcileTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證提醒調解與結單日或今天的預設提醒時間
struct CampaignReminderReconcileTests {

    // MARK: - Properties

    /// 固定的既有事件與提醒時間，供調解情境使用
    private static let existingLink = CampaignReminderLink(
        eventIdentifier: "OLD-EVENT",
        reminderTimestamp: Date(timeIntervalSince1970: 1_000)
    )

    /// 六種基本輸入與缺少原開團的兩種情境，預期調解各自明寫
    private static let reconcileScenarios: [ReconcileScenario] = [
        ReconcileScenario(
            wantsReminder: true,
            existingLink: nil,
            originalTitle: nil,
            newTitle: "「四月團」訂購提醒",
            chosenTimestamp: Date(timeIntervalSince1970: 1_000),
            expected: .create
        ),
        ReconcileScenario(
            wantsReminder: true,
            existingLink: existingLink,
            originalTitle: "「四月團」訂購提醒",
            newTitle: "「四月團」訂購提醒",
            chosenTimestamp: Date(timeIntervalSince1970: 1_000),
            expected: nil
        ),
        ReconcileScenario(
            wantsReminder: true,
            existingLink: existingLink,
            originalTitle: "「四月團」訂購提醒",
            newTitle: "「五月團」訂購提醒",
            chosenTimestamp: Date(timeIntervalSince1970: 1_000),
            expected: .rebuild(oldEventIdentifier: "OLD-EVENT")
        ),
        ReconcileScenario(
            wantsReminder: true,
            existingLink: existingLink,
            originalTitle: "「四月團」訂購提醒",
            newTitle: "「四月團」訂購提醒",
            chosenTimestamp: Date(timeIntervalSince1970: 2_000),
            expected: .rebuild(oldEventIdentifier: "OLD-EVENT")
        ),
        ReconcileScenario(
            wantsReminder: false,
            existingLink: existingLink,
            originalTitle: "「四月團」訂購提醒",
            newTitle: "「五月團」訂購提醒",
            chosenTimestamp: Date(timeIntervalSince1970: 2_000),
            expected: .remove(eventIdentifier: "OLD-EVENT")
        ),
        ReconcileScenario(
            wantsReminder: false,
            existingLink: nil,
            originalTitle: nil,
            newTitle: "「四月團」訂購提醒",
            chosenTimestamp: Date(timeIntervalSince1970: 1_000),
            expected: nil
        ),
        ReconcileScenario(
            wantsReminder: true,
            existingLink: existingLink,
            originalTitle: nil,
            newTitle: "「五月團」訂購提醒",
            chosenTimestamp: Date(timeIntervalSince1970: 1_000),
            expected: nil
        ),
        ReconcileScenario(
            wantsReminder: true,
            existingLink: existingLink,
            originalTitle: nil,
            newTitle: "「五月團」訂購提醒",
            chosenTimestamp: Date(timeIntervalSince1970: 2_000),
            expected: .rebuild(oldEventIdentifier: "OLD-EVENT")
        ),
    ]

    /// 依提醒意圖、連結、原標題與時間差異決定建立、移除、重建或維持
    ///
    /// - Parameter scenario: 獨立列出輸入與預期調解的測試情境
    @Test(arguments: CampaignReminderReconcileTests.reconcileScenarios)
    func decide_提醒意圖與既有內容組合_回傳預期調解(scenario: ReconcileScenario) {
        // Given

        // When
        let reconcile = CampaignReminderReconcile.decide(
            wantsReminder: scenario.wantsReminder,
            existingLink: scenario.existingLink,
            originalTitle: scenario.originalTitle,
            newTitle: scenario.newTitle,
            chosenTimestamp: scenario.chosenTimestamp
        )

        // Then
        #expect(reconcile == scenario.expected)
    }

    /// 有結單日取結單日，沒有則取注入的今天，兩者都設定為上午九點
    ///
    /// - Parameters:
    ///   - hasCloseDate: 是否提供與今天不同日期的結單日
    ///   - expectedTimestamp: 以字面值指定的預期提醒時間戳
    /// - Throws: 無法建立 UTC 時區時拋出測試錯誤
    @Test(arguments: [
        (true, Date(timeIntervalSince1970: 1_778_576_400)),
        (false, Date(timeIntervalSince1970: 1_778_230_800)),
    ])
    func defaultTimestamp_結單日有無設定_取對應日期上午九點(
        hasCloseDate: Bool,
        expectedTimestamp: Date
    ) throws(any Error) {
        // Given
        let calendar = try TestDependencies.makeUTCCalendar()
        let closeDate = hasCloseDate ? Date(timeIntervalSince1970: 1_778_604_015) : nil
        let now = Date(timeIntervalSince1970: 1_778_264_430)

        // When
        let timestamp = CampaignReminderRequest.defaultTimestamp(
            closeDate: closeDate,
            now: now,
            calendar: calendar
        )

        // Then
        #expect(timestamp == expectedTimestamp)
    }
}

// MARK: - Nested Types

extension CampaignReminderReconcileTests {

    /// 提醒意圖與既有內容的固定輸入，以及獨立的預期調解
    struct ReconcileScenario: Sendable {

        /// 使用者是否要保留提醒
        let wantsReminder: Bool

        /// 已存在的事件識別值與提醒時間
        let existingLink: CampaignReminderLink?

        /// 原開團的提醒標題；沒有原開團時為 `nil`
        let originalTitle: String?

        /// 儲存後的提醒標題
        let newTitle: String

        /// 使用者選定的提醒時間戳
        let chosenTimestamp: Date

        /// 此組輸入應得到的調解結果
        let expected: CampaignReminderReconcile?
    }
}
