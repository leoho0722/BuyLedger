//
//  CustomerRank.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

/// 強調區塊的單一名次資料
struct CustomerRank: Equatable {

    // MARK: - Properties

    /// 名次 (由 1 起算，依累計消費由高到低)
    let rank: Int

    /// 客戶彙總列
    let customer: CustomerRow
}

// MARK: - Identifiable

extension CustomerRank: Identifiable {

    /// 沿用客戶姓名作為識別值 (同名客戶已在彙總時合併)
    var id: String {
        customer.id
    }
}
