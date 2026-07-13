//
//  CustomerTier.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

// MARK: - Display Properties

extension CustomerTier {

    /// 顯示在介面中的分級名稱
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
