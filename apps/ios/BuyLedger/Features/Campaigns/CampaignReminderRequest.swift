//
//  CampaignReminderRequest.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation

/// 保存提醒調解所需的開團、事件標題、全天日期與提示時間
struct CampaignReminderRequest: Equatable, Sendable {

    // MARK: - Properties

    /// 提醒連結對應的開團識別值
    let campaignID: Campaign.ID

    /// 要建立、移除或重建提醒事件的方式
    let reconcile: CampaignReminderReconcile

    /// 行事曆中顯示的訂購提醒標題
    let title: String

    /// 提醒時間戳在指定曆法中的當日起始
    let eventDate: Date

    /// 自當天零點起算的提示秒數，依時與分換算
    let alarmOffset: TimeInterval

    /// 使用者選定的完整提醒日期與時間
    let timestamp: Date
}

// MARK: - Internal Method

extension CampaignReminderRequest {

    /// 取結單日或注入的今天，建立當日上午九點的預設提醒時間
    ///
    /// - Parameters:
    ///   - closeDate: 開團的結單日；未設定時使用今天
    ///   - now: 呼叫端提供的現在時間
    ///   - calendar: 呼叫端提供的曆法與時區
    /// - Returns: 對應日期的上午九點；曆法無法設定時間時保留當日起始
    static func defaultTimestamp(closeDate: Date?, now: Date, calendar: Calendar) -> Date {
        let baseDay = calendar.startOfDay(for: closeDate ?? now)
        return calendar.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: baseDay
        ) ?? baseDay
    }

    /// 依開團、調解與提醒時間戳組出全天事件日期和提示位移
    ///
    /// - Parameters:
    ///   - campaign: 要套用提醒調解的開團
    ///   - reconcile: 要執行的提醒調解
    ///   - timestamp: 使用者選定的提醒日期與時間
    ///   - calendar: 呼叫端提供的曆法與時區
    /// - Returns: 帶有全天事件日期與分鐘提示位移的提醒請求
    static func make(
        campaign: Campaign,
        reconcile: CampaignReminderReconcile,
        timestamp: Date,
        calendar: Calendar
    ) -> Self {
        let minuteOfDay = calendar.component(.hour, from: timestamp) * 60
            + calendar.component(.minute, from: timestamp)
        return Self(
            campaignID: campaign.id,
            reconcile: reconcile,
            title: campaign.reminderTitle,
            eventDate: calendar.startOfDay(for: timestamp),
            alarmOffset: TimeInterval(minuteOfDay * 60),
            timestamp: timestamp
        )
    }
}
