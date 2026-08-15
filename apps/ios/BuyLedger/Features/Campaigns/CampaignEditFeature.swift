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
    
    /// 編輯／新增開團表單的狀態
    @ObservableState
    struct State: Equatable, Identifiable, Sendable {
        
        /// 原始開團；`nil` 代表「新開團」流程
        let original: Campaign?
        
        /// 目前取得鍵盤焦點的欄位；`nil` 代表無焦點
        var focusedField: Field?
        
        /// 表單草稿：收斂 7 個納入未儲存變更判斷的欄位 (見 ``CampaignDraft``)
        var draft: CampaignDraft
        
        /// 儲存被拒絕的原因；`nil` 表示沒有錯誤
        var nameConflictMessage: String?
        
        /// 捨棄未儲存變更的確認彈窗
        @Presents var discardConfirmation: AlertState<Action.DiscardAlert>? = nil
        
        // MARK: - Identifiable Properties
        
        /// 表單 instance 的穩定識別值，供 SwiftUI sheet item 使用
        let id: UUID
        
        /// 開啟表單時的初始草稿，用於判斷是否變更
        let initialDraft: CampaignDraft
        
        // MARK: - Init
        
        /// 依原始開團建立草稿狀態
        /// - Parameters:
        ///   - original: 要編輯的開團；`nil` 表示新開團
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
            // 初始草稿同時作為目前草稿與比較基準
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
        
        // MARK: - Computed Properties
        
        /// 草稿是否有未儲存變更
        var isDirty: Bool {
            draft != initialDraft
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
            case .binding(\.draft.name):
                // 重新編輯名稱時清掉舊的重複名稱錯誤，避免修正後仍殘留過期訊息
                state.nameConflictMessage = nil
                return .none
                
            case .binding:
                return .none
                
            case .saveTapped:
                // 唯一性檢查與儲存由父層處理
                // 驗證通過後父層才關閉表單，本地不再自行 dismiss
                return .none
                
            case .cancelTapped:
                // 有未儲存變更時先確認捨棄。
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
    
    /// 表單中可取得鍵盤焦點的欄位；case 依畫面上的視覺順序宣告
    enum Field: Hashable {
        
        // MARK: - Cases
        
        /// 開團名稱
        case name
        
        /// 備註
        case notes
    }
}

/// 開團編輯表單的草稿值型別，收斂納入未儲存變更判斷的 7 個欄位
@ObservableState
struct CampaignDraft: Equatable, Sendable {
    
    // MARK: - Data Properties
    
    /// 開團名稱草稿
    var name: String
    
    /// 開團日期草稿
    var openDate: Date
    
    /// 結單日期；過期時狀態改為 closed
    var closeDate: Date
    
    /// 開團狀態草稿
    var status: CampaignStatus
    
    /// 開團備註草稿
    var notes: String
    
    /// 是否建立訂購提醒；儲存時由 CampaignFeature 處理
    var wantsReminder: Bool
    
    /// 訂購提醒時間；儲存時轉成行事曆事件
    var reminderTimestamp: Date
    
    // MARK: - Init
    
    /// 依原始開團建立草稿；`original` 為 `nil` 時各欄位採新開團預設值
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
