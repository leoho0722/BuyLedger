//
//  OrdersDetailNavigationFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture

/// 訂單詳情導覽子 Feature，以同一條 `path` 管理窄版推入與寬版詳情，本身不持有 View
@Reducer
struct OrdersDetailNavigationFeature {

    // MARK: - State

    /// 詳情導覽的唯一堆疊狀態
    @ObservableState
    struct State: Equatable {

        /// 共用訂單的唯讀引用，建立與同步 `path` 詳情時使用
        private let orders: SharedReader<[LedgerOrder]>

        /// 訂單詳情導覽路徑，供窄版推入與寬版詳情欄共用
        var path = StackState<Path.State>()

        /// 以共用訂單建立詳情導覽，初始不開啟詳情
        ///
        /// - Parameter orders: 共用訂單的唯讀引用
        init(orders: SharedReader<[LedgerOrder]>) {
            self.orders = orders
        }

        /// 經唯一入口推入訂單詳情，先清空舊路徑；重開目前唯一詳情時保留原元素
        ///
        /// - Parameter orderID: 要顯示的訂單識別值
        mutating func showDetail(orderID: LedgerOrder.ID) {
            OrdersDetailSelection.showDetail(orderID: orderID, orders: orders, path: &path)
        }

        /// 清空所有詳情路徑，回到訂單根清單
        mutating func clearDetail() {
            path.removeAll()
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

        /// 載入完成後只移除已不存在訂單的詳情
        mutating func applyLoadedOrders() {
            popUnavailable(orders: orders.wrappedValue)
        }

        /// 移除已不存在訂單的詳情，保留仍存在元素的識別值
        ///
        /// - Parameter orders: 目前可用的訂單快照
        private mutating func popUnavailable(orders: [LedgerOrder]) {
            OrdersDetailSelection.popUnavailable(orders: orders, path: &path)
        }
    }

    // MARK: - Action

    /// 詳情導覽堆疊收到的事件
    enum Action {

        /// 詳情導覽堆疊事件
        ///
        /// - Parameter action: 詳情導覽堆疊收到的事件
        case path(StackActionOf<Path>)
    }

    // MARK: - Body

    /// 組合詳情導覽堆疊，本層沒有自身邏輯
    var body: some ReducerOf<Self> {
        Reduce(core)
            .forEach(\.path, action: \.path)
    }
}

// MARK: - Private Method

private extension OrdersDetailNavigationFeature {

    /// 回傳 `.none`，堆疊事件交由子層自行處理
    ///
    /// - Parameters:
    ///   - state: 詳情導覽狀態
    ///   - action: 堆疊事件
    /// - Returns: 沒有後續效果，回傳 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .path:
            return .none
        }
    }
}
