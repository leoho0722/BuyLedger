//
//  OrderStatusFilter.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 訂單列表可使用的狀態篩選
enum OrderStatusFilter: Hashable, Identifiable {
    
    // MARK: - Cases
    
    /// 顯示全部訂單
    case all
    
    /// 顯示指定狀態的訂單
    case status(OrderStatus)
    
    // MARK: - Identifiable Properties
    
    /// 篩選選項的穩定識別值
    var id: String {
        switch self {
        case .all:
            "all"
        case let .status(status):
            status.rawValue
        }
    }
    
    // MARK: - Static Properties
    
    /// 第一階段訂單列表使用的篩選選項
    static let orderBrowsingCases: [OrderStatusFilter] = [
        .all,
        .status(.quoting),
        .status(.confirmed),
        .status(.purchased),
        .status(.shipping),
        .status(.partiallyArrived),
        .status(.arrived),
        .status(.delivered),
        .status(.pickedUp),
        .status(.merged),
    ]
    
    /// 集運中訂單的快捷篩選
    static let shipping = OrderStatusFilter.status(.shipping)
    
    // MARK: - Computed Properties
    
    /// 篩選對應的訂單狀態
    var orderStatus: OrderStatus? {
        switch self {
        case .all:
            nil
        case let .status(status):
            status
        }
    }
    
    // MARK: - Display Properties
    
    /// 顯示在篩選列中的標題
    var title: String {
        switch self {
        case .all:
            "全部"
        case let .status(status):
            status.title
        }
    }
}
