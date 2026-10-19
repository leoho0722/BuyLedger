//
//  OrderListSnapshot.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/18.
//

/// 清單與工具列共用的單次篩選結果，不持有可變的資料引用
struct OrderListSnapshot: Equatable, Sendable {

    // MARK: - Properties

    /// 已套用全部篩選條件的訂單，保留來源順序
    let orders: [LedgerOrder]

    /// 與訂單順序相同的識別值，供工具列顯示筆數
    let ids: [LedgerOrder.ID]

    /// 篩選結果非空且每筆都已勾選時為真
    let isAllSelected: Bool
}
