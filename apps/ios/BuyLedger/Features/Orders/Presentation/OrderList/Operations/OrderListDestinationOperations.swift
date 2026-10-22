//
//  OrderListDestinationOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture

/// 清單目的地的提交、關閉與已套用篩選同步
enum OrderListDestinationOperations {

}

// MARK: - Internal Method

extension OrderListDestinationOperations {

    /// 處理目的地委派並在選取改變時通知容器
    ///
    /// - Parameters:
    ///   - action: 目的地內部事件或關閉事件
    ///   - state: 清單目前的狀態
    /// - Returns: 選取變更委派，或不需後續處理的效果
    static func apply(
        _ action: PresentationAction<OrderListFeature.Destination.Action>,
        state: inout OrderListFeature.State
    ) -> Effect<OrderListFeature.Action> {
        switch action {
        case .presented(.filterSheet(.delegate(.applied(let selection)))):
            let previousID = state.selectedOrderID
            OrdersFilterOperations.filterApplied(selection, state: &state)
            guard previousID != state.selectedOrderID else {
                return .none
            }
            return .send(.delegate(.selectionChanged(state.selectedOrderID)))

        case .presented(.filterSheet(.delegate(.cancelled))):
            state.destination = nil
            return .none

        case .presented(.categoryPicker(.delegate(.applied(let categories)))):
            let previousID = state.selectedOrderID
            OrdersFilterOperations.categoryApplied(categories, state: &state)
            guard previousID != state.selectedOrderID else {
                return .none
            }
            return .send(.delegate(.selectionChanged(state.selectedOrderID)))

        case .presented(.categoryPicker(.delegate(.cancelled))):
            state.destination = nil
            return .none

        case .presented(.filterSheet), .presented(.categoryPicker), .dismiss:
            return .none
        }
    }

    /// 將目前已套用篩選同步給面板，保留尚未套用的草稿
    ///
    /// - Parameter state: 清單與目前開啟的目的地狀態
    static func syncCommittedSelection(state: inout OrderListFeature.State) {
        let selection = state.committedFilterSelection
        switch state.destination {
        case .filterSheet:
            state.destination?.modify(\.filterSheet) {
                $0.committedFilterSelection = selection
            }

        case .categoryPicker:
            state.destination?.modify(\.categoryPicker) {
                $0.committedCategories = selection.categories
            }

        case nil:
            break
        }
    }

    /// 更新清單與目前目的地的日期脈絡，保留草稿與呈現欄位
    ///
    /// - Parameters:
    ///   - context: Root 或清單 reducer 提供的日期與行事曆
    ///   - state: 清單與目前開啟的目的地狀態
    static func refreshDateContext(
        _ context: OrderDateContext,
        state: inout OrderListFeature.State
    ) {
        state.dateContext = context
        switch state.destination {
        case .filterSheet:
            state.destination?.modify(\.filterSheet) {
                $0.dateContext = context
            }

        case .categoryPicker:
            state.destination?.modify(\.categoryPicker) {
                $0.dateContext = context
            }

        case nil:
            break
        }
    }
}
