//
//  OrdersDetailNavigationFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture

/// 訂單詳情導覽子 Feature，管理 iPhone 推入堆疊與 iPad 右欄詳情，本身不持有 View
@Reducer
struct OrdersDetailNavigationFeature {

    // MARK: - State

    /// 詳情導覽的堆疊與右欄狀態
    @ObservableState
    struct State: Equatable {

        /// 共用訂單的唯讀引用，建立與同步詳情時使用
        private let orders: SharedReader<[LedgerOrder]>

        /// iPhone 詳情的導覽路徑
        var path = StackState<Path.State>()

        /// iPad 右欄的詳情，與清單選取同步
        var regularDetail: OrderDetailFeature.State?

        /// 以共用訂單建立詳情導覽，iPad 右欄預設顯示第一筆
        ///
        /// - Parameter orders: 共用訂單的唯讀引用
        init(orders: SharedReader<[LedgerOrder]>) {
            self.orders = orders
            self.regularDetail = orders.wrappedValue.first.map {
                OrderDetailFeature.State(orderID: $0.id, orders: orders)
            }
        }

        /// 經唯一入口推入訂單詳情，先清空舊路徑
        ///
        /// - Parameter orderID: 要顯示的訂單識別值
        mutating func showDetail(orderID: LedgerOrder.ID) {
            OrdersDetailSelection.showDetail(orderID: orderID, orders: orders, path: &path)
        }

        /// 套用寫入結果：移除已刪除或合併掉的詳情，合併失敗時一併移除已不存在的詳情
        ///
        /// - Parameter outcome: 寫入子層的結果計畫
        mutating func apply(_ outcome: OrdersWriteOutcome) {
            for id in outcome.detailPopIDs {
                path.popDetail(orderID: id)
            }
            if outcome.shouldPopUnavailableDetails {
                popUnavailable(orders: orders.wrappedValue)
            }
        }

        /// 載入完成後移除已不存在訂單的詳情，右欄依清單選取顯示對應的訂單
        ///
        /// - Parameter selectedOrderID: 清單目前選取的訂單識別值
        mutating func applyLoadedOrders(selectedOrderID: LedgerOrder.ID?) {
            popUnavailable(orders: orders.wrappedValue)
            syncRegularDetail(selectedOrderID: selectedOrderID)
        }

        /// 依清單選取同步右欄詳情，保留相同訂單的子狀態
        ///
        /// - Parameter selectedOrderID: 清單目前選取的訂單識別值
        mutating func syncRegularDetail(selectedOrderID: LedgerOrder.ID?) {
            regularDetail = OrdersDetailSelection.detail(
                id: selectedOrderID,
                current: regularDetail,
                orders: orders
            )
        }

        /// 移除已不存在訂單的詳情，保留仍存在元素的識別值
        ///
        /// - Parameter orders: 目前可用的訂單快照
        private mutating func popUnavailable(orders: [LedgerOrder]) {
            OrdersDetailSelection.popUnavailable(orders: orders, path: &path)
        }
    }

    // MARK: - Action

    /// 詳情導覽堆疊與 iPad 右欄收到的事件
    enum Action {

        /// iPhone 詳情導覽堆疊事件
        ///
        /// - Parameter action: 詳情導覽堆疊收到的事件
        case path(StackActionOf<Path>)

        /// iPad 右欄詳情的操作與委派
        ///
        /// - Parameter action: 詳情事件
        case regularDetail(OrderDetailFeature.Action)
    }

    // MARK: - Body

    /// 組合堆疊與右欄詳情子層，本層沒有自身邏輯
    var body: some Reducer<State, Action> {
        Reduce(core)
            .forEach(\.path, action: \.path)
            .ifLet(\.regularDetail, action: \.regularDetail) {
                OrderDetailFeature()
            }
    }
}

// MARK: - Private Method

private extension OrdersDetailNavigationFeature {

    /// 堆疊與右欄詳情的事件由子層自行處理，本層逐一回傳 `.none`
    ///
    /// - Parameters:
    ///   - state: 詳情導覽狀態
    ///   - action: 堆疊或右欄詳情事件
    /// - Returns: 沒有後續效果，回傳 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .path:
            return .none

        case .regularDetail:
            return .none
        }
    }
}
