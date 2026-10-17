//
//  OrdersDetailSelection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture

/// 訂單詳情的選取查詢與堆疊操作，只接收唯讀訂單及導覽子狀態
enum OrdersDetailSelection {

}

// MARK: - Internal Method

extension OrdersDetailSelection {

    /// 依目前選取查出右欄詳情，同一識別值保留原詳情狀態
    ///
    /// - Parameters:
    ///   - id: 清單目前選取的訂單識別值
    ///   - current: 已建立的右欄詳情
    ///   - orders: 共用訂單的唯讀引用
    /// - Returns: 選取不存在時為 `nil`，否則為對應詳情
    static func detail(
        id: LedgerOrder.ID?,
        current: OrderDetailFeature.State?,
        orders: SharedReader<[LedgerOrder]>
    ) -> OrderDetailFeature.State? {
        guard let id, orders.wrappedValue.contains(where: { $0.id == id }) else {
            return nil
        }
        if current?.orderID == id {
            return current
        }
        return OrderDetailFeature.State(orderID: id, orders: orders)
    }

    /// 經唯一入口以指定訂單取代詳情堆疊，訂單不存在時保留原路徑
    ///
    /// - Parameters:
    ///   - orderID: 要顯示的訂單識別值
    ///   - orders: 共用訂單的唯讀引用
    ///   - path: iPhone 的詳情導覽堆疊
    static func showDetail(
        orderID: LedgerOrder.ID,
        orders: SharedReader<[LedgerOrder]>,
        path: inout StackState<OrdersDetailNavigationFeature.Path.State>
    ) {
        guard orders.wrappedValue.contains(where: { $0.id == orderID }) else {
            return
        }
        path.removeAll()
        path.append(.detail(OrderDetailFeature.State(orderID: orderID, orders: orders)))
    }

    /// 移除已不存在的訂單詳情並保留仍存在元素的識別值
    ///
    /// - Parameters:
    ///   - orders: 目前可用的訂單快照
    ///   - path: iPhone 的詳情導覽堆疊
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
