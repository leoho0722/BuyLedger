//
//  OrderRequestPlan.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

/// 依訂單快照解析請求，交由容器套用的操作值
enum OrderRequestPlan {

    /// 請求的訂單不存在或不適用
    case none

    /// 建立新增或編輯表單
    ///
    /// - Parameter original: 編輯的訂單；新增時為 `nil`
    case edit(LedgerOrder?)

    /// 由容器帶入日期脈絡，建立合併候選清單
    ///
    /// - Parameter primary: 發起合併的主訂單
    case merge(LedgerOrder)

    /// 呈現容器的目的地，目前用於刪除確認
    ///
    /// - Parameter destination: 容器要呈現的目的地
    case present(OrdersPresentationFeature.Destination.State)

    /// 推入訂單詳情
    ///
    /// - Parameter id: 訂單識別值
    case showDetail(LedgerOrder.ID)

    /// 轉送寫入請求
    ///
    /// - Parameter action: 寫入子層的請求
    case write(OrderWritesFeature.Action)

    /// 依目前設定呈現 AI 摘要或未啟用提示
    case aiSummary
}

// MARK: - Internal Method

extension OrderRequestPlan {

    /// 只依訂單值決定後續操作，不修改容器
    ///
    /// - Parameters:
    ///   - request: 清單或詳情的操作請求
    ///   - orders: 目前共用訂單的快照
    /// - Returns: 容器應套用的呈現或寫入操作
    static func fulfill(_ request: OrderRequest, orders: [LedgerOrder]) -> Self {
        switch request {
        case .create:
            return .edit(nil)

        case .edit(let id):
            guard let order = orders.first(where: { $0.id == id }) else {
                return .none
            }
            return .edit(order)

        case .merge(let id):
            guard let primary = orders.first(where: { $0.id == id }),
                  OrderStatusRules.canMerge(status: primary.status) else {
                return .none
            }
            return .merge(primary)

        case .delete(let id):
            guard let order = orders.first(where: { $0.id == id }) else {
                return .none
            }
            return .present(.deleteConfirmation(for: order))

        case .showDetail(let id):
            guard orders.contains(where: { $0.id == id }) else {
                return .none
            }
            return .showDetail(id)

        case .batchStatusChange(let changed):
            return .write(.batchStatusChangeRequested(changed))

        case .changeStatus(let id, let status):
            return .write(.statusChangeRequested(id: id, status: status))

        case .aiSummary:
            return .aiSummary
        }
    }
}
