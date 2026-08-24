//
//  CustomersFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/12.
//

import ComposableArchitecture
import Foundation

/// 客戶名單畫面顯示用的彙總列
struct CustomerRow: Equatable, Identifiable, Sendable {
    
    // MARK: - Identifiable Properties
    
    /// 用客戶姓名當識別值 (同名客戶會被聚合成一筆)
    var id: String { name }
    
    // MARK: - Data Properties
    
    /// 客戶姓名
    let name: String
    
    /// 顯示在頭像上的姓名縮寫
    let initials: String
    
    /// 客戶分級
    let tier: CustomerTier
    
    /// 依營收歸屬口徑計入的訂單筆數
    let orderCount: Int
    
    /// 累計消費 (NT$)
    let totalSpent: Decimal
    
    /// 最近一筆訂單的日期
    let lastOrderDate: Date
}

// MARK: - Internal Method

extension CustomerRow {
    
    /// 依營收歸屬規則彙總訂單；取消與報價中客戶仍保留
    /// - Parameter orders: 目前訂單清單
    /// - Returns: 依累計消費由高到低排序的客戶列
    static func aggregate(orders: [LedgerOrder]) -> [CustomerRow] {
        let grouped = Dictionary(grouping: orders, by: { $0.customer.name })
        let contributingIDs = Set(LedgerOrder.revenueAttributionOrders(from: orders).map(\.id))
        
        return grouped
            .compactMap { name, list -> CustomerRow? in
                guard let first = list.first else {
                    return nil
                }
                let contributing = list.filter { contributingIDs.contains($0.id) }
                let totalSpent = contributing.reduce(Decimal.zero) { $0 + $1.summary.revenue }
                let lastDate = list.map(\.date).max() ?? first.date
                
                return CustomerRow(
                    name: name,
                    initials: first.customer.initials,
                    tier: first.customer.tier,
                    orderCount: contributing.count,
                    totalSpent: totalSpent,
                    lastOrderDate: lastDate
                )
            }
            .sorted { $0.totalSpent > $1.totalSpent }
    }
}

/// 客戶彙總功能，提供訂單投影與客戶消費摘要
@Reducer
struct CustomersFeature {
    
    // MARK: - State
    
    /// 客戶彙總功能狀態
    @ObservableState
    struct State: Equatable {
        
        /// 來源訂單；由 ``RootFeature`` 與 ``OrdersFeature/State/orders`` 保持同步
        var orders: [LedgerOrder] = []
        
        /// 依累計消費由高到低排序的客戶彙總列
        var customers: [CustomerRow] {
            CustomerRow.aggregate(orders: orders)
        }
    }
    
    // MARK: - Action
    
    /// 客戶彙總功能可處理的事件
    @CasePathable
    enum Action: Equatable {
        
        /// 畫面出現時觸發訂單載入
        case task
        
        /// 由根功能轉發的跨功能意圖
        case delegate(Delegate)
        
        /// 客戶名單可能發出的跨 feature 意圖
        @CasePathable
        enum Delegate: Equatable {
            
            /// 使用者點擊客戶列或強調卡，帶客戶姓名
            case customerTapped(String)
        }
    }
    
    // MARK: - Reducer Body
    
    /// 客戶彙總功能 reducer；``task`` 由 ``RootFeature`` 攔截處理，本身不需回應
    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .task:
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}
