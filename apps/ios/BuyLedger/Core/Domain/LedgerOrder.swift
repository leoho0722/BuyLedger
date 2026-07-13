//
//  LedgerOrder.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

// MARK: - Static Properties

extension LedgerOrder {

    /// 單筆訂單可附加的照片張數上限
    ///
    /// 作為唯一來源：編輯表單的 PhotosPicker `maxSelectionCount`、計數標籤與 reducer 的截斷守門皆引用此值
    static let maxPhotoCount = 5
}

// MARK: - Computed Properties

extension LedgerOrder {

    /// 訂單的財務摘要
    var summary: OrderSummary {
        OrderSummary(order: self)
    }

    /// 這筆訂單是否由多筆訂單合併而成 (合併後產生的新訂單)
    var isMergeResult: Bool {
        !mergedSourceIDs.isEmpty
    }

    /// 是否計入「類別收益」彙總
    ///
    /// 只算「原始訂單」、不算合併產生的新單，避免同一筆收益被算兩次
    ///
    /// 原始訂單 (不是合併出來的) 才入組：狀態沿用既有 realized 規則、並額外放行「已合併」，
    /// 讓被合併掉的舊單仍以它原本的類別、金額與日期入帳
    var contributesToCategoryBreakdown: Bool {
        !isMergeResult && (OrderStatus.realizedStatuses.contains(status) || status == .merged)
    }

    /// 列表中顯示的商品摘要，每項商品各自一行，名稱後接購買數量 (例如「藍牙耳機 x2」)
    var itemSummary: String {
        guard !items.isEmpty else {
            return "未命名商品"
        }

        return items.map { "\($0.name) x\($0.quantity)" }.joined(separator: "\n")
    }
}
