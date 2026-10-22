//
//  CampaignReminderFeatureTests+Fixtures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

// MARK: - Nested Types

extension CampaignReminderFeatureTests {

    /// 替身行事曆收到的建立請求，用來逐項比對標題、日期與提示位移
    struct RecordedReminder: Equatable, Sendable {

        /// 替身行事曆收到的訂購提醒標題
        let title: String

        /// 全天事件的日期
        let eventDate: Date

        /// 自當天零點起算的提示秒數
        let alarmOffset: TimeInterval
    }

    /// 替身連結資料收到的寫入，用來比對開團識別值與連結內容
    struct SavedLink: Equatable, Sendable {

        /// 連結所屬的開團識別值
        let campaignID: String

        /// 替身收到要保存的事件識別碼與提醒時間
        let link: CampaignReminderLink
    }
}

// MARK: - Internal Method

extension CampaignReminderFeatureTests {

    /// 建立以共用連結為初始狀態的測試 store
    ///
    /// - Parameters:
    ///   - links: 與父層共用的提醒連結
    ///   - hasLoadedLinks: 是否已成功載入過連結
    ///   - dependencies: 要覆寫的測試依賴
    /// - Returns: 只覆寫指定依賴的 `CampaignReminderFeature` 測試 store
    static func makeStore(
        links: Shared<[Campaign.ID: CampaignReminderLink]>,
        hasLoadedLinks: Bool = false,
        _ dependencies: @escaping (inout DependencyValues) -> Void
    ) -> TestStoreOf<CampaignReminderFeature> {
        var initial = CampaignReminderFeature.State(links: links)
        initial.hasLoadedLinks = hasLoadedLinks
        return TestStore(initialState: initial) {
            CampaignReminderFeature()
        } withDependencies: {
            dependencies(&$0)
        }
    }

    /// 建立測試用的提醒請求，未指定的欄位取 2026-04-20 18:00 UTC 的提醒
    ///
    /// - Parameters:
    ///   - reconcile: 要執行的提醒調解
    ///   - title: 行事曆事件標題
    ///   - eventDate: 全天事件的日期
    ///   - alarmOffset: 自當天零點起算的提示秒數
    ///   - timestamp: 使用者選定的提醒日期與時間
    /// - Returns: 開團 `C1` 的提醒請求
    static func makeRequest(
        _ reconcile: CampaignReminderReconcile,
        title: String = "「四月團」訂購提醒",
        eventDate: Date = CampaignReminderFeatureTests.eventDate,
        alarmOffset: TimeInterval = 64_800,
        timestamp: Date = CampaignReminderFeatureTests.newTimestamp
    ) -> CampaignReminderRequest {
        CampaignReminderRequest(
            campaignID: campaignID,
            reconcile: reconcile,
            title: title,
            eventDate: eventDate,
            alarmOffset: alarmOffset,
            timestamp: timestamp
        )
    }
}
