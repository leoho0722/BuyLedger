//
//  CampaignSavePlan.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation

/// 通過重名檢查後要寫入的開團，以及儲存後的改名與提醒意圖
struct CampaignSavePlan: Equatable, Sendable {

    // MARK: - Properties

    /// 要新增或更新的完整開團
    let campaign: Campaign

    /// 原開團改名後需要同步的訂單歸屬；無改名時為 `nil`
    let rename: Rename?

    /// 儲存與改名處理完成後的提醒調解；無需調解時為 `nil`
    let reminder: CampaignReminderRequest?
}

// MARK: - Nested Types

extension CampaignSavePlan {

    /// 訂單歸屬要替換的原名稱與新名稱
    struct Rename: Equatable, Sendable {

        /// 原開團名稱
        let from: String

        /// 儲存後的開團名稱
        let to: String
    }
}

// MARK: - Internal Method

extension CampaignSavePlan {

    /// 以表單請求組裝開團，保留結算日期並判定改名與提醒調解
    ///
    /// - Parameters:
    ///   - request: 子表單送出的原開團、去空白名稱與草稿
    ///   - existingLink: 此開團的現有提醒連結
    ///   - newID: 呼叫端產生的新開團識別值；編輯時不使用
    ///   - calendar: 換算提醒事件日期與提示位移的行事曆
    /// - Returns: 可交給寫入子 Feature 的完整儲存計畫
    static func make(
        request: CampaignEditFeature.SaveRequest,
        existingLink: CampaignReminderLink?,
        newID: Campaign.ID,
        calendar: Calendar
    ) -> Self {
        let campaign = Campaign(
            id: request.original?.id ?? newID,
            name: request.name,
            openDate: request.draft.openDate,
            closeDate: request.draft.closeDate,
            status: request.draft.status,
            settledDate: request.original?.settledDate,
            notes: request.draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        let rename = request.original.flatMap {
            $0.name == request.name ? nil : Rename(from: $0.name, to: request.name)
        }
        let reconcile = CampaignReminderReconcile.decide(
            wantsReminder: request.draft.wantsReminder,
            existingLink: existingLink,
            originalTitle: request.original?.reminderTitle,
            newTitle: campaign.reminderTitle,
            chosenTimestamp: request.draft.reminderTimestamp
        )
        let reminder = reconcile.map {
            CampaignReminderRequest.make(
                campaign: campaign,
                reconcile: $0,
                timestamp: request.draft.reminderTimestamp,
                calendar: calendar
            )
        }
        return Self(campaign: campaign, rename: rename, reminder: reminder)
    }

    /// 原名未變直接放行，其他情況以最新清單檢查不同開團的同名資料
    ///
    /// - Parameters:
    ///   - name: 已去空白的待儲存名稱
    ///   - originalName: 原開團名稱；新增時為 `nil`
    ///   - editingID: 原開團識別值；新增時為 `nil`
    ///   - campaigns: 送出當下的最新開團清單
    /// - Returns: 其他開團去空白後同名且非原名儲存時為 `true`
    static func conflicts(
        name: String,
        originalName: String?,
        editingID: Campaign.ID?,
        campaigns: [Campaign]
    ) -> Bool {
        guard name != originalName else {
            return false
        }
        return campaigns.contains {
            $0.id != editingID && $0.name.trimmingCharacters(in: .whitespacesAndNewlines) == name
        }
    }
}
