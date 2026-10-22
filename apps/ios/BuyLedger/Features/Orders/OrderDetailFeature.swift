//
//  OrderDetailFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation

/// 訂單詳情的內容與操作請求，寫入與呈現交給容器
@Reducer
struct OrderDetailFeature {

    // MARK: - State

    /// 詳情的訂單識別值與唯讀共用資料
    @ObservableState
    struct State: Equatable {

        /// 目前顯示詳情的訂單識別值
        let orderID: LedgerOrder.ID

        /// 容器、載入與寫入子層共用的訂單，詳情只讀取
        @SharedReader var orders: [LedgerOrder]

        /// 目前訂單；共用資料已移除時為 `nil`
        var order: LedgerOrder? {
            orders.first { $0.id == orderID }
        }

        /// 狀態選單的選項，只有已合併訂單保留已合併
        var selectableStatuses: [OrderStatus] {
            guard let order else {
                return []
            }
            return OrderStatusRules.selectableStatuses(for: order.status)
        }

        /// 是否可開始合併，取消與已合併訂單不適用
        var canMerge: Bool {
            guard let order else {
                return false
            }
            return OrderStatusRules.canMerge(status: order.status)
        }

        /// 成本圖表使用的金額與語意色調
        var costComponents: [OrderCostBreakdown.Component] {
            guard let order else {
                return []
            }
            return OrderCostBreakdown.components(for: order)
        }

        /// 訂單來源去除前後空白後的文字，空白時顯示空狀態符號
        var orderSourceText: String {
            let name = order?.orderSource.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return name.isEmpty ? "—" : name
        }

        /// 商品類別去除空白後以「、」串接的文字，沒有有效類別時顯示空狀態符號
        var categoriesText: String {
            let names = Self.validNames(order?.categories ?? [])
            return names.isEmpty ? "—" : names.joined(separator: "、")
        }

        /// 開團名稱去除空白後以「、」串接的文字；沒有有效開團時為 `nil`，畫面改顯示未歸團
        var campaignNamesText: String? {
            let names = Self.validNames(order?.campaignNames ?? [])
            return names.isEmpty ? nil : names.joined(separator: "、")
        }

        /// 備註去除前後空白後是否仍有內容，決定詳情是否顯示備註
        var hasNotes: Bool {
            guard let order else {
                return false
            }
            return !order.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        /// 有無卡折抵或補款金額，決定詳情是否顯示無卡明細卡片
        var hasCardlessAdjustments: Bool {
            guard let order else {
                return false
            }
            return order.cardlessDeductionAmount > 0 || order.cardlessSupplementAmount > 0
        }

        /// 總成本是否大於零，決定詳情是否顯示成本拆解
        var hasCostBreakdown: Bool {
            guard let order else {
                return false
            }
            return order.summary.totalCost > 0
        }

        /// 以容器的唯讀共用引用建立詳情
        ///
        /// - Parameters:
        ///   - orderID: 要顯示的訂單識別值
        ///   - orders: 共用訂單的唯讀引用
        init(orderID: LedgerOrder.ID, orders: SharedReader<[LedgerOrder]>) {
            self.orderID = orderID
            self._orders = orders
        }

        /// 去除前後空白並排除空白名稱，保留原有順序
        ///
        /// - Parameter names: 原始名稱
        /// - Returns: 去除空白後仍有內容的名稱
        private static func validNames(_ names: [String]) -> [String] {
            names
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
    }

    // MARK: - Action

    /// 詳情互動與交給容器的請求
    enum Action {

        /// 使用者在詳情上的操作
        ///
        /// - Parameter action: 選單操作
        case view(View)

        /// 請容器決定呈現或寫入
        ///
        /// - Parameter action: 訂單操作請求
        case delegate(Delegate)

        /// 詳情選單送出的互動
        @CasePathable
        enum View {

            /// 選擇新的訂單狀態
            ///
            /// - Parameter status: 要套用的新狀態
            case statusChanged(OrderStatus)

            /// 點擊編輯訂單
            case editTapped

            /// 點擊合併訂單
            case mergeTapped

            /// 點擊刪除訂單
            case deleteTapped
        }

        /// 詳情交給容器處理的事件
        @CasePathable
        enum Delegate: Equatable {

            /// 要求容器執行訂單操作
            ///
            /// - Parameter request: 目前訂單的操作請求
            case requested(OrderRequest)
        }
    }

    // MARK: - Body

    /// 將互動轉成請求，不啟動非同步工作
    var body: some Reducer<State, Action> {
        Reduce(core)
    }
}

// MARK: - Private Method

private extension OrderDetailFeature {

    /// 將詳情操作交給容器，不修改共用訂單
    ///
    /// - Parameters:
    ///   - state: 詳情的唯讀狀態
    ///   - action: 使用者互動或委派
    /// - Returns: 容器需要處理的訂單請求
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .view(.statusChanged(let status)):
            return .send(.delegate(.requested(.changeStatus(id: state.orderID, status: status))))

        case .view(.editTapped):
            return .send(.delegate(.requested(.edit(state.orderID))))

        case .view(.mergeTapped):
            return .send(.delegate(.requested(.merge(state.orderID))))

        case .view(.deleteTapped):
            return .send(.delegate(.requested(.delete(state.orderID))))

        case .delegate:
            return .none
        }
    }
}
