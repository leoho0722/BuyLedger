//
//  RootFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// App 根層級狀態與導覽。
@Reducer
struct RootFeature {

    // MARK: - State

    /// App 根層級狀態。
    @ObservableState
    struct State: Equatable {

        /// 目前選取的主要分頁。
        var selectedTab: RootTab = .dashboard

        /// 訂單功能狀態。
        var orders = OrdersFeature.State()

        /// 匯率工具狀態。
        var fx = FxFeature.State()

        /// 報價試算狀態。
        var quote = QuoteFeature.State()

        /// 設定頁狀態。
        var settings = SettingsFeature.State()

    }

    // MARK: - Action

    /// App 根層級可處理的事件。
    @CasePathable
    enum Action: Equatable {

        /// 使用者切換主要分頁。
        case tabSelected(RootTab)

        /// 從非訂單分頁（如 Dashboard 的 onboarding）發起「新訂單」流程；會同時把 selectedTab 切到 `.orders` 並把 ``OrdersFeature/State/editOrder`` 設好，讓 ``OrdersView`` 的 sheet 能立刻顯示。
        case startNewOrder

        /// 使用者從側邊欄智慧分組點擊狀態，跳到訂單頁並套用篩選。
        case smartGroupSelected(OrderStatus)

        /// 使用者從客戶名單點擊客戶，跳到訂單頁並把搜尋字串設為客戶名。
        case customerSelected(String)

        /// 使用者從分析頁點擊類別 bar，跳到訂單頁並把搜尋字串設為類別名。
        case categorySelected(String)

        /// 訂單功能事件。
        case orders(OrdersFeature.Action)

        /// 匯率工具事件。
        case fx(FxFeature.Action)

        /// 報價試算事件。
        case quote(QuoteFeature.Action)

        /// 設定頁事件。
        case settings(SettingsFeature.Action)
    }

    // MARK: - Reducer Body

    /// App 根層級 reducer。
    var body: some Reducer<State, Action> {
        Scope(state: \.orders, action: \.orders) {
            OrdersFeature()
        }

        Scope(state: \.fx, action: \.fx) {
            FxFeature()
        }

        Scope(state: \.quote, action: \.quote) {
            QuoteFeature()
        }

        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }

        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none

            case .startNewOrder:
                state.selectedTab = .orders
                state.orders.editOrder = OrderEditFeature.State()
                return .none

            case let .smartGroupSelected(status):
                state.selectedTab = .orders
                state.orders.selectedStatus = .status(status)
                state.orders.selectedDatePeriod = .all
                state.orders.selectedOrderID = state.orders.filteredOrders.first?.id
                return .none

            case let .customerSelected(name):
                state.selectedTab = .orders
                state.orders.searchText = name
                state.orders.selectedStatus = .all
                state.orders.selectedDatePeriod = .all
                state.orders.selectedOrderID = state.orders.filteredOrders.first?.id
                return .none

            case let .categorySelected(category):
                state.selectedTab = .orders
                state.orders.searchText = category
                state.orders.selectedStatus = .all
                state.orders.selectedDatePeriod = .all
                state.orders.selectedOrderID = state.orders.filteredOrders.first?.id
                return .none

            case .orders:
                return .none

            case .fx:
                return .none

            case .quote:
                return .none

            case .settings:
                return .none
            }
        }
    }
}
