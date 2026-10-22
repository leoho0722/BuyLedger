//
//  OrdersCascadeOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation

/// 計算本機交易完成後應套用到共用訂單的調整
enum OrdersCascadeOperations {

}

// MARK: - Nested Types

extension OrdersCascadeOperations {

    /// 父層在開團或主檔交易完成後要求套用的訂單調整
    enum Request: Equatable, Sendable {

        /// 移除已刪除的開團歸屬
        ///
        /// - Parameter name: 已刪除的開團名稱
        case campaignDeleted(String)

        /// 替換開團歸屬中的名稱
        ///
        /// - Parameters:
        ///   - from: 原開團名稱
        ///   - to: 新開團名稱
        case campaignRenamed(from: String, to: String)

        /// 替換指定種類的主檔引用
        ///
        /// - Parameters:
        ///   - kind: 已改名的主檔種類
        ///   - rename: 原名稱與新名稱
        case lookupItemRenamed(kind: LookupKind, rename: LookupItemRename)
    }
}

// MARK: - Internal Method

extension OrdersCascadeOperations {

    /// 依調整種類更新訂單，不執行持久化或寫入共用引用
    ///
    /// - Parameters:
    ///   - request: 開團或主檔的調整請求
    ///   - orders: 寫入子層鎖定後提供的訂單
    static func apply(_ request: Request, in orders: inout [LedgerOrder]) {
        switch request {
        case .campaignDeleted(let name):
            campaignDeleted(name, in: &orders)

        case .campaignRenamed(let from, let to):
            campaignRenamed(from: from, to: to, in: &orders)

        case .lookupItemRenamed(let kind, let rename):
            lookupItemRenamed(rename, kind: kind, in: &orders)
        }
    }

    /// 依編號套用已正規化的付款方式快照，保留未受影響的訂單
    ///
    /// - Parameters:
    ///   - updatedOrders: 主檔交易完成後的權威訂單快照
    ///   - orders: 寫入子層鎖定後提供的訂單
    static func applyPaymentMethodFlags(
        _ updatedOrders: [LedgerOrder],
        in orders: inout [LedgerOrder]
    ) {
        let updatedByID = Dictionary(
            uniqueKeysWithValues: updatedOrders.map {
                ($0.id, $0)
            }
        )
        orders = orders.map {
            updatedByID[$0.id] ?? $0
        }
    }

    /// 依編號替換現有訂單，不重新插入等待期間被刪除的訂單
    ///
    /// - Parameters:
    ///   - updatedOrders: 寫入成功的訂單
    ///   - orders: 寫入子層鎖定後提供的訂單
    static func applyUpdates(_ updatedOrders: [LedgerOrder], in orders: inout [LedgerOrder]) {
        for order in updatedOrders {
            if let index = orders.firstIndex(where: { $0.id == order.id }) {
                orders[index] = order
            }
        }
    }
}

// MARK: - Private Method

private extension OrdersCascadeOperations {

    /// 清除訂單對已刪除開團的歸屬，保留其他團名
    ///
    /// - Parameters:
    ///   - name: 已刪除的開團名稱
    ///   - orders: 要就地更新的訂單副本
    static func campaignDeleted(_ name: String, in orders: inout [LedgerOrder]) {
        let name = trimmedName(name)
        guard !name.isEmpty else {
            return
        }
        orders = orders.map { order in
            guard order.campaignNames.contains(name) else {
                return order
            }
            return order.removingCampaign(name)
        }
    }

    /// 去掉業務名稱的頭尾空白與換行
    ///
    /// - Parameter name: 待正規化的名稱
    /// - Returns: 去除頭尾空白後的名稱
    static func trimmedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 把指定開團的舊名稱換成新名稱，保留其他開團歸屬
    ///
    /// - Parameters:
    ///   - from: 原開團名稱
    ///   - to: 新開團名稱
    ///   - orders: 要就地更新的訂單副本
    static func campaignRenamed(from: String, to: String, in orders: inout [LedgerOrder]) {
        guard let rename = normalizedRename(from: from, to: to) else {
            return
        }
        orders = orders.map { order in
            guard order.campaignNames.contains(rename.oldName) else {
                return order
            }
            return order.renamingCampaign(from: rename.oldName, to: rename.newName)
        }
    }

    /// 只接受兩端非空且不同的改名，並正規化頭尾空白
    ///
    /// - Parameters:
    ///   - from: 原名稱
    ///   - to: 新名稱
    /// - Returns: 合法的改名；任一端空白或名稱相同時為 `nil`
    static func normalizedRename(from: String, to: String) -> LookupItemRename? {
        let from = trimmedName(from)
        let to = trimmedName(to)
        guard !from.isEmpty, !to.isEmpty, from != to else {
            return nil
        }
        return LookupItemRename(oldName: from, newName: to)
    }

    /// 依主檔種類替換訂單引用，只改引用舊名稱的欄位
    ///
    /// - Parameters:
    ///   - rename: 原主檔名稱與新名稱
    ///   - kind: 已改名的主檔種類
    ///   - orders: 要就地更新的訂單副本
    static func lookupItemRenamed(
        _ rename: LookupItemRename,
        kind: LookupKind,
        in orders: inout [LedgerOrder]
    ) {
        guard let rename = normalizedRename(from: rename.oldName, to: rename.newName) else {
            return
        }
        orders = orders.map { order in
            guard kind.isReferenced(by: order, name: rename.oldName) else {
                return order
            }
            return kind.renamingReference(in: order, from: rename.oldName, to: rename.newName)
        }
    }
}
