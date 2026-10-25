//
//  CampaignReminderFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

/// 提供開團提醒測試共用的資料、請求與 store 建立輔助
enum CampaignReminderFeatureTestSupport {

    // MARK: - Properties

    /// 測試共用的開團識別值
    static let campaignID = "C1"

    /// 提醒事件的全天日期 (2026-04-20 00:00 UTC)
    static let eventDate = Date(timeIntervalSince1970: 1_776_643_200)

    /// 重建前的提醒時間 (2026-04-20 09:00 UTC)
    static let oldTimestamp = Date(timeIntervalSince1970: 1_776_675_600)

    /// 建立或重建後的提醒時間 (2026-04-20 18:00 UTC)
    static let newTimestamp = Date(timeIntervalSince1970: 1_776_708_000)

    /// 重建前開團連結的舊事件
    static let oldLink = CampaignReminderLink(
        eventIdentifier: "EVT-old",
        reminderTimestamp: oldTimestamp
    )

    /// 建立或重建後開團連結的新事件
    static let newLink = CampaignReminderLink(
        eventIdentifier: "EVT-new",
        reminderTimestamp: newTimestamp
    )
}

// MARK: - Nested Types

extension CampaignReminderFeatureTestSupport {

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

        /// 替身收到要保存的提醒連結，含事件識別碼與提醒時間
        let link: CampaignReminderLink
    }
}

// MARK: - Internal Method

extension CampaignReminderFeatureTestSupport {

    /// 建立以共用連結為初始狀態的測試 store
    ///
    /// - Parameters:
    ///   - links: 與開團功能共用的提醒連結
    ///   - hasLoadedLinks: 是否已成功載入過連結
    ///   - dependencies: 要覆寫的測試依賴
    /// - Returns: 只覆寫指定依賴的 `CampaignReminderFeature` 測試 store
    @MainActor
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

    /// 建立測試用的提醒請求，未指定的欄位預設為 2026-04-20 00:00 UTC 的全天事件，於當天 18:00 UTC 提示
    ///
    /// - Parameters:
    ///   - reconcile: 要執行的提醒調解
    ///   - title: 行事曆事件標題
    ///   - eventDate: 全天事件的日期
    ///   - alarmOffset: 自當天零點起算的提示秒數
    ///   - timestamp: 使用者選定的提醒日期與時間
    /// - Returns: 開團 C1 的提醒請求
    static func makeRequest(
        _ reconcile: CampaignReminderReconcile,
        title: String = "「四月團」訂購提醒",
        eventDate: Date = eventDate,
        alarmOffset: TimeInterval = 64_800,
        timestamp: Date = newTimestamp
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
