//
//  OrdersDetailNavigationFeature+Path.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture

// MARK: - Nested Types

extension OrdersDetailNavigationFeature {

    /// 詳情導覽可推入的詳情畫面
    @Reducer
    enum Path {

        /// 提供詳情內容並將操作交給容器
        ///
        /// - Parameter feature: 訂單詳情的 Feature
        case detail(OrderDetailFeature)
    }
}

// MARK: - Internal Method

extension StackState where Element == OrdersDetailNavigationFeature.Path.State {

    /// 移除指定訂單的詳情與後續元素，保留前方元素的識別值
    ///
    /// - Parameter orderID: 要移除的訂單識別值
    mutating func popDetail(orderID: LedgerOrder.ID) {
        let shownID = ids.first {
            self[id: $0]?.detail?.orderID == orderID
        }
        guard let shownID else {
            return
        }
        pop(from: shownID)
    }
}

// MARK: - Equatable

extension OrdersDetailNavigationFeature.Path.State: Equatable {

}
