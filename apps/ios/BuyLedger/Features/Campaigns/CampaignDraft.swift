//
//  CampaignDraft.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation

/// 開團編輯表單的草稿值型別，收斂納入未儲存變更判斷的 7 個欄位
@ObservableState
struct CampaignDraft: Equatable, Sendable {

    // MARK: - Properties

    /// 開團名稱草稿
    var name: String

    /// 開團日期草稿
    var openDate: Date

    /// 結單日期；過期時狀態改為 `.closed`
    var closeDate: Date

    /// 開團狀態草稿
    var status: CampaignStatus

    /// 開團備註草稿
    var notes: String

    /// 是否建立訂購提醒；儲存時由 `CampaignFeature` 處理
    var wantsReminder: Bool

    /// 訂購提醒時間；儲存時轉成行事曆事件
    var reminderTimestamp: Date

    // MARK: - Init

    /// 依原始開團建立草稿；`original` 為 `nil` 時各欄位採新開團預設值
    ///
    /// - Parameters:
    ///   - original: 要編輯的開團；`nil` 表示新開團
    ///   - currentDate: 新開團日期與表單預設值使用的時間
    ///   - wantsReminder: 是否建立訂購提醒
    ///   - reminderTimestamp: 訂購提醒時間
    init(
        original: Campaign?,
        currentDate: Date,
        wantsReminder: Bool,
        reminderTimestamp: Date
    ) {
        self.name = original?.name ?? ""
        self.openDate = original?.openDate ?? currentDate
        self.closeDate = original?.closeDate ?? currentDate
        self.status = original?.status ?? .ongoing
        self.notes = original?.notes ?? ""
        self.wantsReminder = wantsReminder
        self.reminderTimestamp = reminderTimestamp
    }
}
