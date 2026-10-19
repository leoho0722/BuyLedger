//
//  OrderListInteraction.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

/// 訂單清單互動的純狀態更新與委派值
enum OrderListInteraction {

}

// MARK: - Internal Method

extension OrderListInteraction {

    /// 更新清單篩選或選取，回傳容器需要處理的事件
    ///
    /// - Parameters:
    ///   - action: 使用者的清單互動
    ///   - state: 清單狀態
    /// - Returns: 操作請求或選取變更；純清單變更回傳 `nil`
    static func apply(
        _ action: OrderListFeature.Action.View,
        state: inout OrderListFeature.State
    ) -> OrderListFeature.Action.Delegate? {
        switch action {
        case .task, .retryTapped, .categoryPickerTapped, .filterSheetTapped:
            return nil

        case .statusFilterSelected(let filter):
            OrdersFilterOperations.statusFilterSelected(filter, state: &state)
            return .selectionChanged(state.selectedOrderID)

        case .datePeriodSelected(let period):
            OrdersFilterOperations.datePeriodSelected(period, state: &state)
            return .selectionChanged(state.selectedOrderID)

        case .paymentMethodFilterSelected(let paymentMethod):
            OrdersFilterOperations.paymentMethodFilterSelected(paymentMethod, state: &state)
            return .selectionChanged(state.selectedOrderID)

        case .clearFiltersTapped:
            guard OrdersFilterOperations.clearFilters(state: &state) else {
                return nil
            }
            return .selectionChanged(state.selectedOrderID)

        case .searchTextChanged(let searchText):
            OrdersFilterOperations.searchTextChanged(searchText, state: &state)
            return .selectionChanged(state.selectedOrderID)

        case .orderSelected(let id):
            OrdersFilterOperations.orderSelected(id, state: &state)
            return .selectionChanged(id)

        case .editOrderTapped(let id):
            return .requested(.edit(id))

        case .newOrderTapped:
            return .requested(.create)

        case .mergeOrderTapped(let id):
            return .requested(.merge(id))

        case .selectionModeToggled:
            OrdersBatchOperations.selectionModeToggled(state: &state)
            return nil

        case .orderSelectionToggled(let id):
            OrdersBatchOperations.orderSelectionToggled(id, state: &state)
            return nil

        case .selectAllTapped:
            OrdersBatchOperations.selectAllTapped(state: &state)
            return nil

        case .clearSelectionTapped:
            OrdersBatchOperations.clearSelectionTapped(state: &state)
            return nil

        case .batchStatusChanged(let status):
            let changed = OrdersBatchOperations.batchStatusChanged(status, state: &state)
            guard let changed else {
                return nil
            }
            return .requested(.batchStatusChange(changed))

        case .deleteOrderTapped(let id):
            return .requested(.delete(id))

        case .aiSummaryTapped:
            return .requested(.aiSummary)

        case .orderTapped(let id):
            return .requested(.showDetail(id))
        }
    }
}
