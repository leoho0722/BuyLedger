//
//  OrderMergeSavePlan.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import Foundation

/// 合併寫入所需的新訂單、來源與樂觀更新前後的完整快照
struct OrderMergeSavePlan: Equatable, Sendable {

    // MARK: - Properties

    /// 要建立的合併結果
    let order: LedgerOrder

    /// 要標記為已合併的來源訂單編號
    let sourceIDs: [LedgerOrder.ID]

    /// 寫入失敗時要回復的合併前快照
    let previousOrders: [LedgerOrder]

    /// 同時包含新增結果與來源已合併狀態的樂觀更新快照
    let updatedOrders: [LedgerOrder]

    // MARK: - Init

    /// 依現有訂單與合併草稿計算一次寫入需要的快照
    ///
    /// - Parameters:
    ///   - edit: 合併確認表單
    ///   - orders: 合併前的訂單
    ///   - newOrderID: 新訂單完整編號來源
    init(edit: OrderEditFeature.State, orders: [LedgerOrder], newOrderID: () -> String) {
        let result = OrderDraft.resolveWriteResult(
            edit,
            existingOrders: orders,
            newOrderID: newOrderID
        )
        self.order = result.order
        self.sourceIDs = edit.mergeSourceIDs
        self.previousOrders = orders
        var updated = orders
        if result.isNewOrder {
            updated.insert(result.order, at: 0)
        } else if let index = updated.firstIndex(where: { $0.id == result.order.id }) {
            updated[index] = result.order
        }
        self.updatedOrders = updated.map { order in
            guard edit.mergeSourceIDs.contains(order.id), order.id != result.order.id else {
                return order
            }
            return order.withStatus(.merged)
        }
    }
}
