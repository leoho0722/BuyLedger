//
//  OrdersContainerPlan+Writes.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

// MARK: - Internal Method

extension OrdersContainerPlan {

    /// 依寫入委派計算清單選取、詳情移除、表單收尾與失敗通知，只回傳結果不修改狀態
    ///
    /// - Parameters:
    ///   - result: 寫入子層已完成的結果
    ///   - state: 寫入子層處理後的容器唯讀快照
    /// - Returns: 容器應套用的各子層變更
    static func writeResult(
        _ result: OrderWritesFeature.Action.Delegate,
        state: OrdersFeature.State
    ) -> OrdersWriteOutcome {
        var outcome = OrdersWriteOutcome()
        switch result {
        case .saved(let id, let isNewOrder):
            if isNewOrder, state.list.selectedOrderID != id {
                outcome.selection = OrdersWriteOutcome.Selection(orderID: id, shouldNotify: true)
            }

        case .merged(let id):
            outcome.selection = OrdersWriteOutcome.Selection(
                orderID: id,
                shouldNotify: state.list.selectedOrderID != id
            )
            outcome.detailPopIDs = state.orders.first { $0.id == id }?.mergedSourceIDs ?? []

        case .optionAdded(let option):
            outcome.addedOption = option

        case .deleted(let id):
            outcome.detailPopIDs = [id]
            outcome.closesEditOf = id
            if state.list.selectedOrderID == id {
                var list = state.list
                list.selectFirstFilteredOrder()
                outcome.selection = OrdersWriteOutcome.Selection(
                    orderID: list.selectedOrderID,
                    shouldNotify: true
                )
            }

        case .failed(let failure):
            outcome.shouldPopUnavailableDetails = failure == .merge
            outcome.notice = .writeFailure(TextState(LocalizedStringKey(failure.message)))
        }
        return outcome
    }
}
