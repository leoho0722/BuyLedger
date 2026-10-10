//
//  OrdersContainerPlan+Requests.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation

// MARK: - Internal Method

extension OrdersContainerPlan {

    /// 依共用請求與資料快照決定要呈現的表單、要推入的詳情或要轉送的寫入
    ///
    /// - Parameters:
    ///   - request: 清單或詳情的操作請求
    ///   - state: 容器的唯讀快照
    ///   - context: reducer 解析後的目前時間與行事曆
    ///   - formID: 編輯或新增表單的識別值；其餘請求為 `nil`
    /// - Returns: 容器應套用的結果
    static func fulfill(
        _ request: OrderRequest,
        state: OrdersFeature.State,
        context: OrderDateContext?,
        formID: UUID?
    ) -> OrdersRequestOutcome {
        switch OrderRequestPlan.fulfill(request, orders: state.orders) {
        case .none:
            return .none

        case .edit(let original):
            guard let formID, let context else {
                return .none
            }
            let options = state.makeEditOptions(now: context.now, calendar: context.calendar)
            return .present(
                .edit(
                    OrderEditFeature.State(
                        original: original,
                        id: formID,
                        options: options,
                        currentDate: context.now,
                        defaultCurrency: state.defaultCurrency
                    )
                )
            )

        case .merge(let primary):
            guard let dateContext = state.list.dateContext ?? context else {
                return .none
            }
            return .present(
                .merge(
                    OrderMergeFeature.State(
                        primary: primary,
                        orders: state.orders,
                        dateContext: dateContext
                    )
                )
            )

        case .present(let destination):
            return .present(destination)

        case .showDetail(let id):
            return .showDetail(id)

        case .write(let action):
            return .write(action)

        case .aiSummary:
            guard state.aiSummarySettings.isEnabled else {
                return .present(.aiDisabled)
            }
            return .present(
                .aiSummary(
                    AISummaryFeature.State(
                        prompt: OrderSummaryPrompt.summaryPrompt(
                            orders: state.list.filteredOrders,
                            selectedCategory: state.list.selectedCategory
                        ),
                        model: state.aiSummarySettings.model
                    )
                )
            )
        }
    }
}
