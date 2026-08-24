//
//  OrderDetailPath.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/12.
//

import ComposableArchitecture
import Foundation

/// ``OrdersFeature/State/detailPath`` 的最小堆疊元素
@Reducer
struct OrderDetailPath {
    
    // MARK: - State
    
    /// 堆疊中單一詳情頁的狀態
    @ObservableState
    struct State: Equatable {
        
        /// 對應顯示的訂單編號
        let orderID: LedgerOrder.ID
    }
    
    // MARK: - Action
    
    /// 詳情操作由 OrdersFeature 處理
    enum Action: Equatable {}
    
    // MARK: - Reducer Body
    
    /// 純展示元素，無自訂邏輯
    var body: some Reducer<State, Action> {
        EmptyReducer()
    }
}
