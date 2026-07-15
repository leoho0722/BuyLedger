//
//  CampaignEditFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import Foundation

/// 新增或編輯開團 (Campaign) 的表單功能
///
/// 僅持有草稿欄位；`saveTapped` 與 `cancelTapped` 皆觸發 dismiss，實際的寫入與 cascade 由父層 ``CampaignFeature`` 攔截 `saveTapped` 處理
@Reducer
struct CampaignEditFeature {

    // MARK: - State

    /// 編輯／新增開團表單的狀態
    @ObservableState
    struct State: Equatable, Identifiable, Sendable {

        /// 原始開團；`nil` 代表「新開團」流程
        let original: Campaign?

        /// 開團名稱草稿
        var draftName: String

        /// 開團日期草稿
        var draftOpenDate: Date

        /// 結單日期草稿 (必填)；當結單日早於「現在」時，狀態會自動由 ``CampaignStatus/ongoing`` 轉為 ``CampaignStatus/closed``
        var draftCloseDate: Date

        /// 開團狀態草稿
        var draftStatus: CampaignStatus

        /// 開團備註草稿
        var draftNotes: String

        /// 是否要為此開團建立訂購提醒的意圖；僅切換意圖、不觸碰行事曆，實際建立／移除由父層 ``CampaignFeature`` 在儲存時 reconcile
        var wantsReminder: Bool

        /// 訂購提醒的時間戳 (日期＋提示時間)；意圖開啟時由使用者在 popup 選定，儲存時換算全天事件日期與提示位移
        var reminderTimestamp: Date

        /// popup 內暫存的提醒時間戳；按「加入提醒／完成」才提交回 ``reminderTimestamp``，「取消」不提交
        var draftReminderTimestamp: Date

        /// 是否呈現日期＋時間選擇 popup
        var isReminderPickerPresented: Bool

        // MARK: - Identifiable Properties

        /// 表單 instance 的穩定識別值，供 SwiftUI sheet item 使用
        let id: UUID

        // MARK: - Init

        /// 依原始開團建立草稿狀態
        /// - Parameters:
        ///   - original: 要編輯的開團；`nil` 表示新開團
        ///   - id: 表單 instance 的穩定識別值；caller 應從 `@Dependency(\.uuid)` 取得以維持可測試性
        ///   - currentDate: 新開團時 ``draftOpenDate`` 與 ``draftCloseDate`` 的預設值；caller 應從 `@Dependency(\.date)` 取得當下時間以維持可測試性
        ///   - wantsReminder: 是否要建立訂購提醒的初始意圖；新開團預設 `false`，編輯既有開團時由 caller 依「該開團目前是否已有提醒」帶入
        ///   - reminderTimestamp: 提醒時間戳 (日期＋提示時間) 初值；由 caller 依每團現有設定 (無則預設結單日/今天 09:00) 帶入
        init(
            original: Campaign? = nil,
            id: UUID,
            currentDate: Date,
            wantsReminder: Bool = false,
            reminderTimestamp: Date
        ) {
            self.original = original
            self.draftName = original?.name ?? ""
            self.draftOpenDate = original?.openDate ?? currentDate
            self.draftCloseDate = original?.closeDate ?? currentDate
            self.draftStatus = original?.status ?? .ongoing
            self.draftNotes = original?.notes ?? ""
            self.wantsReminder = wantsReminder
            self.reminderTimestamp = reminderTimestamp
            self.draftReminderTimestamp = reminderTimestamp
            self.isReminderPickerPresented = false
            self.id = id
        }
    }

    // MARK: - Action

    /// 表單可處理的事件
    @CasePathable
    enum Action: BindableAction, Equatable {

        /// SwiftUI 雙向繫結事件
        case binding(BindingAction<State>)

        /// 使用者按下取消
        case cancelTapped

        /// 使用者按下儲存
        case saveTapped

        /// 使用者點「新增提醒」或提醒時間列，開啟日期＋時間選擇 popup
        case reminderPickerRequested

        /// 使用者點「移除提醒」，清除提醒意圖
        case removeReminderTapped

        /// popup 按「加入提醒／完成」，提交草稿時間戳並開啟意圖
        case reminderPickerConfirmed

        /// popup 取消，關閉不提交
        case reminderPickerCancelled
    }

    // MARK: - Dependency Properties

    /// 由父層注入的 dismiss effect
    @Dependency(\.dismiss) private var dismiss

    // MARK: - Reducer Body

    /// 表單 reducer
    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .cancelTapped, .saveTapped:
                return .run { _ in await dismiss() }

            case .reminderPickerRequested:
                state.draftReminderTimestamp = state.reminderTimestamp
                state.isReminderPickerPresented = true
                return .none

            case .removeReminderTapped:
                state.wantsReminder = false
                return .none

            case .reminderPickerConfirmed:
                state.reminderTimestamp = state.draftReminderTimestamp
                state.wantsReminder = true
                state.isReminderPickerPresented = false
                return .none

            case .reminderPickerCancelled:
                state.isReminderPickerPresented = false
                return .none
            }
        }
    }
}
