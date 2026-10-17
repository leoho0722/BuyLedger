//
//  CampaignReminderReconcile.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation

/// 依使用者的提醒意圖與既有事件內容決定建立、移除或重建
enum CampaignReminderReconcile: Equatable, Sendable {

    /// 建立新的提醒事件
    case create

    /// 移除目前連結的提醒事件
    ///
    /// - Parameter eventIdentifier: 要移除的系統行事曆事件識別碼
    case remove(eventIdentifier: String)

    /// 先建立新提醒事件，成功後再移除舊事件
    ///
    /// - Parameter oldEventIdentifier: 新事件建立成功後要移除的舊事件識別碼
    case rebuild(oldEventIdentifier: String)
}

// MARK: - Internal Method

extension CampaignReminderReconcile {

    /// 依提醒意圖與既有內容判定調解，沒有原開團時不把標題視為變更
    ///
    /// - Parameters:
    ///   - wantsReminder: 使用者是否要保留提醒
    ///   - existingLink: 此開團目前連結的事件與提醒時間
    ///   - originalTitle: 原開團的提醒標題；沒有原開團時為 `nil`
    ///   - newTitle: 儲存後的提醒標題
    ///   - chosenTimestamp: 使用者選定的提醒時間戳
    /// - Returns: 要執行的提醒調解；內容不需變更時為 `nil`
    static func decide(
        wantsReminder: Bool,
        existingLink: CampaignReminderLink?,
        originalTitle: String?,
        newTitle: String,
        chosenTimestamp: Date
    ) -> Self? {
        guard let existingLink else {
            return wantsReminder ? .create : nil
        }
        guard wantsReminder else {
            return .remove(eventIdentifier: existingLink.eventIdentifier)
        }
        let hasTitleChanged = originalTitle.map { $0 != newTitle } ?? false
        if hasTitleChanged || existingLink.reminderTimestamp != chosenTimestamp {
            return .rebuild(oldEventIdentifier: existingLink.eventIdentifier)
        }
        return nil
    }
}
