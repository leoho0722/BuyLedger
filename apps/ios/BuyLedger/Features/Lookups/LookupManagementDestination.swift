//
//  LookupManagementDestination.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import Foundation

// MARK: - Destination

extension LookupManagementFeature {
    
    /// 改名 / 編輯付款方式的呈現目的地
    @Reducer
    enum Destination {
        
        /// 重新命名 (訂單來源／商品類別／付款方式／對帳狀態皆適用)
        case rename(RenameFeature)
        
        /// 付款方式編輯資料；只在 paymentMethod 使用
        case editPaymentMethod(EditPaymentMethodFeature)
        
        /// 新增純名稱主檔項目 (訂單來源／商品類別／對帳狀態)
        case addNameOnly(AddNameOnlyFeature)
        
        /// 新增付款方式 (需同時決定分類旗標，故走獨立表單)
        case addPaymentMethod(AddPaymentMethodFeature)
    }
}

extension LookupManagementFeature.Destination.State: Equatable {}
extension LookupManagementFeature.Destination.Action: Equatable {}

// MARK: - Rename Feature

extension LookupManagementFeature.Destination {
    
    /// 重新命名表單狀態與事件
    @Reducer
    struct RenameFeature {
        
        // MARK: - State
        
        /// 重新命名表單狀態
        @ObservableState
        struct State: Equatable {
            
            /// 原始名稱
            let originalName: String
            
            /// 使用者輸入的新名稱草稿
            var draft: String
            
            // MARK: - Computed Properties
            
            /// 草稿去除前後空白後非空，且名稱已變更
            var canSave: Bool {
                let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                return !trimmed.isEmpty && trimmed != originalName
            }
        }
        
        // MARK: - Action
        
        /// 重新命名表單可處理的事件
        enum Action: Equatable {
            
            /// 使用者編輯草稿文字
            case draftChanged(String)
            
            /// 使用者確認編輯後送出表單結果
            case saveButtonTapped
        }
        
        // MARK: - Reducer Body
        
        /// 重新命名表單 reducer，只更新草稿
        var body: some Reducer<State, Action> {
            Reduce { state, action in
                switch action {
                case let .draftChanged(draft):
                    state.draft = draft
                    return .none
                    
                case .saveButtonTapped:
                    return .none
                }
            }
        }
    }
}

// MARK: - Edit Payment Method Feature

extension LookupManagementFeature.Destination {
    
    /// 付款方式編輯狀態，保存進入時的分類旗標
    @Reducer
    struct EditPaymentMethodFeature {
        
        // MARK: - State
        
        /// 付款方式編輯狀態，保存進入時的分類旗標
        @ObservableState
        struct State: Equatable {
            
            /// 原始付款方式名稱
            let originalName: String
            
            /// 進入編輯當下的付款方式分類旗標快照
            let flags: PaymentMethodFlags
        }
        
        // MARK: - Action
        
        /// 編輯付款方式表單可處理的事件
        enum Action: Equatable {
            
            /// 使用者確認編輯後送出表單結果
            case saveButtonTapped(
                name: String,
                flags: PaymentMethodFlags
            )
        }
        
        // MARK: - Reducer Body
        
        /// 付款方式表單 reducer；寫入由父層處理
        var body: some Reducer<State, Action> {
            Reduce { _, _ in
                    .none
            }
        }
    }
}

// MARK: - Add Name Only Feature

extension LookupManagementFeature.Destination {
    
    /// 新增純名稱主檔項目的表單狀態與事件
    @Reducer
    struct AddNameOnlyFeature {
        
        // MARK: - State
        
        /// 新增表單狀態
        @ObservableState
        struct State: Equatable {}
        
        // MARK: - Action
        
        /// 新增表單可處理的事件
        enum Action: Equatable {
            
            /// 使用者確認新增後送出名稱
            case saveButtonTapped(name: String)
        }
        
        // MARK: - Reducer Body
        
        /// 新增表單 reducer；實際寫入 domain effect 由父層攔截 `saveButtonTapped` 處理
        var body: some Reducer<State, Action> {
            Reduce { _, _ in
                    .none
            }
        }
    }
}

// MARK: - Add Payment Method Feature

extension LookupManagementFeature.Destination {
    
    /// 新增付款方式的表單狀態與事件
    @Reducer
    struct AddPaymentMethodFeature {
        
        // MARK: - State
        
        /// 新增付款方式表單狀態
        @ObservableState
        struct State: Equatable {}
        
        // MARK: - Action
        
        /// 新增付款方式表單可處理的事件
        enum Action: Equatable {
            
            /// 使用者確認新增後送出名稱
            case saveButtonTapped(
                name: String,
                flags: PaymentMethodFlags
            )
        }
        
        // MARK: - Reducer Body
        
        /// 新增付款方式表單 reducer
        var body: some Reducer<State, Action> {
            Reduce { _, _ in
                    .none
            }
        }
    }
}
