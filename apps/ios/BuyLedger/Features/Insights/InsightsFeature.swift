//
//  InsightsFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture
import Foundation

/// 分析分頁功能，提供唯讀資料與區間選擇
@Reducer
struct InsightsFeature {
    
    // MARK: - State
    
    /// 分析功能狀態
    @ObservableState
    struct State: Equatable {
        
        /// 訂單投影；由 ``RootFeature`` 與 ``OrdersFeature/State/orders`` 保持同步
        var orders: [LedgerOrder] = []
        
        /// 開團投影；由 ``RootFeature`` 與 ``CampaignFeature/State/campaigns`` 保持同步
        var campaigns: [Campaign] = []
        
        /// 訂單載入狀態
        var loadState: OrdersFeature.State.LoadState = .loading
        
        /// 目前選取的趨勢期間
        var insightsDateRange: InsightsDateRange = .twelveMonths
    }
    
    // MARK: - Action
    
    /// 分析功能可處理的事件
    @CasePathable
    enum Action: BindableAction, Equatable {
        
        /// SwiftUI 雙向繫結事件 (分析區間 segmented picker)
        case binding(BindingAction<State>)
        
        /// 畫面出現時觸發載入
        case task
        
        /// 使用者點擊載入失敗畫面的重試鈕
        case retryTapped
        
        /// 由根功能轉發的跨功能意圖
        case delegate(Delegate)
        
        /// 分析頁可能發出的跨 feature 意圖
        @CasePathable
        enum Delegate: Equatable {
            
            /// 要求重新載入
            case refresh
            
            /// 使用者點擊每團毛利排行的某一團，帶開團名稱
            case campaignTapped(String)
            
            /// 使用者點擊類別排行的某個類別，帶類別名稱
            case categoryTapped(String)
        }
    }
    
    // MARK: - Reducer Body
    
    /// 分析功能 reducer
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { _, action in
            switch action {
            case .binding:
                return .none
                
            case .task, .retryTapped:
                return .send(.delegate(.refresh))
                
            case .delegate:
                return .none
            }
        }
    }
}
