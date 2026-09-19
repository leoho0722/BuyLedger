//
//  PaymentReceiptStatus.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/05/30.
//

import Foundation

// MARK: - Computed Properties

extension PaymentReceiptStatus {

    /// 顯示在介面中的狀態名稱
    var title: String {
        switch self {
        case .pending:
            "待收款"
        case .received:
            "已收款"
        }
    }
}
