//
//  CustomerTier.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//
//  資料形狀 (cases) 由 Generated/CustomerTier.generated.swift 產生；
//  本檔僅保留手寫業務邏輯。改欄位請改 shared/data-model/schema/ 後重新 generate。
//

import Foundation

// MARK: - Display Properties

extension CustomerTier {

    /// 顯示在介面中的分級名稱。
    var title: String {
        switch self {
        case .new:
            "新客"
        case .regular:
            "常客"
        case .vip:
            "VIP"
        }
    }
}
