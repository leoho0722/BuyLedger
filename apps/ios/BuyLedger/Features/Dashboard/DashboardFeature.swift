//
//  DashboardFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture
import Foundation

/// 總覽分頁功能，提供訂單、開團與月獲利目標的唯讀投影
@Reducer
struct DashboardFeature {
    
    // MARK: - State
    
    /// 總覽功能狀態
    @ObservableState
    struct State: Equatable {
        
        /// 訂單投影；由 ``RootFeature`` 與 ``OrdersFeature/State/orders`` 保持同步
        var orders: [LedgerOrder] = []
        
        /// 開團投影；由 ``RootFeature`` 與 ``CampaignFeature/State/campaigns`` 保持同步
        var campaigns: [Campaign] = []
        
        /// 月獲利目標
        var monthlyProfitGoalTwd: Decimal = 80_000
        
        /// 訂單載入狀態
        var loadState: OrdersFeature.State.LoadState = .loading
    }
    
    // MARK: - Action
    
    /// 總覽功能可處理的事件
    @CasePathable
    enum Action: Equatable {
        
        /// 畫面出現時觸發載入
        case task
        
        /// 使用者點擊載入失敗畫面的重試鈕
        case retryTapped
        
        /// 由根功能轉發的跨功能意圖
        case delegate(Delegate)
        
        /// 總覽可能發出的跨 feature 意圖
        @CasePathable
        enum Delegate: Equatable {
            
            /// 重新載入訂單與設定
            case refresh
            
            /// 使用者點擊進行中開團卡，帶開團名稱
            case campaignTapped(String)
            
            /// 使用者點擊「建立第一筆訂單」
            case newOrderTapped
            
            /// 使用者點擊「查看全部」訂單
            case viewAllOrdersTapped
        }
    }
    
    // MARK: - Reducer Body
    
    /// 總覽功能 reducer
    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .task, .retryTapped:
                return .send(.delegate(.refresh))
                
            case .delegate:
                return .none
            }
        }
    }
}
