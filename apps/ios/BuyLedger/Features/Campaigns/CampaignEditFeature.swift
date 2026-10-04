//
//  CampaignEditFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import Foundation

/// 新增或編輯開團 (Campaign) 的表單功能
@Reducer
struct CampaignEditFeature {

    // MARK: - State

    /// 編輯與新增開團表單的狀態
    @ObservableState
    struct State: Equatable, Identifiable, Sendable {

        /// 原始開團；`nil` 代表新增流程
        let original: Campaign?

        /// 目前取得鍵盤焦點的欄位；`nil` 代表無焦點
        var focusedField: Field?

        /// 納入未儲存變更判斷的七個草稿欄位
        var draft: CampaignDraft

        /// 父層拒絕儲存的原因；`nil` 表示沒有錯誤
        var nameConflictMessage: String?

        /// 捨棄未儲存變更的確認彈窗
        @Presents var discardConfirmation: AlertState<Action.DiscardAlert>? = nil

        /// 表單的穩定識別值，供 SwiftUI sheet item 使用
        let id: UUID

        /// 開啟表單時的初始草稿，用於判斷是否變更
        let initialDraft: CampaignDraft

        /// 名稱欄位綁定的草稿名稱；畫面綁這個屬性，改名時才能清除過期的重名訊息
        var draftName: String {
            get {
                draft.name
            }
            set {
                draft.name = newValue
            }
        }

        /// 草稿是否有未儲存變更
        var isDirty: Bool {
            draft != initialDraft
        }

        /// 名稱去掉頭尾空白後是否可送出，重名由父層驗證
        var canSave: Bool {
            !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        /// 依原始開團建立草稿狀態
        ///
        /// - Parameters:
        ///   - original: 要編輯的開團；`nil` 表示新增
        ///   - id: 表單識別值
        ///   - currentDate: 新開團日期與表單預設值使用的時間
        ///   - wantsReminder: 是否建立訂購提醒
        ///   - reminderTimestamp: 訂購提醒時間
        init(
            original: Campaign? = nil,
            id: UUID,
            currentDate: Date,
            wantsReminder: Bool = false,
            reminderTimestamp: Date
        ) {
            self.original = original
            let draft = CampaignDraft(
                original: original,
                currentDate: currentDate,
                wantsReminder: wantsReminder,
                reminderTimestamp: reminderTimestamp
            )
            self.draft = draft
            self.initialDraft = draft
            self.id = id
        }

        /// 依原始開團與提醒連結建立草稿狀態，並決定提醒開關與提醒時間
        ///
        /// - Parameters:
        ///   - original: 要編輯的開團；`nil` 表示新增
        ///   - link: 原始開團目前的提醒連結；`nil` 表示沒有提醒
        ///   - id: 表單識別值
        ///   - now: 新開團日期、表單預設值與預設提醒時間使用的現在時間
        ///   - calendar: 換算預設提醒時間的曆法與時區
        /// - Note: 有連結時開啟提醒並沿用連結的時間，否則取結單日 (新開團取今天) 的上午九點
        init(
            original: Campaign? = nil,
            link: CampaignReminderLink? = nil,
            id: UUID,
            now: Date,
            calendar: Calendar
        ) {
            self.init(
                original: original,
                id: id,
                currentDate: now,
                wantsReminder: link != nil,
                reminderTimestamp: link?.reminderTimestamp
                    ?? CampaignReminderRequest.defaultTimestamp(
                        closeDate: original?.closeDate,
                        now: now,
                        calendar: calendar
                    )
            )
        }

        /// 表單可取得焦點的欄位，依畫面的視覺順序宣告
        enum Field: Hashable {

            /// 開團名稱
            case name

            /// 備註
            case notes
        }
    }

    // MARK: - Action

    /// 表單可處理的事件
    enum Action: BindableAction, Equatable {

        /// SwiftUI 雙向繫結事件
        ///
        /// - Parameter action: 要更新的欄位與值
        case binding(BindingAction<State>)

        /// 使用者在表單上的操作
        ///
        /// - Parameter action: 儲存或取消的操作
        case view(View)

        /// 交給父層驗證與處理的儲存意圖
        ///
        /// - Parameter action: 要交給父層的請求
        case delegate(Delegate)

        /// 有未儲存變更時的捨棄確認事件
        ///
        /// - Parameter action: 捨棄確認的呈現或選項事件
        case discardConfirmation(PresentationAction<DiscardAlert>)

        /// 使用者在表單上的操作
        @CasePathable
        enum View: Equatable {

            /// 使用者按下儲存
            case saveButtonTapped

            /// 使用者按下取消
            case cancelButtonTapped
        }

        /// 要交給父層處理的請求
        @CasePathable
        enum Delegate: Equatable {

            /// 名稱有效，請父層驗證重名後儲存
            ///
            /// - Parameter request: 原開團、去空白名稱與完整草稿
            case saveRequested(SaveRequest)
        }

        /// 捨棄確認彈窗的選項
        @CasePathable
        enum DiscardAlert: Equatable {

            /// 確認捨棄未儲存變更並關閉表單
            case discard
        }
    }

    // MARK: - Dependencies

    /// 由父層注入的關閉效果
    @Dependency(\.dismiss) private var dismiss

    // MARK: - Body

    /// 組合繫結、表單邏輯與捨棄確認
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce(core)
            .ifLet(\.$discardConfirmation, action: \.discardConfirmation)
    }
}

// MARK: - Nested Types

extension CampaignEditFeature {

    /// 子層名稱驗證通過後交給父層的完整儲存意圖
    struct SaveRequest: Equatable, Sendable {

        /// 原開團；`nil` 表示新增
        let original: Campaign?

        /// 已去掉頭尾空白的開團名稱
        let name: String

        /// 完整草稿，保留表單輸入與提醒意圖
        let draft: CampaignDraft
    }
}

// MARK: - Private Method

private extension CampaignEditFeature {

    /// 處理表單驗證、送出與取消，重名判定留給父層
    ///
    /// - Parameters:
    ///   - state: 要更新的表單狀態
    ///   - action: 要處理的表單事件
    /// - Returns: 儲存請求或關閉表單的效果
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding(\.draftName):
            state.nameConflictMessage = nil
            return .none

        case .binding:
            return .none

        case .view(.saveButtonTapped):
            let name = state.draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                return .none
            }
            let request = SaveRequest(original: state.original, name: name, draft: state.draft)
            return .send(.delegate(.saveRequested(request)))

        case .view(.cancelButtonTapped):
            return closeForm(state: &state)

        case .delegate:
            return .none

        case .discardConfirmation(.presented(.discard)):
            return .run { _ in
                await dismiss()
            }

        case .discardConfirmation:
            return .none
        }
    }

    /// 關閉表單；有未儲存變更時先要求使用者確認捨棄
    ///
    /// - Parameter state: 要更新的表單狀態
    /// - Returns: 沒有變更時為關閉表單的效果，有變更時不執行任何效果
    func closeForm(state: inout State) -> Effect<Action> {
        guard state.isDirty else {
            return .run { _ in
                await dismiss()
            }
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
    }
}
