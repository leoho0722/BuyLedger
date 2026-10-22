//
//  CampaignFeatureTests+ReminderFixtures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation

@testable import BuyLedger

// MARK: - Nested Types

extension CampaignFeatureTests {

    /// 儲存開團後轉送給提醒子 Feature 的請求案例：建立、提醒時間重建與改名重建
    struct ReminderRequestScenario: Sendable {

        /// 新增與提醒時間重建的輸入與預期請求；日期以 UTC 的 epoch 秒數明寫
        static let scenarios = [
            Self(
                original: nil,
                existingCampaigns: [],
                links: [:],
                draftName: "新團",
                reminderTimestamp: Date(timeIntervalSince1970: 1_776_708_000),
                expectedCampaign: Campaign(
                    id: "00000000-0000-0000-0000-000000000001",
                    name: "新團",
                    openDate: TestDependencies.fixedNow,
                    closeDate: TestDependencies.fixedNow,
                    status: .ongoing,
                    settledDate: nil,
                    notes: ""
                ),
                expectedRequest: CampaignReminderRequest(
                    campaignID: "00000000-0000-0000-0000-000000000001",
                    reconcile: .create,
                    title: "「新團」訂購提醒",
                    eventDate: Date(timeIntervalSince1970: 1_776_643_200),
                    alarmOffset: 64_800,
                    timestamp: Date(timeIntervalSince1970: 1_776_708_000)
                )
            ),
            Self(
                original: Campaign.fixture(
                    id: "C1",
                    name: "四月團",
                    openDate: Date(timeIntervalSince1970: 1_775_001_600),
                    closeDate: Date(timeIntervalSince1970: 1_776_643_200),
                    status: .ongoing,
                    settledDate: nil,
                    notes: ""
                ),
                existingCampaigns: [
                    Campaign.fixture(
                        id: "C1",
                        name: "四月團",
                        openDate: Date(timeIntervalSince1970: 1_775_001_600),
                        closeDate: Date(timeIntervalSince1970: 1_776_643_200),
                        status: .ongoing,
                        settledDate: nil,
                        notes: ""
                    ),
                ],
                links: [
                    "C1": CampaignReminderLink(
                        eventIdentifier: "EVT-old",
                        reminderTimestamp: Date(timeIntervalSince1970: 1_776_675_600)
                    ),
                ],
                draftName: "四月團",
                reminderTimestamp: Date(timeIntervalSince1970: 1_777_226_400),
                expectedCampaign: Campaign(
                    id: "C1",
                    name: "四月團",
                    openDate: Date(timeIntervalSince1970: 1_775_001_600),
                    closeDate: Date(timeIntervalSince1970: 1_776_643_200),
                    status: .ongoing,
                    settledDate: nil,
                    notes: ""
                ),
                expectedRequest: CampaignReminderRequest(
                    campaignID: "C1",
                    reconcile: .rebuild(oldEventIdentifier: "EVT-old"),
                    title: "「四月團」訂購提醒",
                    eventDate: Date(timeIntervalSince1970: 1_777_161_600),
                    alarmOffset: 64_800,
                    timestamp: Date(timeIntervalSince1970: 1_777_226_400)
                )
            ),
        ]

        /// 原開團改名時的輸入與獨立預期請求
        static let renamedScenario = Self(
            original: Campaign.fixture(
                id: "C1",
                name: "舊團名",
                openDate: Date(timeIntervalSince1970: 1_775_001_600),
                closeDate: nil,
                status: .ongoing,
                settledDate: nil,
                notes: ""
            ),
            existingCampaigns: [
                Campaign.fixture(
                    id: "C1",
                    name: "舊團名",
                    openDate: Date(timeIntervalSince1970: 1_775_001_600),
                    closeDate: nil,
                    status: .ongoing,
                    settledDate: nil,
                    notes: ""
                ),
            ],
            links: [
                "C1": CampaignReminderLink(
                    eventIdentifier: "EVT-old",
                    reminderTimestamp: Date(timeIntervalSince1970: 1_776_675_600)
                ),
            ],
            draftName: "新團名",
            reminderTimestamp: Date(timeIntervalSince1970: 1_776_675_600),
            expectedCampaign: Campaign(
                id: "C1",
                name: "新團名",
                openDate: Date(timeIntervalSince1970: 1_775_001_600),
                closeDate: TestDependencies.fixedNow,
                status: .ongoing,
                settledDate: nil,
                notes: ""
            ),
            expectedRequest: CampaignReminderRequest(
                campaignID: "C1",
                reconcile: .rebuild(oldEventIdentifier: "EVT-old"),
                title: "「新團名」訂購提醒",
                eventDate: Date(timeIntervalSince1970: 1_776_643_200),
                alarmOffset: 32_400,
                timestamp: Date(timeIntervalSince1970: 1_776_675_600)
            )
        )

        /// 開啟表單時編輯的原開團；新開團為 `nil`
        let original: Campaign?

        /// 儲存前共用開團清單的內容
        let existingCampaigns: [Campaign]

        /// 儲存前共用的提醒連結
        let links: [Campaign.ID: CampaignReminderLink]

        /// 使用者在表單輸入的開團名稱
        let draftName: String

        /// 使用者在表單選定的提醒時間
        let reminderTimestamp: Date

        /// 儲存後預期寫入共用清單的開團
        let expectedCampaign: Campaign

        /// 預期轉送給提醒子 Feature 的請求
        let expectedRequest: CampaignReminderRequest
    }
}
