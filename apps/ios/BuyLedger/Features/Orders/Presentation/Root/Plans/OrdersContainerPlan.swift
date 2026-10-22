//
//  OrdersContainerPlan.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

/// 依請求與唯讀快照計算容器建立表單前需要解析的識別值與時間
enum OrdersContainerPlan {

}

// MARK: - Internal Method

extension OrdersContainerPlan {

    /// 建立表單或合併候選時才需要解析目前時間與行事曆，純轉送的請求不需要
    ///
    /// - Parameters:
    ///   - request: 清單或詳情的操作請求
    ///   - state: 容器的唯讀快照
    /// - Returns: 是否應由 reducer 解析目前時間與行事曆
    static func requiresDateContext(_ request: OrderRequest, state: OrdersFeature.State) -> Bool {
        if requiresFormID(request, state: state) {
            return true
        }
        if case .merge(let id) = request, state.list.dateContext == nil {
            return state.orders.contains {
                $0.id == id && OrderStatusRules.canMerge(status: $0.status)
            }
        }
        return false
    }

    /// 新增與有效編輯需要消耗表單識別值，合併與其餘請求不需要
    ///
    /// - Parameters:
    ///   - request: 清單或詳情的操作請求
    ///   - state: 容器的唯讀快照
    /// - Returns: 是否應由 reducer 解析新的表單識別值
    static func requiresFormID(_ request: OrderRequest, state: OrdersFeature.State) -> Bool {
        switch request {
        case .create:
            return true

        case .edit(let id):
            return state.orders.contains { $0.id == id }

        case .merge, .delete, .showDetail, .batchStatusChange, .changeStatus, .aiSummary:
            return false
        }
    }
}
