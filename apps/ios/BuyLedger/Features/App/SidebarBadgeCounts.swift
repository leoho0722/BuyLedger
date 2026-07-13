//
//  SidebarBadgeCounts.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation

/// iPad 側邊欄「訂單」分頁與智慧分組的徽章計數
///
/// 完全 derive 自訂單清單的純函式，供 ``RootSidebarLayout`` 呼叫並可獨立測試
enum SidebarBadgeCounts {

    // MARK: - Static Properties

    /// 視為「進行中」(已確認 / 已下單 / 集運中 / 部分到貨 / 已到貨) 的訂單狀態集合
    static let activeStatuses: Set<OrderStatus> = [
        .confirmed, .purchased, .shipping, .partiallyArrived, .arrived,
    ]
}

// MARK: - Internal Method

extension SidebarBadgeCounts {

    /// 目前進行中的訂單數量，顯示在側邊欄「訂單」分頁的紅色徽章
    /// - Parameter orders: 目前的訂單清單
    /// - Returns: 進行中的訂單數量
    static func activeOrderCount(orders: [LedgerOrder]) -> Int {
        orders.lazy
            .filter { activeStatuses.contains($0.status) }
            .count
    }

    /// 計算指定狀態的訂單數量，顯示在側邊欄「智慧分組」各列
    /// - Parameters:
    ///   - status: 要計算的狀態
    ///   - orders: 目前的訂單清單
    /// - Returns: 該狀態的訂單數量
    static func orderCount(for status: OrderStatus, orders: [LedgerOrder]) -> Int {
        orders.lazy
            .filter { $0.status == status }
            .count
    }
}
