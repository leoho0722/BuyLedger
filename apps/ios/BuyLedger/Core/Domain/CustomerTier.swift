//
//  CustomerTier.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

// MARK: - Computed Properties

extension CustomerTier {

    /// 顯示在介面中的分級名稱
    var title: String {
        switch self {
        case .new:
            "customers.list.label.new"
        case .regular:
            "customers.list.label.returning"
        case .vip:
            "VIP"
        }
    }
}
