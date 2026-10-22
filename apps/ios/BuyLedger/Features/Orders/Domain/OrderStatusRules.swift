//
//  OrderStatusRules.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/7.
//

/// 訂單畫面共用的狀態選項與合併資格規則
enum OrderStatusRules {

}

// MARK: - Internal Method

extension OrderStatusRules {

    /// 保留原有狀態順序，僅已合併訂單可選取已合併
    ///
    /// - Parameter status: 訂單目前狀態
    /// - Returns: 此訂單的可選狀態
    static func selectableStatuses(for status: OrderStatus) -> [OrderStatus] {
        OrderStatus.allCases.filter { $0 != .merged || status == .merged }
    }

    /// 判斷訂單是否可進入合併流程
    ///
    /// - Parameter status: 訂單目前狀態
    /// - Returns: 未合併且未取消時為可合併
    static func canMerge(status: OrderStatus) -> Bool {
        status != .merged && status != .cancelled
    }
}
