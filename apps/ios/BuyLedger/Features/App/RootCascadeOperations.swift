//
//  RootCascadeOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation

/// 本機交易完成後同步根功能持有的訂單副本
enum RootCascadeOperations {}

// MARK: - Internal Method

extension RootCascadeOperations {

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

// MARK: - Private Method

private extension RootCascadeOperations {

    /// 去掉業務名稱的頭尾空白與換行
    ///
    /// - Parameter name: 待正規化的名稱
    /// - Returns: 去除頭尾空白後的名稱
    static func trimmedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 只接受兩端非空且不同的改名，並正規化頭尾空白
    ///
    /// - Parameters:
    ///   - from: 原名稱
    ///   - to: 新名稱
    /// - Returns: 合法的改名；任一端空白或名稱相同時為 nil
    static func normalizedRename(from: String, to: String) -> LookupItemRename? {
        let from = trimmedName(from)
        let to = trimmedName(to)
        guard !from.isEmpty, !to.isEmpty, from != to else {
            return nil
        }
        return LookupItemRename(oldName: from, newName: to)
    }
}
