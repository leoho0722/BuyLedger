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

    /// 依寫入委派計算詳情移除、表單收尾與失敗通知
    ///
    /// - Parameters:
    ///   - result: 寫入子層已完成的結果
    ///   - state: 寫入子層處理後的容器唯讀快照
    /// - Returns: 容器應套用的各子層變更
    /// - Note: 存檔與合併不自動開啟詳情；此方法只回傳結果，不修改狀態
    static func writeResult(
        _ result: OrderWritesFeature.Action.Delegate,
        state: OrdersFeature.State
    ) -> OrdersWriteOutcome {
        var outcome = OrdersWriteOutcome()
        switch result {
        case .saved:
            break

        case .merged(let id):
            outcome.detailPopIDs = state.orders.first { $0.id == id }?.mergedSourceIDs ?? []

        case .deleted(let id):
            outcome.detailPopIDs = [id]
            outcome.closesEditOf = id

        case .failed(let failure):
            outcome.shouldPopUnavailableDetails = failure == .merge
            outcome.notice = .writeFailure(TextState(LocalizedStringKey(failure.message)))
        }
        return outcome
    }
}
