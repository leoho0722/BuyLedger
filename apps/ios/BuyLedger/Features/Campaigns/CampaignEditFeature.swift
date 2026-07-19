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

        /// 訂購提醒的時間戳 (日期＋提示時間)；意圖開啟時由使用者以表單內 inline `DatePicker` 直接編輯，儲存時換算全天事件日期與提示位移
        var reminderTimestamp: Date

        /// 有未儲存變更時，取消所觸發的「捨棄變更／繼續編輯」確認彈窗；`nil` 代表未顯示
        ///
        /// 採 `AlertState` (centered modal) 而非 `ConfirmationDialogState`：取消是 toolbar 按鈕，iOS 26 起 `.confirmationDialog` 對 toolbar 觸發會位置偏移
        @Presents var discardConfirmation: AlertState<Action.DiscardAlert>? = nil

        // MARK: - Identifiable Properties

        /// 表單 instance 的穩定識別值，供 SwiftUI sheet item 使用
        let id: UUID

        /// 表單開啟當下的草稿指紋；與 ``draftFingerprint`` 比對得出 ``isDirty``，供未儲存變更關閉確認使用
        let initialDraftFingerprint: DraftFingerprint

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
            self.id = id

            // 初始指紋＝表單開啟時的基準 (original 或新開團預設；提醒意圖由 caller 帶入)，與 ``draftFingerprint`` 比對得出 dirty
            // 各欄位運算式須與上方 draft 的初始賦值保持一致
            self.initialDraftFingerprint = DraftFingerprint(
                name: original?.name ?? "",
                openDate: original?.openDate ?? currentDate,
                closeDate: original?.closeDate ?? currentDate,
                status: original?.status ?? .ongoing,
                notes: original?.notes ?? "",
                wantsReminder: wantsReminder,
                reminderTimestamp: reminderTimestamp
            )
        }

        // MARK: - Computed Properties

        /// 目前草稿指紋；涵蓋全部可儲存草稿欄位 (含提醒意圖與時間戳)，與 ``initialDraftFingerprint`` 比對得出 ``isDirty``
        var draftFingerprint: DraftFingerprint {
            DraftFingerprint(
                name: draftName,
                openDate: draftOpenDate,
                closeDate: draftCloseDate,
                status: draftStatus,
                notes: draftNotes,
                wantsReminder: wantsReminder,
                reminderTimestamp: reminderTimestamp
            )
        }

        /// 草稿是否已被修改：目前草稿指紋與開啟時的初始指紋不同即為 `true`；供未儲存變更下滑關閉確認判斷
        var isDirty: Bool {
            draftFingerprint != initialDraftFingerprint
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

        /// 有未儲存變更時、取消所觸發的捨棄確認彈窗事件
        case discardConfirmation(PresentationAction<DiscardAlert>)

        /// 捨棄確認彈窗的選項
        @CasePathable
        enum DiscardAlert: Equatable {

            /// 使用者確認捨棄未儲存的變更並關閉表單
            case discard
        }
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

            case .saveTapped:
                return .run { _ in await dismiss() }

            case .cancelTapped:
                // 有未儲存變更時先以彈窗確認、避免下滑或取消靜默遺失草稿；無變更則直接關閉
                guard state.isDirty else {
                    return .run { _ in await dismiss() }
                }

                state.discardConfirmation = AlertState {
                    TextState("捨棄變更")
                } actions: {
                    ButtonState(role: .destructive, action: .discard) {
                        TextState("捨棄變更")
                    }
                    ButtonState(role: .cancel) {
                        TextState("繼續編輯")
                    }
                } message: {
                    TextState("這個開團有尚未儲存的變更，離開後將不會保留。")
                }
                return .none

            case .discardConfirmation(.presented(.discard)):
                return .run { _ in await dismiss() }

            case .discardConfirmation:
                return .none
            }
        }
        .ifLet(\.$discardConfirmation, action: \.discardConfirmation)
    }
}

// MARK: - Nested Types

extension CampaignEditFeature.State {

    /// 開團編輯草稿的指紋：聚合全部可儲存欄位 (含提醒意圖)，供 dirty 判斷偵測未儲存變更
    ///
    /// 集中定義所有草稿欄位；日後新增草稿欄位時須同步補進此型別，否則該欄位的變更不會被 ``CampaignEditFeature/State/isDirty`` 偵測
    struct DraftFingerprint: Equatable {

        // MARK: - Data Properties

        let name: String
        let openDate: Date
        let closeDate: Date
        let status: CampaignStatus
        let notes: String
        let wantsReminder: Bool
        let reminderTimestamp: Date
    }
}
