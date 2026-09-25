//
//  CustomersFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/12.
//

import ComposableArchitecture
import Foundation

/// 客戶彙總功能，提供訂單投影與客戶消費摘要
@Reducer
struct CustomersFeature {

    // MARK: - State

    /// 客戶彙總功能狀態
    @ObservableState
    struct State: Equatable {

        /// 來源訂單；由 ``RootFeature`` 與 ``OrdersFeature/State/orders`` 保持同步
        var orders: [LedgerOrder] = []

        /// 依累計消費由高到低排序的客戶彙總列
        var customers: [CustomerRow] {
            CustomerRow.aggregate(orders: orders)
        }
    }

    // MARK: - Action

    /// 客戶彙總功能可處理的事件
    @CasePathable
    enum Action: Equatable {

        /// 使用者可直接操作的客戶名單事件
        ///
        /// - Parameter action: 使用者在客戶名單畫面執行的操作
        case view(View)

        /// 由根功能轉發的跨功能意圖
        ///
        /// - Parameter action: 要交給根功能處理的結果
        case delegate(Delegate)

        /// 客戶名單畫面事件
        @CasePathable
        enum View: Equatable {

            /// 畫面出現時觸發訂單載入
            case task

            /// 使用者點擊客戶列或強調卡
            ///
            /// - Parameter name: 被點擊的客戶姓名
            case customerTapped(String)
        }

        /// 客戶名單可能發出的跨 feature 意圖
        @CasePathable
        enum Delegate: Equatable {

            /// 請根功能觸發訂單載入
            case ordersLoadRequested

            /// 使用者已選定客戶，交由根功能導覽至訂單頁
            ///
            /// - Parameter name: 被選定的客戶姓名
            case customerSelected(String)
        }
    }

    // MARK: - Body

    /// 客戶彙總功能 reducer
    var body: some Reducer<State, Action> {
        Reduce(core)
    }
}

// MARK: - Private Method

private extension CustomersFeature {

    /// 依收到的事件更新客戶彙總狀態，並回傳要執行的 Effect
    ///
    /// - Parameters:
    ///   - state: 目前的客戶彙總狀態
    ///   - action: 這次收到的客戶彙總事件
    /// - Returns: 接下來要執行的 Effect，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .view(.task):
            return .send(.delegate(.ordersLoadRequested))

        case let .view(.customerTapped(name)):
            return .send(.delegate(.customerSelected(name)))

        case .delegate:
            return .none
        }
    }
}
