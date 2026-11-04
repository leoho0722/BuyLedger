//
//  OrdersDetailSelection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture

/// 訂單詳情路徑的查詢與堆疊操作，只接收唯讀訂單及導覽子狀態
enum OrdersDetailSelection {}

// MARK: - Internal Method

extension OrdersDetailSelection {

    /// 經唯一入口開啟指定訂單；重開目前唯一詳情時保留元素，其餘情況取代詳情路徑
    ///
    /// - Parameters:
    ///   - orderID: 要顯示的訂單識別值
    ///   - orders: 共用訂單的唯讀引用
    ///   - path: 訂單詳情導覽路徑
    static func showDetail(
        orderID: LedgerOrder.ID,
        orders: SharedReader<[LedgerOrder]>,
        path: inout StackState<OrdersDetailNavigationFeature.Path.State>
    ) {
        guard orders.wrappedValue.contains(where: { $0.id == orderID }) else {
            return
        }
        if path.count == 1, path.last?.detail?.orderID == orderID {
            return
        }
        path.removeAll()
        path.append(.detail(OrderDetailFeature.State(orderID: orderID, orders: orders)))
    }

    /// 移除已不存在的訂單詳情並保留仍存在元素的識別值
    ///
    /// - Parameters:
    ///   - orders: 目前可用的訂單快照
    ///   - path: 訂單詳情導覽路徑
    static func popUnavailable(
        orders: [LedgerOrder],
        path: inout StackState<OrdersDetailNavigationFeature.Path.State>
    ) {
        let availableIDs = Set(orders.map(\.id))
        let removedIDs = path.compactMap { $0.detail?.orderID }
            .filter { !availableIDs.contains($0) }
        for id in removedIDs {
            path.popDetail(orderID: id)
        }
    }
}
