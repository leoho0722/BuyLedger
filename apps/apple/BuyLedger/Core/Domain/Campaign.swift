//
//  Campaign.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//
//  資料形狀 (stored properties、init) 由 Generated/Campaign.generated.swift 產生；
//  本檔僅保留手寫業務邏輯 (結團判定)。
//  改欄位請改 shared/data-model/schema/ 後重新 generate。
//

import Foundation

// MARK: - Computed Properties

extension Campaign {

    /// 是否已結團。
    var isSettled: Bool {
        settledDate != nil
    }
}
